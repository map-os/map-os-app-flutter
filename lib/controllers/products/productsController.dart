import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/TokenController.dart';

class ControllerProducts {
  static const String _productsKey = 'cached_products';

  Future<bool> hasInternetConnection() async {
    try {
      final result = await http.get(Uri.parse('http://clients3.google.com/generate_204'));
      return result.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getAllProducts(int page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await hasInternetConnection()) {
      print('Você está offline, carregando dados salvos localmente...');
      return _loadProductsFromLocal(prefs);
    }

    await APIConfig.ensureBaseURLInitialized();
    String? token = prefs.getString('access_token');
    var response = await _reqProducts(token, page);

    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      token = prefs.getString('access_token');
      response = await _reqProducts(token, page);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        await _saveProductsFromLocal(prefs, data['result']);
        return data['result'];
      } else {
        throw Exception('${data['message']}');
      }
    } else {
      throw Exception('Errro na conexão com a API');
    }
  }

  Future<void> _saveProductsFromLocal(SharedPreferences prefs, List<dynamic> products) async {
    String jsonProducts = jsonEncode(products);
    await prefs.setString(_productsKey, jsonProducts);
    print('produtos salvos para uso Offline');
  }

  Future<List<dynamic>> _loadProductsFromLocal(SharedPreferences prefs) async {
    String? jsonProducts = prefs.getString(_productsKey);
    if (jsonProducts != null) {
      List<dynamic> products = jsonDecode(jsonProducts);
      print('produtos carregados localmente');
      return products;
    } else {
      throw Exception('Nenhum registro encontrado Localmente');
    }
  }

  Future<http.Response> _reqProducts(String? token, int page) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.prodtuostesEndpoint}?page=$page');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<Map<String, dynamic>> getProductById(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await hasInternetConnection()) {
      print('Sem conexão Carregando Produtos localmente');
      return _loadProductByIdFromLocal(prefs, id);
    }

    await APIConfig.ensureBaseURLInitialized();
    String? token = prefs.getString('access_token');
    var response = await _reqProductById(token, id);

    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      token = prefs.getString('access_token');
      response = await _reqProductById(token, id);
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        await _saveProductToLocal(prefs, id, data['result']);
        return data['result'];
      } else {
        throw Exception('${data['message']}');
      }
    } else {
      throw Exception('Error requesting product by ID');
    }
  }

  Future<void> _saveProductToLocal(SharedPreferences prefs, int id, Map<String, dynamic> product) async {
    String key = 'product_$id';
    String jsonproduct = jsonEncode(product);
    await prefs.setString(key, jsonproduct);
    print('product details saved locally.');
  }

  Future<Map<String, dynamic>> _loadProductByIdFromLocal(SharedPreferences prefs, int id) async {
    String key = 'product_$id';
    String? jsonproduct = prefs.getString(key);
    if (jsonproduct != null) {
      Map<String, dynamic> product = jsonDecode(jsonproduct);
      print('Dados salvos Localmente');
      return product;
    } else {
      throw Exception('O Produto $id não foi salvo localmente 😢.');
    }
  }

  Future<http.Response> _reqProductById(String? token, int id) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.prodtuostesEndpoint}/$id');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
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
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.prodtuostesEndpoint}/$id');

    return await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
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
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.prodtuostesEndpoint}');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
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

  Future<bool> deleteProduct(int id) async {
    await APIConfig.ensureBaseURLInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var response = await _reqDeleteProduct(token, id);
    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      String? newToken = prefs.getString('access_token');
      response = await _reqDeleteProduct(newToken, id);
    }

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Erro ao deletar o produto');
    }
  }

  Future<http.Response> _reqDeleteProduct(String? token, int id) async {
    final url = Uri.parse('${APIConfig.baseURL}${APIConfig.prodtuostesEndpoint}/$id');
    return await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

}
