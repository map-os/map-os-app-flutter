import 'package:flutter/material.dart';

class AnexosTab extends StatelessWidget {
  final Map<String, dynamic>? ordemServico;

  AnexosTab({this.ordemServico});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Conteúdo da Tab 1'),
    );
  }
}
