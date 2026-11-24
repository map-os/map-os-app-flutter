import '../../core/utils/formatters.dart';

class GrupoDePermissao {
  const GrupoDePermissao({required this.id, required this.nome, this.ativo = true, this.exigir2fa = false, this.permissoes = const [], this.usuarios = 0});

  final int id;
  final String nome;
  final bool ativo;
  final bool exigir2fa;
  final List<String> permissoes;
  final int usuarios;

  factory GrupoDePermissao.fromJson(Map<String, dynamic> j) => GrupoDePermissao(
        id: asInt(j['id']),
        nome: asString(j['nome']),
        ativo: j['ativo'] != false,
        exigir2fa: j['exigir_2fa'] == true,
        permissoes: (j['permissoes'] as List? ?? const []).map((e) => e.toString()).toList(),
        usuarios: asInt(j['usuarios']),
      );
}

class PermissaoDoCatalogo {
  const PermissaoDoCatalogo({required this.codigo, required this.grupo, required this.nome, this.descricao = ''});

  final String codigo;
  final String grupo;
  final String nome;
  final String descricao;

  factory PermissaoDoCatalogo.fromJson(Map<String, dynamic> j) =>
      PermissaoDoCatalogo(codigo: asString(j['codigo']), grupo: asString(j['grupo']), nome: asString(j['nome']), descricao: asString(j['descricao']));
}

class CampoDeConfiguracao {
  const CampoDeConfiguracao({required this.chave, required this.rotulo, required this.tipo, this.grupo = '', this.ajuda = '', this.opcoes = const [], this.valor});

  final String chave;
  final String rotulo;
  final String tipo;
  final String grupo;
  final String ajuda;
  final List<(String, String)> opcoes;
  final dynamic valor;

  bool get segredoDefinido => valor is Map && (valor as Map)['definido'] == true;

  factory CampoDeConfiguracao.fromJson(Map<String, dynamic> j) => CampoDeConfiguracao(
        chave: asString(j['chave']),
        rotulo: asString(j['rotulo']),
        tipo: asString(j['tipo']),
        grupo: asString(j['grupo']),
        ajuda: asString(j['ajuda']),
        opcoes: [for (final o in (j['opcoes'] as List? ?? const []).whereType<Map>()) (asString(o['valor']), asString(o['nome']))],
        valor: j['valor'],
      );
}

class AbaDeConfiguracao {
  const AbaDeConfiguracao({required this.id, required this.nome, required this.campos});

  final String id;
  final String nome;
  final List<CampoDeConfiguracao> campos;

  factory AbaDeConfiguracao.fromJson(Map<String, dynamic> j) => AbaDeConfiguracao(
        id: asString(j['id']),
        nome: asString(j['nome']),
        campos: (j['campos'] as List? ?? const []).whereType<Map>().map((e) => CampoDeConfiguracao.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
}

class RegistroDeAuditoria {
  const RegistroDeAuditoria({required this.id, required this.acao, this.usuario = '', this.ip = '', this.dataHora});

  final int id;
  final String acao;
  final String usuario;
  final String ip;
  final DateTime? dataHora;

  factory RegistroDeAuditoria.fromJson(Map<String, dynamic> j) =>
      RegistroDeAuditoria(id: asInt(j['id']), acao: asString(j['acao']), usuario: asString(j['usuario']), ip: asString(j['ip']), dataHora: asDate(j['data_hora']));
}

class EmailNaFila {
  const EmailNaFila({required this.id, required this.para, required this.status, this.assunto = '', this.dataHora});

  final int id;
  final String para;
  final String status;
  final String assunto;
  final DateTime? dataHora;

  String get situacao => switch (status) {
        'sent' => 'Enviado',
        'failed' => 'Falhou',
        'sending' => 'Enviando',
        _ => 'Na fila',
      };

  factory EmailNaFila.fromJson(Map<String, dynamic> j) =>
      EmailNaFila(id: asInt(j['id']), para: asString(j['para']), status: asString(j['status']), assunto: asString(j['assunto']), dataHora: asDate(j['data_hora']));
}

class InfoDoSistema {
  const InfoDoSistema({required this.versao, this.migracoesPendentes = 0, this.problemas = const [], this.ultimaVersao, this.temAtualizacao = false, this.notas = ''});

  final String versao;
  final int migracoesPendentes;
  final List<String> problemas;
  final String? ultimaVersao;
  final bool temAtualizacao;
  final String notas;
}
