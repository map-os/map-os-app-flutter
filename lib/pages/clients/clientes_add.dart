import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';

class ClienteAddScreen extends StatefulWidget {
  @override
  _ClienteAddScreenState createState() => _ClienteAddScreenState();
}

class _ClienteAddScreenState extends State<ClienteAddScreen> {
  late TextEditingController _nomeClienteController;
  late TextEditingController _celularController;
  late TextEditingController _telefoneController;
  late TextEditingController _documentoController;
  late TextEditingController _emailtoController;
  late TextEditingController _ruaController;
  late TextEditingController _numeroController;
  late TextEditingController _bairroController;
  late TextEditingController _cidadeController;
  late TextEditingController _estadoController;
  late TextEditingController _cepController;
  late TextEditingController _complementoController;

  @override
  void initState() {
    super.initState();
    _nomeClienteController = TextEditingController();
    _celularController = TextEditingController();
    _telefoneController = TextEditingController();
    _documentoController = TextEditingController();
    _emailtoController = TextEditingController();
    _ruaController = TextEditingController();
    _numeroController = TextEditingController();
    _bairroController = TextEditingController();
    _cidadeController = TextEditingController();
    _estadoController = TextEditingController();
    _cepController = TextEditingController();
    _complementoController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Cliente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.0),
              TextFormField(
                controller: _nomeClienteController,
                decoration: InputDecoration(
                  labelText: 'Nome do Cliente',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.person),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _celularController,
                decoration: InputDecoration(
                  labelText: 'Celular',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.phone),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.phone),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _documentoController,
                decoration: InputDecoration(
                  labelText: 'Documento',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.description),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _emailtoController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _ruaController,
                decoration: InputDecoration(
                  labelText: 'Rua',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.location_on),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _numeroController,
                decoration: InputDecoration(
                  labelText: 'Número',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.format_list_numbered),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _bairroController,
                decoration: InputDecoration(
                  labelText: 'Bairro',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.location_city),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _cepController,
                decoration: InputDecoration(
                  labelText: 'CEP',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.location_on),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _cidadeController,
                decoration: InputDecoration(
                  labelText: 'Cidade',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.location_city),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _estadoController,
                decoration: InputDecoration(
                  labelText: 'Estado',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.location_on),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _complementoController,
                decoration: InputDecoration(
                  labelText: 'Complemento',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.format_list_numbered),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              SizedBox(height: 16.0),
          Container(
            height: 50.0,
            decoration: BoxDecoration(
              color: Color(0xfffa9e10), // Cor de fundo do botão
              borderRadius: BorderRadius.circular(8.0), // Borda arredondada
            ),
            child:
            ElevatedButton(
                onPressed: () {
                  _addCliente();
                },
                child: Text('Adicionar Cliente'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xfffa9e10),
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addCliente() async {
    var clienteData = {
      'nomeCliente': _nomeClienteController.text,
      'celular': _celularController.text,
      'telefone': _telefoneController.text,
      'documento': _documentoController.text,
      'email': _emailtoController.text,
      'rua': _ruaController.text,
      'numero': _numeroController.text,
      'bairro': _bairroController.text,
      'cep': _cepController.text,
      'cidade': _cidadeController.text,
      'estado': _estadoController.text,
      'complemento': _complementoController.text,
      'senha': _documentoController.text,
      'contato': '',
      'fornecedor': 0,
    };

    String ciKey = await _getCiKey();

    var headers = {
      'Content-Type': 'application/json',
      'X-API-KEY': ciKey,
    };

    var url = '${APIConfig.baseURL}${APIConfig.clientesEndpoint}';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(clienteData),
      );

      if (response.statusCode == 200) {
        print(response.body);
        _showSnackBar('Cliente adicionado com sucesso',
            backgroundColor: Colors.green,
            textColor: Colors.white);
        _clearFields();
      } else {
        var errorMessage = 'Falha ao adicionar cliente';

        if (response.body.isNotEmpty) {
          var responseBody = json.decode(response.body);
          if (responseBody['message'] != null && responseBody['message'].isNotEmpty) {
            errorMessage = responseBody['message'];
          }
        }
        _showSnackBar(errorMessage,
            backgroundColor: Colors.green,
            textColor: Colors.white);
      }
    } catch (error) {
      print('Erro ao enviar solicitação POST: $error');
      _showSnackBar('Erro na conexão com a API',
          backgroundColor: Colors.red, textColor: Colors.white);
    }
  }


  void _showSnackBar(String message,
      {Color backgroundColor = Colors.black,
        Color textColor = Colors.white}) {
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

  void _clearFields() {
    _nomeClienteController.clear();
    _celularController.clear();
    _telefoneController.clear();
    _documentoController.clear();
    _emailtoController.clear();
    _ruaController.clear();
    _numeroController.clear();
    _bairroController.clear();
    _cepController.clear();
    _cidadeController.clear();
    _estadoController.clear();
    _complementoController.clear();
  }
}
