import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_store.dart';

class AuthRepository {
  AuthRepository(this._api, this._session);

  final ApiClient _api;
  final SessionStore _session;

  Future<void> login({
    required String serverUrl,
    required String email,
    required String password,
  }) async {
    final url = AppConfig.normalizeBaseUrl(serverUrl);
    if (url.isEmpty) throw const ApiException('Informe a URL do servidor MAP-OS.');
    await _session.setBaseUrl(url);

    final result = await _api.post(
      '/login',
      auth: false,
      body: {'email': email.trim(), 'password': password},
    );

    final map = result is Map ? Map<String, dynamic>.from(result) : const <String, dynamic>{};
    final access = map['access_token'] as String?;
    if (access == null) throw const ApiException('Resposta de login inválida.');

    await _session.saveTokens(access: access, refresh: map['refresh_token'] as String?);
    final perms = map['permissions'];
    if (perms is List && perms.isNotEmpty && perms.first is Map) {
      await _session.savePermissions(Map<String, dynamic>.from(perms.first as Map));
    }
    await _session.setLastEmail(email.trim());
  }

  Future<void> logout() => _session.clearSession();
}
