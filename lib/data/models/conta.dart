import '../../core/utils/formatters.dart';
import 'catalogo.dart';
import 'ordem_servico.dart';

class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    this.email = '',
    this.telefone = '',
    this.celular = '',
    this.cpf = '',
    this.cidade = '',
    this.estado = '',
    this.fotoUrl = '',
    this.dataExpiracao,
  });

  final int id;
  final String nome;
  final String email;
  final String telefone;
  final String celular;
  final String cpf;
  final String cidade;
  final String estado;
  final String fotoUrl;
  final DateTime? dataExpiracao;

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: asInt(j['idUsuarios']),
        nome: Fmt.plain(j['nome']),
        email: asString(j['email']),
        telefone: asString(j['telefone']),
        celular: asString(j['celular']),
        cpf: asString(j['cpf']),
        cidade: asString(j['cidade']),
        estado: asString(j['estado']),
        fotoUrl: asString(j['url_image_user']),
        dataExpiracao: asDate(j['dataExpiracao']),
      );
}

class Emitente {
  const Emitente({
    required this.appName,
    required this.nome,
    this.cnpj = '',
    this.telefone = '',
    this.email = '',
    this.logoUrl = '',
    this.cidade = '',
    this.uf = '',
  });

  final String appName;
  final String nome;
  final String cnpj;
  final String telefone;
  final String email;
  final String logoUrl;
  final String cidade;
  final String uf;

  factory Emitente.fromJson(Map<String, dynamic> j) {
    final e = j['emitente'] is Map ? Map<String, dynamic>.from(j['emitente']) : <String, dynamic>{};
    return Emitente(
      appName: asString(j['appName']),
      nome: asString(e['nome']),
      cnpj: asString(e['cnpj']),
      telefone: asString(e['telefone']),
      email: asString(e['email']),
      logoUrl: asString(e['url_logo']),
      cidade: asString(e['cidade']),
      uf: asString(e['uf']),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.countOs,
    required this.clientes,
    required this.produtos,
    required this.servicos,
    required this.garantias,
    required this.vendas,
    required this.osAbertas,
    required this.osAndamento,
    required this.estoqueBaixo,
  });

  final int countOs;
  final int clientes;
  final int produtos;
  final int servicos;
  final int garantias;
  final int vendas;
  final List<OrdemServico> osAbertas;
  final List<OrdemServico> osAndamento;
  final List<Produto> estoqueBaixo;

  factory DashboardData.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) => (j[k] is List)
        ? (j[k] as List).whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList()
        : <T>[];
    return DashboardData(
      countOs: asInt(j['countOs']),
      clientes: asInt(j['clientes']),
      produtos: asInt(j['produtos']),
      servicos: asInt(j['servicos']),
      garantias: asInt(j['garantias']),
      vendas: asInt(j['vendas']),
      osAbertas: list('osAbertas', OrdemServico.fromJson),
      osAndamento: list('osAndamento', OrdemServico.fromJson),
      estoqueBaixo: list('estoqueBaixo', Produto.fromJson),
    );
  }
}

/// Permissões do usuário logado (chaves do MAP-OS: aCliente, eOs, dProduto...).
class Permissions {
  const Permissions(this._map);

  final Map<String, dynamic> _map;

  /// Sem dados de permissão (versões antigas da API) → libera tudo.
  bool can(String key) => _map.isEmpty || asString(_map[key]) == '1';

  bool canAdd(String module) => can('a$module');
  bool canEdit(String module) => can('e$module');
  bool canDelete(String module) => can('d$module');
  bool canView(String module) => can('v$module');
}
