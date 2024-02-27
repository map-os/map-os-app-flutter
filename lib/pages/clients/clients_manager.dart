import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';

class ClienteEditScreen extends StatefulWidget {
  final Map<String, dynamic> cliente;

  ClienteEditScreen({required this.cliente});

  @override
  _ClienteEditScreenState createState() => _ClienteEditScreenState();
}

class _ClienteEditScreenState extends State<ClienteEditScreen> {
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
    _nomeClienteController =
        TextEditingController(text: widget.cliente['nomeCliente'] ?? '');
    _celularController =
        TextEditingController(text: widget.cliente['celular'] ?? '');
    _telefoneController =
        TextEditingController(text: widget.cliente['telefone'] ?? '');
    _documentoController =
        TextEditingController(text: widget.cliente['documento'] ?? '');
    _emailtoController =
        TextEditingController(text: widget.cliente['email'] ?? '');
    _ruaController =
        TextEditingController(text: widget.cliente['rua'] ?? '');
    _numeroController =
        TextEditingController(text: widget.cliente['numero'] ?? '');
    _bairroController =
        TextEditingController(text: widget.cliente['bairro'] ?? '');
    _cidadeController =
        TextEditingController(text: widget.cliente['cidade'] ?? '');
    _estadoController =
        TextEditingController(text: widget.cliente['estado'] ?? '');
    _cepController =
        TextEditingController(text: widget.cliente['cep'] ?? '');

    _complementoController =
        TextEditingController(text: widget.cliente['complemento'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Cliente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ID do Cliente: ${widget.cliente['idClientes'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _nomeClienteController,
                decoration: InputDecoration(
                  labelText: 'Nome do Cliente',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.person, color: Color(0xfffa9e10)),
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
                controller: _celularController,
                decoration: InputDecoration(
                  labelText: 'Celular',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(
                      Icons.phone_android, color: Color(0xfffa9e10)),
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
                controller: _telefoneController,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.phone, color: Color(0xfffa9e10)),
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
              // Corrigi o texto duplicado e adicionei um ícone de documento
              TextFormField(
                controller: _documentoController,
                decoration: InputDecoration(
                  labelText: 'Documento',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.description, color: Color(0xfffa9e10)),
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
              TextFormField(
                controller: _emailtoController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.email, color: Color(0xfffa9e10)),
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
              // Alterei a cor de fundo e o estilo da borda
              TextFormField(
                controller: _ruaController,
                decoration: InputDecoration(
                  labelText: 'Rua',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.map, color: Color(0xfffa9e10)),
                  filled: true,
                  fillColor: Color(0x99fff4e6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 15.0),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xfffa9e10),
                        width: 2.0), // Define a cor da borda quando selecionado
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              // Alterei o campo de texto para aceitar apenas números
              TextFormField(
                controller: _numeroController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Número',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.numbers, color: Color(0xfffa9e10)),
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
              TextFormField(
                controller: _bairroController,
                decoration: InputDecoration(
                  labelText: 'Bairro',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(
                      Icons.maps_home_work, color: Color(0xfffa9e10)),
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
              // Adicionei um exemplo de validação de CEP
              TextFormField(
                controller: _cepController,
                decoration: InputDecoration(
                  labelText: 'CEP',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.numbers, color: Color(0xfffa9e10)),
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
                keyboardType: TextInputType.number,
                maxLength: 8,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Informe o CEP';
                  } else if (value.length != 8) {
                    return 'CEP inválido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _cidadeController,
                decoration: InputDecoration(
                  labelText: 'Cidade',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.map, color: Color(0xfffa9e10)),
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
              TextFormField(
                controller: _estadoController,
                decoration: InputDecoration(
                  labelText: 'Estado',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.map, color: Color(0xfffa9e10)),
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
              TextFormField(
                controller: _complementoController,
                decoration: InputDecoration(
                  labelText: 'Complemento',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.add, color: Color(0xfffa9e10)),
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
              Container(
                height: 50.0,
                decoration: BoxDecoration(
                  color: Color(0xfffa9e10), // Cor de fundo do botão
                  borderRadius: BorderRadius.circular(8.0), // Borda arredondada
                ),
                child:
                ElevatedButton(
                  onPressed: () async {
                    String ciKey = await _getCiKey();

                    Map<String, dynamic> updatedCliente = {
                      'idClientes': widget.cliente['idClientes'],
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
                    };

                    Future<bool> success = _updateCliente(
                        updatedCliente); // Removido o await
                    if (await success) {
                      _showSnackBar('Cliente atualizado com sucesso',
                          backgroundColor: Colors.green,
                          textColor: Colors.white);
                    } else {
                      _showSnackBar('Falha ao atualizar o cliente',
                          backgroundColor: Colors.red, textColor: Colors.white);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xfffa9e10),
                  ),
                  child: Text('Salvar Alterações'),
                ),
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
      duration: Duration(seconds: 2), // Definindo a duração do SnackBar
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<String> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    return ciKey;
  }


  Future<bool> _updateCliente(Map<String, dynamic> updatedCliente) async {
    String ciKey = await _getCiKey();

    var url =
        '${APIConfig.baseURL}${APIConfig.clientesEndpoint}/${widget.cliente['idClientes']}';
    try {
      // Formatando o mapa updatedCliente para corresponder ao formato JSON esperado
      Map<String, dynamic> formattedCliente = {
        "idClientes": updatedCliente['idClientes'],
        "asaas_id": null,
        "nomeCliente": updatedCliente['nomeCliente'],
        "sexo": null,
        "pessoa_fisica": "1",
        "documento": updatedCliente['documento'],
        "telefone": updatedCliente['telefone'],
        "celular": updatedCliente['celular'],
        "email": updatedCliente['email'],
        "senha": updatedCliente['senha'],
        "dataCadastro": updatedCliente['dataCadastro'],
        "rua": updatedCliente['rua'],
        "numero": updatedCliente['numero'],
        "bairro": updatedCliente['bairro'],
        "cidade": updatedCliente['cidade'],
        "estado": updatedCliente['estado'],
        "cep": updatedCliente['cep'],
        "contato": null,
        "complemento": updatedCliente['complemento'],
        "fornecedor": "0"
      };

      var response = await http.put(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-API-KEY': ciKey,
        },
        body: jsonEncode(
            formattedCliente), // Serializa o mapa para JSON com formatação
      );

      if (response.statusCode == 200) {
        print('Cliente atualizado com sucesso');
        return true;
      } else {
        print('Falha ao atualizar o cliente: ${response.reasonPhrase}');
        return false;
      }
    } catch (error) {
      print('Erro ao enviar solicitação PUT: $error');
      return false;
    }
  }
}