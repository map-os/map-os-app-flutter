import 'package:shared_preferences/shared_preferences.dart';

class APIConfig {
  static const String appVersion = '0.2.0 Beta';

  // Campo estático para armazenar a baseURL
  static String? baseURL;

  // Método para inicializar a baseURL
  static Future<void> initBaseURL() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    baseURL = prefs.getString('baseURL');
  }

  //ENDPOINTS
  static const String indexEndpoint = '/index.php/api';
  static const String loginEndpoint = '/index.php/api/login';
  static const String clientesEndpoint = '/index.php/api/clientes';
  static const String prodtuostesEndpoint = '/index.php/api/produtos'; // Corrigido o nome do endpoint
  static const String servicossEndpoint = '/index.php/api/servicos';
  static const String osEndpoint = '/index.php/api/os';
  static const String usuarioEndpoint = '/index.php/api/usuarios';
  static const String profileEndpoint = '/index.php/api/conta';
}