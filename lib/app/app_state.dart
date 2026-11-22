import 'package:flutter/material.dart';

import '../core/storage/session_store.dart';
import '../data/models/conta.dart';
import '../data/repositories/auth_repository.dart';

/// Estado de autenticação observado pelo AuthGate.
class AuthState extends ChangeNotifier {
  AuthState(this._session, this._repo) : _loggedIn = _session.hasSession;

  final SessionStore _session;
  final AuthRepository _repo;
  bool _loggedIn;

  bool get loggedIn => _loggedIn;
  Permissions get permissions => Permissions(_session.permissions);
  String? get lastEmail => _session.lastEmail;
  String? get serverUrl => _session.baseUrl;

  /// Primeiro acesso: ainda não viu o onboarding nem configurou um servidor.
  /// Quem já tinha URL salva (versões anteriores) pula direto para o login.
  bool get needsOnboarding =>
      !_loggedIn && !_session.onboardingDone && (_session.baseUrl ?? '').isEmpty;

  Future<void> completeOnboarding(String serverUrl) async {
    await _session.setBaseUrl(serverUrl);
    await _session.setOnboardingDone();
    notifyListeners();
  }

  /// Troca o servidor (já testado) a partir da tela de login.
  Future<void> setServer(String serverUrl) async {
    await _session.setBaseUrl(serverUrl);
    notifyListeners();
  }

  Future<void> login({required String serverUrl, required String email, required String password}) async {
    await _repo.login(serverUrl: serverUrl, email: email, password: password);
    _loggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    sessionExpired();
  }

  /// Chamado pelo ApiClient quando o refresh falha.
  void sessionExpired() {
    if (!_loggedIn) return;
    _loggedIn = false;
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
