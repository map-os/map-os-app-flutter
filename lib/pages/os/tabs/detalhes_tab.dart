import 'package:flutter/material.dart';

class DetalhesTab extends StatelessWidget {
  final Map<String, dynamic>? ordemServico;

  DetalhesTab({this.ordemServico});

  @override
  Widget build(BuildContext context) {
    return ordemServico == null
        ? Center(child: CircularProgressIndicator())
        : Column(
      children: [
        Text('Detalhes da Ordem de Serviço'),
        Text('ID: ${ordemServico!['idOs']}'),
        Text('Cliente: ${ordemServico!['nomeCliente']}'),
        Text('Data inicial: ${ordemServico!['dataInicial']}'),
        Text('Data final: ${ordemServico!['dataFinal']}'),
        Text('Status: ${ordemServico!['status']}'),
        Text('Descricão: ${ordemServico!['descricaoProduto']}'),
        Text('Defeito: ${ordemServico!['defeito']}'),
        Text('Laudo Técnico: ${ordemServico!['laudoTecnico']}'),
        Text('Observações: ${ordemServico!['observacoes']}'),
        Text('Valor: ${ordemServico!['calcTotal']}'),
      ],
    );
  }
}
