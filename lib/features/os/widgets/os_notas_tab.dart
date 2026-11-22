import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/ui.dart';
import '../../../data/models/ordem_servico.dart';
import '../../../data/repositories/os_repository.dart';

class OsNotasTab extends StatefulWidget {
  const OsNotasTab({super.key, required this.os, required this.canEdit, required this.onChanged});

  final OrdemServico os;
  final bool canEdit;
  final Future<void> Function() onChanged;

  @override
  State<OsNotasTab> createState() => _OsNotasTabState();
}

class _OsNotasTabState extends State<OsNotasTab> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await context.read<OsRepository>().addAnotacao(widget.os.id, text);
      _ctrl.clear();
      await widget.onChanged();
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _remove(Anotacao n) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir anotação?',
      message: 'Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runAction(context, () => context.read<OsRepository>().removeAnotacao(widget.os.id, n.id));
    if (done) await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final notas = widget.os.anotacoes.reversed.toList();
    return Column(
      children: [
        Expanded(
          child: notas.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: Gaps.xl),
                    EmptyView(
                      icon: Icons.sticky_note_2_outlined,
                      title: 'Nenhuma anotação',
                      message: 'Registre o andamento do atendimento para a equipe.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: Gaps.pageOf(context),
                  itemCount: notas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Gaps.sm),
                  itemBuilder: (context, i) {
                    final n = notas[i];
                    final match = RegExp(r'^\[(.+?)\]\s*').firstMatch(n.texto);
                    final autor = match?.group(1) ?? '';
                    final texto = match == null ? n.texto : n.texto.substring(match.end);
                    return AppCard(
                      padding: const EdgeInsets.fromLTRB(Gaps.lg, Gaps.md, Gaps.xs, Gaps.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InitialsAvatar(autor.isEmpty ? '?' : autor, size: 34),
                          const SizedBox(width: Gaps.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (autor.isNotEmpty)
                                      Flexible(child: Text(autor, style: context.text.labelLarge, overflow: TextOverflow.ellipsis)),
                                    if (autor.isNotEmpty) const SizedBox(width: Gaps.sm),
                                    Text(Fmt.dateTime(n.dataHora), style: context.text.bodySmall),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(texto, style: context.text.bodyMedium?.copyWith(height: 1.4)),
                              ],
                            ),
                          ),
                          if (widget.canEdit)
                            IconButton(
                              tooltip: 'Excluir',
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.close_rounded, size: 18, color: context.tokens.muted),
                              onPressed: () => _remove(n),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        if (widget.canEdit)
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border(top: BorderSide(color: context.tokens.border)),
            ),
            padding: const EdgeInsets.fromLTRB(Gaps.lg, Gaps.sm, Gaps.sm, Gaps.sm),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Escreva uma anotação...'),
                    ),
                  ),
                  const SizedBox(width: Gaps.sm),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
