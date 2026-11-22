import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/catalogo.dart';
import '../../data/repositories/cadastros_repository.dart';
import 'produto_detail_page.dart';
import 'produto_form_page.dart';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  late final PagedController<Produto> _ctrl = PagedController(
    fetch: (page, search) => context.read<ProdutosRepository>().list(page: page, search: search),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => page));
    if (changed == true) _ctrl.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = context.watch<AuthState>().permissions.canAdd('Produto');
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _open(const ProdutoFormPage()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo'),
            )
          : null,
      body: PagedListView<Produto>(
        controller: _ctrl,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
          child: ContentWidthScroll(
            child: SearchField(hint: 'Buscar por descrição ou código', onChanged: _ctrl.setSearch),
          ),
        ),
        empty: (searching) => EmptyView(
          icon: Icons.inventory_2_outlined,
          title: searching ? 'Nenhum produto encontrado' : 'Nenhum produto cadastrado',
          message: searching ? 'Tente outro termo de busca.' : null,
        ),
        itemBuilder: (context, p) => ProdutoTile(produto: p, onTap: () => _open(ProdutoDetailPage(produtoId: p.id))),
      ),
    );
  }
}

class ProdutoTile extends StatelessWidget {
  const ProdutoTile({super.key, required this.produto, required this.onTap});

  final Produto produto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = produto;
    final stockColor = p.estoque <= 0
        ? AppColors.danger
        : p.estoqueBaixo
            ? AppColors.warning
            : AppColors.success;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.md),
      onTap: onTap,
      child: Row(
        children: [
          const IconBadge(Icons.inventory_2_outlined, color: AppColors.produtos),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.descricao, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: stockColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${Fmt.number(p.estoque)} ${p.unidade.toLowerCase()} em estoque', style: context.text.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Gaps.sm),
          Text(Fmt.money(p.precoVenda), style: context.text.titleSmall),
        ],
      ),
    );
  }
}
