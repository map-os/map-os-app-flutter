import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/TokenController.dart';
import 'package:mapos_app/utils/cache_helper.dart';
import 'package:flutter/foundation.dart';

class ControllerChamados {
  static const String _ChamadosKey = 'cached_Chamados';

  Future<bool> hasInternetConnection() async {
    if (kIsWeb) return true;
    try {
      final result = await http.get(Uri.parse('https://www.google.com/generate_204'));
      return result.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getAllChamados(int page, int perPage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await hasInternetConnection()) {
      debugPrint('Voce esta offline, carregando chamados salvos localmente...');
      return _loadChamadosFromLocal(prefs);
    }

    try {
      await APIConfig.ensureBaseURLInitialized();
      String? token = prefs.getString('access_token');
      var response = await _reqChamados(token, page, perPage);

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        token = prefs.getString('access_token');
        response = await _reqChamados(token, page, perPage);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status']) {
          await _saveChamadosFromLocal(prefs, data['result']);
          return data['result'];
        } else {
          throw Exception('${data['message']}');
        }
      } else {
        if (kIsWeb) {
          return _loadChamadosFromLocal(prefs);
        }
        throw Exception('Erro na conexao com a API');
      }
    } catch (e) {
      if (kIsWeb) {
        return _loadChamadosFromLocal(prefs);
      }
      rethrow;
    }
  }

  Future<http.Response> _reqChamados(String? token, int page, int perPage) async {
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

  Future<void> _saveChamadosFromLocal(SharedPreferences prefs, List<dynamic> Chamados) async {
    String jsonChamados = jsonEncode(Chamados);
    await CacheHelper.safeSetString(prefs, _ChamadosKey, jsonChamados);
    debugPrint('chamados salvos para uso Offline');
  }

  Future<List<dynamic>> _loadChamadosFromLocal(SharedPreferences prefs) async {
    String? jsonChamados = prefs.getString(_ChamadosKey);
    if (jsonChamados != null) {
      List<dynamic> Chamados = jsonDecode(jsonChamados);
      debugPrint('chamados carregados localmente');
      return Chamados;
    } else {
      throw Exception('Nenhum chamado encontrado Localmente');
    }
  }

  Future<Map<String, dynamic>> getChamadoById(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await hasInternetConnection()) {
      debugPrint('Sem conexao, carregando chamado localmente');
      return _loadChamadoByIdFromLocal(prefs, id);
    }

    try {
      await APIConfig.ensureBaseURLInitialized();
      String? token = prefs.getString('access_token');
      var response = await _reqChamadoById(token, id);

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        token = prefs.getString('access_token');
        response = await _reqChamadoById(token, id);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status']) {
          await _saveChamadoToLocal(prefs, id, data['result']);
          return data['result'];
        } else {
          throw Exception('${data['message']}');
        }
      } else {
        if (kIsWeb) {
          return _loadChamadoByIdFromLocal(prefs, id);
        }
        throw Exception('Chamado nao Encontrado');
      }
    } catch (e) {
      if (kIsWeb) {
        return _loadChamadoByIdFromLocal(prefs, id);
      }
      rethrow;
    }
  }

  Future<http.Response> _reqChamadoById(String? token, int id) async {
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

  Future<void> _saveChamadoToLocal(SharedPreferences prefs, int id, Map<String, dynamic> chamado) async {
    String key = 'chamado_$id';
    String jsonChamado = jsonEncode(chamado);
    await CacheHelper.safeSetString(prefs, key, jsonChamado);
    debugPrint('chamado salvo localmente');
  }

  Future<Map<String, dynamic>> _loadChamadoByIdFromLocal(SharedPreferences prefs, int id) async {
    String key = 'chamado_$id';
    String? jsonChamado = prefs.getString(key);
    if (jsonChamado != null) {
      Map<String, dynamic> chamado = jsonDecode(jsonChamado);
      debugPrint('Dados do chamado carregados localmente');
      return chamado;
    } else {
      throw Exception('O Chamado $id nao foi salvo localmente');
    }
  }

  Future<Map<String, dynamic>> addChamado(Map<String, dynamic> chamadoData) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqAddChamado(token, chamadoData);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqAddChamado(newToken, chamadoData);
    }

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erro ao abrir chamado');
    }
  }

  Future<http.Response> _reqAddChamado(String? token, Map<String, dynamic> chamadoData) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'App-Version': APIConfig.appVersion,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(chamadoData),
    );
  }

  Future<bool> deleteChamado(int id) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqDeleteChamado(token, id);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqDeleteChamado(newToken, id);
    }

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }

  Future<http.Response> _reqDeleteChamado(String? token, int id) async {
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
      throw Exception('Erro ao buscar usuarios');
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