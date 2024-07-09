import 'package:mapos_app/api/apiConfig.dart';

class UrlController {
  Future<void> saveBaseURL(String url) async {
    await APIConfig.updateBaseURL(url);
  }

  Future<String?> getBaseURL() async {
    await APIConfig.ensureBaseURLInitialized();
    return APIConfig.baseURL;
  }
}