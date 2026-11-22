import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/catalogo.dart';
import '../../data/repositories/cadastros_repository.dart';
import 'produto_form_page.dart';

class ProdutoDetailPage extends StatefulWidget {
  const ProdutoDetailPage({super.key, required this.produtoId});

  final int produtoId;

  @override
  State<ProdutoDetailPage> createState() => _ProdutoDetailPageState();
}

class _ProdutoDetailPageState extends State<ProdutoDetailPage> {
  late Future<Produto> _future = _load();
  bool _changed = false;

  Future<Produto> _load() => context.read<ProdutosRepository>().get(widget.produtoId);
  void _reload() => setState(() => _future = _load());

  Future<void> _edit(Produto p) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ProdutoFormPage(produto: p)));
    if (saved == true) {
      _changed = true;
      _reload();
    }
  }

  Future<void> _delete(Produto p) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir produto?',
      message: '"${p.descricao}" será removido permanentemente.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runAction(context, () => context.read<ProdutosRepository>().delete(p.id), success: 'Produto excluído.');
    if (done && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final perms = context.watch<AuthState>().permissions;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: FutureBuilder<Produto>(
        future: _future,
        builder: (context, snap) {
          final p = snap.data;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Produto'),
              actions: [
                if (p != null && perms.canEdit('Produto'))
                  IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(p)),
                if (p != null && perms.canDelete('Produto'))
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _delete(p),
                  ),
              ],
            ),
            body: snap.hasError
                ? ErrorView(error: snap.error!, onRetry: _reload)
                : p == null
                    ? const SkeletonList(count: 4)
                    : _content(context, p),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, Produto p) {
    final stockColor = p.estoque <= 0
        ? AppColors.danger
        : p.estoqueBaixo
            ? AppColors.warning
            : AppColors.success;
    return ListView(
      padding: Gaps.pageOf(context),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: const EdgeInsets.all(Gaps.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconBadge(Icons.inventory_2_outlined, color: AppColors.produtos, size: 52),
                    const SizedBox(height: Gaps.lg),
                    Text(p.descricao, style: context.text.titleLarge),
                    if (p.codDeBarra.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 16, color: context.tokens.muted),
                          const SizedBox(width: 6),
                          Text(p.codDeBarra, style: context.text.bodySmall),
                        ],
                      ),
                    ],
                    const SizedBox(height: Gaps.lg),
                    Text('Preço de venda', style: context.text.bodySmall),
                    Text(Fmt.money(p.precoVenda), style: context.text.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: Gaps.md),
              Row(
                children: [
                  Expanded(child: _Metric(label: 'Custo', value: Fmt.money(p.precoCompra))),
                  const SizedBox(width: Gaps.sm),
                  Expanded(
                    child: _Metric(
                      label: 'Margem',
                      value: p.precoCompra > 0 ? '${p.margem.toStringAsFixed(0)}%' : '—',
                      color: p.margem < 0 ? AppColors.danger : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gaps.sm),
              Row(
                children: [
                  Expanded(
                    child: _Metric(label: 'Estoque', value: '${Fmt.number(p.estoque)} ${p.unidade}', color: stockColor),
                  ),
                  const SizedBox(width: Gaps.sm),
                  Expanded(child: _Metric(label: 'Estoque mínimo', value: '${Fmt.number(p.estoqueMinimo)} ${p.unidade}')),
                ],
              ),
              if (p.estoqueBaixo) ...[
                const SizedBox(height: Gaps.md),
                AppCard(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                      const SizedBox(width: Gaps.md),
                      Expanded(
                        child: Text(
                          p.estoque <= 0 ? 'Produto sem estoque.' : 'Estoque abaixo do mínimo definido.',
                          style: context.text.bodyMedium,
                        ),
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
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.text.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: context.text.titleMedium?.copyWith(color: color)),
          ],
        ),
      );
}
