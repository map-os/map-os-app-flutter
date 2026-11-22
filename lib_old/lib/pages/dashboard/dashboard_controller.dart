import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/TokenController.dart';
import 'package:mapos_app/utils/cache_helper.dart';
import 'package:flutter/foundation.dart';


class DashboardController {
  int countOs = 0;
  int clientes = 0;
  int produtos = 0;
  int servicos = 0;
  int garantias = 0;
  int vendas = 0;
  List<dynamic> osAbertas = [];
  List<dynamic> osAndamento = [];
  List<dynamic> estoqueBaixo = [];

  Future<void> fetchDashboardData() async {
    if (await _hasInternetConnection()) {
      await _fetchDataFromAPI();
    } else {
      debugPrint('Sem acesso à internet, carregando dados locais.');
      await _loadLocalData();
    }
  }

  Future<bool> _hasInternetConnection() async {
    if (kIsWeb) return true;
    try {
      final result = await http.get(Uri.parse('https://www.google.com/generate_204'));
      return result.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchDataFromAPI() async {
    try {
      await APIConfig.ensureBaseURLInitialized();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      var response = await _tryFetchWithRenewal(token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status']) {
          _updateDashboardData(data['result']);
          await _saveLocalData(data['result']);
        } else {
          if (kIsWeb) {
            await _loadLocalData();
            return;
          }
          throw Exception('Erro ao buscar dados do dashboard: ${data['message']}');
        }
      } else {
        debugPrint('Erro ao fazer requisição: ${response.body}');
        await _loadLocalData();
      }
    } catch (e) {
      if (kIsWeb) {
        await _loadLocalData();
        return;
      }
      rethrow;
    }
  }

  Future<http.Response> _tryFetchWithRenewal(String? token) async {
    var response = await _fetchData(token);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      token = prefs.getString('access_token');
      response = await _fetchData(token);
    }
    return response;
  }


  Future<http.Response> _fetchData(String? token) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.indexEndpoint}');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'App-Version': APIConfig.appVersion,
        'Authorization': 'Bearer $token',
      },
    );
  }

  void _updateDashboardData(dynamic data) {
    countOs = data['countOs'];
    clientes = data['clientes'];
    produtos = data['produtos'];
    servicos = data['servicos'];
    garantias = data['garantias'];
    vendas = data['vendas'];
    osAbertas = data['osAbertas'];
    osAndamento = data['osAndamento'];
    estoqueBaixo = data['estoqueBaixo'];
  }

  Future<void> _saveLocalData(dynamic data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await CacheHelper.safeSetString(prefs, 'dashboard_data', jsonEncode(data));
  }

  Future<void> _loadLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString('dashboard_data');
    if (jsonData != null) {
      final data = jsonDecode(jsonData);
      _updateDashboardData(data);
    } else {
      debugPrint('Nenhum dado local encontrado. Operando com dados padrões.');
    }
  }
}
