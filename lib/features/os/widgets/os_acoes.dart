import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/ui.dart';
import '../../../data/repositories/os_repository.dart';

Future<void> showPixSheet(BuildContext context, {required Future<Pix> Function() carregar, required String titulo}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _PixSheet(carregar: carregar, titulo: titulo),
  );
}

class _PixSheet extends StatefulWidget {
  const _PixSheet({required this.carregar, required this.titulo});

  final Future<Pix> Function() carregar;
  final String titulo;

  @override
  State<_PixSheet> createState() => _PixSheetState();
}

class _PixSheetState extends State<_PixSheet> {
  late final Future<Pix> _pix = widget.carregar();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Gaps.xl, Gaps.lg, Gaps.xl, Gaps.xl + Gaps.systemBottom(context)),
      child: FutureBuilder<Pix>(
        future: _pix,
        builder: (context, snap) {
          if (snap.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 48),
                const SizedBox(height: Gaps.md),
                Text(friendlyError(snap.error!), textAlign: TextAlign.center),
              ],
            );
          }
          final pix = snap.data;
          if (pix == null) return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.titulo, style: context.text.titleLarge),
              const SizedBox(height: Gaps.xs),
              Text(Fmt.money(pix.valor), style: context.text.headlineSmall),
              const SizedBox(height: Gaps.lg),
              if (pix.payload.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(Gaps.md),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Gaps.radiusSm)),
                  child: QrImageView(data: pix.payload, size: 220, backgroundColor: Colors.white, padding: EdgeInsets.zero),
                ),
              const SizedBox(height: Gaps.md),
              Text('Chave: ${pix.chave}', style: context.text.bodySmall),
              const SizedBox(height: Gaps.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copiar PIX copia e cola'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: pix.payload));
                    if (context.mounted) Toast.success(context, 'Código PIX copiado.');
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<bool> showFaturarSheet(
  BuildContext context, {
  required String titulo,
  required String descricao,
  required double total,
  required Future<void> Function(FaturaInput fatura) faturar,
  String sucesso = 'Faturado. A receita foi lançada no financeiro.',
}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _FaturarSheet(titulo: titulo, descricao: descricao, total: total, faturar: faturar, sucesso: sucesso),
    ),
  );
  return r ?? false;
}

class _FaturarSheet extends StatefulWidget {
  const _FaturarSheet({required this.titulo, required this.descricao, required this.total, required this.faturar, required this.sucesso});

  final String titulo;
  final String descricao;
  final double total;
  final Future<void> Function(FaturaInput fatura) faturar;
  final String sucesso;

  @override
  State<_FaturarSheet> createState() => _FaturarSheetState();
}

class _FaturarSheetState extends State<_FaturarSheet> {
  late final _descricao = TextEditingController(text: widget.descricao);
  final _observacoes = TextEditingController();
  DateTime _vencimento = DateTime.now();
  DateTime _recebimento = DateTime.now();
  bool _recebido = false;
  String? _forma;
  List<String> _formas = const [];
  bool _salvando = false;
  Map<String, String> _erros = const {};

  @override
  void initState() {
    super.initState();
    context.read<OsRepository>().opcoes().then((o) {
      if (mounted) setState(() => _formas = o.formasPagamento);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _descricao.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _faturar() async {
    if (_forma == null) {
      setState(() => _erros = {'forma_pagamento': 'Escolha a forma de pagamento.'});
      return;
    }
    setState(() {
      _salvando = true;
      _erros = const {};
    });
    try {
      await widget.faturar(
            FaturaInput(
              descricao: _descricao.text.trim(),
              vencimento: _vencimento,
              formaPagamento: _forma!,
              recebido: _recebido,
              dataRecebimento: _recebimento,
              observacoes: _observacoes.text.trim(),
            ),
          );
      if (!mounted) return;
      Toast.success(context, widget.sucesso);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erros = e.erros);
      if (mounted && e.erros.isEmpty) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Gaps.xl, Gaps.lg, Gaps.xl, Gaps.xl + Gaps.systemBottom(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.titulo, style: context.text.titleLarge),
          const SizedBox(height: Gaps.xs),
          Text('Total: ${Fmt.money(widget.total)}', style: context.text.bodyMedium),
          const SizedBox(height: Gaps.lg),
          AppTextField(controller: _descricao, label: 'Descrição do lançamento'),
          if (_erros['descricao'] != null) _Erro(_erros['descricao']!),
          const SizedBox(height: Gaps.md),
          DateField(label: 'Vencimento', value: _vencimento, onChanged: (d) => setState(() => _vencimento = d)),
          const SizedBox(height: Gaps.md),
          DropdownButtonFormField<String>(
            initialValue: _forma,
            decoration: InputDecoration(labelText: 'Forma de pagamento', errorText: _erros['forma_pagamento']),
            items: [for (final f in _formas) DropdownMenuItem(value: f, child: Text(f))],
            onChanged: (v) => setState(() => _forma = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Já recebido'),
            value: _recebido,
            onChanged: (v) => setState(() => _recebido = v),
          ),
          if (_recebido) DateField(label: 'Data do recebimento', value: _recebimento, onChanged: (d) => setState(() => _recebimento = d)),
          if (_erros['data_recebimento'] != null) _Erro(_erros['data_recebimento']!),
          const SizedBox(height: Gaps.md),
          AppTextField(controller: _observacoes, label: 'Observações', maxLines: 2),
          const SizedBox(height: Gaps.xl),
          LoadingButton(label: 'Faturar', icon: Icons.receipt_long_rounded, loading: _salvando, onPressed: _faturar),
        ],
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Gaps.xs),
        child: Text(texto, style: const TextStyle(color: AppColors.danger)),
      );
}
