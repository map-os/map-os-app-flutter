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
  bool _editingEnabled = false;

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

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Serviço'),
        actions: [
          IconButton(
            icon: Icon(_editingEnabled ? Icons.edit_note_sharp : Icons.edit),
            onPressed: () async {
              Map<String, dynamic> permissionsMap = await _getCiKey();
              List<dynamic> permissoes = permissionsMap['permissoes'];

              bool hasPermissionToEdit = false;

              for (var permissao in permissoes) {
                if (permissao['eServico'] == '1') {
                  hasPermissionToEdit = true;
                  break;
                }
              }
              if (hasPermissionToEdit) {
                setState(() {
                  _editingEnabled = !_editingEnabled;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Você não tem permissões para editar serviços.'),
                  ),
                );
              }
            },
          ),
        ],
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
                enabled: _editingEnabled,
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: Colors.orange),
                  prefixIcon: Icon(Icons.construction_outlined, color: Color(0xfffa9e10)),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xfffadccc), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _descricaoServicoController,
                enabled: _editingEnabled,
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Descricao',
                  labelStyle: TextStyle(color: Colors.orange),
                  prefixIcon: Icon(Icons.description_outlined, color: Color(0xfffa9e10)),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xfffadccc), width: 2.0),
                  ),
                ),
              ),


              SizedBox(height: 16.0),
              TextFormField(
                controller: _precoServicoController,
                enabled: _editingEnabled,
                style: TextStyle(color: Colors.grey[700]),
                decoration: InputDecoration(
                  labelText: 'Valor',
                  labelStyle: TextStyle(color: Colors.orange),
                  prefixIcon: Icon(Icons.attach_money, color: Color(0xfffa9e10)),
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xfffadccc), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _editingEnabled ? _saveChanges : null,
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

  void _saveChanges() async {
    // Map<String, dynamic> ciKey = await _getCiKey();

    Map<String, dynamic> updatedServico = {
      'idServicos': widget.servico['idServico'],
      'nome': _nomeServicoController.text,
      'descricao': _descricaoServicoController.text,
      'preco': _precoServicoController.text,
    };

    Future<bool> success = _updateServico(updatedServico);
    if (await success) {
      _showSnackBar('Serviço atualizado com sucesso',
          backgroundColor: Colors.green, textColor: Colors.white);
    } else {
      _showSnackBar('Falha ao atualizar o serviço',
          backgroundColor: Colors.red, textColor: Colors.white);
    }
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



  Future<bool> _updateServico(Map<String, dynamic> updatedServico) async {
    Map<String, dynamic> ciKey = await _getCiKey();

    var url =
        '${APIConfig.baseURL}${APIConfig.servicossEndpoint}/${widget.servico['idServicos']}';
    print(url);
    try {
      var response = await http.put(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-API-KEY': ciKey['ciKey'],
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
