import '../../core/utils/formatters.dart';

class Produto {
  const Produto({
    required this.id,
    required this.descricao,
    this.codDeBarra = '',
    this.unidade = 'UNID',
    this.precoCompra = 0,
    this.precoVenda = 0,
    this.estoque = 0,
    this.estoqueMinimo = 0,
  });

  final int id;
  final String descricao;
  final String codDeBarra;
  final String unidade;
  final double precoCompra;
  final double precoVenda;
  final double estoque;
  final double estoqueMinimo;

  bool get estoqueBaixo => estoque <= 0 || (estoqueMinimo > 0 && estoque <= estoqueMinimo);

  double get margem => precoCompra > 0 ? (precoVenda - precoCompra) / precoCompra * 100 : 0;

  factory Produto.fromJson(Map<String, dynamic> j) => Produto(
        id: asInt(j['idProdutos']),
        descricao: Fmt.plain(j['descricao']),
        codDeBarra: asString(j['codDeBarra']),
        unidade: asString(j['unidade']).isEmpty ? 'UNID' : asString(j['unidade']),
        precoCompra: asDouble(j['precoCompra']),
        precoVenda: asDouble(j['precoVenda']),
        estoque: asDouble(j['estoque']),
        estoqueMinimo: asDouble(j['estoqueMinimo']),
      );

  Map<String, dynamic> toJson() => {
        'codDeBarra': codDeBarra,
        'descricao': descricao,
        'unidade': unidade,
        'precoCompra': precoCompra,
        'precoVenda': precoVenda,
        'estoque': estoque,
        'estoqueMinimo': estoqueMinimo,
        'saida': 1,
        'entrada': 1,
      };
}

class Servico {
  const Servico({required this.id, required this.nome, this.descricao = '', this.preco = 0});

  final int id;
  final String nome;
  final String descricao;
  final double preco;

  factory Servico.fromJson(Map<String, dynamic> j) => Servico(
        id: asInt(j['idServicos']),
        nome: Fmt.plain(j['nome']),
        descricao: Fmt.plain(j['descricao']),
        preco: asDouble(j['preco']),
      );

  Map<String, dynamic> toJson() => {'nome': nome, 'descricao': descricao, 'preco': preco};
}
