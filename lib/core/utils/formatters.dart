import 'package:intl/intl.dart';

/// Conversões tolerantes — a API MAP-OS devolve números como string.
int asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.toInt() ?? fallback;
}

double asDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.')) ?? fallback;
}

String asString(dynamic v) => v == null ? '' : v.toString();

DateTime? asDate(dynamic v) {
  final s = asString(v);
  if (s.isEmpty || s.startsWith('0000')) return null;
  return DateTime.tryParse(s);
}

abstract final class Fmt {
  static final _money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  static final _number = NumberFormat.decimalPattern('pt_BR');
  static final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _dateShort = DateFormat("dd 'de' MMM", 'pt_BR');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  static String money(num? value) => _money.format(value ?? 0);

  static String number(num? value) {
    final v = value ?? 0;
    return v == v.roundToDouble() ? v.toInt().toString() : _number.format(v);
  }

  static String date(DateTime? d, {String empty = '—'}) => d == null ? empty : _date.format(d);
  static String dateShort(DateTime? d) => d == null ? '—' : _dateShort.format(d);
  static String dateTime(DateTime? d) => d == null ? '—' : _dateTime.format(d);

  /// Formato aceito pela API ao criar/editar OS.
  static String apiDate(DateTime d) => _date.format(d);

  static DateTime? parseDate(String text) {
    try {
      return _date.parseStrict(text);
    } catch (_) {
      return null;
    }
  }

  /// "R$ 1.234,56" → 1234.56
  static double parseMoney(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    return double.tryParse(digits) ?? 0;
  }

  /// Remove HTML vindo dos editores ricos do MAP-OS e decodifica entidades.
  static String plain(dynamic html) {
    var s = asString(html);
    if (s.isEmpty) return '';
    s = s
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(p|div|li|h\d)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#40;', '(')
        .replaceAll('&#41;', ')')
        .replaceAll(RegExp(r'\[removed\]'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  static String initials(String name) {
    final parts = plain(name).trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static String onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');
}
