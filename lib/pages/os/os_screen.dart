import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:mapos_app/pages/os/os_view.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:intl/intl.dart';
import 'package:mapos_app/assets/app_colors.dart';
import 'package:mapos_app/pages/os/os_add.dart';
/*
SANTT -- 2024
github.com/Fesantt
*/
class OsScreen extends StatefulWidget {
  @override
  _OsScreenState createState() => _OsScreenState();
}

class _OsScreenState extends State<OsScreen> {
  int _selectedIndex = 4;
  List<dynamic> os = [];
  List<dynamic> filteredOs = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  String _currentTheme = 'TemaSecundario'; // Tema padrão
  ScrollController _scrollController = ScrollController();
  int _currentPage = 0; // Página atual
  bool _loading = false; // Variable to track loading state


  @override
  void initState() {
    super.initState();
    _getOs();
    _getTheme();
    _scrollController.addListener(_scrollListener);
  }



  Future<void> _getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String theme = prefs.getString('theme') ?? 'TemaSecundario';
    setState(() {
      _currentTheme = theme;
    });
  }

  void _scrollListener() {
    if (!_loading &&
        _scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
      _getOs(page: _currentPage + 1);
    }
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _getOs({int page = 1}) async {
    setState(() {
      _loading = true;
    });

    try {
      Map<String, dynamic> keyAndPermissions = await _getCiKey();
      String ciKey = keyAndPermissions['ciKey'] ?? '';
      Map<String, String> headers = {
        'Authorization': 'Bearer $ciKey',
      };
      var url = '${APIConfig.baseURL}${APIConfig.osEndpoint}?page=$page';

      var response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('result')) {
          List<dynamic> newOs = data['result'];
          setState(() {
            if (page == 1) {
              os.clear(); // Clear the existing list only when loading the first page
            }
            os.addAll(newOs); // Add new data to the list
            filteredOs = List.from(os); // Update filtered list
            _currentPage = page; // Update current page
          });
        } else {
          print('Key "result" not found in API response');
        }
      } else {
        print('Failed to load os: ${response.body}');
      }
    } catch (e) {
      print('Error loading os: $e');
    } finally {
      setState(() {
        _loading = false; // Reset loading indicator
      });
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
      filteredOs = List.from(os); // Restore filtered list to the original
    });
  }

  Future<void> _filterOs(String searchText) async {
    if (searchText.isEmpty) {
      setState(() {
        filteredOs.clear(); // Limpar a lista filtrada se não houver texto de pesquisa
      });
      return;
    }

    try {
      setState(() {
        _loading = true; // Ativar indicador de carregamento
      });

      final Map<String, dynamic> keyAndPermissions = await _getCiKey();
      final String ciKey = keyAndPermissions['ciKey'] ?? '';
      Map<String, String> headers = {
        'Authorization': 'Bearer $ciKey',
      };
      final url =
          '${APIConfig.baseURL}${APIConfig.osEndpoint}';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['result'];

        // Filtrar pelo nome do cliente ou ID da OS
        List<dynamic> filteredList = [];
        for (var item in data) {
          String clientName = item['nomeCliente'].toLowerCase();
          String osId = item['idOs'].toString().toLowerCase();
          if (clientName.contains(searchText.toLowerCase()) || osId.contains(searchText.toLowerCase())) {
            filteredList.add(item);
          }
        }

        setState(() {
          filteredOs = List.from(filteredList); // Atualizar lista filtrada com resultados da API
        });
      } else {
        print('Failed to filter os: ${response.body}');
      }
    } catch (e) {
      print('Error filtering os: $e');
    } finally {
      setState(() {
        _loading = false; // Desativar indicador de carregamento, independentemente do resultado
      });
    }
  }

  Color _getStatusColor(String status) {
    String statusLowerCase = status.toLowerCase().trim();

    switch (statusLowerCase) {
      case 'aberto':
        return Colors.black;
      case 'orçamento':
        return Colors.blue;
      case 'aprovado':
        return Colors.green;
      case 'em andamento':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      case 'finalizado':
        return Color(0xff225566);
      case 'Faturado':
        return Color(0xff8100fc);
      default:
        return Colors.grey;
    }
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
            ? Text('Ordens de Serviço')
            : TextField(
                controller: searchController,
                style: TextStyle(
                    color: _currentTheme == 'TemaPrimario'
                        ? TemaPrimario.buscaFont
                        : TemaSecundario.buscaFont,
                ),
                onChanged: (value) {
                  _filterOs(value);
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
      body: filteredOs.isEmpty
          ? Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        controller: _scrollController,
        itemCount: filteredOs.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 0.0),
            child: Card(
              color: _currentTheme == 'TemaPrimario'
                  ? TemaPrimario.listagemCard
                  : TemaSecundario.listagemCard,
              margin: EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 10.0),
              child: ListTile(
                onTap: () async {
                  Navigator.push(
                    context,
                    PageTransition(
                      child: OsManager(os: filteredOs[index]),
                      type: PageTransitionType.leftToRight,
                    ),
                  );
                },
                contentPadding: EdgeInsets.all(8.0),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _currentTheme == 'TemaPrimario'
                ? TemaPrimario.backId
                    : TemaSecundario.backId,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: EdgeInsets.all(10.0),
                          child: Center(
                            child: Text(
                              '${filteredOs[index]['idOs']}',
                              style: TextStyle(
                                fontSize: (MediaQuery.of(context).size.width *
                                    0.040),
                                fontWeight: FontWeight.bold,
                                color: _currentTheme == 'TemaPrimario'
                                    ? TemaPrimario.idColor
                                    : TemaSecundario.idColor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${filteredOs[index]['nomeCliente'].split(' ').take(2).join(' ')}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: (MediaQuery.of(context).size.width * 0.035),
                                color: _currentTheme == 'TemaPrimario'
                                    ? TemaPrimario.listagemTextColor
                                    : TemaSecundario.listagemTextColor,
                              ),
                            ),

                            Text(
                              'Inicio: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(filteredOs[index]['dataInicial'] ?? '0'))}',
                              style: TextStyle(
                                fontSize: (MediaQuery.of(context).size.width *
                                    0.0350),
                                color: _currentTheme == 'TemaPrimario'
                                    ? TemaPrimario.listagemTextColor
                                    : TemaSecundario.listagemTextColor,
                              ),
                            ),
                            Text(
                              'Limite: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(filteredOs[index]['dataFinal'] ?? '0'))}',
                              style: TextStyle(
                                fontSize: (MediaQuery.of(context).size.width *
                                    0.0350),
                                color: _currentTheme == 'TemaPrimario'
                                    ? TemaPrimario.listagemTextColor
                                    : TemaSecundario.listagemTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      child: Text(
                        '${filteredOs[index]['status'] ?? ''}',
                        style: TextStyle(
                          color: _getStatusColor(
                              filteredOs[index]['status'] ?? ''),
                          fontWeight: FontWeight.bold,
                          fontSize: (MediaQuery.of(context).size.width * 0.025),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: FloatingActionButton(
        onPressed: () async {
          Map<String, dynamic> permissions = await _getCiKey();
          bool hasPermissionToAdd = false;
          for (var permissao in permissions['permissoes']) {
            if (permissao['aOs'] == '1') {
              hasPermissionToAdd = true;
              break;
            }
          }
          if (hasPermissionToAdd) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdicionarOs()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                    'Você não tem permissão para adicionar Ordens de Serviço.'),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
