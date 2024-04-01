import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:mapos_app/pages/clients/clients_screen.dart';
import 'package:mapos_app/pages/os/os_screen.dart';
import 'package:mapos_app/pages/products/products_screen.dart';
import 'package:mapos_app/pages/services/services_screen.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';
import 'package:mapos_app/widgets/menu_lateral.dart';
import 'package:mapos_app/models/dashboardModel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mapos_app/pages/audit/audit.dart';
import 'package:intl/intl.dart';
import 'package:mapos_app/assets/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/assets/app_colors.dart';


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
  }
  String _currentTheme = 'TemaSecundario';
  Future<void> _loadTheme() async {
    ThemeMode themeMode = await ThemePreferences().getTheme();
    setState(() {
      _currentTheme = themeMode == ThemeMode.dark ? 'TemaPrimario' : 'TemaSecundario';
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
        actions: [
          IconButton(
            icon: _currentTheme == 'TemaPrimario'
                ? Icon(Boxicons.bx_moon, color: Color(0xFFDC7902)) // Ícone de lua
                : Icon(Boxicons.bx_sun), // Ícone de sol
            onPressed: () {
              setState(() {
                _currentTheme =
                _currentTheme == 'TemaPrimario' ? 'TemaSecundario' : 'TemaPrimario';
                _saveTheme(_currentTheme);
              });
            },
          ),

        ],
      ),
      drawer: MenuLateral(),
      bottomNavigationBar: BottomNavigationBarWidget(
        activeIndex: _selectedIndex,
        context: context,
        onTap: _onItemTapped,
      ),
      body: ListView(
        children: [
          Container(
            height: MediaQuery.of(context).size.width * 0.83,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xff333649),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
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
                        // Lógica a ser executada quando o Container for tocado
                        print('Container 2 foi tocado!');
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.3, // 40% da largura da tela
                        height: MediaQuery.of(context).size.height * 0.180, // 20% da altura da tela
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0), // Borda arredondada
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: CardWidget(
                            color: Colors.transparent, // Defina a cor do CardWidget como transparente
                            content: Container(
                              decoration: BoxDecoration(
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
                                    size: 48.0,
                                    color: _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.iconColor
                                        : TemaSecundario.iconColor,
                                  ),
                                  SizedBox(height: 1.0),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$clientes',
                                      style:  TextStyle(
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
                        // Lógica a ser executada quando o Container for tocado
                        print('Container 2 foi tocado!');
                      },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.3, // 40% da largura da tela
                      height: MediaQuery.of(context).size.height * 0.180, // 20% da altura da tela
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0), // Borda arredondada
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: CardWidget(
                          color: Colors.transparent, // Defina a cor do CardWidget como transparente
                          content: Container(
                            decoration: BoxDecoration(
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
                                  size: 48.0,
                                  color: _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.iconColor
                                      : TemaSecundario.iconColor,
                                ),
                                SizedBox(height: 1.0),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$servicos',
                                    style:  TextStyle(
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
                        // Lógica a ser executada quando o Container for tocado
                        print('Container 3 foi tocado!');
                      },
                   child:  Container(
                      width: MediaQuery.of(context).size.width * 0.3, // 40% da largura da tela
                      height: MediaQuery.of(context).size.height * 0.180, // 20% da altura da tela
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0), // Borda arredondada
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
                          color: Colors.transparent, // Defina a cor do CardWidget como transparente
                          content: Container(
                            decoration: BoxDecoration(
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
                                  Boxicons.bxs_basket,
                                  size: 48.0,
                                  color: _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.iconColor
                                      : TemaSecundario.iconColor,
                                ),
                                SizedBox(height: 1.0),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      '$produtos',
                                      style:  TextStyle(
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
                    Container(
                      width: MediaQuery.of(context).size.width * 0.3, // 40% da largura da tela
                      height: MediaQuery.of(context).size.height * 0.180, // 20% da altura da tela
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0), // Borda arredondada
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
                          color: Colors.transparent, // Defina a cor do CardWidget como transparente
                          content: Container(
                            decoration: BoxDecoration(
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
                                  Boxicons.bxs_detail,
                                  size: 48.0,
                                  color: _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.iconColor
                                      : TemaSecundario.iconColor,
                                ),
                                SizedBox(height: 1.0),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    '$countOs',
                                    style:  TextStyle(
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
                                  'O.S.',
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
                      width: MediaQuery.of(context).size.width * 0.3, // 40% da largura da tela
                      height: MediaQuery.of(context).size.height * 0.180, // 20% da altura da tela
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
                          color: Colors.transparent, // Defina a cor do CardWidget como transparente
                          content: Container(
                            decoration: BoxDecoration(
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
                                  size: 48.0,
                                  color: _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.iconColor
                                      : TemaSecundario.iconColor,
                                ),
                                SizedBox(height: 1.0),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      '$garantias',
                                      style:  TextStyle(
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
                      width: MediaQuery.of(context).size.width * 0.3, // 40% da largura da tela
                      height: MediaQuery.of(context).size.height * 0.180, // 20% da altura da tela
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0), // Borda arredondada
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
                          color: Colors.transparent, // Defina a cor do CardWidget como transparente
                          content: Container(
                            decoration: BoxDecoration(
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
                                  Boxicons.bx_money,
                                  size: 48.0,
                                  color: _currentTheme == 'TemaPrimario'
                                      ? TemaPrimario.iconColor
                                      : TemaSecundario.iconColor,                                ),
                                SizedBox(height: 1.0),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      '$vendas',
                                      style:  TextStyle(
                                        fontSize: 24.0,
                                        color: _currentTheme == 'TemaPrimario'
                                            ? TemaPrimario.ColorText
                                            : TemaSecundario.ColorText,                                        fontWeight: FontWeight.w700,
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
                                        : TemaSecundario.ColorText,                                    fontWeight: FontWeight.w700,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0.0, bottom: 8.0, top: 8 ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _currentTheme == 'TemaPrimario'
                        ? TemaPrimario.titleBackgrounColor
                        : TemaSecundario.titleBackgrounColor,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Ordens de Serviço em Aberto',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.titleTextColor
                              : TemaSecundario.titleTextColor,
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          fontWeight: FontWeight.w800
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 200, // Altura fixa para os cards
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: osAbertasList.map((os) {
                      final splitData = os.split(' - ');
                      if (splitData.length != 4) {
                        return SizedBox(); // Retorna um espaço em branco se os dados estiverem incorretos
                      }
                      final id = splitData[0];
                      final nomeCompleto = splitData[1];
                      final dataInicial = splitData[2];
                      final dataFinal = splitData[3];
                      final nomeSobrenome = nomeCompleto.split(' ');
                      String nomeFormatado = '';
                      if (nomeSobrenome.length >= 2) {
                        nomeFormatado = '${nomeSobrenome[0]} ${nomeSobrenome[1]}';
                      } else {
                        nomeFormatado = nomeCompleto;
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 200, // Largura fixa para os cards
                          child: Card(
                            elevation: 2, // Adiciona uma sombra ao card
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0), // Borda arredondada
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                gradient: LinearGradient(
                                  colors: [
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor1
                                        : TemaSecundario.gradienteColorTwo1,
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor2
                                        : TemaSecundario.gradienteColorTwo2,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Container(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                    color: _currentTheme == 'TemaPrimario'
                                                        ? TemaPrimario.secondaryColor
                                                        : TemaSecundario.secondaryColor,
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text(
                                                    'ID: $id',
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      color: _currentTheme == 'TemaPrimario'
                                                          ? TemaPrimario.ColorText
                                                          : TemaSecundario.ColorText,
                                                      fontSize: MediaQuery.of(context).size.width * 0.035,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.visibility),
                                              color: _currentTheme == 'TemaPrimario'
                                                  ? TemaPrimario.ColorText
                                                  : TemaSecundario.titleTextColor,
                                              onPressed: () {
                                                // Lógica quando o botão de visualização é pressionado
                                              },
                                            ),
                                          ],
                                        ),
                                      ),


                                      SizedBox(height: 5.0),
                                      Text(
                                        'Cliente: $nomeFormatado',
                                        style: TextStyle(
                                            color: _currentTheme == 'TemaPrimario'
                                                ? TemaPrimario.ColorText
                                                : TemaSecundario.titleTextColor,
                                            fontWeight: FontWeight.w700
                                        ), // Cor do texto
                                      ),
                                      SizedBox(height: 5.0),
                                      Text(
                                        'Entrada: ${formatarData(dataInicial)}',
                                        style: TextStyle( color: _currentTheme == 'TemaPrimario'
                                            ? TemaPrimario.ColorText
                                            : TemaSecundario.titleTextColor,
                                        ), // Cor do texto
                                      ),
                                      SizedBox(height: 3.0),
                                      Text(
                                        'Data final: ${formatarData(dataFinal)}',
                                        style: TextStyle( color: _currentTheme == 'TemaPrimario'
                                            ? TemaPrimario.ColorText
                                            : TemaSecundario.titleTextColor), // Cor do texto
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0.0, bottom: 8.0, top: 8 ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _currentTheme == 'TemaPrimario'
                        ? TemaPrimario.titleBackgrounColor
                        : TemaSecundario.titleBackgrounColor,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Ordens de Serviço em Andamento',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.titleTextColor
                              : TemaSecundario.titleTextColor,
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          fontWeight: FontWeight.w800
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 200, // Altura fixa para os cards
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: osAndamentoList.map((os) {
                      final splitData = os.split(' - ');
                      if (splitData.length != 4) {
                        return SizedBox(); // Retorna um espaço em branco se os dados estiverem incorretos
                      }
                      final id = splitData[0];
                      final nomeCompleto = splitData[1];
                      final dataInicial = splitData[2];
                      final dataFinal = splitData[3];
                      final nomeSobrenome = nomeCompleto.split(' ');
                      String nomeFormatado = '';
                      if (nomeSobrenome.length >= 2) {
                        nomeFormatado = '${nomeSobrenome[0]} ${nomeSobrenome[1]}';
                      } else {
                        nomeFormatado = nomeCompleto;
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 200, // Largura fixa para os cards
                          child: Card(
                            elevation: 2, // Adiciona uma sombra ao card
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0), // Borda arredondada
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                gradient: LinearGradient(
                                  colors: [
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor1
                                        : TemaSecundario.gradienteColorTwo1,
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor2
                                        : TemaSecundario.gradienteColorTwo2,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Container(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                  color: _currentTheme == 'TemaPrimario'
                                                      ? TemaPrimario.secondaryColor
                                                      : TemaSecundario.secondaryColor,
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text(
                                                    'ID: $id',
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      color: _currentTheme == 'TemaPrimario'
                                                          ? TemaPrimario.ColorText
                                                          : TemaSecundario.ColorText,
                                                      fontSize: MediaQuery.of(context).size.width * 0.035,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.visibility),
                                              color: _currentTheme == 'TemaPrimario'
                                                  ? TemaPrimario.ColorText
                                                  : TemaSecundario.titleTextColor,
                                              onPressed: () {
                                                // Lógica quando o botão de visualização é pressionado
                                              },
                                            ),
                                          ],
                                        ),
                                      ),


                                      SizedBox(height: 5.0),
                                      Text(
                                        'Cliente: $nomeFormatado',
                                        style: TextStyle(
                                            color: _currentTheme == 'TemaPrimario'
                                                ? TemaPrimario.ColorText
                                                : TemaSecundario.titleTextColor,
                                            fontWeight: FontWeight.w700
                                        ), // Cor do texto
                                      ),
                                      SizedBox(height: 5.0),
                                      Text(
                                        'Entrada: ${formatarData(dataInicial)}',
                                        style: TextStyle( color: _currentTheme == 'TemaPrimario'
                                            ? TemaPrimario.ColorText
                                            : TemaSecundario.titleTextColor,
                                        ), // Cor do texto
                                      ),
                                      SizedBox(height: 3.0),
                                      Text(
                                        'Data final: ${formatarData(dataFinal)}',
                                        style: TextStyle( color: _currentTheme == 'TemaPrimario'
                                            ? TemaPrimario.ColorText
                                            : TemaSecundario.titleTextColor), // Cor do texto
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding:  EdgeInsets.only(left: 0.0, bottom: 8.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _currentTheme == 'TemaPrimario'
                        ? TemaPrimario.titleBackgrounColor
                        : TemaSecundario.titleBackgrounColor,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Produtos com Estoque Baixo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.titleTextColor
                              : TemaSecundario.titleTextColor,
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          fontWeight: FontWeight.w800
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 200, // Altura fixa para os cards
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: estoqueBaixoList.map((os) {
                      final splitData = os.split(' - ');
                      if (splitData.length != 4) {
                        return SizedBox(); // Retorna um espaço em branco se os dados estiverem incorretos
                      }
                      final id = splitData[0];
                      final nomeCompleto = splitData[1];
                      final precoVenda = splitData[2];
                      final estoque = splitData[3];
                      final nomeSobrenome = nomeCompleto.split(' ');
                      String nomeFormatado = '';
                      if (nomeSobrenome.length >= 3) {
                        nomeFormatado = '${nomeSobrenome[0]} ${nomeSobrenome[1]} ${nomeSobrenome[2]}';
                      } else {
                        nomeFormatado = nomeCompleto;
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 200, // Largura fixa para os cards
                          child: Card(
                            elevation: 4, // Adiciona uma sombra ao card
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0), // Borda arredondada
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                gradient: LinearGradient(
                                  colors: [
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor1
                                        : TemaSecundario.gradienteColorTwo1,
                                    _currentTheme == 'TemaPrimario'
                                        ? TemaPrimario.gradienteColor2
                                        : TemaSecundario.gradienteColorTwo2,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Container(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                  color: _currentTheme == 'TemaPrimario'
                                                      ? TemaPrimario.secondaryColor
                                                      : TemaSecundario.secondaryColor,
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text(
                                                    'ID: $id',
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      color: _currentTheme == 'TemaPrimario'
                                                          ? TemaPrimario.ColorText
                                                          : TemaSecundario.ColorText,
                                                      fontSize: MediaQuery.of(context).size.width * 0.035,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.visibility),
                                              color: _currentTheme == 'TemaPrimario'
                                                  ? TemaPrimario.ColorText
                                                  : TemaSecundario.secondaryColor,
                                              onPressed: () {
                                                // Lógica quando o botão de visualização é pressionado
                                              },
                                            ),
                                          ],
                                        ),
                                      ),


                                      SizedBox(height: 5.0),
                                      Text(
                                        'Produto: $nomeFormatado',
                                        style: TextStyle(
                                            color: _currentTheme == 'TemaPrimario'
                                                ? TemaPrimario.ColorText
                                                : TemaSecundario.secondaryColor,
                                            fontWeight: FontWeight.w700
                                        ), // Cor do texto
                                      ),
                                      SizedBox(height: 5.0),
                                      Text(
                                        'Preço: R\$ $precoVenda',
                                        style: TextStyle(color: _currentTheme == 'TemaPrimario'
                                            ? TemaPrimario.ColorText
                                            : TemaSecundario.secondaryColor), // Cor do texto
                                      ),
                                      SizedBox(height: 3.0),
                                      Text(
                                        'Estoque: $estoque',
                                        style: TextStyle(color: _currentTheme == 'TemaPrimario'
                                            ? TemaPrimario.ColorText
                                            : TemaSecundario.secondaryColor,), // Cor do texto
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
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

  Future<void> _saveTheme(String theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
    setState(() {
      _currentTheme = theme;
    });
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
