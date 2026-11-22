import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/conta.dart';
import '../../data/repositories/cadastros_repository.dart';
import '../clientes/clientes_page.dart';
import '../dashboard/dashboard_page.dart';
import '../os/os_list_page.dart';
import '../produtos/produtos_page.dart';
import '../profile/account_menu.dart';
import '../servicos/servicos_page.dart';

/// Permite que telas filhas troquem a aba ativa (ex.: "ver todas" no dashboard).
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.goTo, required super.child});

  final ValueChanged<int> goTo;

  static ShellScope? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const int tabInicio = 0;
  static const int tabOs = 1;
  static const int tabClientes = 2;
  static const int tabProdutos = 3;
  static const int tabServicos = 4;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _visited = <int>{0};

  /// Usuário logado — só para o rodapé da sidebar (telas largas).
  late final Future<Usuario?> _me =
      context.read<ContaRepository>().perfil().then<Usuario?>((u) => u).catchError((_) => null);

  static const _destinations = [
    (Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Início'),
    (Icons.assignment_outlined, Icons.assignment_rounded, 'Ordens'),
    (Icons.people_outline_rounded, Icons.people_rounded, 'Clientes'),
    (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Produtos'),
    (Icons.handyman_outlined, Icons.handyman_rounded, 'Serviços'),
  ];

  void _go(int i) => setState(() {
        _index = i;
        _visited.add(i);
      });

  Widget _page(int i) {
    // Abas são construídas sob demanda e mantidas vivas depois.
    if (!_visited.contains(i)) return const SizedBox.shrink();
    switch (i) {
      case 0:
        return const DashboardPage();
      case 1:
        return const OsListPage();
      case 2:
        return const ClientesPage();
      case 3:
        return const ProdutosPage();
      default:
        return const ServicosPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final body = IndexedStack(index: _index, children: List.generate(5, _page));

    return ShellScope(
      goTo: _go,
      child: PopScope(
        canPop: _index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _go(0);
        },
        child: wide
            ? Scaffold(
                body: Row(
                  children: [
                    _Sidebar(
                      index: _index,
                      extended: MediaQuery.sizeOf(context).width >= 1200,
                      destinations: _destinations,
                      onSelect: _go,
                      me: _me,
                    ),
                    VerticalDivider(width: 1, color: context.tokens.border),
                    Expanded(child: body),
                  ],
                ),
              )
            : Scaffold(
                body: body,
                bottomNavigationBar: DecoratedBox(
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: context.tokens.border))),
                  child: NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: _go,
                    destinations: [
                      for (final d in _destinations)
                        NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Sidebar das telas largas: logo, navegação e conta no rodapé.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.index,
    required this.extended,
    required this.destinations,
    required this.onSelect,
    required this.me,
  });

  final int index;
  final bool extended;
  final List<(IconData, IconData, String)> destinations;
  final ValueChanged<int> onSelect;
  final Future<Usuario?> me;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: extended ? 248 : 88,
      color: context.colors.surface,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(extended ? Gaps.lg : Gaps.lg, Gaps.lg, Gaps.lg, Gaps.xl),
              child: Row(
                mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(Gaps.radius)),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover, alignment: Alignment.centerLeft),
                  ),
                  if (extended) ...[
                    const SizedBox(width: Gaps.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppConfig.appName, style: context.text.titleMedium),
                          Text('Mobile', style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            for (final (i, d) in destinations.indexed)
              _SidebarItem(
                icon: i == index ? d.$2 : d.$1,
                label: d.$3,
                selected: i == index,
                extended: extended,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(Gaps.md),
              child: FutureBuilder<Usuario?>(
                future: me,
                builder: (context, snap) {
                  final u = snap.data;
                  return Material(
                    color: context.tokens.subtle,
                    borderRadius: BorderRadius.circular(Gaps.radius),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Gaps.radius),
                      onTap: () => showAccountMenu(context, u),
                      child: Padding(
                        padding: const EdgeInsets.all(Gaps.sm),
                        child: Row(
                          mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                          children: [
                            InitialsAvatar(u?.nome ?? 'U', size: 36, imageUrl: u?.fotoUrl),
                            if (extended) ...[
                              const SizedBox(width: Gaps.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u?.nome ?? 'Minha conta',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.titleSmall,
                                    ),
                                    Text(
                                      u?.email ?? 'Perfil e ajustes',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.unfold_more_rounded, size: 18, color: context.tokens.muted),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : context.tokens.muted;
    final item = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: extended ? 46 : 56,
      padding: EdgeInsets.symmetric(horizontal: extended ? Gaps.md : 0),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(Gaps.radiusSm),
      ),
      child: extended
          ? Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: Gaps.md),
                Expanded(
                  child: Text(
                    label,
                    style: context.text.labelLarge?.copyWith(
                      color: selected ? context.colors.onSurface : context.tokens.muted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: context.text.labelSmall?.copyWith(
                    color: selected ? context.colors.onSurface : context.tokens.muted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.md, vertical: 2),
      child: Tooltip(
        message: extended ? '' : label,
        child: InkWell(borderRadius: BorderRadius.circular(Gaps.radiusSm), onTap: onTap, child: item),
      ),
    );
  }
}
