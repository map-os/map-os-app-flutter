import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Agrupa campos de formulário em um card com título.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.children, this.icon});

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gaps.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: context.tokens.muted),
                  const SizedBox(width: Gaps.sm),
                ],
                Text(title, style: context.text.titleSmall),
              ],
            ),
            const SizedBox(height: Gaps.lg),
            ..._spaced(children),
          ],
        ),
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(const SizedBox(height: Gaps.md));
      out.add(items[i]);
    }
    return out;
  }
}

/// TextFormField com padrões do app.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.obscure = false,
    this.suffix,
    this.textInputAction,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
      inputFormatters: inputFormatters,
      maxLines: obscure ? 1 : maxLines,
      minLines: maxLines > 1 ? 3 : 1,
      obscureText: obscure,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction ?? (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}

/// Campo de data com seletor nativo; valor exibido em dd/MM/yyyy.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Gaps.radiusSm),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(Fmt.date(value, empty: 'Selecionar')),
      ),
    );
  }
}

/// Campo que abre um seletor (ex.: cliente, técnico).
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.errorText,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final IconData? icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasValue = (value ?? '').isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(Gaps.radiusSm),
      onTap: onTap,
      child: InputDecorator(
        isEmpty: !hasValue,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          prefixIcon: icon == null ? null : Icon(icon),
          suffixIcon: const Icon(Icons.unfold_more_rounded),
        ),
        child: hasValue ? Text(value!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
      ),
    );
  }
}

/// Barra inferior fixa com botão de salvar.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.tokens.border)),
      ),
      padding: const EdgeInsets.fromLTRB(Gaps.lg, Gaps.md, Gaps.lg, Gaps.md),
      child: SafeArea(
        top: false,
        // heightFactor: 1 — sem ele o Center estica até a altura máxima e,
        // como bottomNavigationBar, cobre o formulário inteiro.
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}
