import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:mapos_app/pages/clients/clients_manager.dart';
import 'package:mapos_app/pages/clients/clientes_add.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';

class ClientesScreen extends StatefulWidget {
  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  int _selectedIndex = 3;
  List<dynamic> clientes = [];
  List<dynamic> filteredClientes = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getClientes();
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _getClientes() async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    int page = 1;
    int perPage = 200;

    while (true) {
      var url =
          '${APIConfig.baseURL}${APIConfig.clientesEndpoint}?X-API-KEY=$ciKey&page=$page&per_page=$perPage';

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('result')) {
          List<dynamic> newClientes = data['result'] ?? 0;
          if (newClientes.isEmpty) {
            // Se não houver mais clientes, saia do loop
            break;
          } else {
            // Adicione os novos clientes à lista existente
            setState(() {
              clientes.addAll(newClientes);
              filteredClientes = List.from(clientes); // Atualizar a lista filtrada
            });
            // Avance para a próxima página
            page++;
          }
        } else {
          print('Chave "clientes" não encontrada na resposta da API');
          break; // Saia do loop se não houver clientes
        }
      } else {
        print('Falha ao carregar clientes');
        break; // Saia do loop em caso de falha
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
      filteredClientes = List.from(clientes); // Restaurar lista filtrada para a original
    });
  }

  void _filterClientes(String searchText) {
    setState(() {
      filteredClientes = clientes
          .where((cliente) => cliente['nomeCliente']
          .toLowerCase()
          .contains(searchText.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: !isSearching
            ? Text('Clientes', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.05))
            : TextField(
          controller: searchController,
          style: TextStyle(color: Colors.white, fontSize: MediaQuery.of(context).size.width * 0.05),
          onChanged: (value) {
            _filterClientes(value);
          },
          decoration: InputDecoration(
            hintText: 'Pesquisar...',
            hintStyle: TextStyle(color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            filled: true, // Preenchimento ativado
            fillColor: Color(0xffe79a24), // Cor de fundo personalizada
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
      body: filteredClientes.isEmpty
          ? Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: filteredClientes.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(1.0),
            child: Card(
              child: ListTile(
                onTap: () async {
                  Map<String, dynamic> permissions = await _getCiKey();
                  bool hasPermissionToEdit = false;
                  for (var permissao in permissions['permissoes']) {
                    if (permissao['eCliente'] == '1') {
                      hasPermissionToEdit = true;
                      break;
                    }
                  }
                  if (hasPermissionToEdit) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClienteEditScreen(
                          cliente: filteredClientes[index],
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Você não tem permissão para editar clientes.'),
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
                          '${filteredClientes[index]['idClientes']}',
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
                            '${filteredClientes[index]['nomeCliente']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width * 0.04, // 4% da largura da tela
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Cel: ${filteredClientes[index]['celular']}',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.029, // 4% da largura da tela
                                ),
                              ),
                              SizedBox(width: 8.0),
                              Text(
                                'Tel: ${filteredClientes[index]['telefone']}',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.029, // 4% da largura da tela
                                ),
                              ),
                            ],
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
            if (permissao['aCliente'] == '1') {
              hasPermissionToAdd = true;
              break;
            }
          }
          if (hasPermissionToAdd) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ClienteAddScreen()),
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
        context: context,
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
