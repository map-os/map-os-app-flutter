import 'package:flutter/material.dart';

/// Paleta da marca MAP-OS (navy + laranja), refinada para UI moderna.
abstract final class AppColors {
  // Marca
  static const Color brand = Color(0xFF2B2E4A); // navy
  static const Color brandDeep = Color(0xFF1C1E33);
  static const Color accent = Color(0xFFF3742F); // laranja

  // Neutros — claro
  static const Color bgLight = Color(0xFFF5F6FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE6E8EF);
  static const Color textLight = Color(0xFF1B1D2B);
  static const Color mutedLight = Color(0xFF6B7085);

  // Neutros — escuro
  static const Color bgDark = Color(0xFF0E1018);
  static const Color surfaceDark = Color(0xFF171A25);
  static const Color borderDark = Color(0xFF262A39);
  static const Color textDark = Color(0xFFE9EAF2);
  static const Color mutedDark = Color(0xFF9A9FB5);

  // Semânticas
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Módulos (ícones, KPIs)
  static const Color os = Color(0xFFF3742F);
  static const Color clientes = Color(0xFF2563EB);
  static const Color produtos = Color(0xFFD97706);
  static const Color servicos = Color(0xFF0D9488);
  static const Color garantias = Color(0xFF7C3AED);
  static const Color vendas = Color(0xFF16A34A);
}

/// Cores de status de OS, com tom suave para fundo de chip.
abstract final class StatusColors {
  static const List<String> all = [
    'Aberto',
    'Orçamento',
    'Negociação',
    'Aprovado',
    'Em Andamento',
    'Aguardando Peças',
    'Finalizado',
    'Faturado',
    'Cancelado',
  ];

  static Color of(String? status) {
    switch (_normalize(status)) {
      case 'aberto':
        return const Color(0xFF16A34A);
      case 'orcamento':
        return const Color(0xFFB08A3E);
      case 'negociacao':
        return const Color(0xFF9A8F06);
      case 'aprovado':
        return const Color(0xFF0891B2);
      case 'em andamento':
        return const Color(0xFF2563EB);
      case 'aguardando pecas':
        return const Color(0xFFEA580C);
      case 'finalizado':
        return const Color(0xFF334155);
      case 'faturado':
        return const Color(0xFF9333EA);
      case 'cancelado':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  static IconData icon(String? status) {
    switch (_normalize(status)) {
      case 'aberto':
        return Icons.radio_button_unchecked_rounded;
      case 'orcamento':
        return Icons.request_quote_outlined;
      case 'negociacao':
        return Icons.handshake_outlined;
      case 'aprovado':
        return Icons.thumb_up_alt_outlined;
      case 'em andamento':
        return Icons.autorenew_rounded;
      case 'aguardando pecas':
        return Icons.inventory_2_outlined;
      case 'finalizado':
        return Icons.check_circle_outline_rounded;
      case 'faturado':
        return Icons.receipt_long_outlined;
      case 'cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  static String _normalize(String? s) => (s ?? '')
      .toLowerCase()
      .replaceAll('ç', 'c')
      .replaceAll('ã', 'a')
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .trim();
}
