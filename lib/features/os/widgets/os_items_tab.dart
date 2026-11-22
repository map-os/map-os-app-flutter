import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/ui.dart';
import '../../../data/models/catalogo.dart';
import '../../../data/models/ordem_servico.dart';
import '../../../data/repositories/cadastros_repository.dart';
import '../../../data/repositories/os_repository.dart';
import 'os_dialogs.dart';

enum OsItemKind { produto, servico }

/// Aba de produtos ou serviços de uma OS.
class OsItemsTab extends StatelessWidget {
  const OsItemsTab({
    super.key,
    required this.os,
    required this.kind,
    required this.canEdit,
    required this.onChanged,
  });

  final OrdemServico os;
  final OsItemKind kind;
  final bool canEdit;
  final Future<void> Function() onChanged;

  bool get _isProduto => kind == OsItemKind.produto;
  List<OsItem> get _items => _isProduto ? os.produtos : os.servicos;
  double get _total => _isProduto ? os.totalProdutos : os.totalServicos;

  Future<void> _add(BuildContext context) async {
    final repo = context.read<OsRepository>();
    int? refId;
    String nome = '';
    double preco = 0;

    if (_isProduto) {
      final cat = context.read<ProdutosRepository>();
      final p = await showSearchPicker<Produto>(
        context,
        title: 'Adicionar produto',
        hint: 'Buscar produto',
        fetch: (s) => cat.list(search: s),
        itemBuilder: (context, p) => ListTile(
          leading: const IconBadge(Icons.inventory_2_outlined, color: AppColors.produtos, size: 38),
          title: Text(p.descricao, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('Estoque: ${Fmt.number(p.estoque)} ${p.unidade}'),
          trailing: Text(Fmt.money(p.precoVenda), style: context.text.titleSmall),
        ),
      );
      if (p == null) return;
      refId = p.id;
      nome = p.descricao;
      preco = p.precoVenda;
    } else {
      final cat = context.read<ServicosRepository>();
      final s = await showSearchPicker<Servico>(
        context,
        title: 'Adicionar serviço',
        hint: 'Buscar serviço',
        fetch: (q) => cat.list(search: q),
        itemBuilder: (context, s) => ListTile(
          leading: const IconBadge(Icons.handyman_outlined, color: AppColors.servicos, size: 38),
          title: Text(s.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(Fmt.money(s.preco), style: context.text.titleSmall),
        ),
      );
      if (s == null) return;
      refId = s.id;
      nome = s.nome;
      preco = s.preco;
    }

    if (!context.mounted) return;
    final r = await showItemDialog(context, title: nome, subtitle: 'Defina quantidade e preço', preco: preco);
    if (r == null || !context.mounted) return;

    final ok = await runAction(
      context,
      () => _isProduto
          ? repo.addProduto(os.id, produtoId: refId!, quantidade: r.$1, preco: r.$2)
          : repo.addServico(os.id, servicoId: refId!, quantidade: r.$1, preco: r.$2),
      success: _isProduto ? 'Produto adicionado.' : 'Serviço adicionado.',
    );
    if (ok) await onChanged();
  }

  Future<void> _edit(BuildContext context, OsItem item) async {
    final repo = context.read<OsRepository>();
    final r = await showItemDialog(
      context,
      title: item.nome,
      subtitle: 'Editar item',
      quantidade: item.quantidade,
      preco: item.preco,
      confirmLabel: 'Salvar',
    );
    if (r == null || !context.mounted) return;
    final ok = await runAction(
      context,
      () => _isProduto
          ? repo.updateProduto(os.id, item.itemId, quantidade: r.$1, preco: r.$2)
          : repo.updateServico(os.id, item.itemId, quantidade: r.$1, preco: r.$2),
      success: 'Item atualizado.',
    );
    if (ok) await onChanged();
  }

  Future<void> _remove(BuildContext context, OsItem item) async {
    final repo = context.read<OsRepository>();
    final confirm = await confirmDialog(
      context,
      title: 'Remover item?',
      message: '"${item.nome}" será removido desta OS.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!confirm || !context.mounted) return;
    final ok = await runAction(
      context,
      () => _isProduto ? repo.removeProduto(os.id, item.itemId) : repo.removeServico(os.id, item.itemId),
      success: 'Item removido.',
    );
    if (ok) await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final color = _isProduto ? AppColors.produtos : AppColors.servicos;
    final icon = _isProduto ? Icons.inventory_2_outlined : Icons.handyman_outlined;
    return ListView(
      padding: Gaps.pageOf(context),
      children: [
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Gaps.xl),
            child: EmptyView(
              icon: icon,
              title: _isProduto ? 'Nenhum produto nesta OS' : 'Nenhum serviço nesta OS',
              actionLabel: canEdit ? (_isProduto ? 'Adicionar produto' : 'Adicionar serviço') : null,
              onAction: () => _add(context),
            ),
          )
        else ...[
          Card(
            child: Column(
              children: [
                for (final (i, item) in _items.indexed) ...[
                  if (i > 0) const Divider(indent: Gaps.lg, endIndent: Gaps.lg),
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(Gaps.lg, Gaps.xs, Gaps.xs, Gaps.xs),
                    leading: IconBadge(icon, color: color, size: 38),
                    title: Text(item.nome, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${Fmt.number(item.quantidade)} × ${Fmt.money(item.preco)}'),
                    onTap: canEdit ? () => _edit(context, item) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(Fmt.money(item.subTotal), style: context.text.titleSmall),
                        if (canEdit)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (v) => v == 'edit' ? _edit(context, item) : _remove(context, item),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Editar')),
                              PopupMenuItem(value: 'remove', child: Text('Remover')),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(Gaps.lg),
                  child: Row(
                    children: [
                      Text('Total de ${_isProduto ? 'produtos' : 'serviços'}', style: context.text.bodyMedium),
                      const Spacer(),
                      Text(Fmt.money(_total), style: context.text.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: Gaps.md),
            OutlinedButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(_isProduto ? 'Adicionar produto' : 'Adicionar serviço'),
            ),
          ],
        ],
      ],
    );
  }
}
