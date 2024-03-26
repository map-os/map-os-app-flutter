import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
/*
SANTT -- 2024
TODOS OS PRINTS SERÃO REMOVIDOS E SUBSTITUIDOS POR SNACKBAR --
github.com/Fesantt
*/
class TabServicos extends StatefulWidget {
  final Map<String, dynamic> os;

  TabServicos({required this.os});

  @override
  _TabServicosState createState() => _TabServicosState();
}

class _TabServicosState extends State<TabServicos> {
  late List<dynamic> osData = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _getOs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        child: osData.isNotEmpty
            ? ListView.builder(
                itemCount: osData.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(osData[index]['nome'] ?? 'NaN'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preço: ${osData[index]['preco'] ?? 'NaN'}'),
                          Text('Qtd.: ${osData[index]['quantidade'] ?? 'NaN'}'),
                          Text(
                              'idp_os: ${osData[index]['idServicos_os'] ?? 'NaN'}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteServico(
                              int.parse(osData[index]['idServicos_os']));
                        },
                      ),
                    ),
                  );
                },
              )
            : osData.isEmpty && !_loading
                ? _buildEmptyServicesWidget()
                : CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarDialogAdicionarServico();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyServicesWidget() {
    return Center(
      child: Text(
        'Nenhum serviço adicionado.',
        style: TextStyle(fontSize: 18.0),
      ),
    );
  }

  Future<void> _getOs() async {
    setState(() {
      _loading = true;
    });

    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
    };
    var url =
        '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}?X-API-KEY=$ciKey';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('refresh_token')) {
        String refreshToken = data['refresh_token'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', refreshToken);
      } else {
        print('problema com sua sessão, faça login novamente!');
      }
      if (data.containsKey('result') &&
          data['result'].containsKey('servicos')) {
        setState(() {
          osData = data['result']['servicos'];
          _loading = false;
        });
      } else {
        setState(() {
          osData = [];
          _loading = false;
        });
        print('Key "servicos" not found in API response');
      }
    } else {
      setState(() {
        _loading = false;
      });
      print('Failed to load services');
    }
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _deleteServico(int servicoId) async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';

    var url =
        '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}/servicos/$servicoId';

    var response = await http.delete(
      Uri.parse(url),
      headers: {'X-API-KEY': ciKey},
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
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Serviço excluído com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      _getOs();
    } else {
      print('Failed to delete service');
    }
  }
  Future<void> _mostrarDialogAdicionarServico() async {
    TextEditingController _controller = TextEditingController();
    TextEditingController _quantityController =
    TextEditingController(text: '1');
    List<dynamic> servicos = [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog( // Movido o AlertDialog aqui
              title: Text('Adicionar Serviço'),
              content: Container(
                width: 300, // largura fixa
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(hintText: 'Pesquisar serviços'),
                      onChanged: (value) async {
                        servicos = await _buscarServicos(value);
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(hintText: 'Quantidade'),
                      keyboardType: TextInputType.number,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: servicos.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(servicos[index]['nome'] ?? 'NaN'),
                            subtitle:
                            Text(servicos[index]['idServicos'] ?? 'NaN'),
                            onTap: () {
                              try {
                                int idServico =
                                int.parse(servicos[index]['idServicos']);
                                double preco =
                                double.parse(servicos[index]['preco'] ?? '0');
                                int quantidade =
                                int.parse(_quantityController.text);
                                _adicionarServico(idServico, quantidade, preco);
                                Navigator.of(context).pop();
                              } catch (e) {
                                print('Error adding service: $e');
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Future<List<dynamic>> _buscarServicos(String query) async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
    };
    var url =
        '${APIConfig.baseURL}${APIConfig.servicossEndpoint}/?search=$query';

    var response = await http.get(
      Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('refresh_token')) {
        String refreshToken = data['refresh_token'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', refreshToken);
      } else {
        print('problema com sua sessão, faça login novamente!');
      }
      Map<String, dynamic> responseData = json.decode(response.body);
      List<dynamic> servicos = responseData['result'];
      return servicos;
    } else {
      print('Failed to fetch services');
      return [];
    }
  }

  Future<void> _adicionarServico(
      int idServico, int quantidade, double preco) async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';

    var url =
        '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}/servicos/';

    var body = {
      'idServico': idServico,
      'quantidade': quantidade,
      'preco': preco,
    };

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'X-API-KEY': ciKey},
        body: json.encode(body),
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
        Map<String, dynamic> responseData = json.decode(response.body);
        bool status = responseData['status'];

        if (status) {
          _getOs();
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text('Serviço adicionado com sucesso'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          print('Failed to add service');
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text('Falha ao adicionar o serviço'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('Failed to add service: ${response.reasonPhrase}');
        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar o serviço'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding service: $e');
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar o serviço'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
