import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/cliente.dart';
import '../../data/repositories/cadastros_repository.dart';
import 'cliente_detail_page.dart';
import 'cliente_form_page.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  late final PagedController<Cliente> _ctrl = PagedController(
    fetch: (page, search) => context.read<ClientesRepository>().list(page: page, search: search),
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
    final canAdd = context.watch<AuthState>().permissions.canAdd('Cliente');
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _open(const ClienteFormPage()),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Novo'),
            )
          : null,
      body: PagedListView<Cliente>(
        controller: _ctrl,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
          child: ContentWidthScroll(
            child: SearchField(hint: 'Buscar por nome, documento...', onChanged: _ctrl.setSearch),
          ),
        ),
        empty: (searching) => EmptyView(
          icon: Icons.people_outline_rounded,
          title: searching ? 'Nenhum cliente encontrado' : 'Nenhum cliente cadastrado',
          message: searching ? 'Tente outro termo de busca.' : 'Cadastre o primeiro cliente para começar.',
        ),
        itemBuilder: (context, c) => AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.md),
          onTap: () => _open(ClienteDetailPage(clienteId: c.id)),
          child: Row(
            children: [
              InitialsAvatar(c.nome),
              const SizedBox(width: Gaps.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.nome, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      [c.phone, c.documento].where((s) => s.isNotEmpty).join(' · ').ifEmpty('Sem contato'),
                      style: context.text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.tokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
