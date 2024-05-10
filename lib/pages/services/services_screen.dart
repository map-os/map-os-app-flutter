import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:mapos_app/pages/services/services_manager.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';
import 'package:mapos_app/pages/services/services_add.dart';
import 'package:intl/intl.dart';

import '../../assets/app_colors.dart';

class ServicesScreen extends StatefulWidget {
  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  int _selectedIndex = 1;
  List<dynamic> services = [];
  List<dynamic> filteredServices = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  String _currentTheme = 'TemaPrimario';

  @override
  void initState() {
    super.initState();
    _getServices();
    _getTheme();
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _getServices() async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'Authorization': 'Bearer $ciKey',
    };

    var url =
        '${APIConfig.baseURL}${APIConfig.servicossEndpoint}';
    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        List<dynamic> newServices = data['result'];
        setState(() {
          services.clear();
          services.addAll(newServices);
          filteredServices = List.from(services);
        });
      } else {
        print('Key "services" not found in API response');
      }
    } else {
      print('Failed to load services');
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
      filteredServices = List.from(services);
    });
  }

  void _filterServices(String searchText) {
    setState(() {
      filteredServices = services
          .where((service) =>
          service['nome'].toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  _currentTheme == 'TemaPrimario'
    ? TemaPrimario.listagemBackground
        : TemaSecundario.listagemBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,

        title: !isSearching
            ? Text('Serviços')
            : TextField(
          controller: searchController,
          style: TextStyle(
            color: _currentTheme == 'TemaPrimario'
                ? TemaPrimario.ColorText
                : TemaSecundario.ColorText,
          ),
          onChanged: (value) {
            _filterServices(value);
          },
          decoration: InputDecoration(
            hintText: 'Pesquisar...',
            hintStyle: TextStyle(color: _currentTheme == 'TemaPrimario'
                ? TemaPrimario.buscaFont
                : TemaSecundario.buscaFont),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor:   _currentTheme == 'TemaPrimario'
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
        onRefresh: _getServices,
        child: filteredServices.isEmpty
            ? Center(
          child: services.isEmpty
              ? Text('Nenhum serviço encontrado') // Message when no services are found
              : CircularProgressIndicator(), // Loading indicator when waiting for services
        )
            : ListView.builder(
          itemCount: filteredServices.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.all(1.0),
              child: Card(
                color: _currentTheme == 'TemaPrimario'
                    ? TemaPrimario.listagemCard
                    : TemaSecundario.listagemCard,
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServicoEditScreen(
                          servico: filteredServices[index],
                        ),
                      ),
                    );
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
                            '${filteredServices[index]['idServicos']}',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width *
                                  0.04, // 4% da largura da tela
                              color: _currentTheme == 'TemaPrimario'
                                  ? TemaPrimario.ColorText
                                  : TemaSecundario.ColorTextID,
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
                              '${filteredServices[index]['nome']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: MediaQuery.of(context).size.width *
                                    0.04, // 4% da largura da tela
                                color: _currentTheme == 'TemaPrimario'
                                    ? TemaPrimario.ColorText
                                    : TemaSecundario.ColorText,
                              ),
                            ),
                            Text(
                              'Valor: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(double.parse(filteredServices[index]['preco']))}',
                              style: TextStyle(
                                color: _currentTheme == 'TemaPrimario'
                                    ? TemaPrimario.ColorText
                                    : TemaSecundario.ColorText,
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

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: FloatingActionButton(
        onPressed: () async {
          Map<String, dynamic> permissions = await _getCiKey();
          bool hasPermissionToAdd = false;
          for (var permissao in permissions['permissoes']) {
            if (permissao['aServico'] == '1') {
              hasPermissionToAdd = true;
              break;
            }
          }
          if (hasPermissionToAdd) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ServicoAddScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content:
                Text('Você não tem permissão para adicionar clientes.'),
              ),
            );
          }
        },
        child: Icon(Icons.add, color:
        Color(0xff5fb061)),
        backgroundColor: Color(0xFFECF6ED),
      ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        activeIndex: _selectedIndex,
        context: context,
        onTap: _onItemTapped,
      ),
    );
  }

  Future<void> _getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String theme = prefs.getString('theme') ?? 'TemaSecundario';
    setState(() {
      _currentTheme = theme;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
