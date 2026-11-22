import 'dart:typed_data';

import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../models/ordem_servico.dart';

class OsRepository {
  OsRepository(this._api);
  final ApiClient _api;

  static const int perPage = 20;

  Future<List<OrdemServico>> list({int page = 0, String search = '', String? status}) async {
    final r = await _api.get(
      '/os',
      query: {'page': page, 'perPage': perPage, 'search': search, 'status': status},
      cache: search.isEmpty && status == null,
    );
    if (r is! List) return const [];
    return r.whereType<Map>().map((e) => OrdemServico.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<OrdemServico> get(int id) async {
    final r = await _api.get('/os/$id', cache: true);
    return OrdemServico.fromJson(Map<String, dynamic>.from(r as Map));
  }

  /// Retorna o id da OS criada.
  Future<int> create(OsInput input) async {
    final r = await _api.post('/os', body: input.toJson());
    return r is Map ? asInt(r['idOs']) : 0;
  }

  Future<void> update(int id, OsInput input) => _api.put('/os/$id', body: input.toJson());

  Future<void> delete(int id) => _api.delete('/os/$id');

  // ---- Itens ----
  Future<void> addProduto(int osId, {required int produtoId, required double quantidade, required double preco}) =>
      _api.post('/os/$osId/produtos', body: {
        'idProduto': produtoId,
        'quantidade': quantidade,
        'preco': preco.toStringAsFixed(2),
      });

  Future<void> updateProduto(int osId, int itemId, {required double quantidade, required double preco}) =>
      _api.put('/os/$osId/produtos/$itemId', body: {'quantidade': quantidade, 'preco': preco.toStringAsFixed(2)});

  Future<void> removeProduto(int osId, int itemId) => _api.delete('/os/$osId/produtos/$itemId');

  Future<void> addServico(int osId, {required int servicoId, required double quantidade, required double preco}) =>
      _api.post('/os/$osId/servicos', body: {
        'idServico': servicoId,
        'quantidade': quantidade,
        'preco': preco.toStringAsFixed(2),
      });

  Future<void> updateServico(int osId, int itemId, {required double quantidade, required double preco}) =>
      _api.put('/os/$osId/servicos/$itemId', body: {'quantidade': quantidade, 'preco': preco.toStringAsFixed(2)});

  Future<void> removeServico(int osId, int itemId) => _api.delete('/os/$osId/servicos/$itemId');

  // ---- Desconto ----
  /// [tipo]: 'real' ou 'porcento'. [valorFinal]: total já com desconto.
  Future<void> aplicarDesconto(int osId, {required double desconto, required String tipo, required double valorFinal}) =>
      _api.post('/os/$osId/desconto', body: {
        'desconto': desconto,
        'tipo_desconto': tipo,
        'valor_desconto': valorFinal,
      });

  // ---- Anotações ----
  Future<void> addAnotacao(int osId, String texto) => _api.post('/os/$osId/anotacoes', body: {'anotacao': texto});
  Future<void> removeAnotacao(int osId, int id) => _api.delete('/os/$osId/anotacoes/$id');

  // ---- Anexos ----
  Future<void> uploadAnexo(int osId, Uint8List bytes, String filename) =>
      _api.upload('/os/$osId/anexos', field: 'key', bytes: bytes, filename: filename);

  Future<void> removeAnexo(int osId, int id) => _api.delete('/os/$osId/anexos/$id');

  Future<Uint8List> anexoBytes(String url) => _api.getBytes(url);

  // ---- Agenda ----
  Future<List<OrdemServico>> calendario(DateTime start, DateTime end) async {
    String d(DateTime x) =>
        '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    final r = await _api.get('/calendario', query: {'start': d(start), 'end': d(end)}, cache: true);
    final all = r is Map ? r['allOs'] : null;
    if (all is! List) return const [];
    return all.whereType<Map>().map((e) => OrdemServico.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
