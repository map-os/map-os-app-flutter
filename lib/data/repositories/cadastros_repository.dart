import '../../core/network/api_client.dart';
import '../models/catalogo.dart';
import '../models/cliente.dart';
import '../models/conta.dart';

List<Map<String, dynamic>> _list(dynamic result) => result is List
    ? result.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];

Map<String, dynamic> _map(dynamic result) =>
    result is Map ? Map<String, dynamic>.from(result) : <String, dynamic>{};

class ClientesRepository {
  ClientesRepository(this._api);
  final ApiClient _api;

  Future<List<Cliente>> list({int page = 0, String search = ''}) async {
    final r = await _api.get('/clientes', query: {'page': page, 'search': search}, cache: search.isEmpty);
    return _list(r).map(Cliente.fromJson).toList();
  }

  Future<Cliente> get(int id) async => Cliente.fromJson(_map(await _api.get('/clientes/$id', cache: true)));

  Future<void> create(Cliente c, {String? senha}) =>
      _api.post('/clientes', body: {...c.toJson(), if ((senha ?? '').isNotEmpty) 'senha': senha});

  Future<void> update(Cliente c, {String? senha}) =>
      _api.put('/clientes/${c.id}', body: {...c.toJson(), if ((senha ?? '').isNotEmpty) 'senha': senha});

  Future<void> delete(int id) => _api.delete('/clientes/$id');

  /// Consulta de endereço pelo CEP (ViaCEP).
  Future<Map<String, dynamic>?> buscarCep(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final r = await _api.getExternalJson(Uri.parse('https://viacep.com.br/ws/$digits/json/'));
    if (r == null || r['erro'] != null) return null;
    return r;
  }
}

class ProdutosRepository {
  ProdutosRepository(this._api);
  final ApiClient _api;

  Future<List<Produto>> list({int page = 0, String search = ''}) async {
    final r = await _api.get('/produtos', query: {'page': page, 'search': search}, cache: search.isEmpty);
    return _list(r).map(Produto.fromJson).toList();
  }

  Future<Produto> get(int id) async => Produto.fromJson(_map(await _api.get('/produtos/$id', cache: true)));
  Future<void> create(Produto p) => _api.post('/produtos', body: p.toJson());
  Future<void> update(Produto p) => _api.put('/produtos/${p.id}', body: p.toJson());
  Future<void> delete(int id) => _api.delete('/produtos/$id');
}

class ServicosRepository {
  ServicosRepository(this._api);
  final ApiClient _api;

  Future<List<Servico>> list({int page = 0, String search = ''}) async {
    final r = await _api.get('/servicos', query: {'page': page, 'search': search}, cache: search.isEmpty);
    return _list(r).map(Servico.fromJson).toList();
  }

  Future<Servico> get(int id) async => Servico.fromJson(_map(await _api.get('/servicos/$id', cache: true)));
  Future<void> create(Servico s) => _api.post('/servicos', body: s.toJson());
  Future<void> update(Servico s) => _api.put('/servicos/${s.id}', body: s.toJson());
  Future<void> delete(int id) => _api.delete('/servicos/$id');
}

class ContaRepository {
  ContaRepository(this._api);
  final ApiClient _api;

  Future<DashboardData> dashboard() async => DashboardData.fromJson(_map(await _api.get('/', cache: true)));

  Future<Usuario> perfil() async {
    final r = _map(await _api.get('/conta', cache: true));
    return Usuario.fromJson(_map(r['usuario']));
  }

  Future<Emitente> emitente() async => Emitente.fromJson(_map(await _api.get('/emitente', cache: true)));

  Future<List<Usuario>> usuarios() async =>
      _list(await _api.get('/usuarios', cache: true)).map(Usuario.fromJson).toList();
}
