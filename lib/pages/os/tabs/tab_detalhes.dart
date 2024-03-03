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
    _dataInicialController =
        TextEditingController(text: widget.os['dataInicial']);
    _dataFinalController = TextEditingController(text: widget.os['dataFinal']);
    _responsavelController = TextEditingController(text: widget.os['nome']);
    _statusController = TextEditingController(text: widget.os['status']);
    _descricaoController =
        TextEditingController(text: widget.os['descricaoProduto']);
    _defeitoController = TextEditingController(text: widget.os['defeito']);
    _laudoTecnicoController =
        TextEditingController(text: widget.os['laudoTecnico']);
    _nomeClienteController =
        TextEditingController(text: widget.os['nomeCliente']);
    _celularClienteController =
        TextEditingController(text: widget.os['celular_cliente']);
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
              enabled: false,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Cliente',
                filled: true,
                fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide.none, // Remove a linha preta
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                ),
                labelStyle: TextStyle(
                  color: Colors
                      .black, // Cor do texto quando o campo está desabilitado
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _celularClienteController,
              enabled: false,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Celular Cliente',
                filled: true,
                fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide.none, // Remove a linha preta
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _dataInicialController,
              enabled: false,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Entrada',
                filled: true,
                fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide.none, // Remove a linha preta
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _dataFinalController,
              decoration: InputDecoration(
                labelText: 'Prev. Saída',
                filled: true,
                fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide.none, // Remove a linha preta
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _responsavelController,
              enabled: false,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Responsavel',
                filled: true,
                fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide.none, // Remove a linha preta
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _statusController,
              decoration: InputDecoration(
                labelText: 'Status',
                filled: true,
                fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide.none, // Remove a linha preta
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _descricaoController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Descrição',
                filled: true,
                fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide.none, // Remove a linha preta
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _defeitoController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Defeito',
                filled: true,
                fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide.none, // Remove a linha preta
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _laudoTecnicoController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Laudo Técnico',
                filled: true,
                fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide.none, // Remove a linha preta
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Define o raio do border
                  borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: _atualizarOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2c9b5b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  minimumSize: Size(200, 50),
                ),
                child: Text(
                  'Atualizar OS',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              ),
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

    var url =
        '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}';
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
        Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('refresh_token')) {
          String refreshToken = data['refresh_token'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', refreshToken);
        } else {
          print('problema com sua sessão, faça login novamente!');
        }
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
