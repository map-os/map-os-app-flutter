import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Máscara genérica baseada em padrão (# = dígito).
class PatternMask extends TextInputFormatter {
  PatternMask(this.patterns) : assert(patterns.isNotEmpty);

  /// Lista de padrões ordenada do menor para o maior;
  /// o primeiro que comporta a quantidade de dígitos é usado.
  final List<String> patterns;

  factory PatternMask.phone() => PatternMask(['(##) ####-####', '(##) #####-####']);
  factory PatternMask.cpfCnpj() => PatternMask(['###.###.###-##', '##.###.###/####-##']);
  factory PatternMask.cep() => PatternMask(['#####-###']);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final pattern = patterns.firstWhere(
      (p) => '#'.allMatches(p).length >= digits.length,
      orElse: () => patterns.last,
    );
    final max = '#'.allMatches(pattern).length;
    final d = digits.length > max ? digits.substring(0, max) : digits;

    final buf = StringBuffer();
    var i = 0;
    for (final ch in pattern.split('')) {
      if (i >= d.length) break;
      if (ch == '#') {
        buf.write(d[i++]);
      } else {
        buf.write(ch);
      }
    }
    final text = buf.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Máscara monetária brasileira (R$ 1.234,56) digitando da direita.
class MoneyMask extends TextInputFormatter {
  static final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  static String format(double value) => _fmt.format(value);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final cents = int.tryParse(digits.isEmpty ? '0' : digits) ?? 0;
    final text = _fmt.format(cents / 100);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

abstract final class Validators {
  static String? required(String? v, [String label = 'Campo']) =>
      (v == null || v.trim().isEmpty) ? '$label é obrigatório' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : 'E-mail inválido';
  }

  static String? requiredEmail(String? v) => required(v, 'E-mail') ?? email(v);
}
