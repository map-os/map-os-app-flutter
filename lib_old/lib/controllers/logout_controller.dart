import 'package:shared_preferences/shared_preferences.dart';

class LogoutController {
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('permissions');

  }
}
