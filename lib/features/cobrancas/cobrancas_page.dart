import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/launchers.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/cobranca.dart';
import '../../data/repositories/gestao_repository.dart';
import '../../data/repositories/os_repository.dart';

Future<int?> showGerarCobrancaSheet(BuildContext context, {required String origem, required int origemId}) => showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _GerarCobranca(origem: origem, origemId: origemId),
    );

class _GerarCobranca extends StatefulWidget {
  const _GerarCobranca({required this.origem, required this.origemId});

  final String origem;
  final int origemId;

  @override
  State<_GerarCobranca> createState() => _GerarCobrancaState();
}

class _GerarCobrancaState extends State<_GerarCobranca> {
  late final Future<OpcoesDaOs> _opcoes = context.read<OsRepository>().opcoes();
  int? _escolhida;
  bool _gerando = false;

  Future<void> _gerar(OpcoesDaOs o) async {
    final c = o.cobrancas[_escolhida!];
    setState(() => _gerando = true);
    try {
      final cobranca = await context.read<CobrancasRepository>().gerar(origem: widget.origem, origemId: widget.origemId, gateway: c.gateway, forma: c.forma);
      if (!mounted) return;
      Toast.success(context, 'Cobrança #${cobranca.id} gerada.');
      Navigator.pop(context, cobranca.id);
    } catch (e) {
      if (mounted) Toast.error(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<OpcoesDaOs>(
          future: _opcoes,
          builder: (context, snap) {
            final o = snap.data;
            return Padding(
              padding: const EdgeInsets.fromLTRB(Gaps.xl, Gaps.lg, Gaps.xl, Gaps.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Gerar cobrança', style: context.text.titleLarge),
                  const SizedBox(height: Gaps.md),
                  if (snap.hasError)
                    Text(friendlyError(snap.error!))
                  else if (o == null)
                    const Center(child: CircularProgressIndicator())
                  else if (o.cobrancas.isEmpty)
                    const Text('Nenhum gateway de pagamento está configurado no MAP-OS. Configure em Configurações › Pagamentos no painel.')
                  else ...[
                    RadioGroup<int>(
                      groupValue: _escolhida,
                      onChanged: (v) => setState(() => _escolhida = v),
                      child: Column(
                        children: [
                          for (final (i, c) in o.cobrancas.indexed) RadioListTile<int>(value: i, contentPadding: EdgeInsets.zero, title: Text(c.nome), subtitle: Text(c.gateway)),
                        ],
                      ),
                    ),
                    const SizedBox(height: Gaps.md),
                    LoadingButton(label: 'Gerar', icon: Icons.request_quote_outlined, loading: _gerando, onPressed: _escolhida == null ? null : () => _gerar(o)),
                  ],
                ],
              ),
            );
          },
        ),
      );
}

class CobrancasPage extends StatefulWidget {
  const CobrancasPage({super.key});

  @override
  State<CobrancasPage> createState() => _CobrancasPageState();
}

class _CobrancasPageState extends State<CobrancasPage> {
  String? _origem;
  late final PagedController<Cobranca> _ctrl = PagedController(
    fetch: (page, search) => context.read<CobrancasRepository>().list(page: page, search: search, origem: _origem),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _acoes(Cobranca c) async {
    final perms = context.read<AuthState>().permissions;
    final repo = context.read<CobrancasRepository>();
    final acao = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('Cobrança #${c.id} · ${c.origem}'), subtitle: Text('${Fmt.money(c.valor)} · ${c.statusDescricao.isEmpty ? c.situacao : c.statusDescricao}')),
            const Divider(height: 1),
            if (c.link.isNotEmpty) ListTile(leading: const Icon(Icons.open_in_new_rounded), title: const Text('Abrir boleto ou link'), onTap: () => Navigator.pop(context, 'abrir')),
            if (c.codigoDeBarras.isNotEmpty) ListTile(leading: const Icon(Icons.copy_rounded), title: const Text('Copiar código de barras'), onTap: () => Navigator.pop(context, 'copiar')),
            if (perms.canEdit('Cobranca')) ...[
              ListTile(leading: const Icon(Icons.sync_rounded), title: const Text('Consultar status no gateway'), onTap: () => Navigator.pop(context, 'atualizar')),
              if (!c.paga) ListTile(leading: const Icon(Icons.task_alt_rounded), title: const Text('Confirmar pagamento'), onTap: () => Navigator.pop(context, 'confirmar-pagamento')),
              ListTile(leading: const Icon(Icons.mail_outline_rounded), title: const Text('Enviar por e-mail'), onTap: () => Navigator.pop(context, 'email')),
              if (!c.paga) ListTile(leading: const Icon(Icons.block_rounded), title: const Text('Cancelar no gateway'), onTap: () => Navigator.pop(context, 'cancelar')),
            ],
            if (perms.canDelete('Cobranca'))
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: const Text('Excluir', style: TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.pop(context, 'excluir'),
              ),
          ],
        ),
      ),
    );
    if (acao == null || !mounted) return;
    switch (acao) {
      case 'abrir':
        await Launch.url(c.link);
      case 'copiar':
        await Clipboard.setData(ClipboardData(text: c.codigoDeBarras));
        if (mounted) Toast.success(context, 'Código copiado.');
      case 'email':
        await runAction(context, () => repo.enviarEmail(c.id), success: 'E-mail na fila de envio.');
      case 'excluir':
        final ok = await confirmDialog(context, title: 'Excluir a cobrança #${c.id}?', message: 'Ela também é cancelada no gateway.', confirmLabel: 'Excluir', destructive: true);
        if (ok && mounted && await runAction(context, () => repo.delete(c.id), success: 'Cobrança excluída.')) _ctrl.refresh();
      case 'cancelar':
        final ok = await confirmDialog(context, title: 'Cancelar a cobrança #${c.id}?', message: 'O cliente não vai mais conseguir pagar por ela.', confirmLabel: 'Cancelar cobrança', destructive: true);
        if (ok && mounted && await runAction(context, () => repo.acao(c.id, acao), success: 'Cobrança cancelada.')) _ctrl.refresh();
      default:
        if (await runAction(context, () => repo.acao(c.id, acao), success: acao == 'atualizar' ? 'Status atualizado.' : 'Pagamento confirmado.')) _ctrl.refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cobranças')),
        body: PagedListView<Cobranca>(
          controller: _ctrl,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
            child: ContentWidthScroll(
              child: Column(
                children: [
                  SearchField(hint: 'Cliente, número ou id no gateway', onChanged: _ctrl.setSearch),
                  const SizedBox(height: Gaps.sm),
                  Row(
                    children: [
                      for (final (valor, rotulo) in [(null, 'Todas'), ('os', 'De OS'), ('venda', 'De vendas')])
                        Padding(
                          padding: const EdgeInsets.only(right: Gaps.sm),
                          child: ChoiceChip(
                            label: Text(rotulo),
                            selected: _origem == valor,
                            onSelected: (_) {
                              setState(() => _origem = valor);
                              _ctrl.refresh();
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          empty: (buscando) => EmptyView(
            icon: Icons.request_quote_outlined,
            title: buscando ? 'Nenhuma cobrança encontrada' : 'Nenhuma cobrança',
            message: buscando ? 'Tente outro termo.' : 'Gere cobranças pelo menu de uma OS ou venda.',
          ),
          itemBuilder: (context, c) => AppCard(
            onTap: () => _acoes(c),
            padding: const EdgeInsets.all(Gaps.lg),
            child: Row(
              children: [
                IconBadge(c.paga ? Icons.task_alt_rounded : Icons.request_quote_outlined, color: c.paga ? AppColors.success : AppColors.info, size: 40),
                const SizedBox(width: Gaps.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${c.id} · ${c.origem}', style: context.text.titleSmall),
                      Text(c.cliente, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        [c.statusDescricao.isEmpty ? c.situacao : c.statusDescricao, if (c.vencimento != null) 'vence ${Fmt.date(c.vencimento)}', c.gateway].where((s) => s.isNotEmpty).join(' · '),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(Fmt.money(c.valor), style: context.text.titleSmall),
              ],
            ),
          ),
        ),
      );
}
