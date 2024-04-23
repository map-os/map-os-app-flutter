import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:mapos_app/pages/clients/clients_screen.dart';
import 'package:mapos_app/pages/os/os_screen.dart';
import 'package:mapos_app/pages/products/products_screen.dart';
import 'package:mapos_app/pages/services/services_screen.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';
import 'package:mapos_app/data/dashboardData.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mapos_app/pages/audit/audit.dart';
import 'package:intl/intl.dart';
import 'package:mapos_app/assets/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/assets/app_colors.dart';
import 'package:mapos_app/widgets/calendario.dart';
import 'package:mapos_app/widgets/dash.dart';
import 'package:mapos_app/main.dart';
import 'package:page_transition/page_transition.dart';
import 'package:mapos_app/pages/profile/profile_screen.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';


class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 2;
  int countOs = 0;
  int clientes = 0;
  int produtos = 0;
  int servicos = 0;
  int garantias = 0;
  int vendas = 0;
  List<String> osAbertasList = [];
  List<String> osAndamentoList = [];
  List<String> estoqueBaixoList = [];


  @override
  void initState() {
    super.initState();
    _fetchData();
    _requestPermissions();
    _loadTheme();
    _getProfile();
  }

  String _currentTheme = 'TemaSecundario';

  Future<void> _loadTheme() async {
    ThemeMode themeMode = await ThemePreferences().getTheme();
    setState(() {
      _currentTheme =
      themeMode == ThemeMode.dark ? 'TemaPrimario' : 'TemaSecundario';
    });
  }

  void _fetchData() async {
    DashboardData dashboardData = DashboardData();
    await dashboardData.fetchData(context);

    setState(() {
      countOs = dashboardData.countOs;
      clientes = dashboardData.clientes;
      produtos = dashboardData.produtos;
      servicos = dashboardData.servicos;
      garantias = dashboardData.garantias;
      vendas = dashboardData.vendas;
      osAbertasList = dashboardData.osAbertasList
          .map((os) => '${os.id} - ${os.nomeCliente} - ${os.dataInicial} - ${os
          .dataFinal}')
          .toList();
      osAndamentoList = dashboardData.osAndamentoList
          .map((os) => '${os.id} - ${os.nomeCliente} - ${os.dataInicial} - ${os
          .dataFinal}')
          .toList();
      estoqueBaixoList = dashboardData.estoqueBaixoList
          .map((os) => '${os.id} - ${os.descricao} - ${os.precoVenda} - ${os
          .estoque}')
          .toList();
    });
  }


  void _requestPermissions() async {
    var status = await Permission.storage.status;
    var camera = await Permission.camera.status;
    var notification = await Permission.notification.status;
    if (!status.isGranted || !camera.isGranted || !notification.isGranted) {
      await Permission.storage.request();
      await Permission.camera.request();
      await Permission.notification.request();
    }
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(
                  Icons.account_circle,
                  color: Colors.black87,
                ),
                title: Text(
                  'Perfil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    // color: Colors.blue,
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
              Divider(
                height: 10,
                thickness: 1,
                color: Colors.grey[300],
              ),
              ListTile(
                leading: Icon(
                  Icons.info,
                  color: Colors.black87,
                ),
                title: Text(
                  'Auditoria',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    // color: Colors.blue,
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
              Divider(
                height: 10,
                thickness: 1,
                color: Colors.grey[300],
              ),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: Text(
                  'Sair',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    // color: Colors.red,
                  ),
                ),
                onTap: () {
                  _logout(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentTheme == 'TemaPrimario'
          ? TemaPrimario.backgroundColor
          : TemaSecundario.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        automaticallyImplyLeading: false, // Desativa o botão de voltar
        actions: [
          IconButton(
            icon: _currentTheme == 'TemaPrimario'
                ? Icon(Icons.nightlight_round,
                color: Color(0xFFDC7902)) // Ícone de lua
                : Icon(Icons.wb_sunny), // Ícone de sol
            onPressed: () {
              setState(() {
                _currentTheme =
                _currentTheme == 'TemaPrimario'
                    ? 'TemaSecundario'
                    : 'TemaPrimario';
                _saveTheme(_currentTheme);
              });
            },
          ),
          SizedBox(width: 10),
          Container(
            padding: EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                // Abrir o menu suspenso manualmente ao clicar na imagem de perfil
                _showProfileMenu(context);
              },
              child: CircleAvatar(
                radius: 15,
                backgroundImage: _profileData['url_image_user'] != null &&
                    (_profileData['url_image_user'].toLowerCase().endsWith('.png') ||
                        _profileData['url_image_user'].toLowerCase().endsWith('.jpg'))
                    ? Image.network(_profileData['url_image_user']).image
                    : AssetImage('lib/assets/images/profile.png'),
              ),
            ),
          ),
        ],
      ),
      // drawer: MenuLateral(),
      bottomNavigationBar: BottomNavigationBarWidget(

        activeIndex: _selectedIndex,
        context: context,
        onTap: _onItemTapped,
      ),
      body: ListView(
        children: [
          Container(
            height: MediaQuery
                .of(context)
                .size
                .width * 0.80,
            width: double.infinity,
            decoration: BoxDecoration(
                color: _currentTheme == 'TemaPrimario'
                    ? TemaPrimario.primaryColor
                    : TemaSecundario.primaryColor,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54.withOpacity(0.5), // Cor da sombra
                    spreadRadius: 0.01, // Espalhamento da sombra
                    blurRadius: 10, // Desfoque da sombra
                    offset: Offset(0, 0), // Posição da sombra
                  ),
                ]
            ),
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageTransition(
                            child: ClientesScreen(),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.3,
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              10.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: CardWidget(
                            color: Colors.transparent,
                            content: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.borderDash
                                        : TemaSecundario.borderDash,
                                    width: 2.5),
                                borderRadius: BorderRadius.circular(10.0),
                                gradient: LinearGradient(
                                  colors: [
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor1
                                        : TemaSecundario.gradienteColor1,
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor2
                                        : TemaSecundario.gradienteColor2,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      Icons.supervisor_account,
                                      size: 30.0,
                                      color: _currentTheme == 'TemaPrimario'
                                          ? TemaPrimario.iconColor
                                          : TemaSecundario.iconColorCliente
                                  ),
                                  SizedBox(height: 1.0),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$clientes',
                                      style: TextStyle(
                                        fontSize: 24.0,
                                        color: _currentTheme == 'TemaPrimario'
                                            ? TemaPrimario.ColorText
                                            : TemaSecundario.ColorText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 1.0),
                                  Text(
                                    'Clientes',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: _currentTheme == 'TemaPrimario'
                                          ? TemaPrimario.ColorText
                                          : TemaSecundario.ColorText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    //container serviços
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageTransition(
                            child: ServicesScreen(),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.3, // 40% da largura da tela
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.180, // 20% da altura da tela
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              10.0), // Borda arredondada
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: CardWidget(
                            color: Colors.transparent,
                            content: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.borderDash
                                        : TemaSecundario.borderDash,
                                    width: 2.5),
                                borderRadius: BorderRadius.circular(10.0),
                                gradient: LinearGradient(
                                  colors: [
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor1
                                        : TemaSecundario.gradienteColor1,
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor2
                                        : TemaSecundario.gradienteColor2,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Boxicons.bxs_wrench,
                                    size: 30.0,
                                    color: _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.iconColor
                                        : TemaSecundario.iconColorServicos,
                                  ),
                                  SizedBox(height: 1.0),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$servicos',
                                      style: TextStyle(
                                        fontSize: 24.0,
                                        color: _currentTheme == 'TemaPrimario'
                                            ? TemaPrimario.ColorText
                                            : TemaSecundario.ColorText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 1.0),
                                  Text(
                                    'Serviços',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: _currentTheme == 'TemaPrimario'
                                          ? TemaPrimario.ColorText
                                          : TemaSecundario.ColorText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    //container produtos
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageTransition(
                            child: ProductsScreen(),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.3, // 40% da largura da tela
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.180, // 20% da altura da tela
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              10.0), // Borda arredondada
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: CardWidget(
                            color: Colors.transparent,
                            // Defina a cor do CardWidget como transparente
                            content: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.borderDash
                                        : TemaSecundario.borderDash,
                                    width: 2.5),
                                borderRadius: BorderRadius.circular(10.0),
                                gradient: LinearGradient(
                                  colors: [
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor1
                                        : TemaSecundario.gradienteColor1,
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor2
                                        : TemaSecundario.gradienteColor2,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Boxicons.bxs_package,
                                    size: 30.0,
                                    color: _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.iconColor
                                        : TemaSecundario.iconColorProdutos,
                                  ),
                                  SizedBox(height: 1.0),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$produtos',
                                      style: TextStyle(
                                        fontSize: 24.0,
                                        color: _currentTheme == 'TemaPrimario'
                                            ? TemaPrimario.ColorText
                                            : TemaSecundario.ColorText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 1.0),
                                  Text(
                                    'Produtos',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: _currentTheme == 'TemaPrimario'
                                          ? TemaPrimario.ColorText
                                          : TemaSecundario.ColorText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageTransition(
                            child: OsScreen(),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
                      },
                    child: Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width * 0.3, // 40% da largura da tela
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.180, // 20% da altura da tela
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                            10.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: CardWidget(
                          color: Colors.transparent,
                          content: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.borderDash
                                      : TemaSecundario.borderDash, width: 2.5),
                              borderRadius: BorderRadius.circular(10.0),
                              gradient: LinearGradient(
                                colors: [
                                  _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.gradienteColor1
                                      : TemaSecundario.gradienteColor1,
                                  _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.gradienteColor2
                                      : TemaSecundario.gradienteColor2,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Boxicons.bxs_spreadsheet,
                                  size: 30.0,
                                  color: _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.iconColor
                                      : TemaSecundario.iconColorOs,
                                ),
                                SizedBox(height: 1.0),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$countOs',
                                    style: TextStyle(
                                      fontSize: 24.0,
                                      color: _currentTheme == 'TemaPrimario'
                                          ? TemaPrimario.ColorText
                                          : TemaSecundario.ColorText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 1.0),
                                Text(
                                  'Ordens',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.ColorText
                                        : TemaSecundario.ColorText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    ),
                    Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width * 0.3, // 40% da largura da tela
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.180, // 20% da altura da tela
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: Colors.black54.withOpacity(0.5), // Cor da sombra
                        //     spreadRadius: 0.001, // Espalhamento da sombra
                        //     blurRadius: 5, // Desfoque da sombra
                        //     offset: Offset(2, 1), // Posição da sombra
                        //   ),
                        // ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: CardWidget(
                          color: Colors.transparent,
                          // Defina a cor do CardWidget como transparente
                          content: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.borderDash
                                      : TemaSecundario.borderDash, width: 2.5),
                              borderRadius: BorderRadius.circular(10.0),
                              gradient: LinearGradient(
                                colors: [
                                  _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.gradienteColor1
                                      : TemaSecundario.gradienteColor1,
                                  _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.gradienteColor2
                                      : TemaSecundario.gradienteColor2,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Boxicons.bxs_receipt,
                                  size: 30.0,
                                  color: _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.iconColor
                                      : TemaSecundario.iconColorGarantias,
                                ),
                                SizedBox(height: 1.0),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$garantias',
                                    style: TextStyle(
                                      fontSize: 24.0,
                                      color: _currentTheme == 'TemaPrimario'
                                          ? TemaPrimario.ColorText
                                          : TemaSecundario.ColorText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 1.0),
                                Text(
                                  'Garantias',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.ColorText
                                        : TemaSecundario.ColorText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width * 0.3, // 40% da largura da tela
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.180, // 20% da altura da tela
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                            10.0), // Borda arredondada
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: Colors.black54.withOpacity(0.5), // Cor da sombra
                        //     spreadRadius: 0.001, // Espalhamento da sombra
                        //     blurRadius: 5, // Desfoque da sombra
                        //     offset: Offset(2, 1), // Posição da sombra
                        //   ),
                        // ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: CardWidget(
                          color: Colors.transparent,
                          // Defina a cor do CardWidget como transparente
                          content: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(
                                  color: _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.borderDash
                                      : TemaSecundario.borderDash, width: 2.5),
                              gradient: LinearGradient(
                                colors: [
                                  _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.gradienteColor1
                                      : TemaSecundario.gradienteColor1,
                                  _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.gradienteColor2
                                      : TemaSecundario.gradienteColor2,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 30.0,
                                  color: _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.iconColor
                                      : TemaSecundario.iconColorVendas,),
                                SizedBox(height: 1.0),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$vendas',
                                    style: TextStyle(
                                      fontSize: 24.0,
                                      color: _currentTheme == 'TemaPrimario'
                                          ? TemaPrimario.ColorText
                                          : TemaSecundario.ColorText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 1.0),
                                Text(
                                  'Vendas',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.ColorText
                                        : TemaSecundario.ColorText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 8.0),
          CustomWidget(),
          SizedBox(height: 1.0),
          CalendarWidget(),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _selectTheme() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecione o Tema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Tema Escuro'),
                onTap: () {
                  _saveTheme('TemaPrimario');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Tema Claro'),
                onTap: () {
                  _saveTheme('TemaSecundario');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _saveTheme(String theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
    setState(() {
      _currentTheme = theme;
    });
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

  // Defina uma variável para armazenar os dados do perfil do usuário
  Map<String, dynamic> _profileData = {};

  Future<void> _getProfile({int page = 0}) async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'Authorization': 'Bearer $ciKey',
    };

    var url = '${APIConfig.baseURL}${APIConfig.profileEndpoint}';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      var profileData = responseData['result']['usuario'];
print(profileData);
      // Verifica se existe uma URL de imagem de usuário
      if (profileData.containsKey('url_image_user')) {
        // Carrega a imagem da URL
        try {
          var file = await DefaultCacheManager().getSingleFile(
              profileData['url_image_user']);
          profileData['cachedImage'] = file;
        } catch (e) {
          print('Error loading profile image: $e');
        }
      }

      // Atualiza os dados do perfil do usuário na variável de classe
      setState(() {
        _profileData = profileData;
      });
    } else {
      print('Failed to load profile');
    }
  }


// Exemplo de como usar os dados do perfil do usuário em outros lugares do seu aplicativo
  void _exemploDeUso() {
    // Aqui você pode acessar os dados do perfil do usuário da variável _profileData
    // Por exemplo, para acessar o nome do usuário:
    String nomeDoUsuario = _profileData['nome'] ?? '';
    print('Nome do usuário: $nomeDoUsuario');
  }
}
class CardWidget extends StatelessWidget {
  final Color color;
  final Widget content;

  const CardWidget({
    Key? key,
    required this.color,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: content,
    );
  }
}
String formatarData(String data) {
  // Supondo que a data esteja no formato "yyyy-MM-dd"
  DateTime dateTime = DateTime.parse(data);
  return DateFormat('dd/MM/yyyy').format(dateTime);
}
class ThemePreferences {
  static const String themeKey = 'theme';

  Future<ThemeMode> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Retorna o tema salvo ou o tema padrão como padrão
    String? themeString = prefs.getString(themeKey);
    if (themeString != null) {
      // Se um tema foi salvo, converte a string para um enum ThemeMode
      return themeString == 'TemaPrimario' ? ThemeMode.dark : ThemeMode.light;
    } else {
      // Se nenhum tema foi salvo, retorna o tema do sistema como padrão
      return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeKey, theme.index);
  }
}
