import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
// import 'package:mapos_app/main.dart';

class DashboardData {
  int countOs = 0;
  int clientes = 0;
  int produtos = 0;
  int servicos = 0;
  int garantias = 0;
  int vendas = 0;

  Future<void> fetchData(BuildContext context) async {
    // Inicializa a baseURL se ainda não estiver inicializada
    if (APIConfig.baseURL == null) {
      await APIConfig.initBaseURL();
      if (APIConfig.baseURL == null) {
        return;
      }
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
    };

    var url = '${APIConfig.baseURL}${APIConfig.indexEndpoint}';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {

      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        countOs = data['result']['countOs'] ?? 0;
        clientes = data['result']['clientes'] ?? 0;
        produtos = data['result']['produtos'] ?? 0;
        servicos = data['result']['servicos'] ?? 0;
        garantias = data['result']['garantia'] ?? 0;
        vendas = data['result']['vendas'] ?? 0;
      } else {
        print(data['message']);
      }
    } else {
      print('ERRO');
    }
  }
}

// Future<Map<String, dynamic>> _getUserData() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   String ciKey = prefs.getString('token') ?? '';
//   String permissoesString = prefs.getString('permissoes') ?? '[]';
//   List<dynamic> permissoes = jsonDecode(permissoesString);
//   return {'ci_key': ciKey, 'permissoes': permissoes};
// }
//
// void _logout(BuildContext context) async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   await prefs.remove('token');
//   await prefs.remove('permissoes');
//   Navigator.pushAndRemoveUntil(
//     context,
//     MaterialPageRoute(builder: (context) => LoginPage(() {})),
//         (Route<dynamic> route) => false,
//   );
// }
