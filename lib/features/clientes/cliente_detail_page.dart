import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/utils/launchers.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/cliente.dart';
import '../../data/repositories/cadastros_repository.dart';
import '../../data/models/ordem_servico.dart';
import '../os/os_detail_page.dart';
import '../os/os_form_page.dart';
import 'cliente_form_page.dart';

class ClienteDetailPage extends StatefulWidget {
  const ClienteDetailPage({super.key, required this.clienteId});

  final int clienteId;

  @override
  State<ClienteDetailPage> createState() => _ClienteDetailPageState();
}

class _ClienteDetailPageState extends State<ClienteDetailPage> {
  late Future<Cliente> _future = _load();
  bool _changed = false;
  bool _showAllOs = false;

  Future<Cliente> _load() => context.read<ClientesRepository>().get(widget.clienteId);

  void _reload() => setState(() => _future = _load());

  Future<void> _edit(Cliente c) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ClienteFormPage(cliente: c)));
    if (saved == true) {
      _changed = true;
      _reload();
    }
  }

  Future<void> _delete(Cliente c) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir cliente?',
      message: '"${c.nome}" será removido permanentemente.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runAction(context, () => context.read<ClientesRepository>().delete(c.id), success: 'Cliente excluído.');
    if (done && mounted) Navigator.pop(context, true);
  }

  Future<void> _openOs(int id) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => OsDetailPage(osId: id)));
    if (mounted) _reload();
  }

  Future<void> _newOs(Cliente c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OsFormPage(clienteId: c.id, clienteNome: c.nome)),
    );
    if (mounted) _reload();
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    Toast.info(context, 'Copiado');
  }

  Widget _osSection(BuildContext context, Cliente c) {
    final perms = context.read<AuthState>().permissions;
    final ordens = c.ordens;
    final visible = _showAllOs ? ordens : ordens.take(5).toList();
    bool isClosed(OrdemServico o) {
      final st = o.status.toLowerCase();
      return st.contains('finalizado') || st.contains('faturado') || st.contains('cancelado');
    }

    final abertas = ordens.where((o) => !isClosed(o)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Ordens de serviço · ${c.totalOs > ordens.length ? c.totalOs : ordens.length}',
          action: perms.canAdd('Os') ? 'Nova OS' : null,
          onAction: () => _newOs(c),
        ),
        if (ordens.isEmpty)
          AppCard(
            child: Row(
              children: [
                Icon(Icons.assignment_outlined, color: context.tokens.muted),
                const SizedBox(width: Gaps.md),
                Expanded(
                  child: Text(
                    'Este cliente ainda não tem ordens de serviço.',
                    style: context.text.bodyMedium?.copyWith(color: context.tokens.muted),
                  ),
                ),
              ],
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(child: _OsStat(label: 'Total', value: c.totalOs > ordens.length ? c.totalOs : ordens.length, color: AppColors.os)),
              const SizedBox(width: Gaps.sm),
              Expanded(child: _OsStat(label: 'Em aberto', value: abertas, color: AppColors.info)),
              const SizedBox(width: Gaps.sm),
              Expanded(child: _OsStat(label: 'Concluídas', value: ordens.length - abertas, color: AppColors.success)),
            ],
          ),
          const SizedBox(height: Gaps.sm),
          Card(
            child: Column(
              children: [
                for (final (i, o) in visible.indexed) ...[
                  if (i > 0) const Divider(indent: Gaps.lg, endIndent: Gaps.lg),
                  _OsTile(os: o, onTap: () => _openOs(o.id)),
                ],
                if (ordens.length > 5) ...[
                  const Divider(height: 1),
                  TextButton.icon(
                    onPressed: () => setState(() => _showAllOs = !_showAllOs),
                    icon: Icon(_showAllOs ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                    label: Text(_showAllOs ? 'Mostrar menos' : 'Ver todas (${ordens.length})'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final perms = context.watch<AuthState>().permissions;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: FutureBuilder<Cliente>(
        future: _future,
        builder: (context, snap) {
          final c = snap.data;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cliente'),
              actions: [
                if (c != null && perms.canEdit('Cliente'))
                  IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(c)),
                if (c != null && perms.canDelete('Cliente'))
                  PopupMenuButton<String>(
                    onSelected: (_) => _delete(c),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                          title: Text('Excluir'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            body: snap.hasError
                ? ErrorView(error: snap.error!, onRetry: _reload)
                : c == null
                    ? const SkeletonList(count: 5)
                    : _content(context, c),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, Cliente c) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: Gaps.pageOf(context),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(Gaps.xl),
                  child: Column(
                    children: [
                      InitialsAvatar(c.nome, size: 72),
                      const SizedBox(height: Gaps.md),
                      Text(c.nome, style: context.text.titleLarge, textAlign: TextAlign.center),
                      const SizedBox(height: Gaps.xs),
                      Wrap(
                        spacing: Gaps.sm,
                        alignment: WrapAlignment.center,
                        children: [
                          _Tag(c.pessoaFisica ? 'Pessoa física' : 'Pessoa jurídica'),
                          if (c.fornecedor) const _Tag('Fornecedor'),
                          if (c.dataCadastro != null) _Tag('Desde ${Fmt.date(c.dataCadastro)}'),
                        ],
                      ),
                      if (c.phone.isNotEmpty || c.email.isNotEmpty) ...[
                        const SizedBox(height: Gaps.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (c.phone.isNotEmpty) ...[
                              _ActionButton(icon: Icons.call_outlined, label: 'Ligar', onTap: () => Launch.phone(c.phone)),
                              _ActionButton(
                                icon: Icons.chat_outlined,
                                label: 'WhatsApp',
                                color: const Color(0xFF25D366),
                                onTap: () => Launch.whatsapp(c.phone),
                              ),
                            ],
                            if (c.email.isNotEmpty)
                              _ActionButton(icon: Icons.mail_outline_rounded, label: 'E-mail', onTap: () => Launch.email(c.email)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SectionHeader('Contato'),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.xs),
                  child: Column(
                    children: [
                      InfoRow(
                        icon: Icons.badge_outlined,
                        label: c.pessoaFisica ? 'CPF' : 'CNPJ',
                        value: c.documento,
                        onTap: () => _copy(c.documento),
                        trailing: const Icon(Icons.copy_rounded, size: 18),
                      ),
                      InfoRow(icon: Icons.smartphone_outlined, label: 'Celular', value: c.celular, onTap: () => Launch.phone(c.celular)),
                      InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: c.telefone, onTap: () => Launch.phone(c.telefone)),
                      InfoRow(icon: Icons.mail_outline_rounded, label: 'E-mail', value: c.email, onTap: () => Launch.email(c.email)),
                      if (c.contato.isNotEmpty) InfoRow(icon: Icons.person_outline_rounded, label: 'Contato', value: c.contato),
                    ],
                  ),
                ),
                const SectionHeader('Endereço'),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.xs),
                  child: InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Endereço',
                    value: c.enderecoCompleto,
                    onTap: () => Launch.maps(c.enderecoCompleto.replaceAll('\n', ', ')),
                    trailing: const Icon(Icons.map_outlined, size: 18),
                  ),
                ),
                _osSection(context, c),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _OsStat extends StatelessWidget {
  const _OsStat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.md, vertical: Gaps.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: context.text.titleLarge?.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          Text(label, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _OsTile extends StatelessWidget {
  const _OsTile({required this.os, required this.onTap});

  final OrdemServico os;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final desc = os.descricaoProduto.isNotEmpty ? Fmt.plain(os.descricaoProduto) : Fmt.plain(os.defeito);
    final color = StatusColors.of(os.status);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.md),
        child: Row(
          children: [
            IconBadge(StatusColors.icon(os.status), color: color, size: 38),
            const SizedBox(width: Gaps.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('OS #${os.id}', style: context.text.titleSmall),
                      if (os.dataInicial != null) ...[
                        Text('  ·  ', style: context.text.bodySmall),
                        Text(Fmt.date(os.dataInicial), style: context.text.bodySmall),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc.isEmpty ? 'Sem descrição' : desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gaps.sm),
            StatusChip(os.status, dense: true),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: Gaps.xs),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: context.tokens.subtle, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: context.text.labelSmall?.copyWith(color: context.tokens.muted)),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(Gaps.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gaps.sm),
          child: Column(
            children: [
              IconBadge(icon, color: c, size: 44),
              const SizedBox(height: 6),
              Text(label, style: context.text.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
