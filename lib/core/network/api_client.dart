import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/session_store.dart';
import 'api_exception.dart';

class ApiPage {
  const ApiPage({required this.items, required this.pagina, required this.porPagina, required this.total, required this.paginas, this.meta = const {}});

  final List<Map<String, dynamic>> items;
  final int pagina;
  final int porPagina;
  final int total;
  final int paginas;
  final Map<String, dynamic> meta;

  bool get temMais => pagina < paginas;

  factory ApiPage.fromJson(Map<String, dynamic> body) {
    final meta = body['meta'] is Map ? Map<String, dynamic>.from(body['meta'] as Map) : <String, dynamic>{};
    final data = body['data'];
    int n(String k) => (meta[k] as num?)?.toInt() ?? 0;
    return ApiPage(
      items: data is List ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [],
      pagina: n('pagina'),
      porPagina: n('por_pagina'),
      total: n('total'),
      paginas: n('paginas'),
      meta: meta,
    );
  }
}

class ApiClient {
  ApiClient(this._session, {http.Client? client}) : _http = client ?? http.Client();

  final SessionStore _session;
  final http.Client _http;

  VoidCallback? onSessionExpired;
  VoidCallback? onDoisFatoresObrigatorio;

  Future<bool>? _refreshing;

  String get baseUrl => _session.baseUrl ?? '';

  Uri uri(String path, [Map<String, dynamic>? query]) {
    if (baseUrl.isEmpty) {
      throw const ApiException('Servidor não configurado. Informe a URL do seu MAP-OS.');
    }
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) q[k] = v.toString();
    });
    final u = Uri.parse('$baseUrl${AppConfig.apiPrefix}$path');
    return q.isEmpty ? u : u.replace(queryParameters: q);
  }

  Map<String, String> _headers({bool json = true, bool auth = true}) => {
        if (json) 'Content-Type': 'application/json',
        'Accept': 'application/json',
        'App-Version': AppConfig.appVersion,
        if (auth && _session.accessToken != null) 'Authorization': 'Bearer ${_session.accessToken}',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool cache = false}) async {
    final body = await _getBody(path, query: query, cache: cache);
    return body['data'];
  }

  Future<ApiPage> getPage(String path, {Map<String, dynamic>? query, bool cache = false}) async =>
      ApiPage.fromJson(await _getBody(path, query: query, cache: cache));

  Future<Map<String, dynamic>> _getBody(String path, {Map<String, dynamic>? query, bool cache = false}) async {
    final u = uri(path, query);
    final cacheKey = u.toString().replaceFirst(baseUrl, '');
    try {
      final res = await _send(() => _http.get(u, headers: _headers()));
      final body = _decodificar(res) ?? const <String, dynamic>{};
      if (cache) await _session.writeCache(cacheKey, jsonEncode(body));
      return body;
    } on ApiException catch (e) {
      if (cache && e.isNetwork) {
        final cached = _session.readCache(cacheKey);
        if (cached != null) return Map<String, dynamic>.from(jsonDecode(cached) as Map);
      }
      rethrow;
    }
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) => _semCorpo('POST', path, body: body, auth: auth);
  Future<dynamic> put(String path, {Object? body}) => _semCorpo('PUT', path, body: body);
  Future<dynamic> patch(String path, {Object? body}) => _semCorpo('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _semCorpo('DELETE', path);

  Future<dynamic> _semCorpo(String metodo, String path, {Object? body, bool auth = true}) async {
    final u = uri(path);
    final res = await _send(() {
      final req = http.Request(metodo, u)..headers.addAll(_headers(auth: auth));
      if (body != null || metodo == 'POST') req.body = jsonEncode(body ?? {});
      return _http.send(req).then(http.Response.fromStream);
    }, retryOnAuth: auth);
    return _decodificar(res)?['data'];
  }

  Map<String, dynamic>? _decodificar(http.Response res) {
    try {
      return _decode(res);
    } on ApiException catch (e) {
      if (e.codigo == 'dois_fatores_obrigatorio') onDoisFatoresObrigatorio?.call();
      rethrow;
    }
  }

  Future<dynamic> upload(
    String path, {
    String method = 'POST',
    required String field,
    required Uint8List bytes,
    required String filename,
    Map<String, String> fields = const {},
  }) async {
    final u = uri(path);
    final res = await _send(() async {
      final req = http.MultipartRequest(method, u)
        ..headers.addAll(_headers(json: false))
        ..fields.addAll(fields)
        ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
      return http.Response.fromStream(await _http.send(req));
    });
    return _decode(res)?['data'];
  }

  Future<Uint8List> getBytes(String absoluteUrl) async {
    final res = await _send(() => _http.get(Uri.parse(absoluteUrl), headers: _headers(json: false)));
    if (res.statusCode != 200) {
      _decode(res);
      throw ApiException('Não foi possível carregar o arquivo.', statusCode: res.statusCode);
    }
    return res.bodyBytes;
  }

  Future<Map<String, dynamic>?> getExternalJson(Uri u) async {
    try {
      final res = await _http.get(u).timeout(AppConfig.requestTimeout);
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() request, {bool retryOnAuth = true}) async {
    var res = await _guard(request);
    if (retryOnAuth && res.statusCode == 401 && _session.hasSession) {
      final refreshed = await _refreshToken();
      if (refreshed) res = await _guard(request);
      if (!refreshed || res.statusCode == 401) {
        await _session.clearSession();
        onSessionExpired?.call();
        throw const ApiException('Sua sessão expirou. Entre novamente.', statusCode: 401, codigo: 'sessao_encerrada');
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

  Future<bool> _refreshToken() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final refresh = _session.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    final caminho = _session.tipo == TipoDeConta.cliente ? '/cliente/auth/renovar' : '/auth/renovar';
    try {
      final res = await _http
          .post(uri(caminho), headers: _headers(auth: false), body: jsonEncode({'refresh_token': refresh}))
          .timeout(AppConfig.requestTimeout);
      if (res.statusCode == 409) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return _session.refreshToken != refresh;
      }
      if (res.statusCode != 200) return false;
      final data = (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['data'] as Map?;
      final access = data?['access_token'] as String?;
      final novo = data?['refresh_token'] as String?;
      if (access == null || novo == null) return false;
      await _session.saveTokens(access: access, refresh: novo, sessao: data?['sessao'] as String?);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic>? _decode(http.Response res) {
    if (res.statusCode == 204) return null;

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      body = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body == null) throw ApiException('Resposta inválida do servidor (${res.statusCode}).', statusCode: res.statusCode);
      return body;
    }

    if (body == null || !body.containsKey('codigo')) {
      final dica = switch (res.statusCode) {
        404 => 'Recurso não encontrado',
        >= 500 => 'Erro no servidor',
        _ => 'Resposta inválida do servidor',
      };
      throw ApiException('$dica (${res.statusCode}).', statusCode: res.statusCode);
    }

    final erros = <String, String>{};
    if (body['erros'] is Map) {
      (body['erros'] as Map).forEach((k, v) => erros[k.toString()] = v.toString());
    }
    throw ApiException(
      (body['detail'] ?? body['title'] ?? 'Erro desconhecido').toString(),
      statusCode: res.statusCode,
      codigo: body['codigo']?.toString(),
      erros: erros,
      retryAfter: int.tryParse(res.headers['retry-after'] ?? ''),
    );
  }
}
