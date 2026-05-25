import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color primary = Color(0xFF333649);
  static const Color accent = Color(0xFFF3742F);
  static const Color surface = Color(0xFFF6EFF8);
  static const Color cardDark = Color(0xFF181824);
  static const Color navBar = Color(0xFF343E77);
  static const Color textLight = Color(0xFFE3EBF9);
  static const Color textMuted = Color(0xFF555555);
  static const Color divider = Color(0xFF55596E);
  static const Color appBarView = Color(0xFFFCF5FD);
  static const Color inputFill = Color(0xFF3C4058);
  static const Color loginBg = Color(0xFFE4ECFB);

  // Bottom nav tab colors
  static const Color tabProdutos = Color(0xFFF8B02A);
  static const Color tabServicos = Color(0xFF2CC4C4);
  static const Color tabClientes = Color(0xFF32A7F4);
  static const Color tabOS = Color(0xFFFB6986);

  // Dashboard info card colors
  static const Color dashClientes = Color(0xFF32A8F6);
  static const Color dashProdutos = Color(0xFFFAB12A);
  static const Color dashServicos = Color(0xFF2CC5C5);
  static const Color dashOrdens = Color(0xFFFD6987);
  static const Color dashGarantias = Color(0xFF966ABD);
  static const Color dashVendas = Color(0xFF15B597);

  // Shimmer
  static final Color shimmerBase = Colors.grey[300]!;
  static final Color shimmerHighlight = Colors.grey[100]!;
}