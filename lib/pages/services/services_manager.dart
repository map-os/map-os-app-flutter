import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapos_app/config/constants.dart';

class ServicoEditScreen extends StatefulWidget {
  final Map<String, dynamic> servico;

  ServicoEditScreen({required this.servico});

  @override
  _ServicoEditScreenState createState() => _ServicoEditScreenState();
}

class _ServicoEditScreenState extends State<ServicoEditScreen> {
  late TextEditingController _nomeServicoController;
  late TextEditingController _descricaoServicoController;
  late TextEditingController _precoServicoController;

  @override
  void initState() {
    super.initState();
    _nomeServicoController =
        TextEditingController(text: widget.servico['nome'] ?? '');
    _descricaoServicoController =
        TextEditingController(text: widget.servico['descricao'] ?? '');
    _precoServicoController =
        TextEditingController(text: widget.servico['preco'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Serviço'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ID do Serviço: ${widget.servico['idServicos'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _nomeServicoController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.construction_outlined, color: Color(0xfffa9e10)),
                  filled: true,
                  fillColor: Color(0x99fff4e6),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 2.0),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xfffa9e10),
                        width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _descricaoServicoController,
                decoration: InputDecoration(
                  labelText: 'Descricao',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.description_outlined, color: Color(0xfffa9e10)),
                  filled: true,
                  fillColor: Color(0x99fff4e6),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 2.0),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xfffa9e10),
                        width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _precoServicoController,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.attach_money, color: Color(0xfffa9e10)),
                  filled: true,
                  fillColor: Color(0x99fff4e6),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 2.0),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xfffa9e10),
                        width: 2.0), // Define a cor da borda quando selecionado
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  String ciKey = await _getCiKey();

                  Map<String, dynamic> updatedServico = {
                    'idServicos': widget.servico['idServico'],
                    'nome': _nomeServicoController.text,
                    'descricao': _descricaoServicoController.text,
                    'preco': _precoServicoController.text,
                  };

                  Future<bool> success =
                  _updateServico(updatedServico);
                  if (await success) {
                    _showSnackBar('Serviço atualizado com sucesso',
                        backgroundColor: Colors.green,
                        textColor: Colors.white);
                  } else {
                    _showSnackBar('Falha ao atualizar o serviço',
                        backgroundColor: Colors.red, textColor: Colors.white);
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xfffa9e10),
                ),
                child: Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message,
      {Color backgroundColor = Colors.black, Color textColor = Colors.white}) {
    final snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: textColor)),
      backgroundColor: backgroundColor,
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<String> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    return ciKey;
  }

  Future<bool> _updateServico(Map<String, dynamic> updatedServico) async {
    String ciKey = await _getCiKey();

    var url =
        '${APIConfig.baseURL}${APIConfig.servicossEndpoint}/${widget.servico['idServicos']}';
    print(url);
    try {
      var response = await http.put(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-API-KEY': ciKey,
        },
        body: jsonEncode(updatedServico),
      );

      if (response.statusCode == 200) {
        print('Serviço atualizado com sucesso');
        return true;
      } else {
        print('Falha ao atualizar o serviço: ${response.reasonPhrase}');
        return false;
      }
    } catch (error) {
      print('Erro ao enviar solicitação PUT: $error');
      return false;
    }
  }
}
