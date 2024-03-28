import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapos_app/config/constants.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:mapos_app/pages/services/services_screen.dart';

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
    _precoServicoController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
    );
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
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _descricaoServicoController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.description_outlined),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _precoServicoController,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  prefixIcon: Icon(Icons.attach_money),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2c9b5b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  minimumSize: Size(200, 50),
                ),
                onPressed: () async {
                  String preco = _precoServicoController.text
                      .replaceAll('R\$ ', '')
                      .replaceAll('.', '')
                      .replaceAll(',', '.');
                  Map<String, dynamic> newServico = {
                    'nome': _nomeServicoController.text,
                    'descricao': _descricaoServicoController.text,
                    'preco': preco,
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
                child: Text(
                  'Adicionar Serviço',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
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
      if (response.statusCode == 200) {
        }
        print('Serviço adicionado com sucesso');
        return true;
    } catch (error) {
      print('Erro ao enviar solicitação POST: $error');
      return false;
    }
  }
}
