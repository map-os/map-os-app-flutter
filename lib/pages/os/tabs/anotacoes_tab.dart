import 'package:flutter/material.dart';

class AnotacoesTab extends StatelessWidget {
  final Map<String, dynamic>? ordemServico;

  AnotacoesTab({this.ordemServico});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Conteúdo da Tab 1'),
    );
  }
}
