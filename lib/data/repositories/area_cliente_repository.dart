import 'dart:typed_data';

import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../models/cliente.dart';
import '../models/cobranca.dart';
import '../models/conta.dart';
import '../models/ordem_servico.dart';
import '../models/venda.dart';
import 'cadastros_repository.dart';
import 'os_repository.dart';

class PainelDoCliente {
  const PainelDoCliente({required this.osEmAndamento, required this.totalOs, required this.totalCompras, required this.totalCobrancas, required this.ultimasOs, required this.ultimasCompras});

  final int osEmAndamento;
  final int totalOs;
  final int totalCompras;
  final int totalCobrancas;
  final List<OrdemServico> ultimasOs;
  final List<Venda> ultimasCompras;
}

class AreaClienteRepository {
  AreaClienteRepository(this._api);
  final ApiClient _api;

  Future<PainelDoCliente> painel() async {
    final r = asMap(await _api.get('/cliente/painel', cache: true));
    return PainelDoCliente(
      osEmAndamento: asInt(r['os_em_andamento']),
      totalOs: asInt(r['total_os']),
      totalCompras: asInt(r['total_compras']),
      totalCobrancas: asInt(r['total_cobrancas']),
      ultimasOs: lista(r['ultimas_os']).map(OrdemServico.fromJson).toList(),
      ultimasCompras: lista(r['ultimas_compras']).map(Venda.fromJson).toList(),
    );
  }

  Future<Cliente> conta() async => Cliente.fromJson(asMap(await _api.get('/cliente/conta', cache: true)));

  Future<Cliente> atualizarConta(Map<String, dynamic> dados) async => Cliente.fromJson(asMap(await _api.patch('/cliente/conta', body: dados)));

  Future<List<OrdemServico>> ordens({int page = 0}) async =>
      (await _api.getPage('/cliente/os', query: pagina(page, ''), cache: page == 0)).items.map(OrdemServico.fromJson).toList();

  Future<OrdemServico> os(int id) async => OrdemServico.fromJson(asMap(await _api.get('/cliente/os/$id', cache: true)));

  Future<int> abrirOs({required String descricao, String defeito = '', String observacoes = ''}) async =>
      asInt(asMap(await _api.post('/cliente/os', body: {'descricao_produto': descricao, 'defeito': defeito, 'observacoes': observacoes}))['id']);

  Future<Uint8List> anexo(String url) => _api.getBytes(url);

  Future<Pix> pixDaOs(int id) async => Pix.fromJson(asMap(await _api.get('/cliente/os/$id/pix')));

  Future<List<Venda>> compras({int page = 0}) async =>
      (await _api.getPage('/cliente/compras', query: pagina(page, ''), cache: page == 0)).items.map(Venda.fromJson).toList();

  Future<Venda> compra(int id) async => Venda.fromJson(asMap(await _api.get('/cliente/compras/$id', cache: true)));

  Future<Pix> pixDaCompra(int id) async => Pix.fromJson(asMap(await _api.get('/cliente/compras/$id/pix')));

  Future<List<Cobranca>> cobrancas({int page = 0}) async =>
      (await _api.getPage('/cliente/cobrancas', query: pagina(page, ''), cache: page == 0)).items.map(Cobranca.fromJson).toList();

  Future<List<Sessao>> sessoes() async => lista(await _api.get('/cliente/auth/sessoes')).map(Sessao.fromJson).toList();

  Future<void> encerrarSessao(String id) => _api.delete('/cliente/auth/sessoes/$id');
}
