import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapos_app/config/constants.dart';

class TabDescontos extends StatefulWidget {
  final Map<String, dynamic> os;

  TabDescontos({required this.os});

  @override
  _TabDescontosState createState() => _TabDescontosState();
}

class _TabDescontosState extends State<TabDescontos> {
  late TextEditingController _descontoController;
  late TextEditingController _valorDescontolController;
  late TextEditingController _tipoDescontoController;
  String _selectedOption = 'real';

  @override
  void initState() {
    super.initState();
    _descontoController = TextEditingController(text: widget.os['desconto']);
    _valorDescontolController =
        TextEditingController(text: widget.os['valor_desconto']);
    _tipoDescontoController =
        TextEditingController(text: widget.os['tipo_desconto']);
  }

  @override
  void dispose() {
    _descontoController.dispose();
    _valorDescontolController.dispose();
    _tipoDescontoController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData suffixIcon;
    if (_selectedOption == 'real') {
      suffixIcon = Icons.attach_money;
    } else {
      suffixIcon = Icons.percent;
    }

    return Stack(
      children: [
        SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.0),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey.shade400),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(0, 2), // changes position of shadow
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedOption,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedOption = newValue!;
                      });
                    },
                    items: ['Real', 'Porcento'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value.toLowerCase(),
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Selecionar',
                      suffixIcon: Icon(suffixIcon),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  controller: _descontoController,
                  decoration: InputDecoration(
                    labelText: 'Desconto',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    suffixIcon: _selectedOption == 'real'
                        ? Icon(Icons.attach_money)
                        : Icon(Icons.percent),
                  ),
                  style: TextStyle(fontSize: 16.0),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _atualizarOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff2c9b5b),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    minimumSize: Size(430, 60),
                  ),
                  child: Text(
                    'Adicionar Desconto',
                    style: TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 0,
          right: 0,
           height: 250,// Definindo a altura com base na altura da tela
          child: Transform.rotate(
            angle: 0, // Ângulo ajustado para criar a diagonal
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              width: 1000, // Definindo a largura com base na largura da tela
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(0),
              ),
              child: Center(
                child: Text(
                  'Em Construção',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Função para atualizar a OS
  void _atualizarOS() async {
    Map<String, dynamic> dadosAtualizados = {
      'dataInicial': _descontoController.text,
      'dataFinal': _valorDescontolController.text,
      'nome': _tipoDescontoController.text,
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
