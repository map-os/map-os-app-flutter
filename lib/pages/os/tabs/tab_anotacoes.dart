import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TabAnotacoes extends StatefulWidget {
  final Map<String, dynamic> os;

  TabAnotacoes({required this.os});

  @override
  _TabAnotacoesState createState() => _TabAnotacoesState();
}

class _TabAnotacoesState extends State<TabAnotacoes> {
  List<dynamic> anotacoes = [];

  @override
  void initState() {
    super.initState();
    _getAnotacoesOs();
  }

  Future<Map<String, String>> _getCiKeyAndPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    return {'ciKey': ciKey};
  }

  Future<void> _getAnotacoesOs() async {
    try {
      Map<String, dynamic> keyAndPermissions = await _getCiKeyAndPermissions();
      String ciKey = keyAndPermissions['ciKey'] ?? '';
      Map<String, String> headers = {
        'Authorization': 'Bearer $ciKey',
      };
      var url = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}');
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data.containsKey('result') && data['result'].containsKey('anotacoes')) {
          setState(() {
            anotacoes = data['result']['anotacoes'];
          });
        } else {
          print('Key "anotacoes" not found in API response');
        }
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _exibirDialogoAdicionarAnotacao() async {
    String novaAnotacao = '';

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adicionar Anotação'),
          content: TextField(
            onChanged: (value) {
              novaAnotacao = value;
            },
            decoration: InputDecoration(hintText: "Digite sua anotação"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _adicionarAnotacao(context, novaAnotacao);
              },
              child: Text('Adicionar Anotação'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _adicionarAnotacao(BuildContext context, String novaAnotacao) async {
    try {
      Map<String, dynamic> keyAndPermissions = await _getCiKeyAndPermissions();
      String ciKey = keyAndPermissions['ciKey'] ?? '';
      Map<String, String> headers = {'Authorization': 'Bearer ${ciKey}'};

      var url = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}/anotacoes');

      var novaAnotacaoData = {'anotacao': novaAnotacao};
      var body = json.encode(novaAnotacaoData);

      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        // Atualiza a lista de anotações após adicionar uma nova anotação
        _getAnotacoesOs();

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Anotação adicionada com sucesso!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Falha ao adicionar anotação'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deletarAnotacao(BuildContext context, String idAnotacao) async {
    try {
      Map<String, dynamic> keyAndPermissions = await _getCiKeyAndPermissions();
      String ciKey = keyAndPermissions['ciKey'] ?? '';
      Map<String, String> headers = { 'Authorization': 'Bearer $ciKey'};

      var url = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}/anotacoes/$idAnotacao');

      var response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        _getAnotacoesOs();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Anotação excluída com sucesso!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Falha ao excluir anotação'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 12.0),
          Expanded(
            child: Center(
              child: anotacoes.isEmpty
                  ? CircularProgressIndicator()
                  : ListView.builder(
                padding: EdgeInsets.all(4.0),
                itemCount: anotacoes.length,
                itemBuilder: (context, index) {
                  var anotacao = anotacoes[index];
                  String idAnotacao = anotacao['idAnotacoes'];
                  String textoAnotacao = anotacao['anotacao'];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 56.0),
                          child: ListTile(
                            title: Text(
                              textoAnotacao,
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              _deletarAnotacao(context, idAnotacao);
                            },
                            child: Container(
                              width: 50,
                              color: Colors.red,
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _exibirDialogoAdicionarAnotacao();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.grey[300],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
