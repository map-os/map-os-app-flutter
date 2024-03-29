import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';

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
  Future<void> _exibirDialogoAdicionarAnotacao() async {
    String novaAnotacao = ''; // Variável para armazenar a nova anotação

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adicionar Anotação'),
          content: TextField(
            onChanged: (value) {
              novaAnotacao = value; // Atualiza a variável com o texto digitado
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
                              anotacoes[index],
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
          _exibirDialogoAdicionarAnotacao(); // Exibe o diálogo para adicionar uma nova anotação
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.grey[300], // Cor do botão flutuante
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Posicionamento do botão flutuante
    );
  }



    Future<Map<String, dynamic>> _getCiKeyAndPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _getAnotacoesOs() async {
    try {
      Map<String, dynamic> keyAndPermissions =
      await _getCiKeyAndPermissions();
      String ciKey = keyAndPermissions['ciKey'] ?? '';
      Map<String, String> headers = {'X-API-KEY': ciKey};

      var url = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}');
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data.containsKey('result') &&
            data['result'] is Map &&
            data['result'].containsKey('anotacoes')) {
          var annotationsData = data['result']['anotacoes'] as List;
          var idanotacao = data['result']['anotacoes'];
          var annotations = annotationsData.map((
              annotation) => annotation['anotacao']).toList();
          setState(() {
            anotacoes = annotations;
          });
        } else {
          print(
              'Anotações não encontradas na resposta da API');
        }
      } else {
        print('Falha ao carregar anotações');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _adicionarAnotacao(BuildContext context, String novaAnotacao) async {
    try {
      Map<String, dynamic> keyAndPermissions = await _getCiKeyAndPermissions();
      String ciKey = keyAndPermissions['ciKey'] ?? '';
      Map<String, String> headers = {'X-API-KEY': ciKey};

      var url = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}/anotacoes');

      // Convertendo o mapa 'body' em uma string JSON
      var body = json.encode({'anotacao': novaAnotacao});

      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        // Atualiza a lista de anotações após adicionar uma nova anotação
        setState(() {
          anotacoes.add(novaAnotacao);
        });
        Navigator.of(context).pop();

        // Exibir Snackbar de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Anotação adicionada com sucesso!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Exibir Snackbar de falha
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Falha ao adicionar anotação'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Exibir Snackbar de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  Future<void> _deletarAnotacao(BuildContext context, String anotacaoId) async {
    try {
      Map<String, dynamic> keyAndPermissions = await _getCiKeyAndPermissions();
      String ciKey = keyAndPermissions['ciKey'] ?? '';
      Map<String, String> headers = {'X-API-KEY': ciKey};

      var url = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}/anotacoes/$anotacaoId');

      var response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        // Remova a anotação da lista após a exclusão bem-sucedida
        setState(() {
          anotacoes.removeWhere((anotacao) => anotacao['id'] == anotacaoId);
        });

        // Exibir Snackbar de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Anotação deletada com sucesso!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red, // Por exemplo, cor vermelha para indicar a exclusão
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Exibir Snackbar de falha
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Falha ao deletar anotação',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red, // Por exemplo, cor vermelha para indicar a falha
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Exibir Snackbar de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red, // Por exemplo, cor vermelha para indicar erro
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
