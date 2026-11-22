import '../../core/utils/formatters.dart';

/// Item (produto ou serviço) vinculado a uma OS.
class OsItem {
  const OsItem({
    required this.itemId,
    required this.refId,
    required this.nome,
    required this.quantidade,
    required this.preco,
    required this.subTotal,
    this.unidade = '',
  });

  /// id na tabela de vínculo (idProdutos_os / idServicos_os) — usado em PUT/DELETE.
  final int itemId;

  /// id do produto/serviço no catálogo.
  final int refId;
  final String nome;
  final double quantidade;
  final double preco;
  final double subTotal;
  final String unidade;

  factory OsItem.produto(Map<String, dynamic> j) => OsItem(
        itemId: asInt(j['idProdutos_os']),
        refId: asInt(j['produtos_id']),
        nome: Fmt.plain(j['descricao'] ?? (j['produto'] is Map ? j['produto']['descricao'] : '')),
        quantidade: asDouble(j['quantidade']),
        preco: asDouble(j['preco']),
        subTotal: asDouble(j['subTotal']),
        unidade: asString(j['unidade']),
      );

  factory OsItem.servico(Map<String, dynamic> j) => OsItem(
        itemId: asInt(j['idServicos_os']),
        refId: asInt(j['servicos_id']),
        nome: Fmt.plain(j['nome'] ?? (j['servico'] is Map ? j['servico']['nome'] : '')),
        quantidade: asDouble(j['quantidade']),
        preco: asDouble(j['preco']),
        subTotal: asDouble(j['subTotal']),
      );
}

class Anexo {
  const Anexo({required this.id, required this.nome, required this.url, required this.thumbUrl});

  final int id;
  final String nome;
  final String url;
  final String thumbUrl;

  bool get isImage => RegExp(r'\.(png|jpe?g|gif|webp|bmp)$', caseSensitive: false).hasMatch(nome);

  factory Anexo.fromJson(Map<String, dynamic> j) {
    final url = asString(j['url']);
    final thumb = asString(j['thumb_url']);
    return Anexo(
      id: asInt(j['idAnexos']),
      nome: asString(j['anexo']),
      url: url,
      thumbUrl: thumb.isNotEmpty ? thumb : '$url?miniatura=1',
    );
  }
}

class Anotacao {
  const Anotacao({required this.id, required this.texto, this.dataHora});

  final int id;
  final String texto;
  final DateTime? dataHora;

  factory Anotacao.fromJson(Map<String, dynamic> j) => Anotacao(
        id: asInt(j['idAnotacoes']),
        texto: Fmt.plain(j['anotacao']),
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
    this.descricaoProduto = '',
    this.defeito = '',
    this.observacoes = '',
    this.laudoTecnico = '',
    this.desconto = 0,
    this.tipoDesconto = '',
    this.valorComDesconto = 0,
    this.totalProdutos = 0,
    this.totalServicos = 0,
    this.calcTotal = 0,
    this.faturado = false,
    this.celularCliente = '',
    this.telefoneCliente = '',
    this.emailCliente = '',
    this.textoWhatsApp = '',
    this.produtos = const [],
    this.servicos = const [],
    this.anexos = const [],
    this.anotacoes = const [],
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
  final String descricaoProduto;
  final String defeito;
  final String observacoes;
  final String laudoTecnico;
  final double desconto;
  final String tipoDesconto;
  final double valorComDesconto;
  final double totalProdutos;
  final double totalServicos;
  final double calcTotal;
  final bool faturado;
  final String celularCliente;
  final String telefoneCliente;
  final String emailCliente;
  final String textoWhatsApp;
  final List<OsItem> produtos;
  final List<OsItem> servicos;
  final List<Anexo> anexos;
  final List<Anotacao> anotacoes;

  /// Soma de produtos + serviços, sem desconto.
  double get subtotal => totalProdutos + totalServicos;

  bool get temDesconto => desconto > 0 && valorComDesconto > 0;

  /// Valor final cobrado.
  double get total => temDesconto ? valorComDesconto : subtotal;

  double get valorDoDesconto => temDesconto ? (subtotal - valorComDesconto).clamp(0, double.infinity) : 0;

  String get phone => celularCliente.isNotEmpty ? celularCliente : telefoneCliente;

  factory OrdemServico.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) {
      final v = j[key];
      if (v is! List) return const [];
      return v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList();
    }

    final produtos = list('produtos', OsItem.produto);
    final servicos = list('servicos', OsItem.servico);
    final tp = j.containsKey('produtos') && j['produtos'] is List
        ? produtos.fold<double>(0, (s, i) => s + i.subTotal)
        : asDouble(j['totalProdutos']);
    final ts = j.containsKey('servicos') && j['servicos'] is List
        ? servicos.fold<double>(0, (s, i) => s + i.subTotal)
        : asDouble(j['totalServicos']);

    return OrdemServico(
      id: asInt(j['idOs']),
      status: asString(j['status']),
      clienteId: asInt(j['clientes_id'] ?? j['idClientes']),
      nomeCliente: Fmt.plain(j['nomeCliente']),
      usuarioId: asInt(j['usuarios_id']),
      responsavel: asString(j['nome']),
      dataInicial: asDate(j['dataInicial']),
      dataFinal: asDate(j['dataFinal']),
      garantia: asString(j['garantia']),
      descricaoProduto: asString(j['descricaoProduto']),
      defeito: asString(j['defeito']),
      observacoes: asString(j['observacoes']),
      laudoTecnico: asString(j['laudoTecnico']),
      desconto: asDouble(j['desconto']),
      tipoDesconto: asString(j['tipo_desconto']),
      valorComDesconto: asDouble(j['valor_desconto']),
      totalProdutos: tp,
      totalServicos: ts,
      calcTotal: asDouble(j['calcTotal']),
      faturado: asString(j['faturado']) == '1',
      celularCliente: asString(j['celular_cliente'] ?? j['celular']),
      telefoneCliente: asString(j['telefone_cliente'] ?? j['telefone']),
      emailCliente: asString(j['email']),
      textoWhatsApp: asString(j['textoWhatsApp']),
      produtos: produtos,
      servicos: servicos,
      anexos: list('anexos', Anexo.fromJson),
      anotacoes: list('anotacoes', Anotacao.fromJson),
    );
  }
}

/// Dados enviados ao criar/editar uma OS.
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

  Map<String, dynamic> toJson() => {
        'clientes_id': clienteId,
        'usuarios_id': usuarioId,
        'status': status,
        // A API MAP-OS espera dd/MM/yyyy (yyyy-MM-dd grava 0000-00-00).
        'dataInicial': Fmt.apiDate(dataInicial),
        'dataFinal': Fmt.apiDate(dataFinal),
        'descricaoProduto': descricaoProduto,
        'defeito': defeito,
        'observacoes': observacoes,
        'laudoTecnico': laudoTecnico,
        'garantia': garantia,
      };
}
