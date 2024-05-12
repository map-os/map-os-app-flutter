import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';

class AdicionarOs extends StatefulWidget {
  @override
  _AdicionarOsScreenState createState() => _AdicionarOsScreenState();
}

class _AdicionarOsScreenState extends State<AdicionarOs> {
  TextEditingController _dataInicialController = MaskedTextController(
      mask: '00/00/0000');
  TextEditingController _dataFinalController = MaskedTextController(
      mask: '00/00/0000');
  TextEditingController _statusController = TextEditingController();
  TextEditingController _clientesController = TextEditingController();
  TextEditingController _responsavelController = TextEditingController();
  TextEditingController _descricaoController = TextEditingController();
  TextEditingController _defeitoController = TextEditingController();
  TextEditingController _observacoesController = TextEditingController();
  TextEditingController _laudoTecnicoController = TextEditingController();

  Map<String, String> clientesMap = {};
  List<String> filteredClientes = [];
  Map<String, String> usuariosMap = {};
  List<String> filteredUsuarios = [];
  // String _selectedStatus = 'Aberto';
  List<String> _statusOptions = [
    'Aberto',
    'Orçamento',
    'Aprovado',
    'Negociação',
    'Em Andamento',
    'Aguardando Peças',
    'Finalizado',
    'Cancelado',
    'Faturado',
  ];
  late String _selectedStatus;

  Future<String> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    return ciKey;
  }

  Future<bool> _addOs(Map<String, dynamic> newOs, BuildContext context) async {
    String ciKey = await _getCiKey();

    var url = '${APIConfig.baseURL}${APIConfig.osEndpoint}';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $ciKey',
        },
        body: jsonEncode(newOs),
      );
      if (response.statusCode == 201) {
        _clearFields();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("OS Adicionada com sucesso!"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ));
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Falha ao adicionar OS"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
        return false;
      }
    } catch (error) {
      print('Erro na API: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Erro interno do servidor"),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red, // Set background color to red
      ));
      return false;
    }
  }


  Future<void> _getClientes({int page = 0}) async {
    String ciKey = await _getCiKey();
    Map<String, String> headers = {
      'Authorization': 'Bearer $ciKey',
    };
    var url = '${APIConfig.baseURL}${APIConfig.clientesEndpoint}';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        List<dynamic> newClientes = data['result'] ?? [];
        setState(() {
          clientesMap.clear();
          newClientes.forEach((cliente) {
            clientesMap[cliente['nomeCliente']] =
                cliente['idClientes'].toString();
          });
        });
      } else {
        print('Nenhum cliente encontrado');
      }
    } else {
      print('Falha ao carregar clientes');
    }
  }

  Future<void> _getUsuarios({int page = 0}) async {
    String ciKey = await _getCiKey();
    Map<String, String> headers = {
      'Authorization': 'Bearer $ciKey',
    };
    var url = '${APIConfig.baseURL}${APIConfig.usuarioEndpoint}';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        List<dynamic> newUsuarios = data['result'] ?? [];
        setState(() {
          usuariosMap.clear();
          newUsuarios.forEach((usuario) {
            usuariosMap[usuario['nome']] = usuario['idUsuarios'].toString();
          });
        });
      } else {
        print('Nenhum cliente encontrado');
      }
    } else {
      print('Falha ao carregar clientes');
    }
  }

  void _clearFields() {
    _statusController.clear();
    _clientesController.clear();
    _statusController.clear();
    _clientesController.clear();
    _responsavelController.clear();
    _descricaoController.clear();
    _defeitoController.clear();
    _observacoesController.clear();
    _laudoTecnicoController.clear();
  }

  void _setDataInicial() {
    DateTime dataAtual = DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy').format(dataAtual);
    _dataInicialController.text = formattedDate;

    DateTime dataFinal = dataAtual.add(Duration(days: 3));
    String formattedFinalDate = DateFormat('dd/MM/yyyy').format(dataFinal);
    _dataFinalController.text = formattedFinalDate;
  }


  @override
  void initState() {
    super.initState();
    _getClientes();
    _getUsuarios();
    _setDataInicial();
    _selectedStatus = _statusOptions.first;
    print(_selectedStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Ordem de Serviço'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _clientesController,
                decoration: InputDecoration(
                  labelText: 'Cliente',
                  prefixIcon: Icon(Icons.account_circle_sharp),
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
                onChanged: (value) {
                  setState(() {
                    filteredClientes = clientesMap.keys
                        .where((cliente) =>
                        cliente.toLowerCase().contains(value.toLowerCase()))
                        .toList();
                  });
                },
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: filteredClientes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(filteredClientes[index]),
                    onTap: () {
                      setState(() {
                        _clientesController.text = filteredClientes[index];
                        filteredClientes.clear();
                      });
                    },
                  );
                },
              ),
              TextField(
                controller: _responsavelController,
                decoration: InputDecoration(
                  labelText: 'Responsavel',
                  prefixIcon: Icon(Icons.manage_accounts),
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
                onChanged: (value) {
                  setState(() {
                    filteredUsuarios = usuariosMap.keys
                        .where((usuario) =>
                        usuario.toLowerCase().contains(value.toLowerCase()))
                        .toList();
                  });
                },
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: filteredUsuarios.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(filteredUsuarios[index]),
                    onTap: () {
                      setState(() {
                        _responsavelController.text = filteredUsuarios[index];
                        filteredUsuarios.clear();
                      });
                    },
                  );
                },
              ),
              TextFormField(
                controller: _dataInicialController,
                decoration: InputDecoration(
                  labelText: 'Data Inicial',
                  prefixIcon: Icon(Icons.date_range),
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
              SizedBox(height: 10),
              TextFormField(
                controller: _dataFinalController,
                decoration: InputDecoration(
                  labelText: 'Data Final',
                  prefixIcon: Icon(Icons.date_range_outlined),
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
              SizedBox(height: 10),


        DropdownButtonFormField<String>(
        value: _selectedStatus,
            onChanged: (newValue) {
      setState(() {
      _selectedStatus = newValue!;
      _statusController.text = newValue;
      });
      },
        decoration: InputDecoration(
          labelText: 'Status',
          prefixIcon: Icon(Icons.add),
          filled: true,
          fillColor: Color(0xffb9dbfd).withOpacity(0.3),
          contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
          ),
        ),
        items: _statusOptions.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),

      SizedBox(height: 10),
              TextFormField(
                controller: _descricaoController,
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
                maxLines: 7,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _defeitoController,
                decoration: InputDecoration(
                  labelText: 'Defeito',
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
                maxLines: 7,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _observacoesController,
                decoration: InputDecoration(
                  labelText: 'Observações',
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
                maxLines: 7,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _laudoTecnicoController,
                decoration: InputDecoration(
                  labelText: 'Laudo Técnico',
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
                maxLines: 7,
              ),
              SizedBox(height: 10),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2c9b5b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  minimumSize: Size(200, 50),
                ),
                onPressed: () {
                  String status = _statusController.text.isNotEmpty ? _statusController.text : 'Aberto';
                  Map<String, dynamic> newOs = {

                    "dataInicial": _dataInicialController.text,
                    "dataFinal": _dataFinalController.text,
                    "status": status,
                    "clientes_id": clientesMap[_clientesController.text],
                    "usuarios_id": usuariosMap[_responsavelController.text],
                    "descricaoProduto": _descricaoController.text,
                    "defeito": _defeitoController.text,
                    "observacoes": _observacoesController.text,
                    "laudoTecnico": _laudoTecnicoController.text,
                    "termoGarantia": "",
                    "garantias_id": "",
                    "garantia": "",
                  };
                  _addOs(newOs, context);
                },
                child: Text('Adicionar OS',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
