import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/api/apiConfig.dart';

class TokenController {
  Future<void> regenerateToken() async {
    await APIConfig.ensureBaseURLInitialized();
    final prefs = await SharedPreferences.getInstance();
    String? currentToken = prefs.getString('access_token');

    if (currentToken == null) {
      throw Exception("Nenhum token encontrado.");
    }

    final response = await http.get(
      Uri.parse('${APIConfig.baseURL}${APIConfig.regenToken}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $currentToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true && data['result'] != null && data['result']['access_token'] != null) {
        String newToken = data['result']['access_token'];
        await prefs.setString('access_token', newToken);
        return;
      } else {
        throw Exception("Falha ao regenerar token: ${data['message']}");
      }
    } else {
      throw Exception("Falha ao regenerar token com status code: ${response.statusCode}");
    }
  }
}