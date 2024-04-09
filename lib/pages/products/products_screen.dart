import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:mapos_app/pages/products/products_manager.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';
import 'package:mapos_app/pages/products/products_add.dart';
import 'package:intl/intl.dart';
import 'package:mapos_app/assets/app_colors.dart';

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _selectedIndex = 0;
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  String _currentTheme = 'TemaSecundario'; // Tema padrão

  @override
  void initState() {
    super.initState();
    _getProducts();
    _getTheme();
  }

  Future<void> _getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String theme = prefs.getString('theme') ?? 'TemaPrimario';
    setState(() {
      _currentTheme = theme;
    });
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _getProducts() async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
    };
    var url =
        '${APIConfig.baseURL}${APIConfig.prodtuostesEndpoint}';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        List<dynamic> newProducts = data['result'];
        setState(() {
          products.addAll(newProducts);
          filteredProducts = List.from(products); // Update filtered list
        });
      } else {
        print('Key "products" not found in API response');
      }
    } else {
      print('Failed to load products');
    }
  }

  void _startSearch() {
    setState(() {
      isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      isSearching = false;
      searchController.clear();
      filteredProducts =
          List.from(products); // Restore filtered list to original
    });
  }

  void _filterProducts(String searchText) {
    setState(() {
      filteredProducts = products
          .where((product) => product['descricao']
              .toLowerCase()
              .contains(searchText.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentTheme == 'TemaPrimario'
          ? TemaPrimario.listagemBackground
          : TemaSecundario.listagemBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: !isSearching
            ? Text('Produtos')
            : TextField(
                controller: searchController,
                style: TextStyle(
                    color: _currentTheme == 'TemaPrimario'
                        ? TemaPrimario.buscaFont
                        : TemaSecundario.buscaFont,
                ),
                onChanged: (value) {
                  _filterProducts(value);
                },
                decoration: InputDecoration(
                  hintText: 'Pesquisar...',
                  hintStyle: TextStyle(
                      color: _currentTheme == 'TemaPrimario'
                          ? TemaPrimario.buscaFont
                          : TemaSecundario.buscaFont,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: _currentTheme == 'TemaPrimario'
                      ? TemaPrimario.buscaBack
                      : TemaSecundario.buscaBack,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                ),
              ),
        actions: <Widget>[
          isSearching
              ? IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    _stopSearch();
                  },
                )
              : IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _startSearch();
                  },
                ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: filteredProducts.isEmpty
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Card(
                      color: _currentTheme == 'TemaPrimario'
                          ? TemaPrimario.listagemCard
                          : TemaSecundario.listagemCard,
                      child: ListTile(
                        onTap: () async {
                          Map<String, dynamic> permissions = await _getCiKey();
                          bool hasPermissionToEdit = false;
                          for (var permissao in permissions['permissoes']) {
                            if (permissao['vProduto'] == '1') {
                              hasPermissionToEdit = true;
                              break;
                            }
                          }
                          if (hasPermissionToEdit) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductEditScreen(
                                  product: filteredProducts[index],
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(
                                    'Você não tem permissões para Vizualizar produtos.'),
                              ),
                            );
                          }
                        },
                        contentPadding: EdgeInsets.all(16.0),
                        title: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: _currentTheme == 'TemaPrimario'
                               ? TemaPrimario.backId
                            : TemaSecundario.backId,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  '${filteredProducts[index]['idProdutos']}',
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04, // 4% da largura da tela
                                    color: _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.idColor
                                        : TemaSecundario.idColor,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${filteredProducts[index]['descricao']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.04,
                                      color: _currentTheme == 'TemaPrimario'
                                          ? TemaPrimario.listagemTextColor
                                          : TemaSecundario.listagemTextColor,// 4% da largura da tela
                                    ),
                                  ),
                                  Text(
                                    'Valor: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(double.parse(filteredProducts[index]['precoVenda']))}',
                                    style: TextStyle(
                                      color: _currentTheme == 'TemaPrimario'
                                          ? TemaPrimario.listagemTextColor
                                          : TemaSecundario.listagemTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Map<String, dynamic> permissions = await _getCiKey();
          bool hasPermissionToAdd = false;
          for (var permissao in permissions['permissoes']) {
            if (permissao['aProduto'] == '1') {
              hasPermissionToAdd = true;
              break;
            }
          }
          if (hasPermissionToAdd) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProductAddScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content:
                    Text('Você não tem permissão para adicionar produtos.'),
              ),
            );
          }
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        activeIndex: _selectedIndex,
        context: context, // Passe o contexto aqui
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshProducts() async {
    setState(() {
      products.clear();
      filteredProducts.clear();
    });
    await _getProducts();
  }
}
