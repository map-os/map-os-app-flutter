import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapos_app/config/constants.dart';

class ServicoAddScreen extends StatefulWidget {
  @override
  _ServicoAddScreenState createState() => _ServicoAddScreenState();
}

class _ServicoAddScreenState extends State<ServicoAddScreen> {
  late TextEditingController _nomeServicoController;
  late TextEditingController _descricaoServicoController;
  late TextEditingController _precoServicoController;

  @override
  void initState() {
    super.initState();
    _nomeServicoController = TextEditingController();
    _descricaoServicoController = TextEditingController();
    _precoServicoController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Serviço'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomeServicoController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.construction_outlined),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _descricaoServicoController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _precoServicoController,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xfffa9e10),
                ),
                onPressed: () async {
                  Map<String, dynamic> newServico = {
                    'nome': _nomeServicoController.text,
                    'descricao': _descricaoServicoController.text,
                    'preco': _precoServicoController.text,
                  };

                  bool success = await _addServico(newServico);
                  if (success) {
                    _showSnackBar('Serviço adicionado com sucesso',
                        backgroundColor: Colors.green);
                    // You can add navigation to another screen or pop the current screen here
                  } else {
                    _showSnackBar('Falha ao adicionar o serviço',
                        backgroundColor: Colors.red);
                  }
                },
                child: Text('Adicionar Serviço'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.black}) {
    final snackBar = SnackBar(
      content: Text(message),
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

  Future<bool> _addServico(Map<String, dynamic> newServico) async {
    String ciKey = await _getCiKey();

    var url = '${APIConfig.baseURL}${APIConfig.servicossEndpoint}';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-API-KEY': ciKey,
        },
        body: jsonEncode(newServico),
      );

      if (response.statusCode == 201) {
        print('Serviço adicionado com sucesso');
        return true;
      } else {
        print('Falha ao adicionar o serviço: ${response.reasonPhrase}');
        return false;
      }
    } catch (error) {
      print('Erro ao enviar solicitação POST: $error');
      return false;
    }
  }
}
