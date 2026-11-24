import '../../core/utils/formatters.dart';

class Produto {
  const Produto({
    required this.id,
    required this.descricao,
    this.codDeBarra = '',
    this.unidade = 'UN',
    this.precoCompra = 0,
    this.precoVenda = 0,
    this.estoque = 0,
    this.estoqueMinimo = 0,
    this.entrada = true,
    this.saida = true,
  });

  final int id;
  final String descricao;
  final String codDeBarra;
  final String unidade;
  final double precoCompra;
  final double precoVenda;
  final double estoque;
  final double estoqueMinimo;
  final bool entrada;
  final bool saida;

  bool get estoqueBaixo => estoque <= 0 || (estoqueMinimo > 0 && estoque <= estoqueMinimo);

  double get margem => precoCompra > 0 ? (precoVenda - precoCompra) / precoCompra * 100 : 0;

  factory Produto.fromJson(Map<String, dynamic> j) => Produto(
        id: asInt(j['id']),
        descricao: asString(j['descricao'] ?? j['nome']),
        codDeBarra: asString(j['codigo_barras']),
        unidade: asString(j['unidade']).isEmpty ? 'UN' : asString(j['unidade']),
        precoCompra: asDouble(j['preco_compra']),
        precoVenda: asDouble(j['preco_venda'] ?? j['preco']),
        estoque: asDouble(j['estoque']),
        estoqueMinimo: asDouble(j['estoque_minimo']),
        entrada: j['entrada'] != false,
        saida: j['saida'] != false,
      );

  Map<String, dynamic> toJson() => {
        'codigo_barras': codDeBarra,
        'descricao': descricao,
        'unidade': unidade,
        'preco_compra': precoCompra.toStringAsFixed(2),
        'preco_venda': precoVenda.toStringAsFixed(2),
        'estoque': estoque.round(),
        'estoque_minimo': estoqueMinimo > 0 ? estoqueMinimo.round() : null,
        'entrada': entrada,
        'saida': saida,
      };
}

class Servico {
  const Servico({required this.id, required this.nome, this.descricao = '', this.preco = 0});

  final int id;
  final String nome;
  final String descricao;
  final double preco;

  factory Servico.fromJson(Map<String, dynamic> j) => Servico(
        id: asInt(j['id']),
        nome: asString(j['nome']),
        descricao: asString(j['descricao']),
        preco: asDouble(j['preco']),
      );

  Map<String, dynamic> toJson() => {'nome': nome, 'descricao': descricao, 'preco': preco.toStringAsFixed(2)};
}

class Sugestao {
  const Sugestao({required this.id, required this.nome, this.detalhe = '', this.preco, this.estoque});

  final int id;
  final String nome;
  final String detalhe;
  final double? preco;
  final int? estoque;

  factory Sugestao.fromJson(Map<String, dynamic> j) => Sugestao(
        id: asInt(j['id']),
        nome: asString(j['nome']),
        detalhe: asString(j['detalhe']),
        preco: j['preco'] == null ? null : asDouble(j['preco']),
        estoque: j['estoque'] == null ? null : asInt(j['estoque']),
      );
}
