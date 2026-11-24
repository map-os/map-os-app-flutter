import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/launchers.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/cliente.dart';
import '../../data/models/cobranca.dart';
import '../../data/models/conta.dart';
import '../../data/models/ordem_servico.dart';
import '../../data/models/venda.dart';
import '../../data/repositories/area_cliente_repository.dart';
import '../os/widgets/os_acoes.dart';
import '../os/widgets/os_card.dart';

class ClienteShell extends StatefulWidget {
  const ClienteShell({super.key});

  @override
  State<ClienteShell> createState() => _ClienteShellState();
}

class _ClienteShellState extends State<ClienteShell> {
  int _aba = 0;

  void _irPara(int aba) => setState(() => _aba = aba);

  @override
  Widget build(BuildContext context) {
    final paginas = [
      _InicioPage(irPara: _irPara),
      const _OrdensPage(),
      const _ComprasPage(),
      const _CobrancasPage(),
      const _ContaPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _aba, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: _irPara,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment_rounded), label: 'Minhas OS'),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag_rounded), label: 'Compras'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Cobranças'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Conta'),
        ],
      ),
    );
  }
}

class _InicioPage extends StatefulWidget {
  const _InicioPage({required this.irPara});

  final ValueChanged<int> irPara;

  @override
  State<_InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<_InicioPage> {
  late Future<PainelDoCliente> _painel = context.read<AreaClienteRepository>().painel();

  Future<void> _recarregar() async {
    final f = context.read<AreaClienteRepository>().painel();
    setState(() => _painel = f);
    try {
      await f;
    } catch (_) {}
  }

  Future<void> _novaOs() async {
    final id = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const _NovaOsPage()));
    if (id != null && mounted) {
      await _recarregar();
      if (mounted) await Navigator.push(context, MaterialPageRoute(builder: (_) => _OsPage(id: id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = (context.watch<AuthState>().nome ?? '').split(' ').first;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: AsyncView<PainelDoCliente>(
          future: _painel,
          onRetry: _recarregar,
          builder: (context, p) {
            final abertas = p.ultimasOs.where((o) => !_encerrada(o.status)).toList();
            final historico = p.ultimasOs.where((o) => _encerrada(o.status)).toList();
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _Cabecalho(nome: nome, emAndamento: p.osEmAndamento, onNovaOs: _novaOs),
                Padding(
                  padding: Gaps.pageOf(context),
                  child: ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _Atalho(icone: Icons.assignment_rounded, rotulo: 'Minhas OS', valor: p.totalOs, cor: AppColors.os, onTap: () => widget.irPara(1))),
                            const SizedBox(width: Gaps.sm),
                            Expanded(child: _Atalho(icone: Icons.shopping_bag_rounded, rotulo: 'Compras', valor: p.totalCompras, cor: AppColors.produtos, onTap: () => widget.irPara(2))),
                            const SizedBox(width: Gaps.sm),
                            Expanded(child: _Atalho(icone: Icons.receipt_long_rounded, rotulo: 'Cobranças', valor: p.totalCobrancas, cor: AppColors.info, onTap: () => widget.irPara(3))),
                          ],
                        ),
                        SectionHeader('Em andamento', action: p.osEmAndamento > abertas.length ? 'Ver todas' : null, onAction: () => widget.irPara(1)),
                        if (abertas.isEmpty)
                          AppCard(
                            padding: const EdgeInsets.all(Gaps.lg),
                            child: Row(
                              children: [
                                const IconBadge(Icons.check_circle_outline_rounded, color: AppColors.success, size: 40),
                                const SizedBox(width: Gaps.md),
                                Expanded(child: Text('Nenhum atendimento em andamento. Precisa de algo? Toque em "Abrir nova OS".', style: context.text.bodyMedium)),
                              ],
                            ),
                          )
                        else
                          for (final os in abertas) ...[
                            _OsEmAndamento(os: os, onTap: () => _abrirOs(os.id)),
                            const SizedBox(height: Gaps.sm),
                          ],
                        if (historico.isNotEmpty) ...[
                          const SectionHeader('Concluídas recentemente'),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (final (i, os) in historico.indexed) ...[
                                  if (i > 0) const Divider(height: 1),
                                  ListTile(
                                    onTap: () => _abrirOs(os.id),
                                    leading: Icon(StatusColors.icon(os.status), color: StatusColors.of(os.status)),
                                    title: Text(_titulo(os), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text('OS #${os.id} · ${os.status}'),
                                    trailing: Text(Fmt.money(os.total), style: context.text.titleSmall),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (p.ultimasCompras.isNotEmpty) ...[
                          const SectionHeader('Últimas compras'),
                          for (final v in p.ultimasCompras) ...[
                            _CompraCard(venda: v),
                            const SizedBox(height: Gaps.sm),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _abrirOs(int id) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _OsPage(id: id)));
    await _recarregar();
  }
}

bool _encerrada(String status) => const ['Finalizado', 'Faturado', 'Cancelado'].contains(status);

String _titulo(OrdemServico os) {
  final d = Fmt.plain(os.descricaoProduto);
  return d.isNotEmpty ? d : 'OS #${os.id}';
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.nome, required this.emAndamento, required this.onNovaOs});

  final String nome;
  final int emAndamento;
  final VoidCallback onNovaOs;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gaps.xl, Gaps.lg, Gaps.xl, Gaps.xl),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome.isEmpty ? 'Olá!' : 'Olá, $nome!', style: context.text.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: Gaps.xs),
                  Text(
                    switch (emAndamento) {
                      0 => 'Nenhum atendimento em andamento.',
                      1 => 'Você tem 1 atendimento em andamento.',
                      _ => 'Você tem $emAndamento atendimentos em andamento.',
                    },
                    style: context.text.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: Gaps.lg),
                  FilledButton.icon(
                    onPressed: onNovaOs,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.brandDeep),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Abrir nova OS'),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      );
}

class _Atalho extends StatelessWidget {
  const _Atalho({required this.icone, required this.rotulo, required this.valor, required this.cor, required this.onTap});

  final IconData icone;
  final String rotulo;
  final int valor;
  final Color cor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: Gaps.sm, vertical: Gaps.md),
        child: Column(
          children: [
            IconBadge(icone, color: cor, size: 40),
            const SizedBox(height: Gaps.sm),
            Text('$valor', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(rotulo, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

class _OsEmAndamento extends StatelessWidget {
  const _OsEmAndamento({required this.os, required this.onTap});

  final OrdemServico os;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor = StatusColors.of(os.status);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Gaps.lg),
      child: Row(
        children: [
          Container(width: 4, height: 56, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titulo(os), style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('OS #${os.id} · desde ${Fmt.date(os.dataInicial)}', style: context.text.bodySmall),
                const SizedBox(height: Gaps.sm),
                StatusChip(os.status, dense: true),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (os.total > 0) Text(Fmt.money(os.total), style: context.text.titleSmall),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrdensPage extends StatefulWidget {
  const _OrdensPage();

  @override
  State<_OrdensPage> createState() => _OrdensPageState();
}

class _OrdensPageState extends State<_OrdensPage> {
  late final PagedController<OrdemServico> _ctrl = PagedController(
    pageSize: 20,
    fetch: (page, _) => context.read<AreaClienteRepository>().ordens(page: page),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _novaOs() async {
    final id = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const _NovaOsPage()));
    if (id != null) _ctrl.refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Minhas OS')),
        floatingActionButton: FloatingActionButton(onPressed: _novaOs, tooltip: 'Abrir OS', child: const Icon(Icons.add_rounded)),
        body: PagedListView<OrdemServico>(
          controller: _ctrl,
          empty: (_) => const EmptyView(icon: Icons.assignment_outlined, title: 'Nenhuma ordem de serviço', message: 'Quando a assistência abrir uma OS para você, ela aparece aqui.'),
          itemBuilder: (context, os) => OsCard(os: os, destino: (id) => _OsPage(id: id), onChanged: _ctrl.refresh),
        ),
      );
}

class _NovaOsPage extends StatefulWidget {
  const _NovaOsPage();

  @override
  State<_NovaOsPage> createState() => _NovaOsPageState();
}

class _NovaOsPageState extends State<_NovaOsPage> {
  final _form = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  final _defeito = TextEditingController();
  final _observacoes = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    for (final c in [_descricao, _defeito, _observacoes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final id = await context.read<AreaClienteRepository>().abrirOs(descricao: _descricao.text.trim(), defeito: _defeito.text.trim(), observacoes: _observacoes.text.trim());
      if (!mounted) return;
      Toast.success(context, 'OS #$id aberta. A assistência vai entrar em contato.');
      Navigator.pop(context, id);
    } catch (e) {
      if (mounted) Toast.error(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Abrir ordem de serviço')),
        bottomNavigationBar: BottomActionBar(child: LoadingButton(label: 'Enviar', icon: Icons.send_rounded, loading: _salvando, onPressed: _enviar)),
        body: Form(
          key: _form,
          child: ListView(
            padding: Gaps.pageOf(context),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _descricao,
                      label: 'Equipamento ou serviço',
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Conte o que precisa de atendimento.' : null,
                    ),
                    const SizedBox(height: Gaps.md),
                    AppTextField(controller: _defeito, label: 'Qual o problema?', maxLines: 3, textCapitalization: TextCapitalization.sentences),
                    const SizedBox(height: Gaps.md),
                    AppTextField(controller: _observacoes, label: 'Observações', maxLines: 3, textCapitalization: TextCapitalization.sentences),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _OsPage extends StatefulWidget {
  const _OsPage({required this.id});

  final int id;

  @override
  State<_OsPage> createState() => _OsPageState();
}

class _OsPageState extends State<_OsPage> {
  late Future<OrdemServico> _os = context.read<AreaClienteRepository>().os(widget.id);

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AreaClienteRepository>();
    return Scaffold(
      appBar: AppBar(title: Text('OS #${widget.id}')),
      body: AsyncView<OrdemServico>(
        future: _os,
        onRetry: () => setState(() => _os = repo.os(widget.id)),
        builder: (context, os) => ListView(
          padding: Gaps.pageOf(context),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(Gaps.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [StatusChip(os.status), const Spacer(), Text(Fmt.money(os.total), style: context.text.titleLarge)]),
                        const SizedBox(height: Gaps.md),
                        InfoRow(icon: Icons.event_outlined, label: 'Entrada', value: Fmt.date(os.dataInicial)),
                        InfoRow(icon: Icons.event_available_outlined, label: 'Previsão', value: Fmt.date(os.dataFinal)),
                        if (os.garantiaAte != null) InfoRow(icon: Icons.verified_user_outlined, label: 'Garantia até', value: Fmt.date(os.garantiaAte)),
                        InfoRow(icon: Icons.engineering_outlined, label: 'Técnico', value: os.responsavel),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gaps.md),
                  if (os.total > 0 && !os.faturado)
                    FilledButton.icon(
                      onPressed: () => showPixSheet(context, carregar: () => repo.pixDaOs(os.id), titulo: 'Pagar a OS #${os.id}'),
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: const Text('Pagar com PIX'),
                    ),
                  const SectionHeader('Detalhes'),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextBlock(title: 'Equipamento', text: os.descricaoProduto, icon: Icons.devices_other_outlined),
                        const Divider(height: Gaps.xl),
                        TextBlock(title: 'Defeito', text: os.defeito, icon: Icons.report_problem_outlined),
                        if (os.laudoTecnico.isNotEmpty) ...[
                          const Divider(height: Gaps.xl),
                          TextBlock(title: 'Laudo técnico', text: os.laudoTecnico, icon: Icons.fact_check_outlined),
                        ],
                      ],
                    ),
                  ),
                  if (os.produtos.isNotEmpty || os.servicos.isNotEmpty) ...[
                    const SectionHeader('Itens'),
                    _Itens(itens: [...os.produtos, ...os.servicos], desconto: os.valorDoDesconto, total: os.total),
                  ],
                  if (os.anexos.isNotEmpty) ...[
                    const SectionHeader('Anexos'),
                    Wrap(
                      spacing: Gaps.sm,
                      runSpacing: Gaps.sm,
                      children: [for (final a in os.anexos) _Anexo(anexo: a, carregar: repo.anexo)],
                    ),
                  ],
                  if (os.historico.isNotEmpty) ...[
                    const SectionHeader('Andamento'),
                    AppCard(
                      child: Column(
                        children: [
                          for (final h in os.historico)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(StatusColors.icon(h.novo), color: StatusColors.of(h.novo)),
                              title: Text(h.novo),
                              subtitle: Text(Fmt.dateTime(h.dataHora)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Itens extends StatelessWidget {
  const _Itens({required this.itens, required this.desconto, required this.total});

  final List<OsItem> itens;
  final double desconto;
  final double total;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: [
            for (final i in itens)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(i.nome),
                subtitle: Text('${Fmt.number(i.quantidade)} × ${Fmt.money(i.preco)}'),
                trailing: Text(Fmt.money(i.subTotal)),
              ),
            if (desconto > 0) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: const Text('Desconto'), trailing: Text('- ${Fmt.money(desconto)}')),
            const Divider(),
            ListTile(dense: true, contentPadding: EdgeInsets.zero, title: const Text('Total'), trailing: Text(Fmt.money(total), style: context.text.titleMedium)),
          ],
        ),
      );
}

class _Anexo extends StatelessWidget {
  const _Anexo({required this.anexo, required this.carregar});

  final Anexo anexo;
  final Future<Uint8List> Function(String url) carregar;

  @override
  Widget build(BuildContext context) {
    if (!anexo.isImage) {
      return ActionChip(avatar: const Icon(Icons.attach_file_rounded, size: 18), label: Text(anexo.nome), onPressed: null);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(Gaps.radiusSm),
      child: FutureBuilder<Uint8List>(
        future: carregar(anexo.thumbUrl),
        builder: (context, snap) => snap.hasData
            ? Image.memory(snap.data!, width: 96, height: 96, fit: BoxFit.cover)
            : Container(width: 96, height: 96, color: context.tokens.muted.withValues(alpha: 0.1)),
      ),
    );
  }
}

class _ComprasPage extends StatefulWidget {
  const _ComprasPage();

  @override
  State<_ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<_ComprasPage> {
  late final PagedController<Venda> _ctrl = PagedController(pageSize: 20, fetch: (page, _) => context.read<AreaClienteRepository>().compras(page: page))..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Compras')),
        body: PagedListView<Venda>(
          controller: _ctrl,
          empty: (_) => const EmptyView(icon: Icons.shopping_bag_outlined, title: 'Nenhuma compra', message: 'Suas compras na assistência aparecem aqui.'),
          itemBuilder: (context, v) => _CompraCard(venda: v),
        ),
      );
}

class _CompraCard extends StatelessWidget {
  const _CompraCard({required this.venda});

  final Venda venda;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _CompraPage(id: venda.id))),
        padding: const EdgeInsets.all(Gaps.lg),
        child: Row(
          children: [
            const IconBadge(Icons.shopping_bag_outlined, color: AppColors.produtos, size: 40),
            const SizedBox(width: Gaps.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Compra #${venda.id}', style: context.text.titleSmall),
                  Text(Fmt.date(venda.dataVenda), style: context.text.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [Text(Fmt.money(venda.total), style: context.text.titleSmall), StatusChip(venda.status, dense: true)],
            ),
          ],
        ),
      );
}

class _CompraPage extends StatelessWidget {
  const _CompraPage({required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AreaClienteRepository>();
    return Scaffold(
      appBar: AppBar(title: Text('Compra #$id')),
      body: AsyncView<Venda>(
        future: repo.compra(id),
        onRetry: () => (context as Element).markNeedsBuild(),
        builder: (context, v) => ListView(
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
                        InfoRow(icon: Icons.event_outlined, label: 'Data', value: Fmt.date(v.dataVenda)),
                        if (v.garantiaAte != null) InfoRow(icon: Icons.verified_user_outlined, label: 'Garantia até', value: Fmt.date(v.garantiaAte)),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gaps.md),
                  if (v.total > 0 && !v.faturado)
                    FilledButton.icon(
                      onPressed: () => showPixSheet(context, carregar: () => repo.pixDaCompra(v.id), titulo: 'Pagar a compra #${v.id}'),
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: const Text('Pagar com PIX'),
                    ),
                  const SectionHeader('Produtos'),
                  _Itens(itens: v.produtos, desconto: v.valorDoDesconto, total: v.total),
                  if (v.observacoesCliente.isNotEmpty) ...[
                    const SectionHeader('Observações'),
                    AppCard(child: Text(v.observacoesCliente)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CobrancasPage extends StatefulWidget {
  const _CobrancasPage();

  @override
  State<_CobrancasPage> createState() => _CobrancasPageState();
}

class _CobrancasPageState extends State<_CobrancasPage> {
  late final PagedController<Cobranca> _ctrl = PagedController(pageSize: 20, fetch: (page, _) => context.read<AreaClienteRepository>().cobrancas(page: page))..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cobranças')),
        body: PagedListView<Cobranca>(
          controller: _ctrl,
          empty: (_) => const EmptyView(icon: Icons.receipt_long_outlined, title: 'Nenhuma cobrança', message: 'Boletos e links de pagamento aparecem aqui.'),
          itemBuilder: (context, c) => AppCard(
            padding: const EdgeInsets.all(Gaps.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.origem, style: context.text.titleSmall)),
                    Text(Fmt.money(c.valor), style: context.text.titleSmall),
                  ],
                ),
                const SizedBox(height: Gaps.xs),
                Text([c.situacao, if (c.vencimento != null) 'vence ${Fmt.date(c.vencimento)}', c.formaPagamento].where((s) => s.isNotEmpty).join(' · '), style: context.text.bodySmall),
                if (!c.paga && c.link.isNotEmpty) ...[
                  const SizedBox(height: Gaps.md),
                  OutlinedButton.icon(onPressed: () => Launch.url(c.link), icon: const Icon(Icons.open_in_new_rounded), label: const Text('Abrir para pagar')),
                ],
              ],
            ),
          ),
        ),
      );
}

class _ContaPage extends StatefulWidget {
  const _ContaPage();

  @override
  State<_ContaPage> createState() => _ContaPageState();
}

class _ContaPageState extends State<_ContaPage> {
  late Future<Cliente> _cliente = context.read<AreaClienteRepository>().conta();

  void _recarregar() => setState(() => _cliente = context.read<AreaClienteRepository>().conta());

  Future<void> _sair() async {
    final ok = await confirmDialog(context, title: 'Sair da conta?', message: 'Você vai precisar entrar de novo.', confirmLabel: 'Sair');
    if (ok && mounted) await context.read<AuthState>().logout();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Minha conta')),
        body: AsyncView<Cliente>(
          future: _cliente,
          onRetry: _recarregar,
          builder: (context, c) => ListView(
            padding: Gaps.pageOf(context),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: InitialsAvatar(c.nome, size: 80)),
                    const SizedBox(height: Gaps.md),
                    Text(c.nome, style: context.text.headlineSmall, textAlign: TextAlign.center),
                    Text(c.email, textAlign: TextAlign.center),
                    const SectionHeader('Dados'),
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.xs),
                      child: Column(
                        children: [
                          InfoRow(icon: Icons.badge_outlined, label: 'CPF/CNPJ', value: c.documento),
                          InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: c.telefone),
                          InfoRow(icon: Icons.smartphone_outlined, label: 'Celular', value: c.celular),
                          InfoRow(icon: Icons.location_on_outlined, label: 'Endereço', value: c.enderecoCompleto),
                        ],
                      ),
                    ),
                    const SizedBox(height: Gaps.md),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const Text('Editar meus dados'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () async {
                              final salvou = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => _EditarContaPage(cliente: c)));
                              if (salvou == true) _recarregar();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.devices_rounded),
                            title: const Text('Sessões ativas'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SessoesClientePage())),
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                            title: const Text('Sair', style: TextStyle(color: AppColors.danger)),
                            onTap: _sair,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _EditarContaPage extends StatefulWidget {
  const _EditarContaPage({required this.cliente});

  final Cliente cliente;

  @override
  State<_EditarContaPage> createState() => _EditarContaPageState();
}

class _EditarContaPageState extends State<_EditarContaPage> {
  late final _nome = TextEditingController(text: widget.cliente.nome);
  late final _email = TextEditingController(text: widget.cliente.email);
  late final _telefone = TextEditingController(text: widget.cliente.telefone);
  late final _celular = TextEditingController(text: widget.cliente.celular);
  final _senha = TextEditingController();
  final _senhaAtual = TextEditingController();
  bool _salvando = false;
  Map<String, String> _erros = const {};

  @override
  void dispose() {
    for (final c in [_nome, _email, _telefone, _celular, _senha, _senhaAtual]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _precisaSenhaAtual => _email.text.trim() != widget.cliente.email || _senha.text.isNotEmpty;

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erros = const {};
    });
    try {
      await context.read<AreaClienteRepository>().atualizarConta({
        'nome': _nome.text.trim(),
        'email': _email.text.trim(),
        'telefone': _telefone.text.trim(),
        'celular': _celular.text.trim(),
        if (_senha.text.isNotEmpty) 'senha': _senha.text,
        if (_precisaSenhaAtual) 'senha_atual': _senhaAtual.text,
      });
      if (!mounted) return;
      Toast.success(context, 'Dados salvos.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erros = e.erros);
      if (mounted && e.erros.isEmpty) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _campo(TextEditingController c, String rotulo, String chave, {bool senha = false, TextInputType? teclado}) => Padding(
        padding: const EdgeInsets.only(bottom: Gaps.md),
        child: TextField(
          controller: c,
          obscureText: senha,
          keyboardType: teclado,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: rotulo, errorText: _erros[chave]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Editar meus dados')),
        bottomNavigationBar: BottomActionBar(child: LoadingButton(label: 'Salvar', icon: Icons.check_rounded, loading: _salvando, onPressed: _salvar)),
        body: ListView(
          padding: Gaps.pageOf(context),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _campo(_nome, 'Nome', 'nome'),
                  _campo(_email, 'E-mail', 'email', teclado: TextInputType.emailAddress),
                  _campo(_telefone, 'Telefone', 'telefone', teclado: TextInputType.phone),
                  _campo(_celular, 'Celular', 'celular', teclado: TextInputType.phone),
                  _campo(_senha, 'Nova senha (opcional)', 'senha', senha: true),
                  if (_precisaSenhaAtual) _campo(_senhaAtual, 'Senha atual', 'senha_atual', senha: true),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SessoesClientePage extends StatefulWidget {
  const _SessoesClientePage();

  @override
  State<_SessoesClientePage> createState() => _SessoesClientePageState();
}

class _SessoesClientePageState extends State<_SessoesClientePage> {
  late Future<List<Sessao>> _sessoes = context.read<AreaClienteRepository>().sessoes();

  void _recarregar() => setState(() => _sessoes = context.read<AreaClienteRepository>().sessoes());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sessões ativas')),
        body: AsyncView<List<Sessao>>(
          future: _sessoes,
          onRetry: _recarregar,
          builder: (context, sessoes) => ListView(
            padding: Gaps.pageOf(context),
            children: [
              for (final s in sessoes)
                ListTile(
                  leading: Icon(s.atual ? Icons.smartphone_rounded : Icons.devices_other_outlined),
                  title: Text(s.rotulo),
                  subtitle: Text([if (s.atual) 'Este aparelho', 'Último uso ${Fmt.dateTime(s.ultimoUso)}'].join(' · ')),
                  trailing: s.atual
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.logout_rounded),
                          onPressed: () async {
                            final ok = await runAction(context, () => context.read<AreaClienteRepository>().encerrarSessao(s.id), success: 'Sessão encerrada.');
                            if (ok) _recarregar();
                          },
                        ),
                ),
            ],
          ),
        ),
      );
}
