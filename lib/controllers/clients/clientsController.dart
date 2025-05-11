import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/TokenController.dart';

class ControllerClients {
  static const String _ClientsKey = 'cached_Clients';

  Future<bool> hasInternetConnection() async {
    try {
      final result = await http.get(Uri.parse('http://clients3.google.com/generate_204'));
      return result.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getAllClients(int page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await hasInternetConnection()) {
      print('Você está offline, carregando dados salvos localmente...');
      return _loadClientsFromLocal(prefs);
    }

    await APIConfig.ensureBaseURLInitialized();
    String? token = prefs.getString('access_token');
    var response = await _reqClients(token, page);

    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      token = prefs.getString('access_token');
      response = await _reqClients(token, page);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        await _saveClientsFromLocal(prefs, data['result']);
        return data['result'];
      } else {
        throw Exception('${data['message']}');
      }
    } else {
      throw Exception('Errro na conexão com a API');
    }
  }

  Future<void> _saveClientsFromLocal(SharedPreferences prefs, List<dynamic> Clients) async {
    String jsonClients = jsonEncode(Clients);
    await prefs.setString(_ClientsKey, jsonClients);
    print('produtos salvos para uso Offline');
  }

  Future<List<dynamic>> _loadClientsFromLocal(SharedPreferences prefs) async {
    String? jsonClients = prefs.getString(_ClientsKey);
    if (jsonClients != null) {
      List<dynamic> Clients = jsonDecode(jsonClients);
      print('produtos carregados localmente');
      return Clients;
    } else {
      throw Exception('Nenhum registro encontrado Localmente');
    }
  }

  Future<http.Response> _reqClients(String? token, int page) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.clientesEndpoint}?page=$page');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<Map<String, dynamic>> getClientById(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await hasInternetConnection()) {
      print('Sem conexão Carregando Produtos localmente');
      return _loadClientByIdFromLocal(prefs, id);
    }

    await APIConfig.ensureBaseURLInitialized();
    String? token = prefs.getString('access_token');
    var response = await _reqClientById(token, id);

    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      token = prefs.getString('access_token');
      response = await _reqClientById(token, id);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        await _saveClientToLocal(prefs, id, data['result']);
        return data['result'];
      } else {
        throw Exception('${data['message']}');
      }
    } else {
      throw Exception('Cliente Não encontrado.');
    }
  }

  Future<void> _saveClientToLocal(SharedPreferences prefs, int id, Map<String, dynamic> Client) async {
    String key = 'Client_$id';
    String jsonClient = jsonEncode(Client);
    await prefs.setString(key, jsonClient);
    print('Cliente Salvo para uso local');
  }

  Future<Map<String, dynamic>> _loadClientByIdFromLocal(SharedPreferences prefs, int id) async {
    String key = 'Client_$id';
    String? jsonClient = prefs.getString(key);
    if (jsonClient != null) {
      Map<String, dynamic> Client = jsonDecode(jsonClient);
      print('Dados salvos Localmente');
      return Client;
    } else {
      throw Exception('O Produto $id não foi salvo localmente 😢.');
    }
  }

  Future<http.Response> _reqClientById(String? token, int id) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.clientesEndpoint}/$id');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<bool> updateClient(Map<String, dynamic> clientData) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqUpdateClient(token, clientData);
print(response.body);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqUpdateClient(newToken, clientData);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      throw Exception('Erro ao atualizar o cliente');
    }
  }

  Future<http.Response> _reqUpdateClient(String? token, Map<String, dynamic> clientData) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.clientesEndpoint}/${clientData['idClientes']}');

    return await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(clientData),
    );
  }


  Future<bool> addClient(Map<String, dynamic> clientData) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqAddClient(token, clientData);
    print(response.body);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqAddClient(newToken, clientData);
    }

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      throw Exception('Erro ao adicionar o cliente');
    }
  }

  Future<http.Response> _reqAddClient(String? token, Map<String, dynamic> clientData) async {
    final url = Uri.parse('${APIConfig.baseURL}/${APIConfig.clientesEndpoint}');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(clientData),
    );
  }


  Future<bool> deleteClient(int id) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqDeleteClient(token, id);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqDeleteClient(newToken, id);
    }


    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }

  Future<http.Response> _reqDeleteClient(String? token, int id) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.clientesEndpoint}/$id');
    return await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }


}
