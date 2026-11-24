import 'dart:typed_data';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../models/catalogo.dart';
import '../models/ordem_servico.dart';
import 'cadastros_repository.dart';

class Pix {
  const Pix({required this.valor, required this.payload, required this.qrCode, required this.chave});

  final double valor;
  final String payload;
  final String qrCode;
  final String chave;

  factory Pix.fromJson(Map<String, dynamic> j) =>
      Pix(valor: asDouble(j['valor']), payload: asString(j['payload']), qrCode: asString(j['qr_code']), chave: asString(j['chave']));
}

class FaturaInput {
  const FaturaInput({required this.descricao, required this.vencimento, required this.formaPagamento, this.recebido = false, this.dataRecebimento, this.observacoes = ''});

  final String descricao;
  final DateTime vencimento;
  final String formaPagamento;
  final bool recebido;
  final DateTime? dataRecebimento;
  final String observacoes;

  Map<String, dynamic> toJson() => {
        'descricao': descricao,
        'vencimento': Fmt.apiDate(vencimento),
        'forma_pagamento': formaPagamento,
        'recebido': recebido,
        if (recebido && dataRecebimento != null) 'data_recebimento': Fmt.apiDate(dataRecebimento!),
        'observacoes': observacoes,
      };
}

class OpcoesDaOs {
  const OpcoesDaOs({required this.status, required this.formasPagamento, required this.controleEstoque, this.cobrancas = const []});

  final List<String> status;
  final List<String> formasPagamento;
  final bool controleEstoque;
  final List<({String gateway, String forma, String nome})> cobrancas;
}

class OsRepository {
  OsRepository(this._api);
  final ApiClient _api;

  static const int perPage = AppConfig.pageSize;

  Future<List<OrdemServico>> list({int page = 0, String search = '', String? status}) async {
    final r = await _api.getPage('/os', query: pagina(page, search, {'status': status}), cache: search.isEmpty && status == null);
    return r.items.map(OrdemServico.fromJson).toList();
  }

  Future<OrdemServico> get(int id) async => OrdemServico.fromJson(asMap(await _api.get('/os/$id', cache: true)));

  Future<OpcoesDaOs> opcoes() async {
    final r = asMap(await _api.get('/os/opcoes', cache: true));
    List<String> l(String k) => (r[k] as List? ?? const []).map((e) => e.toString()).toList();
    return OpcoesDaOs(
      status: l('status'),
      formasPagamento: l('formas_pagamento'),
      controleEstoque: r['controle_estoque'] == true,
      cobrancas: [
        for (final c in lista(r['cobrancas'])) (gateway: asString(c['gateway']), forma: asString(c['forma']), nome: asString(c['nome'])),
      ],
    );
  }

  Future<int> create(OsInput input) async => asInt(asMap(await _api.post('/os', body: input.toJson()))['id']);

  Future<void> update(int id, OsInput input) => _api.patch('/os/$id', body: input.toJson());

  Future<void> mudarStatus(int id, String status) => _api.patch('/os/$id', body: {'status': status});

  Future<void> delete(int id) => _api.delete('/os/$id');

  Future<void> addProduto(int osId, {required int produtoId, required double quantidade, double? preco}) =>
      _api.post('/os/$osId/produtos', body: {
        'produto_id': produtoId,
        'quantidade': quantidade.round(),
        if (preco != null) 'preco': preco.toStringAsFixed(2),
      });

  Future<void> removeProduto(int osId, int itemId) => _api.delete('/os/$osId/produtos/$itemId');

  Future<void> addServico(int osId, {required int servicoId, required double quantidade, double? preco}) =>
      _api.post('/os/$osId/servicos', body: {
        'servico_id': servicoId,
        'quantidade': quantidade,
        if (preco != null) 'preco': preco.toStringAsFixed(2),
      });

  Future<void> removeServico(int osId, int itemId) => _api.delete('/os/$osId/servicos/$itemId');

  Future<void> descontoDoItem(int osId, {required bool produto, required int itemId, required String tipo, required double valor}) =>
      _api.put('/os/$osId/${produto ? 'produtos' : 'servicos'}/$itemId/desconto', body: {'tipo': tipo, 'valor': valor.toStringAsFixed(2)});

  Future<void> aplicarDesconto(int osId, {required double desconto, required String tipo}) =>
      _api.put('/os/$osId/desconto', body: {'tipo': tipo, 'valor': desconto.toStringAsFixed(2)});

  Future<void> faturar(int osId, FaturaInput fatura) => _api.post('/os/$osId/faturar', body: fatura.toJson());

  Future<void> enviarEmail(int osId) => _api.post('/os/$osId/email');

  Future<Pix> pix(int osId) async => Pix.fromJson(asMap(await _api.get('/os/$osId/pix')));

  Future<({String telefone, String texto})> whatsapp(int osId) async {
    final r = asMap(await _api.get('/os/$osId/whatsapp'));
    return (telefone: asString(r['telefone']), texto: asString(r['texto']));
  }

  Future<List<Sugestao>> termosDeGarantia(String search) async =>
      lista(await _api.get('/busca/garantias', query: {'busca': search.trim()})).map(Sugestao.fromJson).toList();

  Future<void> addAnotacao(int osId, String texto) => _api.post('/os/$osId/anotacoes', body: {'texto': texto});
  Future<void> removeAnotacao(int osId, int id) => _api.delete('/os/$osId/anotacoes/$id');

  Future<void> uploadAnexo(int osId, Uint8List bytes, String filename) =>
      _api.upload('/os/$osId/anexos', field: 'arquivo', bytes: bytes, filename: filename);

  Future<void> removeAnexo(int osId, int id) => _api.delete('/os/$osId/anexos/$id');

  Future<Uint8List> anexoBytes(String url) => _api.getBytes(url);

  Future<List<OrdemServico>> calendario(DateTime start, DateTime end) async {
    final r = await _api.get('/calendario', query: {'de': Fmt.apiDate(start), 'ate': Fmt.apiDate(end)}, cache: true);
    return lista(r).map(OrdemServico.doCalendario).toList();
  }
}
