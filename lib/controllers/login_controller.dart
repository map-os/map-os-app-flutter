import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mapos_app/api/apiConfig.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController {

  Future<Map<String, dynamic>> login(String email, String password) async {
    await APIConfig.ensureBaseURLInitialized();
    if (APIConfig.baseURL == null || APIConfig.baseURL!.isEmpty) {
      return {
        'success': false,
        'message': 'API URL não configurada. Por favor configure nas configurações.'
      };
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
      String errorMsg = 'Erro ao conectar ao servidor';
      if (kIsWeb) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('cors') || errStr.contains('failed to fetch') || errStr.contains('network error')) {
          errorMsg = 'Erro de CORS: O servidor MAP-OS precisa permitir requisições do app. '
              'Adicione os headers CORS no servidor ou acesse o MAP-OS pelo navegador para testar.';
        }
      }
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        errorMsg = 'Não foi possível conectar ao servidor. Verifique se a URL está correta e se o servidor está online.';
      }
      return {
        'success': false,
        'message': errorMsg
      };
    }
  }
}
