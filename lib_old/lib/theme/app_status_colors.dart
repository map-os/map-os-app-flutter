import 'package:flutter/material.dart';

abstract class AppStatusColors {
  static const Map<String, Color> osStatus = {
    'Orçamento': Color(0xFFCCB27F),
    'Orcamento': Color(0xFFCCB27F),
    'Aberto': Color(0xFF00CC00),
    'Negociação': Color(0xFFADB304),
    'Negociacao': Color(0xFFADB304),
    'Em Andamento': Color(0xFF436DED),
    'Aprovado': Color(0xFF7F7F7F),
    'Faturado': Color(0xFFB166FD),
    'Finalizado': Color(0xFF225566),
    'Aguardando Peças': Color(0xFFFD7E00),
    'Aguardando Pecas': Color(0xFFFD7E00),
    'Cancelado': Color(0xFFFF0000),
  };

  static Color getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    return osStatus[status] ?? Colors.grey;
  }
}