import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/catalogo.dart';
import '../../data/models/conta.dart';
import '../../data/repositories/cadastros_repository.dart';
import '../agenda/agenda_page.dart';
import '../clientes/cliente_form_page.dart';
import '../garantias/garantias_pages.dart';
import '../os/os_detail_page.dart';
import '../os/os_form_page.dart';
import '../os/widgets/os_card.dart';
import '../produtos/produto_detail_page.dart';
import '../profile/account_menu.dart';
import '../servicos/servicos_page.dart';
import '../shell/home_shell.dart';
import '../vendas/vendas_pages.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<(DashboardData, Usuario?)> _future = _load();

  Future<(DashboardData, Usuario?)> _load() async {
    final repo = context.read<ContaRepository>();
    final permissoes = context.read<AuthState>().permissions;
    final results = await Future.wait([
      repo.dashboard(permissoes),
      repo.perfil().then<Usuario?>((u) => u).catchError((_) => null),
    ]);
    return (results[0] as DashboardData, results[1] as Usuario?);
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<(DashboardData, Usuario?)>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Header(usuario: data?.$2, data: data?.$1, onRefresh: _refresh)),
                if (snap.hasError && data == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(error: snap.error!, onRetry: _refresh),
                  )
                else if (data == null)
                  const SliverToBoxAdapter(child: SizedBox(height: 600, child: SkeletonList(count: 6)))
                else
                  SliverToBoxAdapter(
                    child: ContentWidth(
                      maxWidth: 980,
                      child: _Body(data: data.$1, onChanged: _refresh),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.usuario, required this.data, required this.onRefresh});

  final Usuario? usuario;
  final DashboardData? data;
  final VoidCallback onRefresh;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (usuario?.nome ?? '').split(' ').first;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: ContentWidth(
          maxWidth: 980,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gaps.xl, Gaps.lg, Gaps.lg, Gaps.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Fmt.dateShort(DateTime.now()).toUpperCase(),
                            style: context.text.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            firstName.isEmpty ? '$_greeting!' : '$_greeting, $firstName',
                            style: context.text.headlineSmall?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => showAccountMenu(context, usuario),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: InitialsAvatar(usuario?.nome ?? 'U', size: 40, imageUrl: usuario?.fotoUrl),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gaps.xl),
                const _OsQuickSearch(),
                const SizedBox(height: Gaps.md),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderStat(
                        icon: Icons.autorenew_rounded,
                        label: 'Em andamento',
                        value: data?.osAndamento.length,
                        color: const Color(0xFF60A5FA),
                        onTap: () => ShellScope.of(context)?.goTo(HomeShell.tabOs),
                      ),
                    ),
                    const SizedBox(width: Gaps.sm),
                    Expanded(
                      child: _HeaderStat(
                        icon: Icons.radio_button_unchecked_rounded,
                        label: 'Em aberto',
                        value: data?.osAbertas.length,
                        color: const Color(0xFF4ADE80),
                        onTap: () => ShellScope.of(context)?.goTo(HomeShell.tabOs),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OsQuickSearch extends StatefulWidget {
  const _OsQuickSearch();

  @override
  State<_OsQuickSearch> createState() => _OsQuickSearchState();
}

class _OsQuickSearchState extends State<_OsQuickSearch> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go() {
    final id = int.tryParse(_ctrl.text.trim());
    if (id == null || id <= 0) {
      Toast.error(context, 'Digite um número de OS válido.');
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.push(context, MaterialPageRoute(builder: (_) => OsDetailPage(osId: id)));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.go,
      onSubmitted: (_) => _go(),
      style: const TextStyle(color: Colors.white),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        hintText: 'Abrir OS pelo número',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        prefixIcon: Icon(Icons.tag_rounded, color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Gaps.radius),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Gaps.radius),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(6),
          child: IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: AppColors.accent),
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            onPressed: _go,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.data, required this.onChanged});

  final DashboardData data;
  final VoidCallback onChanged;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  VoidCallback? _abrir(BuildContext context, bool permitido, Widget pagina) =>
      permitido ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => pagina)) : null;

  bool _showAbertas = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final onChanged = widget.onChanged;
    final perms = context.watch<AuthState>().permissions;
    final shell = ShellScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 900 ? 6 : 3;

    final kpis = [
      (Icons.assignment_rounded, 'Ordens', data.countOs, AppColors.os, () => shell?.goTo(HomeShell.tabOs)),
      (Icons.people_rounded, 'Clientes', data.clientes, AppColors.clientes, () => shell?.goTo(HomeShell.tabClientes)),
      (Icons.inventory_2_rounded, 'Produtos', data.produtos, AppColors.produtos, () => shell?.goTo(HomeShell.tabProdutos)),
      (Icons.handyman_rounded, 'Serviços', data.servicos, AppColors.servicos, _abrir(context, perms.canView('Servico'), const ServicosPage())),
      (Icons.verified_user_rounded, 'Garantias', data.garantias, AppColors.garantias, _abrir(context, perms.canView('Garantia'), const GarantiasPage())),
      (Icons.point_of_sale_rounded, 'Vendas', data.vendas, AppColors.vendas, _abrir(context, perms.canView('Venda'), const VendasPage())),
    ];

    final actions = [
      if (perms.canAdd('Os'))
        (Icons.add_task_rounded, 'Nova OS', AppColors.os, () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const OsFormPage()));
          onChanged();
        }),
      if (perms.canAdd('Cliente'))
        (Icons.person_add_alt_rounded, 'Cliente', AppColors.clientes, () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ClienteFormPage()));
          onChanged();
        }),
      (Icons.calendar_month_rounded, 'Agenda', AppColors.garantias, () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AgendaPage()));
      }),
      (Icons.search_rounded, 'Ordens', AppColors.servicos, () async => shell?.goTo(HomeShell.tabOs)),
    ];

    final osItems = _showAbertas ? data.osAbertas : data.osAndamento;

    return Padding(
      padding: Gaps.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Atalhos', padding: EdgeInsets.fromLTRB(4, Gaps.sm, 4, Gaps.sm)),
          Row(
            children: [
              for (final (i, a) in actions.indexed) ...[
                if (i > 0) const SizedBox(width: Gaps.sm),
                Expanded(child: _QuickAction(icon: a.$1, label: a.$2, color: a.$3, onTap: a.$4)),
              ],
            ],
          ),
          const SectionHeader('Visão geral'),
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Gaps.sm,
            crossAxisSpacing: Gaps.sm,
            childAspectRatio: 1.05,
            children: [
              for (final k in kpis)
                _KpiTile(
                  icon: k.$1,
                  label: k.$2,
                  value: k.$3,
                  color: k.$4,
                  onTap: k.$5,
                ),
            ],
          ),
          SectionHeader('Ordens de serviço', action: 'Ver todas', onAction: () => shell?.goTo(HomeShell.tabOs)),
          _OsToggle(
            showAbertas: _showAbertas,
            andamento: data.osAndamento.length,
            abertas: data.osAbertas.length,
            onChanged: (v) => setState(() => _showAbertas = v),
          ),
          const SizedBox(height: Gaps.sm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: Column(
              key: ValueKey(_showAbertas),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (osItems.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: Gaps.xl, horizontal: Gaps.lg),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 36, color: context.tokens.muted),
                        const SizedBox(height: Gaps.sm),
                        Text(
                          _showAbertas ? 'Nenhuma OS em aberto.' : 'Nenhuma OS em andamento.',
                          style: context.text.bodyMedium?.copyWith(color: context.tokens.muted),
                        ),
                      ],
                    ),
                  )
                else
                  for (final os in osItems.take(5)) ...[
                    OsCard(os: os, onChanged: onChanged),
                    const SizedBox(height: Gaps.sm),
                  ],
              ],
            ),
          ),
          if (data.estoqueBaixo.isNotEmpty) ...[
            SectionHeader('Estoque baixo · ${data.estoqueBaixo.length}'),
            Card(
              child: Column(
                children: [
                  for (final (i, p) in data.estoqueBaixo.take(6).indexed) ...[
                    if (i > 0) const Divider(indent: Gaps.lg, endIndent: Gaps.lg),
                    _StockTile(produto: p),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.icon, required this.label, required this.value, required this.color, this.onTap});

  final IconData icon;
  final String label;
  final int? value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(Gaps.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Gaps.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.md, vertical: Gaps.md),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: Gaps.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    value == null
                        ? Container(
                            width: 24,
                            height: 18,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : _CountUp(
                            value: value!,
                            style: context.text.titleLarge?.copyWith(color: Colors.white, height: 1.1),
                          ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.65)),
                    ),
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

/// Número que "conta" até o valor ao aparecer.
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '${v.round()}',
        style: style?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

/// Alternador "Em andamento / Em aberto".
class _OsToggle extends StatelessWidget {
  const _OsToggle({required this.showAbertas, required this.andamento, required this.abertas, required this.onChanged});

  final bool showAbertas;
  final int andamento;
  final int abertas;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(bool value, String label, int count) {
      final selected = value == showAbertas;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? context.colors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(Gaps.radiusSm),
              border: Border.all(color: selected ? context.tokens.border : Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: context.text.labelLarge?.copyWith(
                    color: selected ? context.colors.onSurface : context.tokens.muted,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : context.tokens.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: context.text.labelSmall?.copyWith(
                      color: selected ? Colors.white : context.tokens.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.tokens.subtle,
        borderRadius: BorderRadius.circular(Gaps.radius),
      ),
      child: Row(
        children: [
          option(false, 'Em andamento', andamento),
          option(true, 'Em aberto', abertas),
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.produto});

  final Produto produto;

  @override
  Widget build(BuildContext context) {
    final p = produto;
    final ratio = p.estoqueMinimo <= 0 ? 0.0 : (p.estoque / p.estoqueMinimo).clamp(0.0, 1.0);
    final color = p.estoque <= 0 ? AppColors.danger : AppColors.warning;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProdutoDetailPage(produtoId: p.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.md),
        child: Row(
          children: [
            IconBadge(p.estoque <= 0 ? Icons.error_outline_rounded : Icons.warning_amber_rounded, color: color, size: 36),
            const SizedBox(width: Gaps.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.descricao, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.estoque <= 0
                        ? 'Sem estoque · mínimo ${Fmt.number(p.estoqueMinimo)} ${p.unidade}'
                        : '${Fmt.number(p.estoque)} de ${Fmt.number(p.estoqueMinimo)} ${p.unidade} (mínimo)',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.icon, required this.label, required this.value, required this.color, this.onTap});

  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(Gaps.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon, color: color, size: 34),
              const Spacer(),
              if (onTap != null) Icon(Icons.arrow_outward_rounded, size: 16, color: context.tokens.muted),
            ],
          ),
          const Spacer(),
          _CountUp(value: value, style: context.text.headlineSmall?.copyWith(fontSize: 22)),
          Text(label, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: Gaps.md, horizontal: Gaps.xs),
      onTap: onTap,
      child: Column(
        children: [
          IconBadge(icon, color: color, size: 42),
          const SizedBox(height: Gaps.sm),
          Text(label, style: context.text.labelMedium, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
