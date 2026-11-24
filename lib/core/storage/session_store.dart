import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TipoDeConta { usuario, cliente }

class SessionStore {
  SessionStore._(this._prefs, this._secure);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  String? _access;
  String? _refresh;

  static Future<SessionStore> create({FlutterSecureStorage? secure}) async {
    final store = SessionStore._(await SharedPreferences.getInstance(), secure ?? const FlutterSecureStorage());
    await store._carregar();
    return store;
  }

  static const _kBaseUrl = 'baseURL';
  static const _kAccess = 'v2_access_token';
  static const _kRefresh = 'v2_refresh_token';
  static const _kTipo = 'v2_tipo_conta';
  static const _kSessao = 'v2_sessao';
  static const _kPermissions = 'v2_permissoes';
  static const _kNome = 'v2_nome';
  static const _kLastEmail = 'last_email';
  static const _kTipoPreferido = 'tipo_preferido';
  static const _kThemeMode = 'theme_mode';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kCachePrefix = 'cache::';
  static const _chavesDaV1 = ['access_token', 'refresh_token', 'permissions'];

  Future<void> _carregar() async {
    for (final chave in _chavesDaV1) {
      if (_prefs.containsKey(chave)) await _prefs.remove(chave);
    }
    try {
      _access = await _secure.read(key: _kAccess);
      _refresh = await _secure.read(key: _kRefresh);
    } catch (_) {
      _access = null;
      _refresh = null;
    }
  }

  String? get baseUrl => _prefs.getString(_kBaseUrl);
  Future<void> setBaseUrl(String value) => _prefs.setString(_kBaseUrl, value);

  String? get accessToken => _access;
  String? get refreshToken => _refresh;
  bool get hasSession => (_access ?? '').isNotEmpty;

  TipoDeConta get tipo => _prefs.getString(_kTipo) == TipoDeConta.cliente.name ? TipoDeConta.cliente : TipoDeConta.usuario;
  String? get sessao => _prefs.getString(_kSessao);
  String? get nome => _prefs.getString(_kNome);

  Future<void> saveTokens({required String access, required String refresh, String? sessao}) async {
    _access = access;
    _refresh = refresh;
    await _secure.write(key: _kAccess, value: access);
    await _secure.write(key: _kRefresh, value: refresh);
    if (sessao != null) await _prefs.setString(_kSessao, sessao);
  }

  Future<void> iniciar({required TipoDeConta tipo, required String nome}) async {
    await _prefs.setString(_kTipo, tipo.name);
    await _prefs.setString(_kNome, nome);
  }

  List<String>? get permissions {
    final raw = _prefs.getString(_kPermissions);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> savePermissions(List<String> value) => _prefs.setString(_kPermissions, jsonEncode(value));

  TipoDeConta? get tipoPreferido => switch (_prefs.getString(_kTipoPreferido)) {
        'cliente' => TipoDeConta.cliente,
        'usuario' => TipoDeConta.usuario,
        _ => null,
      };
  Future<void> setTipoPreferido(TipoDeConta tipo) => _prefs.setString(_kTipoPreferido, tipo.name);

  String? get lastEmail => _prefs.getString(_kLastEmail);
  Future<void> setLastEmail(String value) => _prefs.setString(_kLastEmail, value);

  String? get themeMode => _prefs.getString(_kThemeMode);
  Future<void> setThemeMode(String value) => _prefs.setString(_kThemeMode, value);

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_kOnboardingDone, true);

  Future<void> clearSession() async {
    _access = null;
    _refresh = null;
    try {
      await _secure.delete(key: _kAccess);
      await _secure.delete(key: _kRefresh);
    } catch (_) {}
    for (final chave in [_kPermissions, _kSessao, _kNome, _kTipo]) {
      await _prefs.remove(chave);
    }
    await clearCache();
  }

  String? readCache(String key) => _prefs.getString('$_kCachePrefix$key');

  Future<void> writeCache(String key, String value) async {
    try {
      await _prefs.setString('$_kCachePrefix$key', value);
    } catch (_) {}
  }

  Future<void> clearCache() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_kCachePrefix));
    for (final k in keys.toList()) {
      await _prefs.remove(k);
    }
  }
}
