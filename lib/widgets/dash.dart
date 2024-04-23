import 'package:flutter/material.dart';
import 'package:mapos_app/data/dashboardData.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/assets/app_colors.dart';
import 'package:intl/intl.dart';

class CustomWidget extends StatefulWidget {
  @override
  _CustomWidgetState createState() => _CustomWidgetState();
}

class _CustomWidgetState extends State<CustomWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int countOs = 0;
  int clientes = 0;
  int produtos = 0;
  int servicos = 0;
  int garantias = 0;
  int vendas = 0;
  List<String> osAbertasList = [];
  List<String> osAndamentoList = [];
  List<String> estoqueBaixoList = [];
  String _currentTheme = 'TemaSecundario'; // Tema padrão
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
    _getTheme();
  }

  Future<void> _getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String theme = prefs.getString('theme') ?? 'TemaPrimario';
    setState(() {
      _currentTheme = theme;
    });
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          .map((os) => '${os.id} - ${os.nomeCliente} - ${os.dataInicial} - ${os.dataFinal}')
          .toList();
      osAndamentoList = dashboardData.osAndamentoList
          .map((os) => '${os.id} - ${os.nomeCliente} - ${os.dataInicial} - ${os.dataFinal}')
          .toList();
      estoqueBaixoList = dashboardData.estoqueBaixoList
          .map((os) => '${os.id} - ${os.descricao} - ${os.precoVenda} - ${os.estoque}')
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color:  _currentTheme == 'TemaPrimario'
              ? TemaPrimario.primaryColor
              : TemaSecundario.primaryColor,
      ),
      width: 300,
      height: 330,
      child: Scaffold(
        body: Column(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: _currentTheme == 'TemaPrimario'
                    ? TemaPrimario.backgroundColor
                    : TemaSecundario.backgroundColor,
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Em Aberto'),
                  Tab(text: 'Em Andamento'),
                  Tab(text: 'Estoque Baixo'),
                ],
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black,
                indicatorSize: TabBarIndicatorSize.label,
              ),
            ),
            Expanded(
              child: Container(
                color: _currentTheme == 'TemaPrimario'
                    ? TemaPrimario.backgroundColor
                    : TemaSecundario.backgroundColor,
              child: TabBarView(
                controller: _tabController,
                children: [
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 285, left: 0.0, bottom: 8.0, top: 8 ),
                          // child: Container(
                          //   alignment: Alignment.topLeft,
                          //   width: MediaQuery.of(context).size.width * 0.4,
                          //   decoration: BoxDecoration(
                          //       color: _currentTheme == 'TemaPrimario'
                          //           ? TemaPrimario.titleBackgrounColor
                          //           : TemaSecundario.titleBackgrounColor,
                          //       borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10))
                          //   ),
                          //   child: Padding(
                          //     padding: EdgeInsets.all(8.0),
                          //     child: Text(
                          //       'O.S em Aberto',
                          //       // textAlign: TextAlign.center,
                          //       style: TextStyle(
                          //         color: _currentTheme == 'TemaPrimario'
                          //             ? TemaPrimario.titleTextColor
                          //             : TemaSecundario.titleTextColor,
                          //         fontSize: MediaQuery.of(context).size.width * 0.035,
                          //         fontWeight: FontWeight.w800,
                          //       ),
                          //     ),
                          //   ),
                          // ),
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
                                                                ? TemaPrimario.primaryColor
                                                                : TemaSecundario.primaryColor,
                                                          ),
                                                          child: Padding(
                                                            padding: EdgeInsets.all(8.0),
                                                            child: Text(
                                                              'OS: $id',
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
                                                            ? TemaPrimario.iconColor
                                                            : TemaSecundario.iconColor,
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
                  ),
                  Center(
                    child:  Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 285.0, bottom: 8.0, top: 8 ),
                          // child: Container(
                          //   width: MediaQuery.of(context).size.width * 0.4,
                          //   decoration: BoxDecoration(
                          //       color: _currentTheme == 'TemaPrimario'
                          //           ? TemaPrimario.titleBackgrounColor
                          //           : TemaSecundario.titleBackgrounColor,
                          //       borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10))
                          //
                          //   ),
                          //
                          //   child: Padding(
                          //     padding: EdgeInsets.all(8.0),
                          //     child: Text(
                          //       'O.S em Andamento',
                          //       style: TextStyle(
                          //           color: _currentTheme == 'TemaPrimario'
                          //               ? TemaPrimario.titleTextColor
                          //               : TemaSecundario.titleTextColor,
                          //           fontSize: MediaQuery.of(context).size.width * 0.035,
                          //           fontWeight: FontWeight.w800
                          //       ),
                          //     ),
                          //   ),
                          // ),
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
                                                              'OS: $id',
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
                                                            ? TemaPrimario.iconColor
                                                            : TemaSecundario.iconColor,
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
                  ),
                  Center(
                    child:  Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 285, left: 0.0, bottom: 8.0, top: 8 ),
                          // child: Container(
                          //   width: MediaQuery.of(context).size.width * 0.75,
                          //   decoration: BoxDecoration(
                          //       color: _currentTheme == 'TemaPrimario'
                          //           ? TemaPrimario.titleBackgrounColor
                          //           : TemaSecundario.titleBackgrounColor,
                          //       borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10))
                          //   ),
                          //   child: Padding(
                          //     padding: EdgeInsets.all(8.0),
                          //     child: Text(
                          //       'Estoque Baixo',
                          //       style: TextStyle(
                          //           color: _currentTheme == 'TemaPrimario'
                          //               ? TemaPrimario.titleTextColor
                          //               : TemaSecundario.titleTextColor,
                          //           fontSize: MediaQuery.of(context).size.width * 0.035,
                          //           fontWeight: FontWeight.w800
                          //       ),
                          //     ),
                          //   ),
                          // ),
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
                                                                ? TemaPrimario.backgroundColor
                                                                : TemaSecundario.backgroundColor,
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
                                                            ? TemaPrimario.iconColor
                                                            : TemaSecundario.iconColor,
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
                                                          : TemaSecundario.titleTextColor,
                                                      fontWeight: FontWeight.w700
                                                  ), // Cor do texto
                                                ),
                                                SizedBox(height: 5.0),
                                                Text(
                                                  'Preço: R\$ $precoVenda',
                                                  style: TextStyle(color: _currentTheme == 'TemaPrimario'
                                                      ? TemaPrimario.ColorText
                                                      : TemaSecundario.titleTextColor), // Cor do texto
                                                ),
                                                SizedBox(height: 3.0),
                                                Text(
                                                  'Estoque: $estoque',
                                                  style: TextStyle(color: _currentTheme == 'TemaPrimario'
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
                  ),
                ],
              ),
            ),
    ),
          ],
        ),
      ),
    );
  }
  String formatarData(String data) {
    // Supondo que a data esteja no formato "yyyy-MM-dd"
    DateTime dateTime = DateTime.parse(data);
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}
