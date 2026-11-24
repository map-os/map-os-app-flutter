import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/admin.dart';
import '../../data/models/conta.dart';
import '../../data/repositories/admin_repository.dart';
import 'comum.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  String? _situacao;
  late final PagedController<Usuario> _ctrl = PagedController(
    fetch: (page, search) => context.read<AdminRepository>().usuarios(page: page, search: search, situacao: _situacao),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _abrir([Usuario? u]) async {
    final salvou = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => UsuarioFormPage(id: u?.id)));
    if (salvou == true) _ctrl.refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Usuários')),
        floatingActionButton: FloatingActionButton.extended(onPressed: _abrir, icon: const Icon(Icons.person_add_alt_rounded), label: const Text('Novo')),
        body: PagedListView<Usuario>(
          controller: _ctrl,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
            child: ContentWidthScroll(
              child: Column(
                children: [
                  SearchField(hint: 'Nome, e-mail ou CPF', onChanged: _ctrl.setSearch),
                  const SizedBox(height: Gaps.sm),
                  Row(
                    children: [
                      for (final (valor, rotulo) in [(null, 'Todos'), ('ativo', 'Ativos'), ('inativo', 'Inativos')])
                        Padding(
                          padding: const EdgeInsets.only(right: Gaps.sm),
                          child: ChoiceChip(
                            label: Text(rotulo),
                            selected: _situacao == valor,
                            onSelected: (_) {
                              setState(() => _situacao = valor);
                              _ctrl.refresh();
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          empty: (buscando) => const EmptyView(icon: Icons.group_outlined, title: 'Nenhum usuário encontrado'),
          itemBuilder: (context, u) => AppCard(
            onTap: () => _abrir(u),
            padding: const EdgeInsets.all(Gaps.lg),
            child: Row(
              children: [
                InitialsAvatar(u.nome, size: 44, imageUrl: u.fotoUrl),
                const SizedBox(width: Gaps.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.nome, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(u.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text([u.grupo, if (u.doisFatoresAtivo) '2FA ativo'].where((s) => s.isNotEmpty).join(' · '), style: context.text.bodySmall),
                    ],
                  ),
                ),
                if (!u.ativo) Text('Inativo', style: context.text.labelSmall?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}

class UsuarioFormPage extends StatefulWidget {
  const UsuarioFormPage({super.key, this.id});

  final int? id;

  @override
  State<UsuarioFormPage> createState() => _UsuarioFormPageState();
}

class _UsuarioFormPageState extends State<UsuarioFormPage> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _cpf = TextEditingController();
  final _rg = TextEditingController();
  final _telefone = TextEditingController();
  final _celular = TextEditingController();
  final _senha = TextEditingController();
  ControlesDeEndereco _endereco = ControlesDeEndereco(const {});
  int? _grupoId;
  bool _ativo = true;
  DateTime? _expiracao;
  Usuario? _usuario;
  List<GrupoDePermissao> _grupos = const [];
  bool _carregando = true;
  Object? _erroAoCarregar;
  bool _salvando = false;
  Map<String, String> _erros = const {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erroAoCarregar = null;
    });
    try {
      final repo = context.read<AdminRepository>();
      final grupos = await repo.grupos();
      final u = widget.id == null ? null : await repo.usuario(widget.id!);
      if (!mounted) return;
      setState(() {
        _grupos = grupos;
        _usuario = u;
        if (u != null) {
          _nome.text = u.nome;
          _email.text = u.email;
          _cpf.text = u.cpf;
          _rg.text = u.rg;
          _telefone.text = u.telefone;
          _celular.text = u.celular;
          _grupoId = u.grupoId;
          _ativo = u.ativo;
          _expiracao = u.dataExpiracao;
          _endereco.dispose();
          _endereco = ControlesDeEndereco(u.endereco);
        }
        _carregando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erroAoCarregar = e;
          _carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_nome, _email, _cpf, _rg, _telefone, _celular, _senha]) {
      c.dispose();
    }
    _endereco.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_grupoId == null) {
      setState(() => _erros = {'grupo_id': 'Escolha o grupo de permissão.'});
      return;
    }
    setState(() {
      _salvando = true;
      _erros = const {};
    });
    final dados = {
      'nome': _nome.text.trim(),
      'email': _email.text.trim(),
      'cpf': _cpf.text.trim(),
      'rg': _rg.text.trim(),
      'telefone': _telefone.text.trim(),
      'celular': _celular.text.trim(),
      if (_senha.text.isNotEmpty) 'senha': _senha.text,
      'grupo_id': _grupoId,
      'ativo': _ativo,
      'data_expiracao': _expiracao == null ? null : Fmt.apiDate(_expiracao!),
      'endereco': _endereco.valores,
    };
    try {
      await context.read<AdminRepository>().salvarUsuario(widget.id, dados);
      if (!mounted) return;
      Toast.success(context, 'Usuário salvo.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erros = e.erros);
      if (mounted && e.erros.isEmpty) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _acao(String acao) async {
    final repo = context.read<AdminRepository>();
    final u = _usuario!;
    if (acao == '2fa') {
      final ok = await confirmDialog(context, title: 'Redefinir a verificação em duas etapas?', message: '${u.nome} vai configurar o 2FA de novo no próximo acesso.', confirmLabel: 'Redefinir');
      if (ok && mounted && await runAction(context, () => repo.redefinirDoisFatores(u.id), success: '2FA redefinido.')) await _carregar();
    } else {
      final ok = await confirmDialog(context, title: 'Excluir ${u.nome}?', message: 'Prefira desativar se o usuário tiver OS ou vendas no histórico.', confirmLabel: 'Excluir', destructive: true);
      if (ok && mounted && await runAction(context, () => repo.excluirUsuario(u.id), success: 'Usuário excluído.') && mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final novo = widget.id == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(novo ? 'Novo usuário' : 'Editar usuário'),
        actions: [
          if (_usuario != null)
            PopupMenuButton<String>(
              onSelected: _acao,
              itemBuilder: (_) => [
                if (_usuario!.doisFatoresAtivo) const PopupMenuItem(value: '2fa', child: Text('Redefinir 2FA')),
                const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
              ],
            ),
        ],
      ),
      bottomNavigationBar: _carregando || _erroAoCarregar != null ? null : BottomActionBar(child: LoadingButton(label: 'Salvar', icon: Icons.check_rounded, loading: _salvando, onPressed: _salvar)),
      body: _carregando
          ? const SkeletonList()
          : _erroAoCarregar != null
              ? ErrorView(error: _erroAoCarregar!, onRetry: _carregar)
              : ListView(
                  padding: Gaps.pageOf(context),
                  children: [
                    ContentWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          campoDeTexto(_nome, 'Nome', _erros, 'nome'),
                          campoDeTexto(_email, 'E-mail', _erros, 'email', teclado: TextInputType.emailAddress),
                          Row(
                            children: [
                              Expanded(child: campoDeTexto(_cpf, 'CPF', _erros, 'cpf', teclado: TextInputType.number)),
                              const SizedBox(width: Gaps.md),
                              Expanded(child: campoDeTexto(_rg, 'RG', _erros, 'rg')),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: campoDeTexto(_telefone, 'Telefone', _erros, 'telefone', teclado: TextInputType.phone)),
                              const SizedBox(width: Gaps.md),
                              Expanded(child: campoDeTexto(_celular, 'Celular', _erros, 'celular', teclado: TextInputType.phone)),
                            ],
                          ),
                          campoDeTexto(_senha, novo ? 'Senha' : 'Nova senha (opcional)', _erros, 'senha', senha: true, ajuda: novo ? 'Mínimo de 8 caracteres.' : 'Deixe em branco para manter.'),
                          DropdownButtonFormField<int>(
                            initialValue: _grupos.any((g) => g.id == _grupoId) ? _grupoId : null,
                            decoration: InputDecoration(labelText: 'Grupo de permissão', errorText: _erros['grupo_id']),
                            items: [for (final g in _grupos) DropdownMenuItem(value: g.id, child: Text(g.ativo ? g.nome : '${g.nome} (inativo)'))],
                            onChanged: (v) => setState(() => _grupoId = v),
                          ),
                          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Ativo'), subtitle: const Text('Usuário inativo não consegue entrar.'), value: _ativo, onChanged: (v) => setState(() => _ativo = v)),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_busy_outlined),
                            title: const Text('Acesso expira em'),
                            subtitle: Text(_expiracao == null ? 'Não expira' : Fmt.date(_expiracao), style: _erros['data_expiracao'] == null ? null : TextStyle(color: context.colors.error)),
                            trailing: _expiracao == null ? const Icon(Icons.edit_calendar_outlined) : IconButton(tooltip: 'Não expira', icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _expiracao = null)),
                            onTap: () async {
                              final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2100), initialDate: _expiracao ?? DateTime.now().add(const Duration(days: 30)));
                              if (d != null) setState(() => _expiracao = d);
                            },
                          ),
                          const SectionHeader('Endereço'),
                          CamposDeEndereco(endereco: _endereco, erros: _erros),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
