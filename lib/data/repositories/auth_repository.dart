import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_store.dart';
import '../../core/utils/formatters.dart';

sealed class ResultadoDoLogin {
  const ResultadoDoLogin();
}

class LoginConcluido extends ResultadoDoLogin {
  const LoginConcluido({this.doisFatoresPendente = false});

  final bool doisFatoresPendente;
}

class SegundoFatorNecessario extends ResultadoDoLogin {
  const SegundoFatorNecessario(this.desafio);

  final String desafio;
}

class AuthRepository {
  AuthRepository(this._api, this._session);

  final ApiClient _api;
  final SessionStore _session;

  static String get dispositivo {
    if (kIsWeb) return 'App MAP-OS (navegador)';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'App MAP-OS (Android)',
      TargetPlatform.iOS => 'App MAP-OS (iPhone)',
      _ => 'App MAP-OS',
    };
  }

  Future<ResultadoDoLogin> login({
    required String serverUrl,
    required String email,
    required String password,
    TipoDeConta tipo = TipoDeConta.usuario,
  }) async {
    final url = AppConfig.normalizeBaseUrl(serverUrl);
    if (url.isEmpty) throw const ApiException('Informe a URL do servidor MAP-OS.');
    await _session.setBaseUrl(url);

    final caminho = tipo == TipoDeConta.cliente ? '/cliente/auth/login' : '/auth/login';
    final dados = asMap(await _api.post(caminho, auth: false, body: {'email': email.trim(), 'senha': password, 'dispositivo': dispositivo}));
    await _session.setLastEmail(email.trim());

    if (dados['dois_fatores'] == true) {
      return SegundoFatorNecessario(asString(dados['desafio']));
    }

    return _concluir(dados, tipo);
  }

  Future<ResultadoDoLogin> confirmarSegundoFator({required String desafio, required String codigo}) async {
    final dados = asMap(await _api.post('/auth/login/dois-fatores', auth: false, body: {'desafio': desafio, 'codigo': codigo.trim(), 'dispositivo': dispositivo}));

    return _concluir(dados, TipoDeConta.usuario);
  }

  Future<ResultadoDoLogin> _concluir(Map<String, dynamic> dados, TipoDeConta tipo) async {
    final access = dados['access_token'] as String?;
    final refresh = dados['refresh_token'] as String?;
    if (access == null || refresh == null) throw const ApiException('Resposta de login inválida.');

    await _session.clearSession();
    await _session.saveTokens(access: access, refresh: refresh, sessao: dados['sessao'] as String?);
    final titular = asMap(dados[tipo == TipoDeConta.cliente ? 'cliente' : 'usuario']);
    await _session.iniciar(tipo: tipo, nome: asString(titular['nome']));

    if (tipo == TipoDeConta.usuario) {
      await atualizarPermissoes();
    }

    return LoginConcluido(doisFatoresPendente: dados['dois_fatores_pendente'] == true);
  }

  Future<void> atualizarPermissoes() async {
    try {
      final conta = asMap(await _api.get('/conta'));
      final permissoes = (conta['permissoes'] as List? ?? const []).map((e) => e.toString()).toList();
      await _session.savePermissions(permissoes);
    } catch (_) {}
  }

  Future<void> logout() async {
    if (_session.hasSession) {
      try {
        await _api.post(_session.tipo == TipoDeConta.cliente ? '/cliente/auth/logout' : '/auth/logout');
      } catch (_) {}
    }
    await _session.clearSession();
  }
}
