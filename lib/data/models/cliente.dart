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
    this.totalOs = 0,
    this.totalVendas = 0,
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
  final int totalOs;
  final int totalVendas;
  final List<OrdemServico> ordens;

  String get phone => celular.isNotEmpty ? celular : telefone;

  String get enderecoCompleto {
    final linha1 = [rua, numero].where((s) => s.isNotEmpty).join(', ');
    final linha2 = [bairro, [cidade, estado].where((s) => s.isNotEmpty).join('/')].where((s) => s.isNotEmpty).join(' · ');
    return [linha1, if (complemento.isNotEmpty) complemento, linha2, cep].where((s) => s.isNotEmpty).join('\n');
  }

  Cliente comOrdens(List<OrdemServico> ordens) => Cliente(
        id: id,
        nome: nome,
        pessoaFisica: pessoaFisica,
        documento: documento,
        telefone: telefone,
        celular: celular,
        email: email,
        rua: rua,
        numero: numero,
        complemento: complemento,
        bairro: bairro,
        cidade: cidade,
        estado: estado,
        cep: cep,
        contato: contato,
        fornecedor: fornecedor,
        dataCadastro: dataCadastro,
        totalOs: totalOs,
        totalVendas: totalVendas,
        ordens: ordens,
      );

  factory Cliente.fromJson(Map<String, dynamic> j) {
    final e = asMap(j['endereco']);
    return Cliente(
      id: asInt(j['id']),
      nome: asString(j['nome']),
      pessoaFisica: j['tipo_pessoa'] != 'juridica',
      documento: asString(j['documento']),
      telefone: asString(j['telefone']),
      celular: asString(j['celular']),
      email: asString(j['email']),
      rua: asString(e['rua']),
      numero: asString(e['numero']),
      complemento: asString(e['complemento']),
      bairro: asString(e['bairro']),
      cidade: asString(e['cidade']),
      estado: asString(e['estado']),
      cep: asString(e['cep']),
      contato: asString(j['contato']),
      fornecedor: j['fornecedor'] == true,
      dataCadastro: asDate(j['data_cadastro']),
      totalOs: asInt(j['total_os']),
      totalVendas: asInt(j['total_vendas']),
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'documento': documento,
        'telefone': telefone,
        'celular': celular,
        'email': email,
        'contato': contato,
        'fornecedor': fornecedor,
        'endereco': {
          'cep': cep,
          'rua': rua,
          'numero': numero,
          'complemento': complemento,
          'bairro': bairro,
          'cidade': cidade,
          'estado': estado,
        },
      };
}
