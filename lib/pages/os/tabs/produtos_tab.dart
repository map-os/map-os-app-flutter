import 'package:flutter/material.dart';

class ProdutosTab extends StatelessWidget {
  final Map<String, dynamic>? ordemServico;

  ProdutosTab({this.ordemServico});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Conteúdo da Tab 1'),
    );
  }
}
