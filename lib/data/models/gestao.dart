import '../../core/utils/formatters.dart';

const formasDeLancamento = [
  'Dinheiro',
  'Pix',
  'Boleto',
  'Cartão de Crédito',
  'Cartão de Débito',
  'Cheque',
  'Cheque Pré-datado',
  'Depósito',
  'Transferência DOC',
  'Transferência TED',
  'Promissória',
];

class Lancamento {
  const Lancamento({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.valor,
    this.clienteFornecedor = '',
    this.clienteId,
    this.desconto = 0,
    this.valorLiquido = 0,
    this.vencimento,
    this.pagamento,
    this.pago = false,
    this.situacao = 'pendente',
    this.formaPagamento = '',
    this.observacoes = '',
    this.vendaId,
  });

  final int id;
  final String tipo;
  final String descricao;
  final double valor;
  final String clienteFornecedor;
  final int? clienteId;
  final double desconto;
  final double valorLiquido;
  final DateTime? vencimento;
  final DateTime? pagamento;
  final bool pago;
  final String situacao;
  final String formaPagamento;
  final String observacoes;
  final int? vendaId;

  bool get receita => tipo == 'receita';

  factory Lancamento.fromJson(Map<String, dynamic> j) => Lancamento(
        id: asInt(j['id']),
        tipo: asString(j['tipo']),
        descricao: asString(j['descricao']),
        valor: asDouble(j['valor']),
        clienteFornecedor: asString(j['cliente_fornecedor']),
        clienteId: j['cliente_id'] == null ? null : asInt(j['cliente_id']),
        desconto: asDouble(j['desconto']),
        valorLiquido: asDouble(j['valor_liquido']),
        vencimento: asDate(j['data_vencimento']),
        pagamento: asDate(j['data_pagamento']),
        pago: j['pago'] == true,
        situacao: asString(j['situacao']),
        formaPagamento: asString(j['forma_pagamento']),
        observacoes: asString(j['observacoes']),
        vendaId: j['venda_id'] == null ? null : asInt(j['venda_id']),
      );
}

class TotaisFinanceiros {
  const TotaisFinanceiros({this.receitas = 0, this.despesas = 0, this.saldo = 0, this.receitasPendentes = 0, this.despesasPendentes = 0});

  final double receitas;
  final double despesas;
  final double saldo;
  final double receitasPendentes;
  final double despesasPendentes;

  factory TotaisFinanceiros.fromJson(Map<String, dynamic> j) => TotaisFinanceiros(
        receitas: asDouble(j['receitas']),
        despesas: asDouble(j['despesas']),
        saldo: asDouble(j['saldo']),
        receitasPendentes: asDouble(j['receitas_pendentes']),
        despesasPendentes: asDouble(j['despesas_pendentes']),
      );
}

class ResumoFinanceiro {
  const ResumoFinanceiro({required this.saldoRealizado, required this.aReceber, required this.aPagar, required this.meses});

  final double saldoRealizado;
  final double aReceber;
  final double aPagar;
  final List<(String, double, double)> meses;

  factory ResumoFinanceiro.fromJson(Map<String, dynamic> j) => ResumoFinanceiro(
        saldoRealizado: asDouble(j['saldo_realizado']),
        aReceber: asDouble(j['a_receber']),
        aPagar: asDouble(j['a_pagar']),
        meses: [
          for (final m in (j['meses'] as List? ?? const []).whereType<Map>())
            (asString(m['mes']), asDouble(m['receitas']), asDouble(m['despesas'])),
        ],
      );
}

class TermoDeGarantia {
  const TermoDeGarantia({required this.id, required this.referencia, required this.texto, this.data, this.autor = ''});

  final int id;
  final String referencia;
  final String texto;
  final DateTime? data;
  final String autor;

  factory TermoDeGarantia.fromJson(Map<String, dynamic> j) => TermoDeGarantia(
        id: asInt(j['id']),
        referencia: asString(j['referencia']),
        texto: asString(j['texto']),
        data: asDate(j['data']),
        autor: asString(asMap(j['autor'])['nome']),
      );
}

class Arquivo {
  const Arquivo({required this.id, required this.nome, required this.url, this.descricao = '', this.data, this.extensao = '', this.tamanhoKb = 0});

  final int id;
  final String nome;
  final String url;
  final String descricao;
  final DateTime? data;
  final String extensao;
  final double tamanhoKb;

  String get nomeDoArquivo => extensao.isEmpty || nome.toLowerCase().endsWith('.${extensao.toLowerCase()}') ? nome : '$nome.$extensao';
  bool get imagem => const ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extensao.toLowerCase().replaceAll('.', ''));
  String get tamanho => tamanhoKb >= 1024 ? '${Fmt.number(tamanhoKb / 1024)} MB' : '${Fmt.number(tamanhoKb)} KB';

  factory Arquivo.fromJson(Map<String, dynamic> j) => Arquivo(
        id: asInt(j['id']),
        nome: asString(j['nome']),
        url: asString(j['url']),
        descricao: asString(j['descricao']),
        data: asDate(j['data']),
        extensao: asString(j['extensao']).replaceAll('.', ''),
        tamanhoKb: asDouble(j['tamanho_kb']),
      );
}

class Relatorio {
  const Relatorio({required this.linhas, required this.totais});

  final List<Map<String, dynamic>> linhas;
  final Map<String, dynamic> totais;

  factory Relatorio.fromJson(Map<String, dynamic> j) => Relatorio(
        linhas: (j['linhas'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
        totais: asMap(j['totais']),
      );
}
