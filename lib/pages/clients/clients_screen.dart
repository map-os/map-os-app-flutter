import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:mapos_app/pages/clients/clients_manager.dart';

class ClientesScreen extends StatefulWidget {
  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<dynamic> clientes = [];
  List<dynamic> filteredClientes = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getClientes();
  }

  Future<String> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    return ciKey;
  }

  Future<void> _getClientes() async {
    String ciKey = await _getCiKey();
    int page = 1;
    int perPage = 200;

    while (true) {
      var url =
          '${APIConfig.baseURL}${APIConfig.clientesEndpoint}?X-API-KEY=$ciKey&page=$page&per_page=$perPage';

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('result')) {
          List<dynamic> newClientes = data['result'];
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
        title: !isSearching
            ? Text('Clientes')
            : TextField(
          controller: searchController,
          style: TextStyle(color: Colors.white),
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
            contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClienteEditScreen(
                        cliente: filteredClientes[index],
                      ),
                    ),
                  );
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
                            fontSize: 20,
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
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                  'Celular: ${filteredClientes[index]['celular']}'),
                              SizedBox(width: 8.0),
                              Visibility(
                                visible: false,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Documento: ${filteredClientes[index]['documento']}'),
                                    Text(
                                        'Email: ${filteredClientes[index]['email']}'),
                                    Text(
                                        'Rua: ${filteredClientes[index]['rua']}'),
                                    Text(
                                        'numero: ${filteredClientes[index]['numero']}'),
                                    Text(
                                        'Bairro: ${filteredClientes[index]['bairro']}'),
                                    Text(
                                        'CEP: ${filteredClientes[index]['cep']}'),
                                    Text(
                                        'Cidade: ${filteredClientes[index]['cidade']}'),
                                    Text(
                                        'Estado: ${filteredClientes[index]['estado']}'),
                                    Text(
                                        'Complemento: ${filteredClientes[index]['complemento']}'),
                                  ],
                                ),
                              ),
                              Text(
                                  'Telefone: ${filteredClientes[index]['telefone']}'),
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
    );
  }
}
