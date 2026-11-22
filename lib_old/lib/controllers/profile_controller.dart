import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/TokenController.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController {

  Future<Map<String, dynamic>> getProfile() async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      return {'success': false, 'message': 'Token não encontrado. Faça login novamente.'};
    }

    try {
      var response = await http.get(
        Uri.parse('${APIConfig.baseURL}${APIConfig.profileEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'App-Version': APIConfig.appVersion,
        },
      );

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        token = prefs.getString('access_token');
        response = await http.get(
          Uri.parse('${APIConfig.baseURL}${APIConfig.profileEndpoint}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'App-Version': APIConfig.appVersion,
          },
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          return {'success': true, 'data': data['result']};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Erro ao carregar perfil.'};
        }
      } else {
        return {'success': false, 'message': 'Erro ao carregar perfil (${response.statusCode}).'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile({String? nome, String? email, String? senha, String? senhaConfirmacao}) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      return {'success': false, 'message': 'Token não encontrado. Faça login novamente.'};
    }

    Map<String, dynamic> body = {};
    if (nome != null && nome.isNotEmpty) body['nome'] = nome;
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (senha != null && senha.isNotEmpty) {
      body['senha'] = senha;
      body['senhaConfirmacao'] = senhaConfirmacao ?? senha;
    }

    try {
      var response = await http.put(
        Uri.parse('${APIConfig.baseURL}${APIConfig.profileEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'App-Version': APIConfig.appVersion,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        token = prefs.getString('access_token');
        response = await http.put(
          Uri.parse('${APIConfig.baseURL}${APIConfig.profileEndpoint}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'App-Version': APIConfig.appVersion,
          },
          body: jsonEncode(body),
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          return {'success': true, 'data': data['result'], 'message': 'Perfil atualizado com sucesso!'};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Erro ao atualizar perfil.'};
        }
      } else {
        return {'success': false, 'message': 'Erro ao atualizar perfil (${response.statusCode}).'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}