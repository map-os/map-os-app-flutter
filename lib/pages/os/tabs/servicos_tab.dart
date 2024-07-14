import 'package:flutter/material.dart';

class ServicosTab extends StatelessWidget {
  final Map<String, dynamic>? ordemServico;

  ServicosTab({this.ordemServico});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Conteúdo da Tab 1'),
    );
  }
}
