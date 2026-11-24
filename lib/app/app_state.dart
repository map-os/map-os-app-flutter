import 'package:flutter/material.dart';

import '../core/storage/session_store.dart';
import '../data/models/conta.dart';
import '../data/repositories/auth_repository.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._session, this._repo) : _loggedIn = _session.hasSession;

  final SessionStore _session;
  final AuthRepository _repo;
  bool _loggedIn;
  bool _doisFatoresPendente = false;

  bool get loggedIn => _loggedIn;
  bool get isCliente => _session.tipo == TipoDeConta.cliente;
  TipoDeConta get tipoPreferido => _session.tipoPreferido ?? TipoDeConta.usuario;
  Future<void> setTipoPreferido(TipoDeConta tipo) => _session.setTipoPreferido(tipo);
  bool get doisFatoresPendente => _doisFatoresPendente;
  Permissions get permissions => Permissions(isCliente ? const [] : _session.permissions);
  String? get lastEmail => _session.lastEmail;
  String? get serverUrl => _session.baseUrl;
  String? get nome => _session.nome;

  bool get needsOnboarding => !_loggedIn && !_session.onboardingDone && (_session.baseUrl ?? '').isEmpty;

  Future<void> completeOnboarding(String serverUrl) async {
    await _session.setBaseUrl(serverUrl);
    await _session.setOnboardingDone();
    notifyListeners();
  }

  Future<void> setServer(String serverUrl) async {
    await _session.setBaseUrl(serverUrl);
    notifyListeners();
  }

  Future<String?> login({required String serverUrl, required String email, required String password, TipoDeConta tipo = TipoDeConta.usuario}) async {
    final resultado = await _repo.login(serverUrl: serverUrl, email: email, password: password, tipo: tipo);

    return _aplicar(resultado);
  }

  Future<String?> confirmarSegundoFator({required String desafio, required String codigo}) async =>
      _aplicar(await _repo.confirmarSegundoFator(desafio: desafio, codigo: codigo));

  String? _aplicar(ResultadoDoLogin resultado) {
    switch (resultado) {
      case SegundoFatorNecessario(:final desafio):
        return desafio;
      case LoginConcluido(:final doisFatoresPendente):
        _doisFatoresPendente = doisFatoresPendente;
        _loggedIn = true;
        notifyListeners();
        return null;
    }
  }

  Future<void> atualizarPermissoes() async {
    await _repo.atualizarPermissoes();
    notifyListeners();
  }

  void doisFatoresObrigatorio() {
    if (_doisFatoresPendente || !_loggedIn) return;
    _doisFatoresPendente = true;
    notifyListeners();
  }

  void doisFatoresAtivado() {
    _doisFatoresPendente = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    sessionExpired();
  }

  void sessionExpired() {
    if (!_loggedIn) return;
    _loggedIn = false;
    _doisFatoresPendente = false;
    notifyListeners();
  }
}

class ThemeState extends ChangeNotifier {
  ThemeState(this._session) : _mode = _parse(_session.themeMode);

  final SessionStore _session;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    _mode = mode;
    _session.setThemeMode(mode.name);
    notifyListeners();
  }

  static ThemeMode _parse(String? v) =>
      ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);
}
