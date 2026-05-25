import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/TokenController.dart';
import 'package:mapos_app/utils/cache_helper.dart';
import 'package:flutter/foundation.dart';

class ControllerOs {
  static const String _OrdemServicoKey = 'cached_OrdemServico';

  Future<bool> hasInternetConnection() async {
    if (kIsWeb) return true;
    try {
      final result = await http.get(Uri.parse('https://www.google.com/generate_204'));
      return result.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getAllOrdemServico(int page, int perPage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await hasInternetConnection()) {
      debugPrint('Você está offline, carregando dados salvos localmente...');
      return _loadOrdemServicoFromLocal(prefs);
    }

    try {
      await APIConfig.ensureBaseURLInitialized();
      String? token = prefs.getString('access_token');
      var response = await _reqOrdemServico(token, page, perPage);

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        token = prefs.getString('access_token');
        response = await _reqOrdemServico(token, page, perPage);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status']) {
          await _saveOrdemServicoFromLocal(prefs, data['result']);
          return data['result'];
        } else {
          throw Exception('${data['message']}');
        }
      } else {
        if (kIsWeb) {
          return _loadOrdemServicoFromLocal(prefs);
        }
        throw Exception('Erro na conexão com a API');
      }
    } catch (e) {
      if (kIsWeb) {
        return _loadOrdemServicoFromLocal(prefs);
      }
      rethrow;
    }
  }

  Future<http.Response> _reqOrdemServico(String? token, int page, int perPage) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}?perPage=$perPage&page=$page');

    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'App-Version': APIConfig.appVersion,
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<void> _saveOrdemServicoFromLocal(SharedPreferences prefs, List<dynamic> OrdemServico) async {
    String jsonOrdemServico = jsonEncode(OrdemServico);
    await CacheHelper.safeSetString(prefs, _OrdemServicoKey, jsonOrdemServico);
    debugPrint('produtos salvos para uso Offline');
  }

  Future<List<dynamic>> _loadOrdemServicoFromLocal(SharedPreferences prefs) async {
    String? jsonOrdemServico = prefs.getString(_OrdemServicoKey);
    if (jsonOrdemServico != null) {
      List<dynamic> OrdemServico = jsonDecode(jsonOrdemServico);
      debugPrint('produtos carregados localmente');
      return OrdemServico;
    } else {
      throw Exception('Nenhum registro encontrado Localmente');
    }
  }

  Future<Map<String, dynamic>> getOrdemServicotById(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await hasInternetConnection()) {
      debugPrint('Sem conexão Carregando Produtos localmente');
      return _loadOrdemServicoByIdFromLocal(prefs, id);
    }

    try {
      await APIConfig.ensureBaseURLInitialized();
      String? token = prefs.getString('access_token');
      var response = await _reqOrdemServicoById(token, id);

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        token = prefs.getString('access_token');
        response = await _reqOrdemServicoById(token, id);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status']) {
          await _saveOrdemServicoToLocal(prefs, id, data['result']);
          return data['result'];
        } else {
          throw Exception('${data['message']}');
        }
      } else {
        if (kIsWeb) {
          return _loadOrdemServicoByIdFromLocal(prefs, id);
        }
        throw Exception('Ordem de Servico não Encomtrada');
      }
    } catch (e) {
      if (kIsWeb) {
        return _loadOrdemServicoByIdFromLocal(prefs, id);
      }
      rethrow;
    }
  }

  Future<http.Response> _reqOrdemServicoById(String? token, int id) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/$id');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'App-Version': APIConfig.appVersion,
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<void> _saveOrdemServicoToLocal(SharedPreferences prefs, int id, Map<String, dynamic> product) async {
    String key = 'ordem_servico_$id';
    String jsonproduct = jsonEncode(product);
    await CacheHelper.safeSetString(prefs, key, jsonproduct);
    debugPrint('product details saved locally.');
  }

  Future<Map<String, dynamic>> _loadOrdemServicoByIdFromLocal(SharedPreferences prefs, int id) async {
    String key = 'ordem_servico_$id';
    String? jsonproduct = prefs.getString(key);
    if (jsonproduct != null) {
      Map<String, dynamic> product = jsonDecode(jsonproduct);
      debugPrint('Dados salvos Localmente');
      return product;
    } else {
      throw Exception('O Produto $id não foi salvo localmente 😢.');
    }
  }

  Future<bool> updateProduct(int id, String? codDeBarra, String descricao, double precoVenda, double precoCompra, int estoque, int estoqueMinimo ) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqUpdateProduct(token, id, codDeBarra, descricao, precoVenda,  precoCompra, estoque, estoqueMinimo);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqUpdateProduct(newToken, id, codDeBarra, descricao, precoVenda, precoCompra, estoque, estoqueMinimo);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      throw Exception('Erro ao atualizar o produto');
    }
  }

  Future<http.Response> _reqUpdateProduct(String? token, int id, String? codDeBarra, String descricao, double precoVenda, double precoCompra, int estoque, int estoqueMinimo) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.produtosEndpoint}/$id');

    return await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'App-Version': APIConfig.appVersion,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'codDeBarra': codDeBarra ?? '',
        'descricao': descricao,
        'unidade': "UNID",
        'precoCompra': precoCompra,
        'precoVenda': precoVenda,
        'estoque': estoque,
        'estoqueMinimo': estoqueMinimo,
        'saida': 1,
        'entrada': 1,
      }),
    );
  }

  Future<bool> addProduct(String? codDeBarra, String descricao, double precoVenda, double precoCompra, int estoque, int estoqueMinimo) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqAddProduct(token, codDeBarra, descricao, precoVenda, precoCompra, estoque, estoqueMinimo);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqAddProduct(newToken, codDeBarra, descricao, precoVenda, precoCompra, estoque, estoqueMinimo);
    }

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      throw Exception('Erro ao adicionar o produto');
    }
  }

  Future<http.Response> _reqAddProduct(String? token, String? codDeBarra, String descricao, double precoVenda, double precoCompra, int estoque, int estoqueMinimo) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.produtosEndpoint}');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'App-Version': APIConfig.appVersion,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'codDeBarra': codDeBarra ?? '',
        'descricao': descricao,
        'unidade': "UNID",
        'precoCompra': precoCompra,
        'precoVenda': precoVenda,
        'estoque': estoque,
        'estoqueMinimo': estoqueMinimo,
        'saida': 1,
        'entrada': 1,
      }),
    );
  }

  Future<bool> deleteOrdemServico(int id) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqDeleteOrdemServico(token, id);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqDeleteOrdemServico(newToken, id);
    }

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Erro ao deletar o produto');
    }
  }

  Future<http.Response> _reqDeleteOrdemServico(String? token, int id) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/$id');
    return await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'App-Version': APIConfig.appVersion,
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<Map<String, dynamic>> addOs(Map<String, dynamic> osData) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    try {
      var response = await _reqAddOs(token, osData);
      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        token = prefs.getString('access_token');
        response = await _reqAddOs(token, osData);
      }

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erro ao abrir OS');
      }
    } catch (e) {
      if (kIsWeb) {
        throw Exception('Erro de conexao. Verifique a URL da API.');
      }
      rethrow;
    }
  }

  Future<http.Response> _reqAddOs(String? token, Map<String, dynamic> osData) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'App-Version': APIConfig.appVersion,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(osData),
    );
  }

  List<dynamic> _cachedClientes = [];

  Future<List<dynamic>> getClientes(String search) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    // Load all clients once, then filter locally
    if (_cachedClientes.isEmpty) {
      var response = await _reqClientes(token);
      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        token = prefs.getString('access_token');
        response = await _reqClientes(token);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] && data['result'] != null) {
          _cachedClientes = data['result'];
        } else {
          return [];
        }
      } else {
        throw Exception('Erro ao buscar clientes');
      }
    }

    // Filter locally by name or document
    if (search.isEmpty) return _cachedClientes;
    final query = search.toLowerCase();
    return _cachedClientes.where((c) {
      final nome = (c['nomeCliente'] ?? '').toString().toLowerCase();
      final doc = (c['documento'] ?? '').toString().toLowerCase();
      return nome.contains(query) || doc.contains(query);
    }).toList();
  }

  Future<http.Response> _reqClientes(String? token) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.clientesEndpoint}');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'App-Version': APIConfig.appVersion,
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<List<dynamic>> getUsuarios() async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqUsuarios(token);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      token = prefs.getString('access_token');
      response = await _reqUsuarios(token);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        return data['result'];
      } else {
        throw Exception('${data['message']}');
      }
    } else {
      throw Exception('Erro ao buscar tecnicos');
    }
  }

  Future<http.Response> _reqUsuarios(String? token) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.usuarioEndpoint}');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'App-Version': APIConfig.appVersion,
        'Authorization': 'Bearer $token',
      },
    );
  }
}
