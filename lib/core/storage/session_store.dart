import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local da sessão e preferências do usuário.
class SessionStore {
  SessionStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SessionStore> create() async =>
      SessionStore(await SharedPreferences.getInstance());

  static const _kBaseUrl = 'baseURL';
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kPermissions = 'permissions';
  static const _kLastEmail = 'last_email';
  static const _kThemeMode = 'theme_mode';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kCachePrefix = 'cache::';

  String? get baseUrl => _prefs.getString(_kBaseUrl);
  Future<void> setBaseUrl(String value) => _prefs.setString(_kBaseUrl, value);

  String? get accessToken => _prefs.getString(_kAccess);
  String? get refreshToken => _prefs.getString(_kRefresh);
  bool get hasSession => (accessToken ?? '').isNotEmpty;

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _prefs.setString(_kAccess, access);
    if (refresh != null && refresh.isNotEmpty) {
      await _prefs.setString(_kRefresh, refresh);
    }
  }

  Map<String, dynamic> get permissions {
    final raw = _prefs.getString(_kPermissions);
    if (raw == null) return const {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }

  Future<void> savePermissions(Map<String, dynamic> value) =>
      _prefs.setString(_kPermissions, jsonEncode(value));

  String? get lastEmail => _prefs.getString(_kLastEmail);
  Future<void> setLastEmail(String value) => _prefs.setString(_kLastEmail, value);

  String? get themeMode => _prefs.getString(_kThemeMode);
  Future<void> setThemeMode(String value) => _prefs.setString(_kThemeMode, value);

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_kOnboardingDone, true);

  /// Encerra a sessão mantendo URL do servidor, último e-mail e tema.
  Future<void> clearSession() async {
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kPermissions);
    await clearCache();
  }

  // ---- Cache offline de respostas GET ----

  String? readCache(String key) => _prefs.getString('$_kCachePrefix$key');

  Future<void> writeCache(String key, String value) async {
    try {
      await _prefs.setString('$_kCachePrefix$key', value);
    } catch (_) {
      // Armazenamento cheio (web) — o cache é opcional.
    }
  }

  Future<void> clearCache() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_kCachePrefix));
    for (final k in keys.toList()) {
      await _prefs.remove(k);
    }
  }
}
