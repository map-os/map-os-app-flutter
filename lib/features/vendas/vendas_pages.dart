import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/search_picker.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/catalogo.dart';
import '../../data/models/conta.dart';
import '../../data/models/ordem_servico.dart';
import '../../data/models/venda.dart';
import '../../data/repositories/cadastros_repository.dart';
import '../../data/repositories/gestao_repository.dart';
import '../cobrancas/cobrancas_page.dart';
import '../os/widgets/os_acoes.dart';
import '../os/widgets/os_dialogs.dart';

class VendasPage extends StatefulWidget {
  const VendasPage({super.key});

  @override
  State<VendasPage> createState() => _VendasPageState();
}

class _VendasPageState extends State<VendasPage> {
  String? _status;
  late final PagedController<Venda> _ctrl = PagedController(
    fetch: (page, search) => context.read<VendasRepository>().list(page: page, search: search, status: _status),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _abrir(Widget pagina) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pagina));
    _ctrl.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final podeAdicionar = context.watch<AuthState>().permissions.canAdd('Venda');
    return Scaffold(
      appBar: AppBar(title: const Text('Vendas')),
      floatingActionButton: podeAdicionar
          ? FloatingActionButton.extended(onPressed: () => _abrir(const VendaFormPage()), icon: const Icon(Icons.add_rounded), label: const Text('Nova venda'))
          : null,
      body: PagedListView<Venda>(
        controller: _ctrl,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
          child: ContentWidthScroll(
            child: Column(
              children: [
                SearchField(hint: 'Buscar por cliente ou número', onChanged: _ctrl.setSearch),
                const SizedBox(height: Gaps.sm),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final s in [null, ...StatusColors.all])
                        Padding(
                          padding: const EdgeInsets.only(right: Gaps.sm),
                          child: ChoiceChip(
                            label: Text(s ?? 'Todas'),
                            selected: _status == s,
                            onSelected: (_) {
                              setState(() => _status = s);
                              _ctrl.refresh();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        empty: (buscando) => EmptyView(
          icon: Icons.point_of_sale_outlined,
          title: buscando || _status != null ? 'Nenhuma venda encontrada' : 'Nenhuma venda ainda',
          message: buscando || _status != null ? 'Tente outro filtro.' : 'Registre a primeira venda no botão abaixo.',
        ),
        itemBuilder: (context, v) => VendaCard(venda: v, onTap: () => _abrir(VendaDetailPage(id: v.id))),
      ),
    );
  }
}

class VendaCard extends StatelessWidget {
  const VendaCard({super.key, required this.venda, required this.onTap});

  final Venda venda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(Gaps.lg),
        child: Row(
          children: [
            const IconBadge(Icons.point_of_sale_outlined, color: AppColors.vendas, size: 40),
            const SizedBox(width: Gaps.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Venda #${venda.id}', style: context.text.titleSmall),
                  Text(venda.nomeCliente, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(Fmt.date(venda.dataVenda), style: context.text.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Fmt.money(venda.total), style: context.text.titleSmall),
                const SizedBox(height: Gaps.xs),
                StatusChip(venda.status, dense: true),
              ],
            ),
          ],
        ),
      );
}

class VendaDetailPage extends StatefulWidget {
  const VendaDetailPage({super.key, required this.id});

  final int id;

  @override
  State<VendaDetailPage> createState() => _VendaDetailPageState();
}

class _VendaDetailPageState extends State<VendaDetailPage> {
  late Future<Venda> _venda = context.read<VendasRepository>().get(widget.id);

  Future<void> _recarregar() async {
    final f = context.read<VendasRepository>().get(widget.id);
    setState(() => _venda = f);
    try {
      await f;
    } catch (_) {}
  }

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    if (await runAction(context, acao, success: sucesso)) await _recarregar();
  }

  Future<void> _adicionarProduto(Venda v) async {
    final repo = context.read<VendasRepository>();
    final p = await showSearchPicker<Sugestao>(
      context,
      title: 'Adicionar produto',
      hint: 'Buscar produto',
      fetch: context.read<ProdutosRepository>().sugestoes,
      itemBuilder: (context, item) => ListTile(
        leading: const IconBadge(Icons.inventory_2_outlined, color: AppColors.produtos, size: 38),
        title: Text(item.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: item.estoque == null ? null : Text('Estoque: ${item.estoque}'),
        trailing: item.preco == null ? null : Text(Fmt.money(item.preco)),
      ),
    );
    if (p == null || !mounted) return;
    final r = await showItemDialog(context, title: p.nome, subtitle: 'Defina quantidade e preço', preco: p.preco ?? 0);
    if (r == null) return;
    await _executar(() => repo.addProduto(v.id, produtoId: p.id, quantidade: r.$1, preco: r.$2), 'Produto adicionado.');
  }

  Future<void> _descontoDoItem(Venda v, OsItem item) async {
    final r = await showDescontoSheet(context, subtotal: item.bruto, descontoAtual: item.desconto?.valor ?? 0, tipoAtual: item.desconto?.tipo ?? 'real');
    if (r == null || !mounted) return;
    await _executar(() => context.read<VendasRepository>().descontoDoItem(v.id, item.itemId, tipo: r.$2, valor: r.$1), 'Desconto do item salvo.');
  }

  Future<void> _desconto(Venda v) async {
    final r = await showDescontoSheet(context, subtotal: v.totalProdutos, descontoAtual: v.desconto, tipoAtual: v.tipoDesconto.isEmpty ? 'real' : v.tipoDesconto);
    if (r == null || !mounted) return;
    await _executar(() => context.read<VendasRepository>().aplicarDesconto(v.id, tipo: r.$2, valor: r.$1), r.$1 > 0 ? 'Desconto aplicado.' : 'Desconto removido.');
  }

  Future<void> _acao(String acao, Venda v) async {
    final repo = context.read<VendasRepository>();
    switch (acao) {
      case 'status':
        final s = await showStatusSheet(context, v.status);
        if (s != null && s != v.status) await _executar(() => repo.update(v.id, {'status': s}), 'Status alterado para $s.');
      case 'editar':
        final salvou = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => VendaFormPage(venda: v)));
        if (salvou == true) await _recarregar();
      case 'pix':
        await showPixSheet(context, carregar: () => repo.pix(v.id), titulo: 'PIX da venda #${v.id}');
      case 'faturar':
        final ok = await showFaturarSheet(context, titulo: 'Faturar venda #${v.id}', descricao: 'Fatura da venda #${v.id}', total: v.total, faturar: (f) => repo.faturar(v.id, f));
        if (ok) await _recarregar();
      case 'cobranca':
        final id = await showGerarCobrancaSheet(context, origem: 'venda', origemId: v.id);
        if (id != null) await _recarregar();
      case 'excluir':
        final ok = await confirmDialog(context, title: 'Excluir a venda #${v.id}?', message: 'Os produtos voltam para o estoque.', confirmLabel: 'Excluir', destructive: true);
        if (!ok || !mounted) return;
        if (await runAction(context, () => repo.delete(v.id), success: 'Venda excluída.') && mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = context.watch<AuthState>().permissions;
    return FutureBuilder<Venda>(
      future: _venda,
      builder: (context, snap) {
        final v = snap.data;
        final editar = v != null && v.editavel && perms.canEdit('Venda');
        return Scaffold(
          appBar: AppBar(
            title: Text('Venda #${widget.id}'),
            actions: [
              if (v != null)
                PopupMenuButton<String>(
                  onSelected: (a) => _acao(a, v),
                  itemBuilder: (_) => [
                    if (editar) const PopupMenuItem(value: 'status', child: Text('Mudar status')),
                    if (editar) const PopupMenuItem(value: 'editar', child: Text('Editar dados')),
                    if (v.total > 0) const PopupMenuItem(value: 'pix', child: Text('PIX')),
                    if (editar && !v.faturado && v.total > 0) const PopupMenuItem(value: 'faturar', child: Text('Faturar')),
                    if (v.cobrancaId == null && v.total > 0 && perms.canAdd('Cobranca')) const PopupMenuItem(value: 'cobranca', child: Text('Gerar cobrança')),
                    if (perms.canDelete('Venda')) const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                  ],
                ),
            ],
          ),
          floatingActionButton: editar ? FloatingActionButton.extended(onPressed: () => _adicionarProduto(v), icon: const Icon(Icons.add_rounded), label: const Text('Produto')) : null,
          body: snap.hasError
              ? ErrorView(error: snap.error!, onRetry: _recarregar)
              : v == null
                  ? const SkeletonList()
                  : RefreshIndicator(
                      onRefresh: _recarregar,
                      child: ListView(
                        padding: Gaps.pageOf(context),
                        children: [
                          ContentWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppCard(
                                  padding: const EdgeInsets.all(Gaps.lg),
                                  child: Column(
                                    children: [
                                      Row(children: [StatusChip(v.status), const Spacer(), Text(Fmt.money(v.total), style: context.text.titleLarge)]),
                                      const SizedBox(height: Gaps.md),
                                      InfoRow(icon: Icons.person_outline_rounded, label: 'Cliente', value: v.nomeCliente),
                                      InfoRow(icon: Icons.badge_outlined, label: 'Vendedor', value: v.vendedor),
                                      InfoRow(icon: Icons.event_outlined, label: 'Data', value: Fmt.date(v.dataVenda)),
                                      if (v.garantiaAte != null) InfoRow(icon: Icons.verified_user_outlined, label: 'Garantia até', value: Fmt.date(v.garantiaAte)),
                                      if (v.faturado) const InfoRow(icon: Icons.receipt_long_outlined, label: 'Financeiro', value: 'Faturada'),
                                      if (v.cobrancaId != null) InfoRow(icon: Icons.request_quote_outlined, label: 'Cobrança', value: '#${v.cobrancaId}'),
                                    ],
                                  ),
                                ),
                                if (!v.editavel) ...[
                                  const SizedBox(height: Gaps.md),
                                  Text('Venda faturada ou cancelada: só leitura.', style: context.text.bodySmall),
                                ],
                                SectionHeader('Produtos', action: editar ? 'Desconto geral' : null, onAction: editar ? () => _desconto(v) : null),
                                if (v.produtos.isEmpty)
                                  const EmptyView(icon: Icons.inventory_2_outlined, title: 'Nenhum produto', message: 'Adicione os produtos vendidos.')
                                else
                                  AppCard(
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                      children: [
                                        for (final i in v.produtos)
                                          ListTile(
                                            title: Text(i.nome),
                                            subtitle: Text([
                                              '${Fmt.number(i.quantidade)} × ${Fmt.money(i.preco)}',
                                              if (i.desconto != null && i.desconto!.valor > 0) 'desconto ${i.desconto!.tipo == 'porcento' ? '${Fmt.number(i.desconto!.valor)}%' : Fmt.money(i.desconto!.valor)}',
                                            ].join(' · ')),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(Fmt.money(i.subTotal)),
                                                if (editar)
                                                  PopupMenuButton<String>(
                                                    onSelected: (a) => a == 'desconto'
                                                        ? _descontoDoItem(v, i)
                                                        : _executar(() => context.read<VendasRepository>().removeProduto(v.id, i.itemId), 'Produto removido.'),
                                                    itemBuilder: (_) => const [
                                                      PopupMenuItem(value: 'desconto', child: Text('Desconto do item')),
                                                      PopupMenuItem(value: 'remover', child: Text('Remover')),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        const Divider(height: 1),
                                        if (v.temDesconto) ListTile(dense: true, title: const Text('Desconto'), trailing: Text('- ${Fmt.money(v.valorDoDesconto)}')),
                                        ListTile(title: const Text('Total'), trailing: Text(Fmt.money(v.total), style: context.text.titleMedium)),
                                      ],
                                    ),
                                  ),
                                if (v.observacoes.isNotEmpty || v.observacoesCliente.isNotEmpty) ...[
                                  const SectionHeader('Observações'),
                                  AppCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (v.observacoes.isNotEmpty) TextBlock(title: 'Internas', text: v.observacoes, icon: Icons.lock_outline_rounded),
                                        if (v.observacoes.isNotEmpty && v.observacoesCliente.isNotEmpty) const Divider(height: Gaps.xl),
                                        if (v.observacoesCliente.isNotEmpty) TextBlock(title: 'Para o cliente', text: v.observacoesCliente, icon: Icons.chat_bubble_outline_rounded),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}

class VendaFormPage extends StatefulWidget {
  const VendaFormPage({super.key, this.venda});

  final Venda? venda;

  @override
  State<VendaFormPage> createState() => _VendaFormPageState();
}

class _VendaFormPageState extends State<VendaFormPage> {
  late int? _clienteId = widget.venda?.clienteId;
  late String _cliente = widget.venda?.nomeCliente ?? '';
  late int? _vendedorId = widget.venda?.vendedorId;
  late String _vendedor = widget.venda?.vendedor ?? '';
  late DateTime _data = widget.venda?.dataVenda ?? DateTime.now();
  late final _garantia = TextEditingController(text: widget.venda?.garantiaDias?.toString() ?? '');
  late final _observacoes = TextEditingController(text: Fmt.plain(widget.venda?.observacoes ?? ''));
  late final _observacoesCliente = TextEditingController(text: Fmt.plain(widget.venda?.observacoesCliente ?? ''));
  bool _salvando = false;
  Map<String, String> _erros = const {};

  @override
  void dispose() {
    _garantia.dispose();
    _observacoes.dispose();
    _observacoesCliente.dispose();
    super.dispose();
  }

  Future<void> _escolherCliente() async {
    final c = await showSearchPicker<Sugestao>(
      context,
      title: 'Selecionar cliente',
      hint: 'Buscar por nome, telefone ou documento',
      fetch: context.read<ClientesRepository>().sugestoes,
      itemBuilder: (context, c) => ListTile(leading: InitialsAvatar(c.nome, size: 38), title: Text(c.nome), subtitle: c.detalhe.isEmpty ? null : Text(c.detalhe)),
    );
    if (c != null) {
      setState(() {
        _clienteId = c.id;
        _cliente = c.nome;
      });
    }
  }

  Future<void> _escolherVendedor() async {
    final u = await showSearchPicker<Usuario>(
      context,
      title: 'Selecionar vendedor',
      hint: 'Buscar usuário',
      fetch: (s) => context.read<ContaRepository>().usuarios(search: s),
      itemBuilder: (context, u) => ListTile(leading: InitialsAvatar(u.nome, size: 38, imageUrl: u.fotoUrl), title: Text(u.nome)),
    );
    if (u != null) {
      setState(() {
        _vendedorId = u.id;
        _vendedor = u.nome;
      });
    }
  }

  Future<void> _salvar() async {
    if (_clienteId == null) {
      setState(() => _erros = {'cliente_id': 'Escolha o cliente.'});
      return;
    }
    setState(() {
      _salvando = true;
      _erros = const {};
    });
    final dados = {
      'cliente_id': _clienteId,
      if (_vendedorId != null && _vendedorId! > 0) 'vendedor_id': _vendedorId,
      'data_venda': Fmt.apiDate(_data),
      'garantia_dias': int.tryParse(_garantia.text.trim()),
      'observacoes': _observacoes.text.trim(),
      'observacoes_cliente': _observacoesCliente.text.trim(),
    };
    try {
      final repo = context.read<VendasRepository>();
      if (widget.venda == null) {
        final v = await repo.create({...dados, 'status': 'Aberto'});
        if (!mounted) return;
        Toast.success(context, 'Venda #${v.id} criada. Adicione os produtos.');
        await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VendaDetailPage(id: v.id)));
      } else {
        await repo.update(widget.venda!.id, dados);
        if (!mounted) return;
        Toast.success(context, 'Venda salva.');
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _erros = e.erros);
      if (mounted && e.erros.isEmpty) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.venda == null ? 'Nova venda' : 'Editar venda #${widget.venda!.id}')),
        bottomNavigationBar: BottomActionBar(child: LoadingButton(label: 'Salvar', icon: Icons.check_rounded, loading: _salvando, onPressed: _salvar)),
        body: ListView(
          padding: Gaps.pageOf(context),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PickerField(label: 'Cliente', value: _cliente.isEmpty ? null : _cliente, icon: Icons.person_outline_rounded, onTap: _escolherCliente, errorText: _erros['cliente_id']),
                  const SizedBox(height: Gaps.md),
                  PickerField(label: 'Vendedor', value: _vendedor.isEmpty ? null : _vendedor, icon: Icons.badge_outlined, onTap: _escolherVendedor, errorText: _erros['vendedor_id']),
                  const SizedBox(height: Gaps.md),
                  DateField(label: 'Data da venda', value: _data, onChanged: (d) => setState(() => _data = d)),
                  const SizedBox(height: Gaps.md),
                  TextField(
                    controller: _garantia,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Garantia (dias)', errorText: _erros['garantia_dias']),
                  ),
                  const SizedBox(height: Gaps.md),
                  AppTextField(controller: _observacoes, label: 'Observações internas', maxLines: 3, textCapitalization: TextCapitalization.sentences),
                  const SizedBox(height: Gaps.md),
                  AppTextField(controller: _observacoesCliente, label: 'Observações para o cliente', maxLines: 3, textCapitalization: TextCapitalization.sentences),
                ],
              ),
            ),
          ],
        ),
      );
}
