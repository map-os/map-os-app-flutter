import '../../core/utils/formatters.dart';
import 'ordem_servico.dart';

class Venda {
  const Venda({
    required this.id,
    required this.status,
    required this.clienteId,
    required this.nomeCliente,
    this.vendedorId = 0,
    this.vendedor = '',
    this.dataVenda,
    this.garantiaDias,
    this.garantiaAte,
    this.observacoes = '',
    this.observacoesCliente = '',
    this.faturado = false,
    this.editavel = true,
    this.totalProdutos = 0,
    this.desconto = 0,
    this.tipoDesconto = '',
    this.valorDoDesconto = 0,
    this.total = 0,
    this.produtos = const [],
    this.cobrancaId,
  });

  final int id;
  final String status;
  final int clienteId;
  final String nomeCliente;
  final int vendedorId;
  final String vendedor;
  final DateTime? dataVenda;
  final int? garantiaDias;
  final DateTime? garantiaAte;
  final String observacoes;
  final String observacoesCliente;
  final bool faturado;
  final bool editavel;
  final double totalProdutos;
  final double desconto;
  final String tipoDesconto;
  final double valorDoDesconto;
  final double total;
  final List<OsItem> produtos;
  final int? cobrancaId;

  bool get temDesconto => valorDoDesconto > 0;

  factory Venda.fromJson(Map<String, dynamic> j) {
    final cliente = asMap(j['cliente']);
    final vendedor = asMap(j['vendedor']);
    final totais = asMap(j['totais']);
    final geral = asMap(totais['desconto_geral']);
    return Venda(
      id: asInt(j['id']),
      status: asString(j['status']),
      clienteId: asInt(cliente['id']),
      nomeCliente: asString(cliente['nome']),
      vendedorId: asInt(vendedor['id']),
      vendedor: asString(vendedor['nome']),
      dataVenda: asDate(j['data_venda']),
      garantiaDias: j['garantia_dias'] == null ? null : asInt(j['garantia_dias']),
      garantiaAte: asDate(j['garantia_ate']),
      observacoes: asString(j['observacoes']),
      observacoesCliente: asString(j['observacoes_cliente']),
      faturado: j['faturado'] == true,
      editavel: j['editavel'] != false,
      totalProdutos: asDouble(totais['produtos']),
      desconto: asDouble(geral['valor']),
      tipoDesconto: asString(geral['tipo']),
      valorDoDesconto: asDouble(totais['desconto']),
      total: totais.isNotEmpty ? asDouble(totais['total']) : asDouble(j['total']),
      produtos: (j['produtos'] is List)
          ? (j['produtos'] as List).whereType<Map>().map((e) => OsItem.produto(Map<String, dynamic>.from(e))).toList()
          : const [],
      cobrancaId: j['cobranca_id'] == null ? null : asInt(j['cobranca_id']),
    );
  }
}
