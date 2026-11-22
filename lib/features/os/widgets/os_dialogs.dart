import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/input_masks.dart';
import '../../../core/widgets/ui.dart';

/// Pede quantidade e preço unitário de um item. Retorna (quantidade, preço).
Future<(double, double)?> showItemDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  double quantidade = 1,
  required double preco,
  String confirmLabel = 'Adicionar',
}) {
  return showModalBottomSheet<(double, double)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ItemSheet(
      title: title,
      subtitle: subtitle,
      quantidade: quantidade,
      preco: preco,
      confirmLabel: confirmLabel,
    ),
  );
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({
    required this.title,
    required this.subtitle,
    required this.quantidade,
    required this.preco,
    required this.confirmLabel,
  });

  final String title;
  final String subtitle;
  final double quantidade;
  final double preco;
  final String confirmLabel;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final _qtd = TextEditingController(text: Fmt.number(widget.quantidade));
  late final _preco = TextEditingController(text: MoneyMask.format(widget.preco));

  double get _q => asDouble(_qtd.text);
  double get _p => Fmt.parseMoney(_preco.text);

  @override
  void dispose() {
    _qtd.dispose();
    _preco.dispose();
    super.dispose();
  }

  void _step(double delta) {
    final next = (_q + delta).clamp(1, 99999).toDouble();
    _qtd.text = Fmt.number(next);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(Gaps.xl, 0, Gaps.xl, Gaps.sheetBottom(context) + Gaps.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: context.text.titleLarge),
          const SizedBox(height: 2),
          Text(widget.subtitle, style: context.text.bodyMedium?.copyWith(color: context.tokens.muted)),
          const SizedBox(height: Gaps.xl),
          Row(
            children: [
              IconButton.outlined(onPressed: () => _step(-1), icon: const Icon(Icons.remove_rounded)),
              const SizedBox(width: Gaps.sm),
              Expanded(
                child: TextField(
                  controller: _qtd,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: Gaps.sm),
              IconButton.outlined(onPressed: () => _step(1), icon: const Icon(Icons.add_rounded)),
            ],
          ),
          const SizedBox(height: Gaps.md),
          TextField(
            controller: _preco,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyMask()],
            decoration: const InputDecoration(labelText: 'Preço unitário', prefixIcon: Icon(Icons.payments_outlined)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Gaps.lg),
          Container(
            padding: const EdgeInsets.all(Gaps.lg),
            decoration: BoxDecoration(color: context.tokens.subtle, borderRadius: BorderRadius.circular(Gaps.radiusSm)),
            child: Row(
              children: [
                Text('Subtotal', style: context.text.bodyMedium),
                const Spacer(),
                Text(Fmt.money(_q * _p), style: context.text.titleLarge),
              ],
            ),
          ),
          const SizedBox(height: Gaps.lg),
          FilledButton(
            onPressed: _q > 0 ? () => Navigator.pop(context, (_q, _p)) : null,
            child: Text(widget.confirmLabel),
          ),
        ],
      ),
    );
  }
}

/// Folha para aplicar desconto. Retorna (valor, tipo, valorFinal).
Future<(double, String, double)?> showDescontoSheet(
  BuildContext context, {
  required double subtotal,
  required double descontoAtual,
  required String tipoAtual,
}) {
  return showModalBottomSheet<(double, String, double)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DescontoSheet(subtotal: subtotal, atual: descontoAtual, tipo: tipoAtual),
  );
}

class _DescontoSheet extends StatefulWidget {
  const _DescontoSheet({required this.subtotal, required this.atual, required this.tipo});

  final double subtotal;
  final double atual;
  final String tipo;

  @override
  State<_DescontoSheet> createState() => _DescontoSheetState();
}

class _DescontoSheetState extends State<_DescontoSheet> {
  late String _tipo = widget.tipo == 'porcento' ? 'porcento' : 'real';
  late final _valor = TextEditingController(text: widget.atual > 0 ? Fmt.number(widget.atual) : '');

  double get _v => asDouble(_valor.text);

  double get _final {
    final d = _tipo == 'porcento' ? widget.subtotal * (_v / 100) : _v;
    return (widget.subtotal - d).clamp(0, double.infinity).toDouble();
  }

  bool get _valid => _v >= 0 && (_tipo == 'porcento' ? _v <= 100 : _v <= widget.subtotal);

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(Gaps.xl, 0, Gaps.xl, Gaps.sheetBottom(context) + Gaps.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Desconto', style: context.text.titleLarge),
          const SizedBox(height: 2),
          Text('Subtotal da OS: ${Fmt.money(widget.subtotal)}', style: context.text.bodyMedium?.copyWith(color: context.tokens.muted)),
          const SizedBox(height: Gaps.xl),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'real', label: Text(r'Valor (R$)')),
              ButtonSegment(value: 'porcento', label: Text('Percentual (%)')),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
          ),
          const SizedBox(height: Gaps.md),
          TextField(
            controller: _valor,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              labelText: _tipo == 'porcento' ? 'Percentual' : 'Valor do desconto',
              prefixText: _tipo == 'porcento' ? null : r'R$ ',
              suffixText: _tipo == 'porcento' ? '%' : null,
              errorText: _valid ? null : 'Desconto maior que o total',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Gaps.lg),
          Container(
            padding: const EdgeInsets.all(Gaps.lg),
            decoration: BoxDecoration(color: context.tokens.subtle, borderRadius: BorderRadius.circular(Gaps.radiusSm)),
            child: Row(
              children: [
                Text('Total com desconto', style: context.text.bodyMedium),
                const Spacer(),
                Text(Fmt.money(_final), style: context.text.titleLarge),
              ],
            ),
          ),
          const SizedBox(height: Gaps.lg),
          FilledButton(
            onPressed: _valid ? () => Navigator.pop(context, (_v, _tipo, _final)) : null,
            child: const Text('Aplicar desconto'),
          ),
        ],
      ),
    );
  }
}

/// Seleção rápida de status.
Future<String?> showStatusSheet(BuildContext context, String atual) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheet) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Gaps.sm, 0, Gaps.sm, Gaps.lg + Gaps.systemBottom(sheet)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.md),
            child: Text('Alterar status', style: sheet.text.titleLarge),
          ),
          for (final s in StatusColors.all)
            ListTile(
              leading: Icon(StatusColors.icon(s), color: StatusColors.of(s)),
              title: Text(s),
              trailing: s == atual ? const Icon(Icons.check_rounded, color: AppColors.accent) : null,
              selected: s == atual,
              onTap: () => Navigator.pop(sheet, s),
            ),
        ],
      ),
    ),
  );
}
