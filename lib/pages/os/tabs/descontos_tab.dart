import 'package:flutter/material.dart';

class DescontosTab extends StatelessWidget {
  final Map<String, dynamic>? ordemServico;

  DescontosTab({this.ordemServico});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Conteúdo da Tab 1'),
    );
  }
}
