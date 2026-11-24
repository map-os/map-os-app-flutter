import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/admin.dart';
import '../../data/repositories/admin_repository.dart';

class GruposPage extends StatefulWidget {
  const GruposPage({super.key});

  @override
  State<GruposPage> createState() => _GruposPageState();
}

class _GruposPageState extends State<GruposPage> {
  late Future<List<GrupoDePermissao>> _grupos = context.read<AdminRepository>().grupos();

  void _recarregar() => setState(() => _grupos = context.read<AdminRepository>().grupos());

  Future<void> _abrir([GrupoDePermissao? g]) async {
    final salvou = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => _GrupoFormPage(grupo: g)));
    if (salvou == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Grupos de permissão')),
        floatingActionButton: FloatingActionButton.extended(onPressed: _abrir, icon: const Icon(Icons.add_rounded), label: const Text('Novo grupo')),
        body: RefreshIndicator(
          onRefresh: () async => _recarregar(),
          child: AsyncView<List<GrupoDePermissao>>(
            future: _grupos,
            onRetry: _recarregar,
            builder: (context, grupos) => ListView(
              padding: Gaps.pageOf(context),
              children: [
                for (final g in grupos) ...[
                  ContentWidth(
                    child: AppCard(
                      onTap: () => _abrir(g),
                      padding: const EdgeInsets.all(Gaps.lg),
                      child: Row(
                        children: [
                          const IconBadge(Icons.admin_panel_settings_outlined, color: AppColors.garantias, size: 40),
                          const SizedBox(width: Gaps.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.nome, style: context.text.titleSmall),
                                Text(
                                  [
                                    '${g.permissoes.length} permissões',
                                    '${g.usuarios} ${g.usuarios == 1 ? 'usuário' : 'usuários'}',
                                    if (g.exigir2fa) 'exige 2FA',
                                    if (!g.ativo) 'inativo',
                                  ].join(' · '),
                                  style: context.text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Gaps.sm),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      );
}

class _GrupoFormPage extends StatefulWidget {
  const _GrupoFormPage({this.grupo});

  final GrupoDePermissao? grupo;

  @override
  State<_GrupoFormPage> createState() => _GrupoFormPageState();
}

class _GrupoFormPageState extends State<_GrupoFormPage> {
  late final _nome = TextEditingController(text: widget.grupo?.nome ?? '');
  late bool _ativo = widget.grupo?.ativo ?? true;
  late bool _exigir2fa = widget.grupo?.exigir2fa ?? false;
  late final Set<String> _marcadas = {...?widget.grupo?.permissoes};
  late final Future<List<PermissaoDoCatalogo>> _catalogo = context.read<AdminRepository>().catalogo();
  bool _salvando = false;
  Map<String, String> _erros = const {};

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erros = const {};
    });
    try {
      await context.read<AdminRepository>().salvarGrupo(widget.grupo?.id, nome: _nome.text.trim(), ativo: _ativo, exigir2fa: _exigir2fa, permissoes: _marcadas.toList());
      if (!mounted) return;
      Toast.success(context, 'Grupo salvo. Quem está no grupo recebe as permissões novas na hora.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erros = e.erros);
      if (mounted && e.erros.isEmpty) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.grupo == null ? 'Novo grupo' : widget.grupo!.nome)),
        bottomNavigationBar: BottomActionBar(child: LoadingButton(label: 'Salvar', icon: Icons.check_rounded, loading: _salvando, onPressed: _salvar)),
        body: FutureBuilder<List<PermissaoDoCatalogo>>(
          future: _catalogo,
          builder: (context, snap) {
            if (snap.hasError) return ErrorView(error: snap.error!, onRetry: () => setState(() {}));
            final catalogo = snap.data;
            if (catalogo == null) return const SkeletonList();
            final porGrupo = <String, List<PermissaoDoCatalogo>>{};
            for (final p in catalogo) {
              porGrupo.putIfAbsent(p.grupo, () => []).add(p);
            }
            return ListView(
              padding: Gaps.pageOf(context),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(controller: _nome, decoration: InputDecoration(labelText: 'Nome do grupo', errorText: _erros['nome'])),
                      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Ativo'), value: _ativo, onChanged: (v) => setState(() => _ativo = v)),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Exigir verificação em duas etapas'),
                        subtitle: const Text('Quem não tiver o 2FA ativo precisa configurar antes de usar.'),
                        value: _exigir2fa,
                        onChanged: (v) => setState(() => _exigir2fa = v),
                      ),
                      if (_erros['permissoes'] != null) Text(_erros['permissoes']!, style: TextStyle(color: context.colors.error)),
                      for (final entrada in porGrupo.entries) ...[
                        SectionHeader(
                          entrada.key,
                          action: entrada.value.every((p) => _marcadas.contains(p.codigo)) ? 'Desmarcar' : 'Marcar todas',
                          onAction: () => setState(() {
                            final todas = entrada.value.every((p) => _marcadas.contains(p.codigo));
                            for (final p in entrada.value) {
                              todas ? _marcadas.remove(p.codigo) : _marcadas.add(p.codigo);
                            }
                          }),
                        ),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (final p in entrada.value)
                                CheckboxListTile(
                                  value: _marcadas.contains(p.codigo),
                                  title: Text(p.nome),
                                  subtitle: p.descricao.isEmpty ? null : Text(p.descricao),
                                  onChanged: (v) => setState(() => v == true ? _marcadas.add(p.codigo) : _marcadas.remove(p.codigo)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
}
