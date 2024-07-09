import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapos_app/api/apiConfig.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController {
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (APIConfig.baseURL == null) {
      await APIConfig.initBaseURL();
      if (APIConfig.baseURL == null) {
        return {
          'success': false,
          'message': 'API URL não configurada. Por favor configure nas configurações.'
        };
      }
    }

    var url = Uri.parse('${APIConfig.baseURL}${APIConfig.loginEndpoint}');
    try {
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'App-Version': APIConfig.appVersion,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['result']['access_token']);

        String permissionsJson = jsonEncode(data['result']['permissions'][0]);
        await prefs.setString('permissions', permissionsJson);

        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao fazer login: ${data['message']}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao conectar ao servidor: $e'
      };
    }
  }
}
