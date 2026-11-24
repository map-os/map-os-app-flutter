import 'dart:typed_data';

import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../models/cobranca.dart';
import '../models/gestao.dart';
import '../models/venda.dart';
import 'cadastros_repository.dart';
import 'os_repository.dart';

class VendasRepository {
  VendasRepository(this._api);
  final ApiClient _api;

  Future<List<Venda>> list({int page = 0, String search = '', String? status}) async =>
      (await _api.getPage('/vendas', query: pagina(page, search, {'status': status}), cache: search.isEmpty && status == null)).items.map(Venda.fromJson).toList();

  Future<Venda> get(int id) async => Venda.fromJson(asMap(await _api.get('/vendas/$id', cache: true)));

  Future<Venda> create(Map<String, dynamic> dados) async => Venda.fromJson(asMap(await _api.post('/vendas', body: dados)));

  Future<Venda> update(int id, Map<String, dynamic> dados) async => Venda.fromJson(asMap(await _api.patch('/vendas/$id', body: dados)));

  Future<void> delete(int id) => _api.delete('/vendas/$id');

  Future<void> addProduto(int id, {required int produtoId, required double quantidade, double? preco}) => _api.post('/vendas/$id/produtos', body: {
        'produto_id': produtoId,
        'quantidade': quantidade.round(),
        if (preco != null) 'preco': preco.toStringAsFixed(2),
      });

  Future<void> removeProduto(int id, int itemId) => _api.delete('/vendas/$id/produtos/$itemId');

  Future<void> descontoDoItem(int id, int itemId, {required String tipo, required double valor}) =>
      _api.put('/vendas/$id/produtos/$itemId/desconto', body: {'tipo': tipo, 'valor': valor.toStringAsFixed(2)});

  Future<void> aplicarDesconto(int id, {required String tipo, required double valor}) =>
      _api.put('/vendas/$id/desconto', body: {'tipo': tipo, 'valor': valor.toStringAsFixed(2)});

  Future<void> faturar(int id, FaturaInput fatura) => _api.post('/vendas/$id/faturar', body: fatura.toJson());

  Future<Pix> pix(int id) async => Pix.fromJson(asMap(await _api.get('/vendas/$id/pix')));
}

class LancamentosRepository {
  LancamentosRepository(this._api);
  final ApiClient _api;

  Future<(List<Lancamento>, TotaisFinanceiros)> list({int page = 0, String search = '', String? tipo, String? situacao, String periodo = 'mes'}) async {
    final r = await _api.getPage('/lancamentos', query: pagina(page, search, {'tipo': tipo, 'situacao': situacao, 'periodo': periodo}));
    return (r.items.map(Lancamento.fromJson).toList(), TotaisFinanceiros.fromJson(asMap(r.meta['totais'])));
  }

  Future<List<({int? clienteId, String nome, String detalhe})>> sugestoes(String busca) async {
    if (busca.trim().isEmpty) return const [];
    return [
      for (final s in lista(await _api.get('/lancamentos/sugestoes', query: {'busca': busca.trim()})))
        (clienteId: s['cliente_id'] == null ? null : asInt(s['cliente_id']), nome: asString(s['nome']), detalhe: asString(s['detalhe'])),
    ];
  }

  Future<ResumoFinanceiro> resumo() async => ResumoFinanceiro.fromJson(asMap(await _api.get('/lancamentos/resumo', query: {'meses': 6}, cache: true)));

  Future<Lancamento> get(int id) async => Lancamento.fromJson(asMap(await _api.get('/lancamentos/$id')));

  Future<void> create(Map<String, dynamic> dados) => _api.post('/lancamentos', body: dados);

  Future<void> update(int id, Map<String, dynamic> dados) => _api.patch('/lancamentos/$id', body: dados);

  Future<void> delete(int id) => _api.delete('/lancamentos/$id');
}

class CobrancasRepository {
  CobrancasRepository(this._api);
  final ApiClient _api;

  Future<List<Cobranca>> list({int page = 0, String search = '', String? origem}) async =>
      (await _api.getPage('/cobrancas', query: pagina(page, search, {'origem': origem}))).items.map(Cobranca.fromJson).toList();

  Future<Cobranca> get(int id) async => Cobranca.fromJson(asMap(await _api.get('/cobrancas/$id')));

  Future<Cobranca> gerar({required String origem, required int origemId, required String gateway, required String forma}) async =>
      Cobranca.fromJson(asMap(await _api.post('/cobrancas', body: {'origem': origem, 'origem_id': origemId, 'gateway': gateway, 'forma_pagamento': forma})));

  Future<Cobranca> acao(int id, String acao) async => Cobranca.fromJson(asMap(await _api.post('/cobrancas/$id/$acao')));

  Future<void> enviarEmail(int id) => _api.post('/cobrancas/$id/email');

  Future<void> delete(int id) => _api.delete('/cobrancas/$id');
}

class GarantiasRepository {
  GarantiasRepository(this._api);
  final ApiClient _api;

  Future<List<TermoDeGarantia>> list({int page = 0, String search = ''}) async =>
      (await _api.getPage('/garantias', query: pagina(page, search))).items.map(TermoDeGarantia.fromJson).toList();

  Future<void> salvar(int? id, {required String referencia, required String texto}) {
    final dados = {'referencia': referencia, 'texto': texto};
    return id == null ? _api.post('/garantias', body: dados) : _api.patch('/garantias/$id', body: dados);
  }

  Future<void> delete(int id) => _api.delete('/garantias/$id');
}

class ArquivosRepository {
  ArquivosRepository(this._api);
  final ApiClient _api;

  Future<List<Arquivo>> list({int page = 0, String search = ''}) async =>
      (await _api.getPage('/arquivos', query: pagina(page, search))).items.map(Arquivo.fromJson).toList();

  Future<void> enviar({required Uint8List bytes, required String nomeDoArquivo, required String nome, String descricao = ''}) =>
      _api.upload('/arquivos', field: 'arquivo', bytes: bytes, filename: nomeDoArquivo, fields: {'nome': nome, 'descricao': descricao});

  Future<void> update(int id, {required String nome, required String descricao}) => _api.patch('/arquivos/$id', body: {'nome': nome, 'descricao': descricao});

  Future<Uint8List> baixar(int id) => _api.getBytes(_api.uri('/arquivos/$id/download').toString());

  Future<void> delete(int id) => _api.delete('/arquivos/$id');
}

class RelatoriosRepository {
  RelatoriosRepository(this._api);
  final ApiClient _api;

  Future<Relatorio> gerar(String tipo, Map<String, dynamic> filtros) async => Relatorio.fromJson(asMap(await _api.get('/relatorios/$tipo', query: filtros)));

  Future<Uint8List> exportar(String tipo, Map<String, dynamic> filtros, String formato) =>
      _api.getBytes(_api.uri('/relatorios/$tipo', {...filtros, 'formato': formato}).toString());
}
