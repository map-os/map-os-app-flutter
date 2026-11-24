import '../../core/utils/formatters.dart';

const statusDaOs = ['Orçamento', 'Negociação', 'Aberto', 'Aprovado', 'Em Andamento', 'Aguardando Peças', 'Finalizado', 'Faturado', 'Cancelado'];

class DescontoDoItem {
  const DescontoDoItem({required this.tipo, required this.valor});

  final String tipo;
  final double valor;

  bool get porcento => tipo == 'porcento';

  static DescontoDoItem? fromJson(dynamic j) {
    final m = asMap(j);
    if (m.isEmpty) return null;
    return DescontoDoItem(tipo: asString(m['tipo']), valor: asDouble(m['valor']));
  }
}

class OsItem {
  const OsItem({
    required this.itemId,
    required this.refId,
    required this.nome,
    required this.quantidade,
    required this.preco,
    required this.subTotal,
    this.unidade = '',
    this.desconto,
  });

  final int itemId;
  final int refId;
  final String nome;
  final double quantidade;
  final double preco;
  final double subTotal;
  final String unidade;
  final DescontoDoItem? desconto;

  double get bruto => preco * quantidade;

  factory OsItem.produto(Map<String, dynamic> j) => OsItem(
        itemId: asInt(j['id']),
        refId: asInt(j['produto_id']),
        nome: asString(j['descricao']),
        quantidade: asDouble(j['quantidade']),
        preco: asDouble(j['preco']),
        subTotal: asDouble(j['subtotal']),
        unidade: asString(j['unidade']),
        desconto: DescontoDoItem.fromJson(j['desconto']),
      );

  factory OsItem.servico(Map<String, dynamic> j) => OsItem(
        itemId: asInt(j['id']),
        refId: asInt(j['servico_id']),
        nome: asString(j['nome']),
        quantidade: asDouble(j['quantidade']),
        preco: asDouble(j['preco']),
        subTotal: asDouble(j['subtotal']),
        desconto: DescontoDoItem.fromJson(j['desconto']),
      );
}

class Anexo {
  const Anexo({required this.id, required this.nome, required this.url, required this.thumbUrl, this.imagem = false});

  final int id;
  final String nome;
  final String url;
  final String thumbUrl;
  final bool imagem;

  bool get isImage => imagem || RegExp(r'\.(png|jpe?g|gif|webp|bmp)$', caseSensitive: false).hasMatch(nome);

  factory Anexo.fromJson(Map<String, dynamic> j) {
    final url = asString(j['url']);
    final thumb = asString(j['miniatura_url']);
    return Anexo(
      id: asInt(j['id']),
      nome: asString(j['nome']),
      url: url,
      thumbUrl: thumb.isNotEmpty ? thumb : url,
      imagem: j['imagem'] == true,
    );
  }
}

class Anotacao {
  const Anotacao({required this.id, required this.texto, this.dataHora});

  final int id;
  final String texto;
  final DateTime? dataHora;

  factory Anotacao.fromJson(Map<String, dynamic> j) => Anotacao(
        id: asInt(j['id']),
        texto: asString(j['texto']),
        dataHora: asDate(j['data_hora']),
      );
}

class HistoricoDeStatus {
  const HistoricoDeStatus({required this.anterior, required this.novo, required this.autor, this.dataHora});

  final String anterior;
  final String novo;
  final String autor;
  final DateTime? dataHora;

  factory HistoricoDeStatus.fromJson(Map<String, dynamic> j) => HistoricoDeStatus(
        anterior: asString(j['status_anterior']),
        novo: asString(j['status_novo']),
        autor: asString(asMap(j['autor'])['nome']),
        dataHora: asDate(j['data_hora']),
      );
}

class OrdemServico {
  const OrdemServico({
    required this.id,
    required this.status,
    required this.clienteId,
    required this.nomeCliente,
    this.usuarioId = 0,
    this.responsavel = '',
    this.dataInicial,
    this.dataFinal,
    this.garantia = '',
    this.garantiaAte,
    this.termoGarantiaId,
    this.termoGarantia = '',
    this.descricaoProduto = '',
    this.defeito = '',
    this.observacoes = '',
    this.laudoTecnico = '',
    this.desconto = 0,
    this.tipoDesconto = '',
    this.valorDoDescontoGeral = 0,
    this.totalProdutos = 0,
    this.totalServicos = 0,
    this.totalFinal,
    this.descontoItens = 0,
    this.faturado = false,
    this.editavel = true,
    this.lancamentoId,
    this.cobrancaId,
    this.celularCliente = '',
    this.telefoneCliente = '',
    this.emailCliente = '',
    this.produtos = const [],
    this.servicos = const [],
    this.anexos = const [],
    this.anotacoes = const [],
    this.historico = const [],
  });

  final int id;
  final String status;
  final int clienteId;
  final String nomeCliente;
  final int usuarioId;
  final String responsavel;
  final DateTime? dataInicial;
  final DateTime? dataFinal;
  final String garantia;
  final DateTime? garantiaAte;
  final int? termoGarantiaId;
  final String termoGarantia;
  final String descricaoProduto;
  final String defeito;
  final String observacoes;
  final String laudoTecnico;
  final double desconto;
  final String tipoDesconto;
  final double valorDoDescontoGeral;
  final double totalProdutos;
  final double totalServicos;
  final double? totalFinal;
  final double descontoItens;
  final bool faturado;
  final bool editavel;
  final int? lancamentoId;
  final int? cobrancaId;
  final String celularCliente;
  final String telefoneCliente;
  final String emailCliente;
  final List<OsItem> produtos;
  final List<OsItem> servicos;
  final List<Anexo> anexos;
  final List<Anotacao> anotacoes;
  final List<HistoricoDeStatus> historico;

  double get subtotal => totalProdutos + totalServicos;
  bool get temDesconto => valorDoDescontoGeral > 0;
  double get total => totalFinal ?? (subtotal - valorDoDescontoGeral);
  double get valorDoDesconto => valorDoDescontoGeral;
  String get phone => celularCliente.isNotEmpty ? celularCliente : telefoneCliente;
  bool get fechada => faturado || status == 'Faturado' || status == 'Cancelado';

  factory OrdemServico.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) {
      final v = j[key];
      if (v is! List) return const [];
      return v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList();
    }

    final cliente = asMap(j['cliente']);
    final tecnico = asMap(j['tecnico']);
    final totais = asMap(j['totais']);
    final geral = asMap(totais['desconto_geral']);
    final termo = asMap(j['termo_garantia']);

    return OrdemServico(
      id: asInt(j['id']),
      status: asString(j['status']),
      clienteId: asInt(cliente['id']),
      nomeCliente: asString(cliente['nome']),
      usuarioId: asInt(tecnico['id']),
      responsavel: asString(tecnico['nome']),
      dataInicial: asDate(j['data_inicial']),
      dataFinal: asDate(j['data_final']),
      garantia: j['garantia_dias'] == null ? '' : asString(j['garantia_dias']),
      garantiaAte: asDate(j['garantia_ate']),
      termoGarantiaId: termo.isEmpty ? null : asInt(termo['id']),
      termoGarantia: asString(termo['referencia']),
      descricaoProduto: asString(j['descricao_produto']),
      defeito: asString(j['defeito']),
      observacoes: asString(j['observacoes']),
      laudoTecnico: asString(j['laudo_tecnico']),
      desconto: asDouble(geral['valor']),
      tipoDesconto: asString(geral['tipo']),
      valorDoDescontoGeral: asDouble(totais['desconto']),
      totalProdutos: asDouble(totais['produtos']),
      totalServicos: asDouble(totais['servicos']),
      totalFinal: totais.isNotEmpty ? asDouble(totais['total']) : (j['total'] != null ? asDouble(j['total']) : null),
      descontoItens: asDouble(totais['desconto_itens']),
      faturado: j['faturado'] == true,
      editavel: j['editavel'] != false,
      lancamentoId: j['lancamento_id'] == null ? null : asInt(j['lancamento_id']),
      cobrancaId: j['cobranca_id'] == null ? null : asInt(j['cobranca_id']),
      celularCliente: asString(cliente['celular']),
      telefoneCliente: asString(cliente['telefone']),
      emailCliente: asString(cliente['email']),
      produtos: list('produtos', OsItem.produto),
      servicos: list('servicos', OsItem.servico),
      anexos: list('anexos', Anexo.fromJson),
      anotacoes: list('anotacoes', Anotacao.fromJson),
      historico: list('historico', HistoricoDeStatus.fromJson),
    );
  }

  factory OrdemServico.doCalendario(Map<String, dynamic> j) => OrdemServico(
        id: asInt(j['os_id']),
        status: asString(j['status']),
        clienteId: 0,
        nomeCliente: asString(j['cliente']),
        dataInicial: asDate(j['data_inicial']),
        dataFinal: asDate(j['data_final']),
        totalFinal: asDouble(j['total']),
        faturado: j['faturado'] == true,
      );
}

class OsInput {
  OsInput({
    required this.clienteId,
    required this.usuarioId,
    required this.status,
    required this.dataInicial,
    required this.dataFinal,
    this.descricaoProduto = '',
    this.defeito = '',
    this.observacoes = '',
    this.laudoTecnico = '',
    this.garantia = '',
    this.termoGarantiaId,
  });

  final int clienteId;
  final int usuarioId;
  final String status;
  final DateTime dataInicial;
  final DateTime dataFinal;
  final String descricaoProduto;
  final String defeito;
  final String observacoes;
  final String laudoTecnico;
  final String garantia;
  final int? termoGarantiaId;

  Map<String, dynamic> toJson() => {
        'cliente_id': clienteId,
        if (usuarioId > 0) 'tecnico_id': usuarioId,
        'status': status,
        'data_inicial': Fmt.apiDate(dataInicial),
        'data_final': Fmt.apiDate(dataFinal),
        'descricao_produto': descricaoProduto,
        'defeito': defeito,
        'observacoes': observacoes,
        'laudo_tecnico': laudoTecnico,
        'garantia_dias': int.tryParse(garantia.trim()),
        'termo_garantia_id': termoGarantiaId,
      };
}
