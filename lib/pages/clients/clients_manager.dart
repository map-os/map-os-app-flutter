import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

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

    _celularController = MaskedTextController(mask: '(00) 00000-0000');
    _celularController.text = widget.cliente['celular'] ?? '';


    _telefoneController = MaskedTextController(mask: '(00) 0000-0000');
    _telefoneController.text = widget.cliente['telefone'] ?? '';

    _documentoController = MaskedTextController(mask: '000.000.000-00');
    _documentoController.text = widget.cliente['ducumento'] ?? '';

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
    _cepController =  MaskedTextController(mask: '00000-000');
    _cepController.text = widget.cliente['cep'] ?? '';

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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.account_circle_sharp, color: Color(0xff333649)),
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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Celular',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.phone_android, color: Color(0xff333649)),
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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.phone, color: Color(0xff333649)),
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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'C.P.F',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.description_sharp, color: Color(0xff333649)),
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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.email, color: Color(0xff333649)),
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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Rua',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.bookmark_added_rounded, color: Color(0xff333649)),
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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Numero',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.numbers, color: Color(0xff333649)),
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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Bairro',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.maps_home_work, color: Color(0xff333649)),
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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'CEP',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.numbers, color: Color(0xff333649)),
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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Cidade',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.bookmark_added_rounded, color: Color(0xff333649)),
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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Estado',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.map, color: Color(0xff333649)),
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
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Complemento',
                  labelStyle: TextStyle(color: Color(0xff333649)),
                  prefixIcon: Icon(
                      Icons.add, color: Color(0xff333649)),
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
              Container(
                height: 50.0,
                decoration: BoxDecoration(
                  color: Color(0xfffa9e10), // Cor de fundo do botão
                  borderRadius: BorderRadius.circular(8.0), // Borda arredondada
                ),
                child:
                ElevatedButton(
                  onPressed: () async {
                    // String ciKey = await _getCiKey();

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