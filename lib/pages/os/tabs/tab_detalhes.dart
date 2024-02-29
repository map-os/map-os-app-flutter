import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapos_app/config/constants.dart';

class TabDetalhes extends StatefulWidget {
  final Map<String, dynamic> os;

  TabDetalhes({required this.os});

  @override
  _TabDetalhesState createState() => _TabDetalhesState();
}

class _TabDetalhesState extends State<TabDetalhes> {
  late TextEditingController _dataInicialController;
  late TextEditingController _dataFinalController;
  late TextEditingController _responsavelController;
  late TextEditingController _statusController;
  late TextEditingController _descricaoController;
  late TextEditingController _defeitoController;
  late TextEditingController _laudoTecnicoController;
  late TextEditingController _nomeClienteController;
  late TextEditingController _celularClienteController;

  @override
  void initState() {
    super.initState();
    _dataInicialController = TextEditingController(text: widget.os['dataInicial']);
    _dataFinalController = TextEditingController(text: widget.os['dataFinal']);
    _responsavelController = TextEditingController(text: widget.os['nome']);
    _statusController = TextEditingController(text: widget.os['status']);
    _descricaoController = TextEditingController(text: widget.os['descricaoProduto']);
    _defeitoController = TextEditingController(text: widget.os['defeito']);
    _laudoTecnicoController = TextEditingController(text: widget.os['laudoTecnico']);
    _nomeClienteController = TextEditingController(text: widget.os['nomeCliente']);
    _celularClienteController = TextEditingController(text: widget.os['celular_cliente']);
  }

  @override
  void dispose() {
    _dataInicialController.dispose();
    _dataFinalController.dispose();
    _responsavelController.dispose();
    _statusController.dispose();
    _descricaoController.dispose();
    _defeitoController.dispose();
    _laudoTecnicoController.dispose();
    _nomeClienteController.dispose();
    _celularClienteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nomeClienteController,
              decoration: InputDecoration(labelText: 'Cliente'),
              style: TextStyle(fontSize: 16.0),
            ),
            TextFormField(
              controller: _celularClienteController,
              decoration: InputDecoration(labelText: 'Celular Cliente'),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            TextFormField(
              controller: _dataInicialController,
              decoration: InputDecoration(labelText: 'Data entrada'),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            TextFormField(
              controller: _dataFinalController,
              decoration: InputDecoration(labelText: 'Prev. Saída'),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            TextFormField(
              controller: _responsavelController,
              decoration: InputDecoration(labelText: 'Responsável'),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            TextFormField(
              controller: _statusController,
              decoration: InputDecoration(labelText: 'Status'),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            TextFormField(
              controller: _descricaoController,
              decoration: InputDecoration(labelText: 'Descrição'),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            TextFormField(
              controller: _defeitoController,
              decoration: InputDecoration(labelText: 'Defeito'),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            TextFormField(
              controller: _laudoTecnicoController,
              decoration: InputDecoration(labelText: 'Laudo Técnico'),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 16.0),
            // Botão para atualizar a OS
            ElevatedButton(
              onPressed: _atualizarOS,
              child: Text('Atualizar OS'),
            ),
          ],
        ),
      ),
    );
  }

  // Função para atualizar a OS
  void _atualizarOS() async {
    Map<String, dynamic> dadosAtualizados = {
      'nomeCliente': _nomeClienteController.text,
      'celular_cliente': _celularClienteController.text,
      'dataInicial': _dataInicialController.text,
      'dataFinal': _dataFinalController.text,
      'nome': _responsavelController.text,
      'status': _statusController.text,
      'descricaoProduto': _descricaoController.text,
      'defeito': _defeitoController.text,
      'laudoTecnico': _laudoTecnicoController.text,
    };

    bool sucesso = await _updateOS(dadosAtualizados);

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OS atualizada com sucesso')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar a OS')),
      );
    }
  }
  Future<bool> _updateOS(Map<String, dynamic> updatedOS) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);

    var url = '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}';
print(url);
    try {
      var response = await http.put(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-API-KEY': ciKey,
        },
        body: jsonEncode(updatedOS),
      );

      if (response.statusCode == 200) {
        print('OS atualizada com sucesso');
        return true;
      } else {
        print('Falha ao atualizar a OS: ${response.reasonPhrase}');
        return false;
      }
    } catch (error) {
      print('Erro ao enviar solicitação PUT: $error');
      return false;
    }
  }
}
