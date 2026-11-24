import 'dart:typed_data';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../models/catalogo.dart';
import '../models/cliente.dart';
import '../models/conta.dart';
import '../models/ordem_servico.dart';

Map<String, dynamic> pagina(int page, String search, [Map<String, dynamic> extras = const {}]) => {
      'pagina': page + 1,
      'por_pagina': AppConfig.pageSize,
      'busca': search.trim(),
      ...extras,
    };

List<Map<String, dynamic>> lista(dynamic data) =>
    data is List ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

class ClientesRepository {
  ClientesRepository(this._api);
  final ApiClient _api;

  Future<List<Cliente>> list({int page = 0, String search = ''}) async {
    final r = await _api.getPage('/clientes', query: pagina(page, search), cache: search.isEmpty);
    return r.items.map(Cliente.fromJson).toList();
  }

  Future<List<Sugestao>> sugestoes(String search) async {
    return lista(await _api.get('/busca/clientes', query: {'busca': search.trim()})).map(Sugestao.fromJson).toList();
  }

  Future<Cliente> get(int id) async {
    final cliente = Cliente.fromJson(asMap(await _api.get('/clientes/$id', cache: true)));
    try {
      final os = await _api.getPage('/clientes/$id/os', query: {'por_pagina': 50}, cache: true);
      return cliente.comOrdens(os.items.map(OrdemServico.fromJson).toList());
    } catch (_) {
      return cliente;
    }
  }

  Future<void> create(Cliente c, {String? senha}) =>
      _api.post('/clientes', body: {...c.toJson(), if ((senha ?? '').isNotEmpty) 'senha': senha});

  Future<void> update(Cliente c, {String? senha}) =>
      _api.patch('/clientes/${c.id}', body: {...c.toJson(), if ((senha ?? '').isNotEmpty) 'senha': senha});

  Future<void> delete(int id) => _api.delete('/clientes/$id');

  Future<Map<String, dynamic>?> buscarCep(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final r = await _api.getExternalJson(Uri.parse('https://viacep.com.br/ws/$digits/json/'));
    if (r == null || r['erro'] != null) return null;
    return r;
  }
}

class ProdutosRepository {
  ProdutosRepository(this._api);
  final ApiClient _api;

  Future<List<Produto>> list({int page = 0, String search = '', bool estoqueBaixo = false}) async {
    final r = await _api.getPage('/produtos', query: pagina(page, search, {if (estoqueBaixo) 'estoque_baixo': true}), cache: search.isEmpty);
    return r.items.map(Produto.fromJson).toList();
  }

  Future<List<Sugestao>> sugestoes(String search) async {
    return lista(await _api.get('/busca/produtos', query: {'busca': search.trim()})).map(Sugestao.fromJson).toList();
  }

  Future<Produto> get(int id) async => Produto.fromJson(asMap(await _api.get('/produtos/$id', cache: true)));
  Future<void> create(Produto p) => _api.post('/produtos', body: p.toJson());
  Future<void> update(Produto p) => _api.patch('/produtos/${p.id}', body: p.toJson());
  Future<void> delete(int id) => _api.delete('/produtos/$id');

  Future<Produto> ajustarEstoque(int id, int quantidade) async =>
      Produto.fromJson(asMap(await _api.post('/produtos/$id/estoque', body: {'quantidade': quantidade})));
}

class ServicosRepository {
  ServicosRepository(this._api);
  final ApiClient _api;

  Future<List<Servico>> list({int page = 0, String search = ''}) async {
    final r = await _api.getPage('/servicos', query: pagina(page, search), cache: search.isEmpty);
    return r.items.map(Servico.fromJson).toList();
  }

  Future<List<Sugestao>> sugestoes(String search) async {
    return lista(await _api.get('/busca/servicos', query: {'busca': search.trim()})).map(Sugestao.fromJson).toList();
  }

  Future<Servico> get(int id) async => Servico.fromJson(asMap(await _api.get('/servicos/$id', cache: true)));
  Future<void> create(Servico s) => _api.post('/servicos', body: s.toJson());
  Future<void> update(Servico s) => _api.patch('/servicos/${s.id}', body: s.toJson());
  Future<void> delete(int id) => _api.delete('/servicos/$id');
}

class ContaRepository {
  ContaRepository(this._api);
  final ApiClient _api;

  Future<DashboardData> dashboard(Permissions permissoes) async {
    Future<int> total(String caminho, String permissao) async {
      if (!permissoes.can(permissao)) return 0;
      try {
        return (await _api.getPage(caminho, query: {'por_pagina': 1}, cache: true)).total;
      } catch (_) {
        return 0;
      }
    }

    Future<List<OrdemServico>> ordens(String status) async {
      if (!permissoes.can('vOs')) return const [];
      final r = await _api.getPage('/os', query: {'status': status, 'por_pagina': 20}, cache: true);
      return r.items.map(OrdemServico.fromJson).toList();
    }

    final resultados = await Future.wait<dynamic>([
      _api.get('/painel', cache: true),
      ordens('Aberto'),
      ordens('Em Andamento'),
      total('/clientes', 'vCliente'),
      total('/produtos', 'vProduto'),
      total('/servicos', 'vServico'),
      total('/garantias', 'vGarantia'),
      total('/vendas', 'vVenda'),
    ]);

    final painel = asMap(resultados[0]);
    final porStatus = asMap(asMap(painel['os'])['por_status']).map((k, v) => MapEntry(k, asInt(v)));
    return DashboardData(
      countOs: porStatus.values.fold(0, (a, b) => a + b),
      osPorStatus: porStatus,
      osAbertas: resultados[1] as List<OrdemServico>,
      osAndamento: resultados[2] as List<OrdemServico>,
      clientes: resultados[3] as int,
      produtos: resultados[4] as int,
      servicos: resultados[5] as int,
      garantias: resultados[6] as int,
      vendas: resultados[7] as int,
      estoqueBaixo: lista(painel['estoque_baixo'])
          .map((p) => Produto(id: asInt(p['id']), descricao: asString(p['descricao']), estoque: asDouble(p['estoque']), estoqueMinimo: asDouble(p['estoque_minimo'])))
          .toList(),
    );
  }

  Future<Conta> conta() async => Conta.fromJson(asMap(await _api.get('/conta', cache: true)));

  Future<Usuario> perfil() async => (await conta()).usuario;

  Future<void> salvarTema(String modo) => _api.patch('/conta/tema', body: {'modo': modo});

  Future<Emitente> emitente() async => Emitente.fromJson(asMap(await _api.get('/emitente', cache: true)));

  Future<List<Usuario>> usuarios({String search = ''}) async {
    final r = await _api.get('/busca/usuarios', query: {'busca': search.trim()});
    return lista(r).map((u) => Usuario(id: asInt(u['id']), nome: asString(u['nome']), telefone: asString(u['detalhe']))).toList();
  }

  Future<void> trocarSenha(String atual, String nova) => _api.put('/conta/senha', body: {'senha_atual': atual, 'nova_senha': nova});

  Future<Usuario> trocarFoto(Uint8List bytes, String nome) async =>
      Usuario.fromJson(asMap(await _api.upload('/conta/imagem', method: 'PUT', field: 'arquivo', bytes: bytes, filename: nome)));

  Future<Map<String, dynamic>> configurarDoisFatores() async => asMap(await _api.post('/conta/dois-fatores/configuracao'));

  Future<List<String>> ativarDoisFatores({required String configuracao, required String codigo, required String senha}) async {
    final r = asMap(await _api.post('/conta/dois-fatores', body: {'configuracao': configuracao, 'codigo': codigo, 'senha': senha}));
    return (r['codigos_recuperacao'] as List? ?? const []).map((e) => e.toString()).toList();
  }

  Future<List<String>> novosCodigos(String senha) async {
    final r = asMap(await _api.post('/conta/dois-fatores/codigos', body: {'senha': senha}));
    return (r['codigos_recuperacao'] as List? ?? const []).map((e) => e.toString()).toList();
  }

  Future<void> desativarDoisFatores(String senha) => _api.post('/conta/dois-fatores/desativar', body: {'senha': senha});

  Future<List<Sessao>> sessoes() async => lista(await _api.get('/auth/sessoes')).map(Sessao.fromJson).toList();
  Future<void> encerrarSessao(String id) => _api.delete('/auth/sessoes/$id');
  Future<int> encerrarOutrasSessoes() async => asInt(asMap(await _api.delete('/auth/sessoes'))['encerradas']);
}
