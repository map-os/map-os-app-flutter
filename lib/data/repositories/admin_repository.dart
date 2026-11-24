import 'dart:typed_data';

import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../models/admin.dart';
import '../models/conta.dart';
import 'cadastros_repository.dart';

class AdminRepository {
  AdminRepository(this._api);
  final ApiClient _api;

  Future<List<Usuario>> usuarios({int page = 0, String search = '', String? situacao}) async =>
      (await _api.getPage('/usuarios', query: pagina(page, search, {'situacao': situacao}))).items.map(Usuario.fromJson).toList();

  Future<Usuario> usuario(int id) async => Usuario.fromJson(asMap(await _api.get('/usuarios/$id')));

  Future<void> salvarUsuario(int? id, Map<String, dynamic> dados) => id == null ? _api.post('/usuarios', body: dados) : _api.patch('/usuarios/$id', body: dados);

  Future<void> excluirUsuario(int id) => _api.delete('/usuarios/$id');

  Future<void> redefinirDoisFatores(int id) => _api.post('/usuarios/$id/dois-fatores/redefinir');

  Future<List<GrupoDePermissao>> grupos() async => lista(await _api.get('/grupos')).map(GrupoDePermissao.fromJson).toList();

  Future<List<PermissaoDoCatalogo>> catalogo() async => lista(await _api.get('/permissoes', cache: true)).map(PermissaoDoCatalogo.fromJson).toList();

  Future<void> salvarGrupo(int? id, {required String nome, required bool ativo, required bool exigir2fa, required List<String> permissoes}) {
    final dados = {'nome': nome, 'ativo': ativo, 'exigir_2fa': exigir2fa, 'permissoes': permissoes};
    return id == null ? _api.post('/grupos', body: dados) : _api.patch('/grupos/$id', body: dados);
  }

  Future<Emitente> emitente() async => Emitente.fromJson(asMap(await _api.get('/emitente')));

  Future<void> salvarEmitente(Map<String, dynamic> dados) => _api.put('/emitente', body: dados);

  Future<void> trocarLogo(Uint8List bytes, String nome) => _api.upload('/emitente/logo', method: 'PUT', field: 'arquivo', bytes: bytes, filename: nome);

  Future<List<AbaDeConfiguracao>> configuracoes() async => lista(await _api.get('/configuracoes')).map(AbaDeConfiguracao.fromJson).toList();

  Future<AbaDeConfiguracao> salvarConfiguracoes(String aba, Map<String, dynamic> valores) async =>
      AbaDeConfiguracao.fromJson(asMap(await _api.patch('/configuracoes/$aba', body: valores)));

  Future<List<RegistroDeAuditoria>> auditoria({int page = 0, String search = ''}) async =>
      (await _api.getPage('/auditoria', query: pagina(page, search))).items.map(RegistroDeAuditoria.fromJson).toList();

  Future<int> limparAuditoria() async => asInt(asMap(await _api.delete('/auditoria'))['apagados']);

  Future<List<EmailNaFila>> emails({int page = 0, String? status}) async =>
      (await _api.getPage('/emails', query: pagina(page, '', {'status': status}))).items.map(EmailNaFila.fromJson).toList();

  Future<void> removerEmail(int id) => _api.delete('/emails/$id');

  Future<InfoDoSistema> sistema() async {
    final s = asMap(await _api.get('/sistema'));
    Map<String, dynamic> a = const {};
    try {
      a = asMap(await _api.get('/sistema/atualizacao'));
    } catch (_) {}
    return InfoDoSistema(
      versao: asString(s['versao']),
      migracoesPendentes: asInt(s['migracoes_pendentes']),
      problemas: [for (final p in (s['problemas'] as List? ?? const [])) p.toString(), for (final p in (a['problemas'] as List? ?? const [])) p.toString()],
      ultimaVersao: a['ultima_versao'] as String?,
      temAtualizacao: a['tem_atualizacao'] == true,
      notas: asString(a['notas']),
    );
  }
}
