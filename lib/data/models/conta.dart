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
    this.grupo = '',
    this.doisFatoresAtivo = false,
    this.temaModo,
    this.temaCor,
    this.rg = '',
    this.ativo = true,
    this.grupoId = 0,
    this.endereco = const {},
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
  final String grupo;
  final bool doisFatoresAtivo;
  final String? temaModo;
  final String? temaCor;
  final String rg;
  final bool ativo;
  final int grupoId;
  final Map<String, String> endereco;

  factory Usuario.fromJson(Map<String, dynamic> j) {
    final endereco = asMap(j['endereco']);
    final tema = asMap(j['tema']);
    return Usuario(
      id: asInt(j['id']),
      nome: asString(j['nome']),
      email: asString(j['email']),
      telefone: asString(j['telefone']),
      celular: asString(j['celular']),
      cpf: asString(j['cpf']),
      cidade: asString(endereco['cidade']),
      estado: asString(endereco['estado']),
      fotoUrl: asString(j['imagem_url']),
      dataExpiracao: asDate(j['data_expiracao']),
      grupo: asString(asMap(j['grupo'])['nome']),
      doisFatoresAtivo: j['dois_fatores_ativo'] == true,
      temaModo: tema['modo'] as String?,
      temaCor: tema['cor'] as String?,
      rg: asString(j['rg']),
      ativo: j['ativo'] != false,
      grupoId: asInt(asMap(j['grupo'])['id']),
      endereco: {for (final e in endereco.entries) e.key: asString(e.value)},
    );
  }
}

class Conta {
  const Conta({
    required this.usuario,
    required this.permissoes,
    required this.doisFatoresAtivo,
    required this.doisFatoresExigido,
    required this.doisFatoresPendente,
    required this.codigosRestantes,
  });

  final Usuario usuario;
  final List<String> permissoes;
  final bool doisFatoresAtivo;
  final bool doisFatoresExigido;
  final bool doisFatoresPendente;
  final int codigosRestantes;

  factory Conta.fromJson(Map<String, dynamic> j) {
    final df = asMap(j['dois_fatores']);
    return Conta(
      usuario: Usuario.fromJson(asMap(j['usuario'])),
      permissoes: (j['permissoes'] is List) ? (j['permissoes'] as List).map((e) => e.toString()).toList() : const [],
      doisFatoresAtivo: df['ativo'] == true,
      doisFatoresExigido: df['exigido_pelo_grupo'] == true,
      doisFatoresPendente: df['pendente'] == true,
      codigosRestantes: asInt(df['codigos_restantes']),
    );
  }
}

class Sessao {
  const Sessao({required this.id, required this.atual, this.dispositivo = '', this.userAgent = '', this.ip = '', this.ultimoUso});

  final String id;
  final bool atual;
  final String dispositivo;
  final String userAgent;
  final String ip;
  final DateTime? ultimoUso;

  String get rotulo => dispositivo.isNotEmpty ? dispositivo : (userAgent.isNotEmpty ? userAgent : 'Dispositivo desconhecido');

  factory Sessao.fromJson(Map<String, dynamic> j) => Sessao(
        id: asString(j['id']),
        atual: j['atual'] == true,
        dispositivo: asString(j['dispositivo']),
        userAgent: asString(j['user_agent']),
        ip: asString(j['ip']),
        ultimoUso: asDate(j['ultimo_uso_em']),
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
    this.ie = '',
    this.endereco = const {},
  });

  final String appName;
  final String nome;
  final String cnpj;
  final String telefone;
  final String email;
  final String logoUrl;
  final String cidade;
  final String uf;
  final String ie;
  final Map<String, String> endereco;

  factory Emitente.fromJson(Map<String, dynamic> j) {
    final endereco = asMap(j['endereco']);
    return Emitente(
      appName: 'MAP-OS',
      nome: asString(j['nome']),
      cnpj: asString(j['cnpj']),
      telefone: asString(j['telefone']),
      email: asString(j['email']),
      logoUrl: asString(j['logo_url']),
      cidade: asString(endereco['cidade']),
      uf: asString(endereco['estado']),
      ie: asString(j['ie']),
      endereco: {for (final e in endereco.entries) e.key: asString(e.value)},
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
    this.osPorStatus = const {},
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
  final Map<String, int> osPorStatus;
}

class Permissions {
  const Permissions(this._codigos);

  final List<String>? _codigos;

  bool can(String key) => _codigos == null || _codigos.contains(key);

  bool canAdd(String module) => can('a$module');
  bool canEdit(String module) => can('e$module');
  bool canDelete(String module) => can('d$module');
  bool canView(String module) => can('v$module');
}
