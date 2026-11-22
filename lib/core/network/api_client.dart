import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/session_store.dart';
import 'api_exception.dart';

/// Cliente HTTP único do app.
///
/// - Injeta token e cabeçalhos padrão;
/// - Desembrulha o envelope `{status, message, result}` da API MAP-OS;
/// - Renova o token automaticamente (POST /refresh) em 401/403;
/// - Faz fallback para cache local em GETs quando não há conexão.
class ApiClient {
  ApiClient(this._session, {http.Client? client}) : _http = client ?? http.Client();

  final SessionStore _session;
  final http.Client _http;

  /// Chamado quando a sessão não pode mais ser renovada.
  VoidCallback? onSessionExpired;

  Future<bool>? _refreshing;

  String get baseUrl => _session.baseUrl ?? '';

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    if (baseUrl.isEmpty) {
      throw const ApiException('Servidor não configurado. Informe a URL do seu MAP-OS.');
    }
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) q[k] = v.toString();
    });
    final uri = Uri.parse('$baseUrl${AppConfig.apiPrefix}$path');
    return q.isEmpty ? uri : uri.replace(queryParameters: q);
  }

  Map<String, String> _headers({bool json = true, bool auth = true}) => {
        if (json) 'Content-Type': 'application/json',
        'Accept': 'application/json',
        'App-Version': AppConfig.appVersion,
        if (auth && _session.accessToken != null)
          'Authorization': 'Bearer ${_session.accessToken}',
      };

  // ---------------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------------

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool cache = false}) async {
    final uri = _uri(path, query);
    final cacheKey = uri.toString().replaceFirst(baseUrl, '');
    try {
      final res = await _send(() => _http.get(uri, headers: _headers()));
      final result = _decode(res);
      if (cache) await _session.writeCache(cacheKey, jsonEncode(result));
      return result;
    } on ApiException catch (e) {
      if (cache && e.isNetwork) {
        final cached = _session.readCache(cacheKey);
        if (cached != null) return jsonDecode(cached);
      }
      rethrow;
    }
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    final uri = _uri(path);
    final res = await _send(
      () => _http.post(uri, headers: _headers(auth: auth), body: jsonEncode(body ?? {})),
      retryOnAuth: auth,
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final uri = _uri(path);
    final res = await _send(() => _http.put(uri, headers: _headers(), body: jsonEncode(body ?? {})));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final uri = _uri(path);
    final res = await _send(() => _http.delete(uri, headers: _headers()));
    return _decode(res);
  }

  Future<dynamic> upload(
    String path, {
    required String field,
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = _uri(path);
    final res = await _send(() async {
      final req = http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers(json: false))
        ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
      return http.Response.fromStream(await _http.send(req));
    });
    return _decode(res);
  }

  /// Baixa bytes de uma URL absoluta autenticada (ex.: anexos da OS).
  Future<Uint8List> getBytes(String absoluteUrl) async {
    final res = await _send(() => _http.get(Uri.parse(absoluteUrl), headers: _headers(json: false)));
    if (res.statusCode != 200) {
      throw ApiException('Não foi possível carregar o arquivo.', statusCode: res.statusCode);
    }
    return res.bodyBytes;
  }

  /// Requisição externa simples (ex.: ViaCEP), sem cabeçalhos da API.
  Future<Map<String, dynamic>?> getExternalJson(Uri uri) async {
    try {
      final res = await _http.get(uri).timeout(AppConfig.requestTimeout);
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Internos
  // ---------------------------------------------------------------------------

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    bool retryOnAuth = true,
  }) async {
    var res = await _guard(request);
    if (retryOnAuth && (res.statusCode == 401 || res.statusCode == 403) && _session.hasSession) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        res = await _guard(request);
      }
      if (!refreshed || res.statusCode == 401) {
        await _session.clearSession();
        onSessionExpired?.call();
        throw const ApiException('Sua sessão expirou. Entre novamente.', statusCode: 401);
      }
    }
    return res;
  }

  Future<http.Response> _guard(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException('O servidor demorou para responder.', isNetwork: true);
    } on ApiException {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (kIsWeb && (msg.contains('failed to fetch') || msg.contains('xmlhttprequest'))) {
        throw const ApiException(
          'Não foi possível acessar o servidor. Verifique a URL e se o MAP-OS permite acesso (CORS).',
          isNetwork: true,
        );
      }
      throw const ApiException('Sem conexão com o servidor.', isNetwork: true);
    }
  }

  /// Garante uma única renovação concorrente.
  Future<bool> _refreshToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refresh = _session.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _http
          .post(
            _uri('/refresh'),
            headers: _headers(auth: false),
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(AppConfig.requestTimeout);
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final access = result?['access_token'] as String?;
      if (data['status'] != true || access == null) return false;
      await _session.saveTokens(access: access, refresh: result?['refresh_token'] as String?);
      return true;
    } catch (_) {
      return false;
    }
  }

  dynamic _decode(http.Response res) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      body = null;
    }

    if (body == null) {
      final hint = res.statusCode == 404 ? 'Recurso não encontrado' : 'Resposta inválida do servidor';
      throw ApiException('$hint (${res.statusCode}).', statusCode: res.statusCode);
    }

    final ok = body['status'] == true && res.statusCode >= 200 && res.statusCode < 300;
    if (!ok) {
      throw ApiException(_cleanMessage(body['message']), statusCode: res.statusCode);
    }
    return body['result'];
  }

  static String _cleanMessage(dynamic message) {
    final text = (message ?? 'Erro desconhecido').toString();
    return text.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
