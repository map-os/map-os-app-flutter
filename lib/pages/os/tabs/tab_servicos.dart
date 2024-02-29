import 'package:flutter/material.dart';

class TabServicos extends StatelessWidget {
  final Map<String, dynamic> os;

  TabServicos({required this.os});

  @override
  Widget build(BuildContext context) {
    // Use os dados da ordem de serviço (os) conforme necessário
    return Center(
      child: Text('Conteúdo da aba Serviços'),
    );
  }
}
