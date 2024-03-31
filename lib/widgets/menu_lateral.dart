import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/pages/clients/clients_screen.dart';
import 'package:mapos_app/main.dart';
import 'package:mapos_app/pages/services/services_screen.dart';
import 'package:mapos_app/pages/products/products_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:mapos_app/pages/profile/profile_screen.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:http/http.dart' as http;
import 'package:mapos_app/pages/audit/audit.dart';
import 'package:mapos_app/settings/settings_screen.dart';

class MenuLateral extends StatefulWidget {
  @override
  _MenuLateralState createState() => _MenuLateralState();
}

class _MenuLateralState extends State<MenuLateral> {
  String _imageUrl = '';
  String _appName = '';

  @override
  void initState() {
    super.initState();
    _loadEmitenteData();
  }

  Future<void> _loadEmitenteData() async {
    try {
      await _getEmitente();
    } catch (e) {
      print('Erro ao carregar dados do emissor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Drawer(
        width: MediaQuery.of(context).size.height * 0.3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), // Aqui definimos as bordas quadradas
            color: Colors.white,
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                } else {
                  List<dynamic> permissoes = snapshot.data?['permissoes'] ?? [];
                  bool temPermissaoCliente = false;
                  bool temPermissaoServicos = false;
                  bool temPermissaoProdutos = false;
                  bool temPermissaoAudit = false;

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
                    if (permissao['cAuditoria'] == "1") {
                      temPermissaoAudit = true;
                    }
                  }

                  return ListView(
                    padding: EdgeInsets.zero,
                    // Evitar bordas arredondadas no ListView
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: <Widget>[
                      Container(
                        height: MediaQuery.of(context).size.height * 0.25,
                        decoration: BoxDecoration(
                          color: Color(0xff333649),

                          image: _imageUrl.isNotEmpty
                          ? DecorationImage(
                          image: NetworkImage(_imageUrl),
                          fit: BoxFit.cover,
                          )
                              : DecorationImage(
                            image: AssetImage("lib/assets/images/logo-two.png"),
                            fit: BoxFit.cover,
                          ),
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(_appName,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        minVerticalPadding: 10.0,
                        leading: Icon(
                          Boxicons.bxs_home,
                          color: Color(0xff333649),
                          size: 20,
                        ),
                        title: Text(
                          'Início',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
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
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(),
                            ),
                          );
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
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsPage(),
                            ),
                          );
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
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClientesScreen(),
                              ),
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
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServicesScreen(),
                              ),
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
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              PageTransition(
                                child: ProductsScreen(),
                                type: PageTransitionType.leftToRight,
                              ),
                            );
                          },
                        ),
                      ),
                      Visibility(
                        visible: temPermissaoAudit,
                        child: ListTile(
                          leading: Icon(
                            Boxicons.bxs_time_five,
                            color: Color(0xff333649),
                            size: 20,
                          ),
                          title: Text(
                            'Auditoria',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              PageTransition(
                                child: Audit(),
                                type: PageTransitionType.leftToRight,
                              ),
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
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
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

  Future<void> _getEmitente({int page = 0}) async {
    Map<String, dynamic> keyAndPermissions = await _getUserData();
    String ciKey = keyAndPermissions['ci_key'] ?? ''; // Correção aqui
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
    };

    var url = '${APIConfig.baseURL}${APIConfig.emitenteEndpoint}?page=$page'; // Adicionei o parâmetro de página se necessário

    var response = await http.get(Uri.parse(url), headers: headers);


    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {

        setState(() {
          _imageUrl = data['result']['emitente']['url_logo'];
          _appName = data['result']['appName'];

        });
      } else {
        // Lidar com a resposta sem 'url_logo'
      }
    } else {
      print('Falha ao carregar emitentes');
    }
  }



  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Limpa os dados de autenticação
    await prefs.remove('token');
    await prefs.remove('permissoes');
    // Navega para a tela de login e remove todas as rotas anteriores
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage(() {})),
      (Route<dynamic> route) => false,
    );
  }
}
