import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/ordem_servico.dart';
import '../../data/repositories/os_repository.dart';
import 'os_detail_page.dart';
import 'os_form_page.dart';
import 'widgets/os_card.dart';

class OsListPage extends StatefulWidget {
  const OsListPage({super.key});

  @override
  State<OsListPage> createState() => _OsListPageState();
}

class _OsListPageState extends State<OsListPage> {
  String? _status;

  late final PagedController<OrdemServico> _ctrl = PagedController(
    pageSize: OsRepository.perPage,
    fetch: (page, search) => context.read<OsRepository>().list(page: page, search: search, status: _status),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setStatus(String? s) {
    setState(() => _status = s);
    _ctrl.refresh();
  }

  Future<void> _create() async {
    final id = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const OsFormPage()));
    if (id == null || !mounted) return;
    _ctrl.refresh();
    if (id > 0) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => OsDetailPage(osId: id)));
      _ctrl.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = context.watch<AuthState>().permissions.canAdd('Os');
    return Scaffold(
      appBar: AppBar(title: const Text('Ordens de serviço')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova OS'),
            )
          : null,
      body: PagedListView<OrdemServico>(
        controller: _ctrl,
        header: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
              child: ContentWidthScroll(child: SearchField(hint: 'Buscar por cliente ou nº', onChanged: _ctrl.setSearch)),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
                children: [
                  _filter(null, 'Todas'),
                  for (final s in StatusColors.all) _filter(s, s),
                ],
              ),
            ),
            const SizedBox(height: Gaps.xs),
          ],
        ),
        empty: (searching) => EmptyView(
          icon: Icons.assignment_outlined,
          title: searching || _status != null ? 'Nenhuma OS encontrada' : 'Nenhuma OS cadastrada',
          message: _status != null ? 'Não há ordens com status "$_status".' : null,
          actionLabel: _status != null ? 'Limpar filtro' : null,
          onAction: () => _setStatus(null),
        ),
        itemBuilder: (context, os) => OsCard(os: os, onChanged: _ctrl.refresh),
      ),
    );
  }

  Widget _filter(String? value, String label) {
    final selected = _status == value;
    final color = value == null ? AppColors.brand : StatusColors.of(value);
    return Padding(
      padding: const EdgeInsets.only(right: Gaps.sm),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        label: Text(label),
        avatar: value == null
            ? null
            : Icon(StatusColors.icon(value), size: 16, color: selected ? Colors.white : color),
        labelStyle: TextStyle(
          color: selected ? Colors.white : null,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        selectedColor: color,
        onSelected: (_) => _setStatus(value),
      ),
    );
  }
}
