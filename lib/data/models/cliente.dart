import '../../core/utils/formatters.dart';
import 'ordem_servico.dart';

class Cliente {
  const Cliente({
    required this.id,
    required this.nome,
    this.pessoaFisica = true,
    this.documento = '',
    this.telefone = '',
    this.celular = '',
    this.email = '',
    this.rua = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.cep = '',
    this.contato = '',
    this.fornecedor = false,
    this.dataCadastro,
    this.ordens = const [],
  });

  final int id;
  final String nome;
  final bool pessoaFisica;
  final String documento;
  final String telefone;
  final String celular;
  final String email;
  final String rua;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;
  final String contato;
  final bool fornecedor;
  final DateTime? dataCadastro;

  /// OS do cliente (vem em `ordensServicos` no GET /clientes/{id}).
  final List<OrdemServico> ordens;

  String get phone => celular.isNotEmpty ? celular : telefone;

  String get enderecoCompleto {
    final linha1 = [rua, numero].where((s) => s.isNotEmpty).join(', ');
    final linha2 = [bairro, [cidade, estado].where((s) => s.isNotEmpty).join('/')]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return [linha1, if (complemento.isNotEmpty) complemento, linha2, cep]
        .where((s) => s.isNotEmpty)
        .join('\n');
  }

  factory Cliente.fromJson(Map<String, dynamic> j) => Cliente(
        id: asInt(j['idClientes']),
        nome: Fmt.plain(j['nomeCliente']),
        pessoaFisica: asString(j['pessoa_fisica']) != '0',
        documento: asString(j['documento']),
        telefone: asString(j['telefone']),
        celular: asString(j['celular']),
        email: asString(j['email']),
        rua: asString(j['rua']),
        numero: asString(j['numero']),
        complemento: asString(j['complemento']),
        bairro: asString(j['bairro']),
        cidade: asString(j['cidade']),
        estado: asString(j['estado']),
        cep: asString(j['cep']),
        contato: asString(j['contato']),
        fornecedor: asString(j['fornecedor']) == '1',
        dataCadastro: asDate(j['dataCadastro']),
        ordens: (j['ordensServicos'] is List)
            ? ((j['ordensServicos'] as List).whereType<Map>().map((e) => OrdemServico.fromJson(Map<String, dynamic>.from(e))).toList()
              ..sort((a, b) => b.id.compareTo(a.id)))
            : const [],
      );

  Map<String, dynamic> toJson() => {
        if (id > 0) 'idClientes': id,
        'nomeCliente': nome,
        'pessoa_fisica': pessoaFisica ? 1 : 0,
        'documento': documento,
        'telefone': telefone,
        'celular': celular,
        'email': email,
        'rua': rua,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
        'cep': cep,
        'contato': contato,
        'fornecedor': fornecedor ? 1 : 0,
      };
}
