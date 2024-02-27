import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/pages/clients/clients_screen.dart';
import 'package:mapos_app/pages/services/services_screen.dart';
import 'package:mapos_app/widgets/menu_lateral.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart'; // Importe o widget BottomNavigationBarWidget
import 'package:mapos_app/main.dart';


class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirmação"),
              content: Text("Deseja Fechar o APP"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Fecha o diálogo
                  },
                  child: Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () {
                    // Remova o token e outras informações de autenticação
                    removeTokenAndNavigateToLogin(context);
                  },
                  child: Text("Sair"),
                ),
              ],
            );
          },
        );

        // Retorna false para indicar que o pop não é tratado aqui
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Dashboard'),
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Confirmação"),
                      content: Text("Deseja realmente sair?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false); // Fecha o diálogo
                          },
                          child: Text("Cancelar"),
                        ),

                        TextButton(
                          onPressed: () {
                            // Remova o token e outras informações de autenticação
                            removeTokenAndNavigateToLogin(context);
                          },
                          child: Text("Sair"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        drawer: MenuLateral(),
        body: Center(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                } else {
                  String ciKey = snapshot.data?['ci_key'] ?? '';
                  List<dynamic> permissoes = snapshot.data?['permissoes'] ?? [];
                  bool temPermissaoCliente = false;
                  bool temPermissaoServicos = false;

                  for (var permissao in permissoes) {
                    if (permissao['vCliente'] == "1") {
                      temPermissaoCliente = true;
                    }

                    if (permissao['vServico'] == "1") {
                      temPermissaoServicos = true;
                    }

                    if (temPermissaoCliente && temPermissaoServicos) {
                      break;
                    }
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),
                      Visibility(
                        visible: temPermissaoCliente,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ClientesScreen()),
                            );
                          },
                          child: Text('Clientes'),
                        ),
                      ),
                      SizedBox(height: 20),
                      Visibility(
                        visible: temPermissaoServicos,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ServicesScreen()),
                            );
                          },
                          child: Text('Serviços'),
                        ),
                      ),
                    ],
                  );
                }
              }
            },
          ),
        ),
        bottomNavigationBar: BottomNavigationBarWidget(
          activeIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ci_key': ciKey, 'permissoes': permissoes};
  }

  void removeTokenAndNavigateToLogin(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('permissoes');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
