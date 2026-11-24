import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Onde o MAP-OS do usuário roda. Define o protocolo usado.
enum ServerMode {
  /// Na internet (hospedagem/VPS) — sempre HTTPS.
  hosted,

  /// Na rede da empresa (IP local, XAMPP, etc.) — HTTP.
  local,
}

/// Resultado do teste de conexão com o servidor.
class ProbeResult {
  const ProbeResult._({
    required this.ok,
    required this.url,
    required this.title,
    required this.message,
    this.elapsed,
    this.tips = const [],
  });

  final bool ok;
  final String url;
  final String title;
  final String message;
  final Duration? elapsed;
  final List<String> tips;

  factory ProbeResult.success(String url, Duration elapsed) => ProbeResult._(
        ok: true,
        url: url,
        title: 'Conexão estabelecida!',
        message: 'Encontramos a API do MAP-OS em ${elapsed.inMilliseconds} ms.',
        elapsed: elapsed,
      );

  factory ProbeResult.fail(String url, String title, String message, [List<String> tips = const []]) =>
      ProbeResult._(ok: false, url: url, title: title, message: message, tips: tips);
}

/// Faz um POST em `/api/v2/auth/login` sem credenciais: um MAP-OS com a API v2
/// recusa com um erro RFC 9457 (`urn:mapos:erro:...`), o que confirma servidor e API.
abstract final class ServerProbe {
  static const Duration timeout = Duration(seconds: 12);

  /// Monta a URL base a partir do que o usuário digitou + o tipo de servidor.
  /// Qualquer protocolo digitado é descartado: quem manda é o [mode].
  static String buildUrl(String input, ServerMode mode) {
    var s = input.trim().replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://'), '');
    s = _trimSlashes(s);
    if (s.endsWith(AppConfig.apiPrefix)) {
      s = _trimSlashes(s.substring(0, s.length - AppConfig.apiPrefix.length));
    }
    if (s.isEmpty) return '';
    return '${mode == ServerMode.local ? 'http' : 'https'}://$s';
  }

  /// Valida o formato antes de testar. Retorna a mensagem de erro ou null.
  static String? validate(String input, ServerMode mode) {
    final url = buildUrl(input, mode);
    if (url.isEmpty) return 'Informe o endereço do servidor.';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty || url.contains(' ')) {
      return 'Endereço inválido. Ex.: ${mode == ServerMode.local ? '192.168.0.10/mapos' : 'minhaempresa.com.br/mapos'}';
    }
    return null;
  }

  /// Aviso para quem digita "localhost" no celular.
  static String? localhostWarning(String input, ServerMode mode) {
    final host = Uri.tryParse(buildUrl(input, mode))?.host ?? '';
    if (host == 'localhost' || host.startsWith('127.')) {
      return 'No celular, "localhost" é o próprio celular. Use o IP do computador que roda o MAP-OS (ex.: 192.168.0.10).';
    }
    return null;
  }

  static Future<ProbeResult> test(String baseUrl, {http.Client? client}) async {
    final c = client ?? http.Client();
    final local = baseUrl.startsWith('http://');
    final sw = Stopwatch()..start();
    try {
      final res = await _postLogin(c, '$baseUrl${AppConfig.apiPrefix}/auth/login');
      sw.stop();
      if (res.statusCode == 404 && !_ehApiV2(res) && await _temApiV1(c, baseUrl)) {
        return ProbeResult.fail(
          baseUrl,
          'MAP-OS desatualizado',
          'Este servidor ainda usa a API antiga (v1). Este app precisa da API v2.',
          const ['Peça ao administrador para atualizar o MAP-OS para a versão mais recente.'],
        );
      }
      return _classify(baseUrl, res, sw.elapsed);
    } on TimeoutException {
      return ProbeResult.fail(
        baseUrl,
        'O servidor não respondeu',
        'Esperamos ${timeout.inSeconds}s e não tivemos resposta.',
        local ? _localTips : _hostedTips,
      );
    } catch (e) {
      return _classifyError(baseUrl, e.toString(), local);
    } finally {
      if (client == null) c.close();
    }
  }

  static Future<http.Response> _postLogin(http.Client c, String url) => c
      .post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json', 'App-Version': AppConfig.appVersion},
        body: jsonEncode(const <String, String>{}),
      )
      .timeout(timeout);

  static Map<String, dynamic>? _json(http.Response res) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static bool _ehApiV2(http.Response res) => (_json(res)?['type'] ?? '').toString().startsWith('urn:mapos:erro');

  static Future<bool> _temApiV1(http.Client c, String baseUrl) async {
    try {
      final res = await _postLogin(c, '$baseUrl${AppConfig.legacyApiPrefix}/login');
      return _json(res)?.containsKey('status') ?? false;
    } catch (_) {
      return false;
    }
  }

  static ProbeResult _classify(String url, http.Response res, Duration elapsed) {
    final code = res.statusCode;

    // Redirecionamento (POST não segue automaticamente).
    if (code >= 300 && code < 400) {
      final location = res.headers['location'] ?? '';
      if (url.startsWith('http://') && location.startsWith('https://')) {
        return ProbeResult.fail(
          url,
          'Esse servidor usa HTTPS',
          'O servidor redirecionou para uma conexão segura.',
          const ['Volte e escolha a opção "Hospedado (HTTPS)".'],
        );
      }
      return ProbeResult.fail(
        url,
        'O servidor redirecionou a requisição',
        location.isEmpty ? 'Recebemos um redirecionamento (HTTP $code).' : 'Redirecionado para: $location',
        const ['Use o endereço final do MAP-OS, exatamente como aparece no navegador.'],
      );
    }

    final body = _json(res);
    if (body != null && (body['type'] ?? '').toString().startsWith('urn:mapos:erro')) {
      switch (body['codigo']) {
        case 'chave_insegura':
          return ProbeResult.fail(url, 'API sem chave configurada', 'Encontramos o MAP-OS, mas a chave dos tokens da API não foi configurada.',
              const ['Peça ao administrador para gerar a chave em Configurações › API.']);
        case 'banco_desatualizado':
          return ProbeResult.fail(url, 'Banco de dados desatualizado', 'Encontramos o MAP-OS, mas o banco de dados precisa ser atualizado.',
              const ['Peça ao administrador para abrir o painel e atualizar o banco de dados.']);
      }
      return ProbeResult.success(url, elapsed);
    }

    if (code == 404) {
      return ProbeResult.fail(
        url,
        'API do MAP-OS não encontrada',
        'O servidor respondeu, mas não existe um MAP-OS nesse caminho.',
        const [
          'Confira se o caminho está completo (ex.: dominio.com.br/mapos).',
          'Abra o endereço no navegador: deve aparecer a tela de login do MAP-OS.',
          'Verifique se a API está ativada (Configurações › API) e se o MAP-OS está atualizado.',
        ],
      );
    }

    if (code >= 500) {
      return ProbeResult.fail(
        url,
        'Erro no servidor (HTTP $code)',
        'O servidor foi encontrado, mas falhou ao processar a requisição.',
        const ['Verifique os logs do servidor ou tente novamente em instantes.'],
      );
    }

    return ProbeResult.fail(
      url,
      'Isso não parece um MAP-OS',
      'O servidor respondeu (HTTP $code), mas não com a API do MAP-OS.',
      const [
        'Confira se o endereço aponta para a pasta do MAP-OS.',
        'Abra o endereço no navegador: deve aparecer a tela de login do MAP-OS.',
      ],
    );
  }

  static ProbeResult _classifyError(String url, String error, bool local) {
    final e = error.toLowerCase();

    if (e.contains('handshake') || e.contains('certificate') || e.contains('wrong_version_number')) {
      return ProbeResult.fail(
        url,
        'Problema com o certificado SSL',
        'Não foi possível criar uma conexão segura (HTTPS) com o servidor.',
        const [
          'Se o servidor não tem certificado SSL, escolha "Local (HTTP)".',
          'Se tem, verifique se o certificado está válido e não expirou.',
        ],
      );
    }

    if (e.contains('failed host lookup') || e.contains('no address associated')) {
      return ProbeResult.fail(
        url,
        'Endereço não encontrado',
        'Não conseguimos encontrar esse domínio.',
        const [
          'Confira se o endereço foi digitado corretamente.',
          'Verifique se o celular está conectado à internet.',
        ],
      );
    }

    if (e.contains('connection refused')) {
      return ProbeResult.fail(
        url,
        'Conexão recusada',
        'O endereço existe, mas nada respondeu nessa porta.',
        local
            ? const [
                'Verifique se o Apache/servidor web está rodando.',
                'Se usa porta diferente de 80, informe-a (ex.: 192.168.0.10:8080/mapos).',
                'Libere a porta no firewall do computador.',
              ]
            : const ['Verifique se o servidor está no ar e a porta está correta.'],
      );
    }

    if (e.contains('xmlhttprequest') || e.contains('failed to fetch')) {
      return ProbeResult.fail(
        url,
        'Acesso bloqueado pelo navegador',
        'O navegador bloqueou a conexão com o servidor.',
        const ['Verifique se o MAP-OS permite acesso externo (CORS) e usa HTTPS.'],
      );
    }

    return ProbeResult.fail(
      url,
      'Não foi possível conectar',
      'O servidor não pôde ser alcançado.',
      local ? _localTips : _hostedTips,
    );
  }

  static const _localTips = [
    'O celular precisa estar na mesma rede Wi-Fi do servidor.',
    'Use o IP do computador (ex.: 192.168.0.10), não "localhost".',
    'Verifique se o firewall libera a porta do servidor web.',
  ];

  static const _hostedTips = [
    'Verifique se o celular está conectado à internet.',
    'Confira se o endereço está correto e o site está no ar.',
  ];

  static String _trimSlashes(String s) {
    var r = s;
    while (r.endsWith('/')) {
      r = r.substring(0, r.length - 1);
    }
    return r;
  }
}
