import 'package:shared_preferences/shared_preferences.dart';

class APIConfig {
  static const String appVersion = '2.1.0';

  static String? baseURL;

  static Future<void> initBaseURL() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    baseURL = prefs.getString('baseURL');
  }

  static Future<void> updateBaseURL(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseURL', url);
    baseURL = url;
  }

  static Future<void> ensureBaseURLInitialized() async {
    if (baseURL == null) {
      await initBaseURL();
    }
  }

  // ENDPOINTS
  static const String indexEndpoint = '';
  static const String loginEndpoint = '/login';
  static const String clientesEndpoint = '/clientes';
  static const String calendarioEndpoint = '/calendario';
  static const String prodtuostesEndpoint = '/produtos';
  static const String servicossEndpoint = '/servicos';
  static const String osEndpoint = '/os';
  static const String usuarioEndpoint = '/usuarios';
  static const String profileEndpoint = '/conta';
  static const String emitenteEndpoint = '/emitente';
  static const String auditoriaEndpoint = '/audit';
  static const String anexosEndpoint = '/anexos';
  static const String regenToken = '/reGenToken';
}
