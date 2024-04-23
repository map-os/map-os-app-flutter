import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
/*
SANTT -- 2024
github.com/Fesantt/MAP-OS-APP-FLUTTER
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
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  height: 90, // Altura do card
                  child: Stack(
                    children: [
                      ListTile(
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          osData[index]['nome'] ?? 'NaN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 1),
                            Text(
                              'Preço: ${osData[index]['preco'] ?? 'NaN'}',
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Qtd: ${osData[index]['quantidade'] ?? 'NaN'}',
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          height: 100, // Mesma altura do card
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.only(
                              // topLeft: Radius.circular(10),
                              bottomRight: Radius.circular(0),
                              topRight: Radius.circular(0),
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.delete),
                            color: Colors.white,
                            onPressed: () {
                              _deleteServico(int.parse(osData[index]['idServicos_os']));
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
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
      'Authorization': 'Bearer $ciKey',
    };
    var url =
        '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}?X-API-KEY=$ciKey';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);

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
      headers: { 'Authorization': 'Bearer $ciKey'},
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
    List<dynamic> servicos = [];
    Map<int, int> quantidades = {}; // Mapa para armazenar a quantidade de cada serviço

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void decrementarQuantidade(int idServico) {
              if (quantidades.containsKey(idServico) && quantidades[idServico]! > 1) {
                setState(() {
                  quantidades[idServico] = quantidades[idServico]! - 1;
                });
              }
            }

            void incrementarQuantidade(int idServico) {
              setState(() {
                quantidades[idServico] = (quantidades[idServico] ?? 0) + 1;
              });
            }

            return AlertDialog(
              title: Text('Adicionar Serviço'),
              content: Container(
                width: 300,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(hintText: 'Pesquisar serviços'),
                      onChanged: (value) async {
                        servicos = await _buscarServicos(value);
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: servicos.length,
                        itemBuilder: (context, index) {
                          final idServico = int.tryParse(servicos[index]['idServicos']) ?? 0;
                          final quantidade = quantidades[idServico] ?? 0;

                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(child: Text(servicos[index]['nome'] ?? 'NaN')),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () => decrementarQuantidade(idServico),
                                ),
                                Text(quantidade.toString()),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () => incrementarQuantidade(idServico),
                                ),
                              ],
                            ),
                            onTap: () {
                              try {
                                final preco = double.tryParse(servicos[index]['preco'] ?? '0') ?? 0.0;
                                _adicionarServico(idServico, quantidade, preco);
                                Navigator.of(context).pop();
                              } catch (e) {
                                print('Erro ao adicionar serviço: $e');
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
      'Authorization': 'Bearer $ciKey',
    };
    var url =
        '${APIConfig.baseURL}${APIConfig.servicossEndpoint}/?search=$query';

    var response = await http.get(
      Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
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
        headers: {'Authorization': 'Bearer ${ciKey}'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
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
