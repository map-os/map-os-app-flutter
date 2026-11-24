import '../../core/utils/formatters.dart';

class Cobranca {
  const Cobranca({
    required this.id,
    required this.status,
    required this.situacao,
    required this.valor,
    this.origemTipo = '',
    this.origemId = 0,
    this.cliente = '',
    this.gateway = '',
    this.formaPagamento = '',
    this.statusDescricao = '',
    this.vencimento,
    this.codigoDeBarras = '',
    this.linkPagamento = '',
    this.linkBoleto = '',
    this.pdf = '',
  });

  final int id;
  final String status;
  final String situacao;
  final double valor;
  final String origemTipo;
  final int origemId;
  final String cliente;
  final String gateway;
  final String formaPagamento;
  final String statusDescricao;
  final DateTime? vencimento;
  final String codigoDeBarras;
  final String linkPagamento;
  final String linkBoleto;
  final String pdf;

  String get origem => origemTipo == 'os' ? 'OS #$origemId' : (origemTipo == 'venda' ? 'Venda #$origemId' : 'Avulsa');
  String get link => [linkPagamento, linkBoleto, pdf].firstWhere((l) => l.isNotEmpty, orElse: () => '');
  bool get paga => situacao == 'Paga';

  factory Cobranca.fromJson(Map<String, dynamic> j) {
    final origem = asMap(j['origem']);
    return Cobranca(
      id: asInt(j['id']),
      status: asString(j['status']),
      situacao: asString(j['situacao']),
      valor: asDouble(j['valor']),
      origemTipo: asString(origem['tipo']),
      origemId: asInt(origem['id']),
      cliente: asString(asMap(j['cliente'])['nome']),
      gateway: asString(j['gateway']),
      formaPagamento: asString(j['forma_pagamento']),
      statusDescricao: asString(j['status_descricao']),
      vencimento: asDate(j['vencimento']),
      codigoDeBarras: asString(j['codigo_de_barras']),
      linkPagamento: asString(j['link_pagamento']),
      linkBoleto: asString(j['link_boleto']),
      pdf: asString(j['pdf']),
    );
  }
}
