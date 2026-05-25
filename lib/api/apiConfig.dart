import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class APIConfig {
  static const String appVersion = '2.1.0-Dev';

  static String? baseURL;

  static String _normalizeURL(String url) {
    url = url.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (kIsWeb && url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/api/v1')) {
      url = url.substring(0, url.length - 7);
    }
    return url;
  }

  static Future<void> initBaseURL() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString('baseURL');
    if (stored != null) {
      baseURL = _normalizeURL(stored);
      if (baseURL != stored) {
        await prefs.setString('baseURL', baseURL!);
      }
    }
  }

  static Future<void> updateBaseURL(String url) async {
    url = _normalizeURL(url);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseURL', url);
    baseURL = url;
  }

  static Future<void> ensureBaseURLInitialized() async {
    await initBaseURL();
  }

  // ENDPOINTS (API v1)
  static const String indexEndpoint = '/api/v1/';
  static const String loginEndpoint = '/api/v1/login';
  static const String clientesEndpoint = '/api/v1/clientes';
  static const String calendarioEndpoint = '/api/v1/calendario';
  static const String produtosEndpoint = '/api/v1/produtos';
  static const String servicossEndpoint = '/api/v1/servicos';
  static const String osEndpoint = '/api/v1/os';
  static const String usuarioEndpoint = '/api/v1/usuarios';
  static const String profileEndpoint = '/api/v1/conta';
  static const String emitenteEndpoint = '/api/v1/emitente';
  static const String auditoriaEndpoint = '/api/v1/audit';
  static const String anexosEndpoint = '/api/v1/anexos';
  static const String regenToken = '/api/v1/reGenToken';
}