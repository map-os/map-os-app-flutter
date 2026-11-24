import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/widgets/ui.dart';
import '../admin/admin_pages.dart';
import '../agenda/agenda_page.dart';
import '../arquivos/arquivos_page.dart';
import '../cobrancas/cobrancas_page.dart';
import '../financeiro/financeiro_pages.dart';
import '../garantias/garantias_pages.dart';
import '../relatorios/relatorios_pages.dart';
import '../servicos/servicos_page.dart';
import '../vendas/vendas_pages.dart';

class MaisPage extends StatelessWidget {
  const MaisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AuthState>().permissions;
    final relatorios = tiposDeRelatorio.any((t) => p.can(t.permissao));
    final modulos = [
      if (p.canView('Venda')) (Icons.point_of_sale_rounded, 'Vendas', AppColors.vendas, () => const VendasPage()),
      if (p.canView('Lancamento')) (Icons.account_balance_wallet_rounded, 'Financeiro', AppColors.success, () => const FinanceiroPage()),
      if (p.canView('Cobranca')) (Icons.request_quote_rounded, 'Cobranças', AppColors.info, () => const CobrancasPage()),
      if (p.canView('Servico')) (Icons.handyman_rounded, 'Serviços', AppColors.servicos, () => const ServicosPage()),
      if (p.canView('Garantia')) (Icons.verified_user_rounded, 'Garantias', AppColors.garantias, () => const GarantiasPage()),
      if (p.canView('Arquivo')) (Icons.folder_rounded, 'Arquivos', AppColors.produtos, () => const ArquivosPage()),
      if (relatorios) (Icons.insights_rounded, 'Relatórios', AppColors.accent, () => const RelatoriosPage()),
      if (p.canView('Os')) (Icons.calendar_month_rounded, 'Agenda', AppColors.os, () => const AgendaPage()),
      if (podeAdministrar(p)) (Icons.admin_panel_settings_rounded, 'Administração', AppColors.clientes, () => const AdminPage()),
    ];
    final colunas = MediaQuery.sizeOf(context).width >= 700 ? 4 : 3;
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: modulos.isEmpty
          ? const EmptyView(icon: Icons.lock_outline_rounded, title: 'Nada por aqui', message: 'Seu usuário não tem acesso a outros módulos.')
          : ListView(
              padding: Gaps.pageOf(context),
              children: [
                ContentWidth(
                  child: GridView.count(
                    crossAxisCount: colunas,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: Gaps.sm,
                    crossAxisSpacing: Gaps.sm,
                    children: [
                      for (final (icone, rotulo, cor, pagina) in modulos)
                        AppCard(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => pagina())),
                          padding: const EdgeInsets.all(Gaps.md),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconBadge(icone, color: cor, size: 48),
                              const SizedBox(height: Gaps.sm),
                              Text(rotulo, style: context.text.titleSmall, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
