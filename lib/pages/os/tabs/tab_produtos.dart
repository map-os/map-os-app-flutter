import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapos_app/providers/calcTotal.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
/*
SANTT -- 2024
TODOS OS PRINTS SERÃO REMOVIDOS E SUBSTITUIDOS POR SNACKBAR --
github.com/Fesantt
*/
class TabProdutos extends StatefulWidget {
  final Map<String, dynamic> os;

  TabProdutos({required this.os});

  @override
  _TabProdutosState createState() => _TabProdutosState();
}

class _TabProdutosState extends State<TabProdutos> {
  late List<dynamic> osData = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = false;
  double _calctotal = 0.0;
  late OsCalculator osCalculator;

  @override
  void initState() {
    super.initState();
    _getProdutosOs();
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
                          osData[index]['descricao'] ?? 'NaN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 1),
                            Text(
                              'Valor: ${osData[index]['precoVenda'] ?? 'NaN'}',
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
                              bottomRight: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(Boxicons.bxs_trash),
                            color: Colors.white,
                            onPressed: () {
                              _deleteProduto(
                                int.parse(
                                    osData[index]['idProdutos_os']),
                              );
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
            ? _buildEmptyProductsWidget()
            : CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarDialogAdicionarProduto();
        },
        child: Icon(Icons.add),
      ),
    );
  }



  Widget _buildEmptyProductsWidget() {
    return Center(
      child: Text(
        'Nenhum produto adicionado.',
        style: TextStyle(fontSize: 18.0),
      ),
    );
  }

  Future<void> _getProdutosOs() async {
    setState(() {
      _loading = true; // Start loading indicator
    });

    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
    };
    var url =
        '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result') &&
          data['result'].containsKey('produtos')) {
        setState(() {
          osData = data['result']['produtos'];
          _loading = false;
        });
      } else {
        setState(() {
          osData = [];
          _loading = false;
        });
        print('Item não encontrado');
      }
    } else {
      setState(() {
        _loading = false;
      });
      print('Falha ao carregar OS');
    }
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _deleteProduto(int produtoId) async {
    try {
      Map<String, dynamic> keyAndPermissions = await _getCiKey();
      String ciKey = keyAndPermissions['ciKey'] ?? '';

      var url =
          '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}/produtos/$produtoId';

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
            content: Text('Produto excluído com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _getProdutosOs();
        _calctotal;
      } else {
      }
    } catch (e) {
      print('Erro durante a exclusão $e');
    }
  }

  Future<void> _mostrarDialogAdicionarProduto() async {
    TextEditingController _controller = TextEditingController();
    TextEditingController _quantityController =
    TextEditingController(text: '1'); // Controller for quantity input
    List<dynamic> produtos = [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Adicionar Produto'),
              content: Container(
                width: 300, // largura fixa
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(hintText: 'Pesquisar produtos'),
                      onChanged: (value) async {
                        produtos = await _buscarProdutos(value);
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
                        itemCount: produtos.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(produtos[index]['descricao'] ?? 'NaN'),
                            subtitle:
                            Text(produtos[index]['idProdutos'] ?? 'NaN'),
                            onTap: () {
                              try {
                                int idProduto =
                                int.parse(produtos[index]['idProdutos']);
                                String precoProduto =
                                    produtos[index]['precoVenda'] ?? '';
                                int quantidade =
                                int.parse(_quantityController.text);

                                _adicionarProduto(
                                    idProduto, precoProduto, quantidade);
                                Navigator.of(context).pop();
                              } catch (e) {
                                print(
                                    'Erro ao converter ID do produto para inteiro: $e');
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

  Future<List<dynamic>> _buscarProdutos(String query) async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';

    var url =
        '${APIConfig.baseURL}${APIConfig.prodtuostesEndpoint}/?search=$query';

    var response =
        await http.get(Uri.parse(url), headers: {'X-API-KEY': ciKey});

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = json.decode(response.body);
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('refresh_token')) {
        String refreshToken = data['refresh_token'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', refreshToken);
      } else {
        print('problema com sua sessão, faça login novamente!');
      }
      List<dynamic> produtos = responseData['result'];
      return produtos;
    } else {
      print('Falha ao carregar produtos!');
      return []; // Retorna uma lista vazia em caso de falha
    }
  }

  Future<void> _adicionarProduto(
      int idProdutos, String precoProduto, int quantidade) async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';

    var url =
        '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}/produtos/';

    var body = {
      'idProduto': idProdutos,
      'preco': precoProduto,
      'quantidade': quantidade.toString(),
    };

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'X-API-KEY': ciKey},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        bool status = responseData['status'];

        if (status) {
          _getProdutosOs();
          _calctotal;
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text('Produto adicionado com sucesso'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          print('Falha ao adicionar produto');
          // Exibindo SnackBar de falha
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text('Falha ao adicionar o produto'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('Falha ao adicionar produto: ${response.reasonPhrase}');

        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar o produto'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding product: $e');
      // Exibindo SnackBar de erro
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar o produto'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
