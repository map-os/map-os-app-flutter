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

    final cor = _isProduto ? AppColors.produtos : AppColors.servicos;
    final escolhido = await showSearchPicker<Sugestao>(
      context,
      title: _isProduto ? 'Adicionar produto' : 'Adicionar serviço',
      hint: _isProduto ? 'Buscar produto' : 'Buscar serviço',
      fetch: (q) => _isProduto ? context.read<ProdutosRepository>().sugestoes(q) : context.read<ServicosRepository>().sugestoes(q),
      itemBuilder: (context, item) => ListTile(
        leading: IconBadge(_isProduto ? Icons.inventory_2_outlined : Icons.handyman_outlined, color: cor, size: 38),
        title: Text(item.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: item.estoque == null ? null : Text('Estoque: ${item.estoque}'),
        trailing: item.preco == null ? null : Text(Fmt.money(item.preco), style: context.text.titleSmall),
      ),
    );
    if (escolhido == null) return;
    refId = escolhido.id;
    nome = escolhido.nome;
    preco = escolhido.preco ?? 0;

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
    final r = await showDescontoSheet(context, subtotal: item.bruto, descontoAtual: item.desconto?.valor ?? 0, tipoAtual: item.desconto?.tipo ?? 'real');
    if (r == null || !context.mounted) return;
    final ok = await runAction(
      context,
      () => repo.descontoDoItem(os.id, produto: _isProduto, itemId: item.itemId, tipo: r.$2, valor: r.$1),
      success: r.$1 > 0 ? 'Desconto do item aplicado.' : 'Desconto do item removido.',
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
                    subtitle: Text([
                      '${Fmt.number(item.quantidade)} × ${Fmt.money(item.preco)}',
                      if (item.desconto != null) 'desconto ${item.desconto!.porcento ? '${Fmt.number(item.desconto!.valor)}%' : Fmt.money(item.desconto!.valor)}',
                    ].join(' · ')),
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
                              PopupMenuItem(value: 'edit', child: Text('Desconto do item')),
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
