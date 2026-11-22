import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_state.dart';
import '../../core/utils/launchers.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/ordem_servico.dart';
import '../../data/repositories/os_repository.dart';
import '../clientes/cliente_detail_page.dart';
import 'os_form_page.dart';
import 'widgets/os_anexos_tab.dart';
import 'widgets/os_dialogs.dart';
import 'widgets/os_items_tab.dart';
import 'widgets/os_notas_tab.dart';

class OsDetailPage extends StatefulWidget {
  const OsDetailPage({super.key, required this.osId});

  final int osId;

  @override
  State<OsDetailPage> createState() => _OsDetailPageState();
}

class _OsDetailPageState extends State<OsDetailPage> {
  OrdemServico? _os;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final os = await context.read<OsRepository>().get(widget.osId);
      if (mounted) {
        setState(() {
          _os = os;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  OsInput _inputFrom(OrdemServico os, {String? status}) => OsInput(
        clienteId: os.clienteId,
        usuarioId: os.usuarioId,
        status: status ?? os.status,
        dataInicial: os.dataInicial ?? DateTime.now(),
        dataFinal: os.dataFinal ?? os.dataInicial ?? DateTime.now(),
        descricaoProduto: os.descricaoProduto,
        defeito: os.defeito,
        observacoes: os.observacoes,
        laudoTecnico: os.laudoTecnico,
        garantia: os.garantia,
      );

  Future<void> _changeStatus(OrdemServico os) async {
    final s = await showStatusSheet(context, os.status);
    if (s == null || s == os.status || !mounted) return;
    final ok = await runAction(
      context,
      () => context.read<OsRepository>().update(os.id, _inputFrom(os, status: s)),
      success: 'Status alterado para "$s".',
    );
    if (ok) await _reload();
  }

  Future<void> _edit(OrdemServico os) async {
    final id = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => OsFormPage(os: os)));
    if (id != null) await _reload();
  }

  Future<void> _desconto(OrdemServico os) async {
    final r = await showDescontoSheet(context, subtotal: os.subtotal, descontoAtual: os.desconto, tipoAtual: os.tipoDesconto);
    if (r == null || !mounted) return;
    final ok = await runAction(
      context,
      () => context.read<OsRepository>().aplicarDesconto(os.id, desconto: r.$1, tipo: r.$2, valorFinal: r.$3),
      success: 'Desconto aplicado.',
    );
    if (ok) await _reload();
  }

  Future<void> _delete(OrdemServico os) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir OS #${os.id}?',
      message: 'A ordem de serviço e todos os seus itens serão removidos permanentemente.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runAction(context, () => context.read<OsRepository>().delete(os.id), success: 'OS excluída.');
    if (done && mounted) Navigator.pop(context, true);
  }

  void _share(OrdemServico os) {
    final b = StringBuffer()
      ..writeln('*Ordem de Serviço #${os.id}*')
      ..writeln('Status: ${os.status}')
      ..writeln('Cliente: ${os.nomeCliente}')
      ..writeln('Período: ${Fmt.date(os.dataInicial)} a ${Fmt.date(os.dataFinal)}');
    final desc = Fmt.plain(os.descricaoProduto);
    if (desc.isNotEmpty) b.writeln('Equipamento: $desc');
    final def = Fmt.plain(os.defeito);
    if (def.isNotEmpty) b.writeln('Defeito: $def');
    if (os.produtos.isNotEmpty) {
      b.writeln('\n*Produtos*');
      for (final p in os.produtos) {
        b.writeln('• ${Fmt.number(p.quantidade)}× ${p.nome} — ${Fmt.money(p.subTotal)}');
      }
    }
    if (os.servicos.isNotEmpty) {
      b.writeln('\n*Serviços*');
      for (final s in os.servicos) {
        b.writeln('• ${Fmt.number(s.quantidade)}× ${s.nome} — ${Fmt.money(s.subTotal)}');
      }
    }
    if (os.temDesconto) b.writeln('\nDesconto: -${Fmt.money(os.valorDoDesconto)}');
    b.writeln('\n*Total: ${Fmt.money(os.total)}*');
    SharePlus.instance.share(ShareParams(text: b.toString(), subject: 'OS #${os.id}'));
  }

  @override
  Widget build(BuildContext context) {
    final os = _os;
    final perms = context.watch<AuthState>().permissions;
    final canEdit = perms.canEdit('Os');

    if (os == null) {
      return Scaffold(
        appBar: AppBar(title: Text('OS #${widget.osId}')),
        body: _error != null ? ErrorView(error: _error!, onRetry: _reload) : const SkeletonList(count: 5),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('OS #${os.id}'),
          actions: [
            IconButton(tooltip: 'Compartilhar', icon: const Icon(Icons.ios_share_rounded), onPressed: () => _share(os)),
            if (canEdit) IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(os)),
            if (perms.canDelete('Os'))
              PopupMenuButton<String>(
                onSelected: (_) => _delete(os),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                      title: Text('Excluir OS'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: ContentWidth(
                maxWidth: 900,
                child: _Header(
                  os: os,
                  canEdit: canEdit,
                  onStatus: () => _changeStatus(os),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsDelegate(
                color: context.theme.scaffoldBackgroundColor,
                tabs: TabBar(
                  isScrollable: true,
                  tabs: [
                    const Tab(text: 'Resumo'),
                    Tab(text: 'Produtos · ${os.produtos.length}'),
                    Tab(text: 'Serviços · ${os.servicos.length}'),
                    Tab(text: 'Anexos · ${os.anexos.length}'),
                    Tab(text: 'Notas · ${os.anotacoes.length}'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _wrap(_ResumoTab(os: os, canEdit: canEdit, onDesconto: () => _desconto(os))),
              _wrap(OsItemsTab(os: os, kind: OsItemKind.produto, canEdit: canEdit, onChanged: _reload)),
              _wrap(OsItemsTab(os: os, kind: OsItemKind.servico, canEdit: canEdit, onChanged: _reload)),
              _wrap(OsAnexosTab(os: os, canEdit: canEdit, onChanged: _reload)),
              _wrap(OsNotasTab(os: os, canEdit: canEdit, onChanged: _reload)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wrap(Widget child) => RefreshIndicator(
        onRefresh: _reload,
        notificationPredicate: (n) => n.depth == 0,
        child: ContentWidth(maxWidth: 900, child: child),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.os, required this.canEdit, required this.onStatus});

  final OrdemServico os;
  final bool canEdit;
  final VoidCallback onStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gaps.lg, Gaps.xs, Gaps.lg, Gaps.md),
      child: AppCard(
        padding: const EdgeInsets.all(Gaps.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: canEdit ? onStatus : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip(os.status),
                      if (canEdit) Icon(Icons.expand_more_rounded, size: 18, color: context.tokens.muted),
                    ],
                  ),
                ),
                const Spacer(),
                if (os.faturado)
                  const StatusChip('Faturado', dense: true),
              ],
            ),
            const SizedBox(height: Gaps.lg),
            InkWell(
              borderRadius: BorderRadius.circular(Gaps.radiusSm),
              onTap: os.clienteId > 0
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClienteDetailPage(clienteId: os.clienteId)))
                  : null,
              child: Row(
                children: [
                  InitialsAvatar(os.nomeCliente, size: 44),
                  const SizedBox(width: Gaps.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(os.nomeCliente, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(os.phone.isEmpty ? 'Sem telefone' : os.phone, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  if (os.phone.isNotEmpty) ...[
                    IconButton.filledTonal(
                      tooltip: 'Ligar',
                      icon: const Icon(Icons.call_outlined, size: 20),
                      onPressed: () => Launch.phone(os.phone),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filled(
                      tooltip: 'WhatsApp',
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                      icon: const Icon(Icons.chat_rounded, size: 20),
                      onPressed: () => Launch.whatsapp(os.phone, text: os.textoWhatsApp),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Gaps.lg),
            const Divider(),
            const SizedBox(height: Gaps.md),
            Row(
              children: [
                Expanded(child: _Meta(label: 'Entrada', value: Fmt.date(os.dataInicial))),
                Expanded(child: _Meta(label: 'Previsão', value: Fmt.date(os.dataFinal))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total', style: context.text.bodySmall),
                      const SizedBox(height: 2),
                      Text(Fmt.money(os.total), style: context.text.titleLarge?.copyWith(color: AppColors.accent)),
                    ],
                  ),
                ),
              ],
            ),
            if (os.responsavel.isNotEmpty) ...[
              const SizedBox(height: Gaps.md),
              Row(
                children: [
                  Icon(Icons.engineering_outlined, size: 16, color: context.tokens.muted),
                  const SizedBox(width: 6),
                  Text('Responsável: ${os.responsavel}', style: context.text.bodySmall),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: context.text.titleSmall),
        ],
      );
}

class _ResumoTab extends StatelessWidget {
  const _ResumoTab({required this.os, required this.canEdit, required this.onDesconto});

  final OrdemServico os;
  final bool canEdit;
  final VoidCallback onDesconto;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: Gaps.pageOf(context),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextBlock(title: 'Equipamento', text: os.descricaoProduto, icon: Icons.devices_other_outlined),
              const Padding(padding: EdgeInsets.symmetric(vertical: Gaps.lg), child: Divider()),
              TextBlock(title: 'Defeito relatado', text: os.defeito, icon: Icons.report_problem_outlined),
              const Padding(padding: EdgeInsets.symmetric(vertical: Gaps.lg), child: Divider()),
              TextBlock(title: 'Laudo técnico', text: os.laudoTecnico, icon: Icons.fact_check_outlined),
              const Padding(padding: EdgeInsets.symmetric(vertical: Gaps.lg), child: Divider()),
              TextBlock(title: 'Observações', text: os.observacoes, icon: Icons.notes_rounded),
              if (os.garantia.isNotEmpty) ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: Gaps.lg), child: Divider()),
                TextBlock(title: 'Garantia', text: '${os.garantia} dias', icon: Icons.verified_user_outlined),
              ],
            ],
          ),
        ),
        const SectionHeader('Valores'),
        AppCard(
          child: Column(
            children: [
              _line(context, 'Produtos', Fmt.money(os.totalProdutos)),
              _line(context, 'Serviços', Fmt.money(os.totalServicos)),
              if (os.temDesconto)
                _line(
                  context,
                  os.tipoDesconto == 'porcento' ? 'Desconto (${Fmt.number(os.desconto)}%)' : 'Desconto',
                  '- ${Fmt.money(os.valorDoDesconto)}',
                  color: AppColors.success,
                ),
              const Padding(padding: EdgeInsets.symmetric(vertical: Gaps.sm), child: Divider()),
              Row(
                children: [
                  Text('Total', style: context.text.titleMedium),
                  const Spacer(),
                  Text(Fmt.money(os.total), style: context.text.headlineSmall),
                ],
              ),
              if (canEdit && os.subtotal > 0) ...[
                const SizedBox(height: Gaps.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onDesconto,
                    icon: const Icon(Icons.local_offer_outlined),
                    label: Text(os.temDesconto ? 'Alterar desconto' : 'Aplicar desconto'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(BuildContext context, String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label, style: context.text.bodyMedium?.copyWith(color: context.tokens.muted)),
            const Spacer(),
            Text(value, style: context.text.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate({required this.tabs, required this.color});

  final TabBar tabs;
  final Color color;

  @override
  double get minExtent => tabs.preferredSize.height;
  @override
  double get maxExtent => tabs.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: color, child: tabs);

  @override
  bool shouldRebuild(covariant _TabsDelegate old) => old.tabs != tabs || old.color != color;
}
