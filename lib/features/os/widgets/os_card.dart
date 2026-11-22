import 'package:flutter/material.dart';

import '../../../core/widgets/ui.dart';
import '../../../data/models/ordem_servico.dart';
import '../os_detail_page.dart';

class OsCard extends StatelessWidget {
  const OsCard({super.key, required this.os, this.onChanged});

  final OrdemServico os;

  /// Chamado ao voltar da tela de detalhe (para recarregar a lista).
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final descricao = Fmt.plain(os.descricaoProduto).isNotEmpty ? Fmt.plain(os.descricaoProduto) : Fmt.plain(os.defeito);
    return AppCard(
      padding: const EdgeInsets.all(Gaps.lg),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => OsDetailPage(osId: os.id)));
        onChanged?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'OS #${os.id}',
                style: context.text.labelLarge?.copyWith(color: context.tokens.muted, letterSpacing: 0.2),
              ),
              const Spacer(),
              StatusChip(os.status, dense: true),
            ],
          ),
          const SizedBox(height: Gaps.sm),
          Text(
            os.nomeCliente.isEmpty ? 'Cliente não informado' : os.nomeCliente,
            style: context.text.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (descricao.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              descricao.replaceAll('\n', ' '),
              style: context.text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: Gaps.md),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 16, color: context.tokens.muted),
              const SizedBox(width: 6),
              Text(
                os.dataFinal != null && os.dataFinal != os.dataInicial
                    ? '${Fmt.dateShort(os.dataInicial)} → ${Fmt.dateShort(os.dataFinal)}'
                    : Fmt.dateShort(os.dataInicial),
                style: context.text.bodySmall,
              ),
              const Spacer(),
              Text(
                Fmt.money(os.total),
                style: context.text.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
