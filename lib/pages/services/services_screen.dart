import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:mapos_app/pages/services/services_manager.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';
import 'package:mapos_app/pages/services/services_add.dart';

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

  @override
  void initState() {
    super.initState();
    _getServices();
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


    while (true) {
      var url =
          '${APIConfig.baseURL}${APIConfig.servicossEndpoint}?X-API-KEY=$ciKey';

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('result')) {
          List<dynamic> newServices = data['result'];
          if (newServices.isEmpty) {
            // If no more services, exit the loop
            break;
          } else {
            setState(() {
              services.addAll(newServices);
              filteredServices = List.from(services); // Update filtered list
            });

          }
        } else {
          print('Key "services" not found in API response');
          break;
        }
      } else {
        print('Failed to load services');
        break;
      }
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
      filteredServices = List.from(services); // Restore filtered list to original
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: !isSearching
            ? Text('Serviços')
            : TextField(
          controller: searchController,
          style: TextStyle(color: Colors.white),
          onChanged: (value) {
            _filterServices(value);
          },
          decoration: InputDecoration(
            hintText: 'Pesquisar...',
            hintStyle: TextStyle(color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Color(0xffe79a24),
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
      body: filteredServices.isEmpty
          ? Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: filteredServices.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(1.0),
            child: Card(
              child: ListTile(
                onTap: () async {
                  Map<String, dynamic> permissions = await _getCiKey();
                  bool hasPermissionToEdit = false;
                  for (var permissao in permissions['permissoes']) {
                    if (permissao['eServico'] == '1') {
                      hasPermissionToEdit = true;
                      break;
                    }
                  }
                  if (hasPermissionToEdit) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServicoEditScreen(
                          servico: filteredServices[index],
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text(
                            'Você não tem permissões para editar serviços.'),
                      ),
                    );
                  }
                },
                contentPadding: EdgeInsets.all(16.0),
                title: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFFD8900),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          '${filteredServices[index]['idServicos']}',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.04, // 4% da largura da tela

                            color: Colors.white,
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
                              fontSize: MediaQuery.of(context).size.width * 0.04, // 4% da largura da tela
                            ),
                          ),
                          Text(
                            'Valor: ${filteredServices[index]['preco']}',
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
      floatingActionButton: FloatingActionButton(
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
                content: Text('Você não tem permissão para adicionar clientes.'),
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
}

