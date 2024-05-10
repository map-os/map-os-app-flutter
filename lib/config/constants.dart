import 'package:shared_preferences/shared_preferences.dart';

class APIConfig {
  static const String appVersion = 'Beta 1.0.0';

  // Campo estático para armazenar a baseURL
  static String? baseURL;

  // Método para inicializar a baseURL
  static Future<void> initBaseURL() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    baseURL = prefs.getString('baseURL');
  }

  //ENDPOINTS
  static const String indexEndpoint = '';
  static const String loginEndpoint = '/login';
  static const String clientesEndpoint = '/clientes';
  static const String prodtuostesEndpoint = '/produtos'; // Corrigido o nome do endpoint
  static const String servicossEndpoint = '/servicos';
  static const String osEndpoint = '/os';
  static const String usuarioEndpoint = '/usuarios';
  static const String profileEndpoint = '/conta';
  static const String emitenteEndpoint = '/emitente';
  static const String auditoriaEndpoint = '/audit';
  static const String anexosEndpoint = '/anexos';
  static const String regenToken = '/reGenToken';
}