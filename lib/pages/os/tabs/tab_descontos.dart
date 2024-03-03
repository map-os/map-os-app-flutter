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
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.0),
            TextFormField(
              controller: _descontoController,
              decoration: InputDecoration(labelText: 'Desconto'),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            // TextFormField(
            //   controller: _valorDescontolController,
            //   decoration: InputDecoration(labelText: 'Prev. Saída'),
            //   style: TextStyle(fontSize: 16.0),
            // ),
            SizedBox(height: 8.0),
            TextFormField(
              controller: _tipoDescontoController,
              decoration: InputDecoration(labelText: 'Tipo de Desconto'),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            SizedBox(height: 16.0),
            // Botão para atualizar a OS
            ElevatedButton(
              onPressed: _atualizarOS,
              child: Text('Atualizar OS'),
            ),
          ],
        ),
      ),
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
