import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/catalogo.dart';
import '../../data/repositories/cadastros_repository.dart';
import 'servico_form_page.dart';

class ServicosPage extends StatefulWidget {
  const ServicosPage({super.key});

  @override
  State<ServicosPage> createState() => _ServicosPageState();
}

class _ServicosPageState extends State<ServicosPage> {
  late final PagedController<Servico> _ctrl = PagedController(
    fetch: (page, search) => context.read<ServicosRepository>().list(page: page, search: search),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _open([Servico? s]) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ServicoFormPage(servico: s)));
    if (changed == true) _ctrl.refresh();
  }

  Future<void> _showDetail(Servico s) async {
    final perms = context.read<AuthState>().permissions;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(Gaps.xl, 0, Gaps.xl, Gaps.xl + Gaps.systemBottom(sheet)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const IconBadge(Icons.handyman_outlined, color: AppColors.servicos, size: 48),
                const SizedBox(width: Gaps.lg),
                Expanded(child: Text(s.nome, style: context.text.titleLarge)),
              ],
            ),
            const SizedBox(height: Gaps.lg),
            Text(Fmt.money(s.preco), style: context.text.headlineMedium),
            const SizedBox(height: Gaps.md),
            Text(
              s.descricao.isEmpty ? 'Sem descrição.' : s.descricao,
              style: context.text.bodyMedium?.copyWith(color: context.tokens.muted, height: 1.4),
            ),
            const SizedBox(height: Gaps.xl),
            Row(
              children: [
                if (perms.canDelete('Servico'))
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Excluir'),
                      onPressed: () async {
                        Navigator.pop(sheet);
                        final ok = await confirmDialog(
                          context,
                          title: 'Excluir serviço?',
                          message: '"${s.nome}" será removido permanentemente.',
                          confirmLabel: 'Excluir',
                          destructive: true,
                        );
                        if (!ok || !mounted) return;
                        final done = await runAction(
                          context,
                          () => context.read<ServicosRepository>().delete(s.id),
                          success: 'Serviço excluído.',
                        );
                        if (done) _ctrl.refresh();
                      },
                    ),
                  ),
                if (perms.canDelete('Servico') && perms.canEdit('Servico')) const SizedBox(width: Gaps.md),
                if (perms.canEdit('Servico'))
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                      onPressed: () {
                        Navigator.pop(sheet);
                        _open(s);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = context.watch<AuthState>().permissions.canAdd('Servico');
    return Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _open(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo'),
            )
          : null,
      body: PagedListView<Servico>(
        controller: _ctrl,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
          child: ContentWidthScroll(child: SearchField(hint: 'Buscar serviço', onChanged: _ctrl.setSearch)),
        ),
        empty: (searching) => EmptyView(
          icon: Icons.handyman_outlined,
          title: searching ? 'Nenhum serviço encontrado' : 'Nenhum serviço cadastrado',
        ),
        itemBuilder: (context, s) => AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.md),
          onTap: () => _showDetail(s),
          child: Row(
            children: [
              const IconBadge(Icons.handyman_outlined, color: AppColors.servicos),
              const SizedBox(width: Gaps.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.nome, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (s.descricao.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(s.descricao, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Gaps.sm),
              Text(Fmt.money(s.preco), style: context.text.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
