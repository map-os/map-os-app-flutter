import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/pages/clients/clients_screen.dart';
import 'package:mapos_app/main.dart';
import 'package:mapos_app/pages/services/services_screen.dart';
import 'package:mapos_app/pages/products/products_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class MenuLateral extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.55, // Defina a largura desejada para o Drawer
      child: Drawer(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.1, // Defina a largura desejada para o ListView
          color: Colors.white,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                } else {
                  // String ciKey = snapshot.data?['ci_key'] ?? '';
                  List<dynamic> permissoes = snapshot.data?['permissoes'] ?? [];
                  bool temPermissaoCliente = false;
                  bool temPermissaoServicos = false;
                  bool temPermissaoProdutos = false;

                  for (var permissao in permissoes) {
                    if (permissao['vCliente'] == "1") {
                      temPermissaoCliente = true;
                    }
                    if (permissao['vServico'] == "1") {
                      temPermissaoServicos = true;
                    }
                    if (permissao['vProduto'] == "1") {
                      temPermissaoProdutos = true;
                    }
                  }

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color: Color(0xff333649),
                          image: DecorationImage(
                            image: AssetImage("lib/assets/images/logo-two.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'MAP-OS APP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          Boxicons.bxs_home,
                          color: Color(0xff333649),
                          size: 20,
                        ),
                        title: Text(
                          'Início',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: MediaQuery.of(context).size.width * 0.044,),
                        ),
                        onTap: () {
                          // Implemente a lógica desejada para o Item 1 aqui
                          Navigator.pop(context);
                          // Navegar para a tela de início
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Boxicons.bxs_user_circle,
                          color: Color(0xff333649),
                          size: 20,
                        ),
                        title: Text(
                          'Perfil',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: MediaQuery.of(context).size.width * 0.044,                          ),
                        ),
                        onTap: () {
                          // Implemente a lógica desejada para o Item 2 aqui
                          Navigator.pop(context);
                          // Navegar para a tela de perfil
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Boxicons.bxs_cog,
                          color: Color(0xff333649),
                          size: 20,
                        ),
                        title: Text(
                          'Configurações',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: MediaQuery.of(context).size.width * 0.044,                          ),
                        ),
                        onTap: () {
                          // Implemente a lógica desejada para o Item 3 aqui
                          Navigator.pop(context);
                          // Navegar para a tela de configurações
                        },
                      ),
                      Divider(
                        color: Color(0xff333649),
                      ),
                      Visibility(
                        visible: temPermissaoCliente,
                        child: ListTile(
                          leading: Icon(
                            Boxicons.bxs_user,
                            color: Color(0xff333649),
                            size: 20,
                          ),
                          title: Text(
                            'Clientes',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: MediaQuery.of(context).size.width * 0.044,                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ClientesScreen()),
                            );
                          },
                        ),
                      ),
                      Visibility(
                        visible: temPermissaoServicos,
                        child: ListTile(
                          leading: Icon(
                            Boxicons.bxs_wrench,
                            color: Color(0xff333649),
                            size: 20,
                          ),
                          title: Text(
                            'Serviços',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: MediaQuery.of(context).size.width * 0.044,                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ServicesScreen()),
                            );
                          },
                        ),
                      ),
                      Visibility(
                        visible: temPermissaoProdutos,
                        child: ListTile(
                          leading: Icon(
                            Boxicons.bxs_basket,
                            color: Color(0xff333649),
                            size: 20,
                          ),
                          title: Text(
                            'Produtos',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: MediaQuery.of(context).size.width * 0.044,                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                                PageTransition(
                                  child: ProductsScreen(),
                                  type: PageTransitionType.leftToRight,
                                )
                            );
                          },
                        ),
                      ),
                      Divider(
                        color: Color(0xff333649),
                      ),
                      ListTile(
                        leading: Icon(
                          Boxicons.bx_log_out,
                          color: Color(0xff333649),
                          size: 20,
                        ),
                        title: Text(
                          'Sair',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: MediaQuery.of(context).size.width * 0.044,                          ),
                        ),
                        onTap: () {
                          // Implemente a lógica para o logout aqui
                          _logout(context);
                        },
                      ),
                    ],
                  );
                }
              }
            },
          ),
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

  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Limpa os dados de autenticação
    await prefs.remove('token');
    await prefs.remove('permissoes');
    // Navega para a tela de login e remove todas as rotas anteriores
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage((){})),
          (Route<dynamic> route) => false,
    );

  }
}
