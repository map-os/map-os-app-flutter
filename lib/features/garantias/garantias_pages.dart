import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/gestao.dart';
import '../../data/repositories/gestao_repository.dart';

class GarantiasPage extends StatefulWidget {
  const GarantiasPage({super.key});

  @override
  State<GarantiasPage> createState() => _GarantiasPageState();
}

class _GarantiasPageState extends State<GarantiasPage> {
  late final PagedController<TermoDeGarantia> _ctrl = PagedController(
    fetch: (page, search) => context.read<GarantiasRepository>().list(page: page, search: search),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _abrir([TermoDeGarantia? t]) async {
    final salvou = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => _TermoFormPage(termo: t)));
    if (salvou == true) _ctrl.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final podeAdicionar = context.watch<AuthState>().permissions.canAdd('Garantia');
    return Scaffold(
      appBar: AppBar(title: const Text('Termos de garantia')),
      floatingActionButton: podeAdicionar ? FloatingActionButton.extended(onPressed: _abrir, icon: const Icon(Icons.add_rounded), label: const Text('Novo termo')) : null,
      body: PagedListView<TermoDeGarantia>(
        controller: _ctrl,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
          child: ContentWidthScroll(child: SearchField(hint: 'Buscar termo', onChanged: _ctrl.setSearch)),
        ),
        empty: (buscando) => EmptyView(
          icon: Icons.verified_user_outlined,
          title: buscando ? 'Nenhum termo encontrado' : 'Nenhum termo de garantia',
          message: buscando ? 'Tente outro termo de busca.' : 'Crie um termo para anexar às OS.',
        ),
        itemBuilder: (context, t) => AppCard(
          onTap: () => _abrir(t),
          padding: const EdgeInsets.all(Gaps.lg),
          child: Row(
            children: [
              const IconBadge(Icons.verified_user_outlined, color: AppColors.garantias, size: 40),
              const SizedBox(width: Gaps.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.referencia.isEmpty ? 'Termo #${t.id}' : t.referencia, style: context.text.titleSmall),
                    Text(Fmt.plain(t.texto), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermoFormPage extends StatefulWidget {
  const _TermoFormPage({this.termo});

  final TermoDeGarantia? termo;

  @override
  State<_TermoFormPage> createState() => _TermoFormPageState();
}

class _TermoFormPageState extends State<_TermoFormPage> {
  late final _referencia = TextEditingController(text: widget.termo?.referencia ?? '');
  late final _texto = TextEditingController(text: Fmt.plain(widget.termo?.texto ?? ''));
  bool _salvando = false;
  Map<String, String> _erros = const {};

  @override
  void dispose() {
    _referencia.dispose();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erros = const {};
    });
    try {
      await context.read<GarantiasRepository>().salvar(widget.termo?.id, referencia: _referencia.text.trim(), texto: textoParaHtml(_texto.text));
      if (!mounted) return;
      Toast.success(context, 'Termo salvo.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erros = e.erros);
      if (mounted && e.erros.isEmpty) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final ok = await confirmDialog(context, title: 'Excluir o termo?', message: 'As OS que usam este termo ficam sem ele.', confirmLabel: 'Excluir', destructive: true);
    if (!ok || !mounted) return;
    if (await runAction(context, () => context.read<GarantiasRepository>().delete(widget.termo!.id), success: 'Termo excluído.') && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final perms = context.watch<AuthState>().permissions;
    final podeSalvar = widget.termo == null ? perms.canAdd('Garantia') : perms.canEdit('Garantia');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.termo == null ? 'Novo termo' : 'Termo #${widget.termo!.id}'),
        actions: [
          if (widget.termo != null && perms.canDelete('Garantia')) IconButton(tooltip: 'Excluir', icon: const Icon(Icons.delete_outline_rounded), onPressed: _excluir),
        ],
      ),
      bottomNavigationBar: podeSalvar ? BottomActionBar(child: LoadingButton(label: 'Salvar', icon: Icons.check_rounded, loading: _salvando, onPressed: _salvar)) : null,
      body: ListView(
        padding: Gaps.pageOf(context),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _referencia, readOnly: !podeSalvar, decoration: InputDecoration(labelText: 'Referência', errorText: _erros['referencia'])),
                const SizedBox(height: Gaps.md),
                TextField(
                  controller: _texto,
                  readOnly: !podeSalvar,
                  minLines: 8,
                  maxLines: 20,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: 'Texto do termo', alignLabelWithHint: true, errorText: _erros['texto']),
                ),
                if (widget.termo?.autor.isNotEmpty ?? false) ...[
                  const SizedBox(height: Gaps.md),
                  Text('Criado por ${widget.termo!.autor} em ${Fmt.date(widget.termo!.data)}.', style: context.text.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String textoParaHtml(String texto) {
  String escapar(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  return texto
      .trim()
      .split(RegExp(r'\n\s*\n'))
      .where((p) => p.trim().isNotEmpty)
      .map((p) => '<p>${p.trim().split('\n').map(escapar).join('<br>')}</p>')
      .join();
}
