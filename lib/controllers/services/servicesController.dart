import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/TokenController.dart';

class ControllerServices {
  static const String _servicesKey = 'cached_services';

  Future<bool> hasInternetConnection() async {
    try {
      final result = await http.get(Uri.parse('http://clients3.google.com/generate_204'));
      return result.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getAllServices(int page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await hasInternetConnection()) {
      print('Você está offline, carregando dados salvos localmente...');
      return _loadServicesFromLocal(prefs);
    }

    await APIConfig.ensureBaseURLInitialized();
    String? token = prefs.getString('access_token');
    var response = await _reqServices(token, page);

    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      token = prefs.getString('access_token');
      response = await _reqServices(token, page);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        await _saveServicesToLocal(prefs, data['result']);
        return data['result'];
      } else {
        throw Exception('${data['message']}');
      }
    } else {
      throw Exception('Errro na conexão com a API');
    }
  }

  Future<void> _saveServicesToLocal(SharedPreferences prefs, List<dynamic> services) async {
    String jsonServices = jsonEncode(services);
    await prefs.setString(_servicesKey, jsonServices);
    print('Serviços salvos para uso Offline');
  }

  Future<List<dynamic>> _loadServicesFromLocal(SharedPreferences prefs) async {
    String? jsonServices = prefs.getString(_servicesKey);
    if (jsonServices != null) {
      List<dynamic> services = jsonDecode(jsonServices);
      print('Serviços carregados localmente');
      return services;
    } else {
      throw Exception('Nenhum registro encontrado Localmente');
    }
  }

  Future<http.Response> _reqServices(String? token, int page) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.servicossEndpoint}?page=$page');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<Map<String, dynamic>> getServiceById(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await hasInternetConnection()) {
      print('No internet connection, loading service details from local storage.');
      return _loadServiceByIdFromLocal(prefs, id);  // Load service details from local storage
    }

    await APIConfig.ensureBaseURLInitialized();
    String? token = prefs.getString('access_token');
    var response = await _reqServiceById(token, id);

    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      token = prefs.getString('access_token');
      response = await _reqServiceById(token, id);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        await _saveServiceToLocal(prefs, id, data['result']);  // Save to local storage
        return data['result'];
      } else {
        throw Exception('${data['message']}');
      }
    } else {
      throw Exception('Error requesting service by ID');
    }
  }

  Future<void> _saveServiceToLocal(SharedPreferences prefs, int id, Map<String, dynamic> service) async {
    String key = 'service_$id';
    String jsonService = jsonEncode(service);
    await prefs.setString(key, jsonService);
    print('Service details saved locally.');
  }

  Future<Map<String, dynamic>> _loadServiceByIdFromLocal(SharedPreferences prefs, int id) async {
    String key = 'service_$id';
    String? jsonService = prefs.getString(key);
    if (jsonService != null) {
      Map<String, dynamic> service = jsonDecode(jsonService);
      print('Dados salvos Localmente');
      return service;
    } else {
      throw Exception('O Serviço $id não foi salvo localmente 😢.');
    }
  }

  Future<http.Response> _reqServiceById(String? token, int id) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.servicossEndpoint}/$id');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<bool> updateService(int id, String nome, String descricao, double preco) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqUpdateService(token, id, nome, descricao, preco);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqUpdateService(newToken, id, nome, descricao, preco);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      throw Exception('Erro ao atualizar o serviço');
    }
  }

  Future<http.Response> _reqUpdateService(String? token, int id, String nome, String descricao, double preco) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.servicossEndpoint}/$id');
    return await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
      }),
    );
  }

  Future<bool> addService(String nome, String descricao, double preco) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqAddService(token, nome, descricao, preco);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqAddService(newToken, nome, descricao, preco);
    }
    print(response.body);
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      throw Exception('Erro ao adicionar o serviço');
    }
  }

  Future<http.Response> _reqAddService(String? token, String nome, String descricao, double preco) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.servicossEndpoint}');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
      }),
    );
  }

  Future<bool> deleteService(int id) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqDeleteService(token, id);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqDeleteService(newToken, id);
    }

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Erro ao deletar o serviço');
    }
  }

  Future<http.Response> _reqDeleteService(String? token, int id) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.servicossEndpoint}/$id');
    return await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

}
