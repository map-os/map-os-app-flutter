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

  @override
  void initState() {
    super.initState();
    _fetchData();
    _requestPermissions();
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
      backgroundColor: Color(0xff4a517a),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
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
            height: MediaQuery.of(context).size.width * 0.7,
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
                              gradient: const LinearGradient(
                                colors: [Color(0xff1b2446),
                                  Color(0xff191d25)],// Cores do degradê
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.supervisor_account,
                                  size: 48.0,
                                  color: Color(0xffdd7902),
                                ),
                                SizedBox(height: 1.0),
                                Text(
                                  '$clientes',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 1.0),
                                const Text(
                                  'Clientes',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    //container serviços
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
                              gradient: const LinearGradient(
                                colors: [Color(0xff1b2446),
                                  Color(0xff191d25)], // Cores do degradê
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Boxicons.bxs_wrench,
                                  size: 48.0,
                                  color: Color(0xffdd7902),
                                ),
                                SizedBox(height: 1.0),
                                Text(
                                  '$servicos',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 1.0),
                                const Text(
                                  'Serviços',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    //container produtos
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
                              gradient: const LinearGradient(
                                colors: [Color(0xff1b2446),
                                  Color(0xff191d25)], // Cores do degradê
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Boxicons.bxs_basket,
                                  size: 48.0,
                                  color: Color(0xffdd7902),
                                ),
                                SizedBox(height: 1.0),
                                Text(
                                  '$produtos',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 1.0),
                                const Text(
                                  'Produtos',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white,
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
                              gradient: const LinearGradient(
                                colors: [Color(0xff1b2446),
                                  Color(0xff191d25)], // Cores do degradê
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Boxicons.bxs_detail,
                                  size: 48.0,
                                  color: Color(0xffdd7902),
                                ),
                                SizedBox(height: 1.0),
                                Text(
                                  '$countOs',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 1.0),
                                const Text(
                                  'O.S',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white,
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
                              gradient: const LinearGradient(
                                colors: [Color(0xff1b2446),
                                  Color(0xff191d25)], // Cores do degradê
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Boxicons.bxs_receipt,
                                  size: 48.0,
                                  color: Color(0xffdd7902),
                                ),
                                SizedBox(height: 1.0),
                                Text(
                                  '$garantias',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 1.0),
                                const Text(
                                  'Garantias',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white,
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
                              gradient: const LinearGradient(
                                colors: [Color(0xff1b2446),
                                  Color(0xff191d25)], // Cores do degradê
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Boxicons.bx_money,
                                  size: 48.0,
                                  color: Color(0xffdd7902),
                                ),
                                SizedBox(height: 1.0),
                                Text(
                                  '$vendas',
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 1.0),
                                const Text(
                                  'Vendas',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0.0, bottom: 8.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Color(0xff333649)
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Ordens de Serviço em Aberto',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
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
                            elevation: 4, // Adiciona uma sombra ao card
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0), // Borda arredondada
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xff1b2446),
                                    Color(0xff191d25)], // Cores do gradiente
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Container(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8.0),
                                          color: Color(0xffdd7902)
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'ID: $id',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: MediaQuery.of(context).size.width * 0.035,
                                              fontWeight: FontWeight.w800
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 2.0),
                                      Text(
                                        'Cliente: $nomeFormatado',
                                        style: TextStyle(color: Colors.white), // Cor do texto
                                      ),
                                      Text(
                                        'Entrada: ${formatarData(dataInicial)}',
                                        style: TextStyle(color: Colors.white), // Cor do texto
                                      ),
                                      Text(
                                        'Data final: ${formatarData(dataFinal)}',
                                        style: TextStyle(color: Colors.white), // Cor do texto
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
}
class CardWidget extends StatelessWidget {
  final Color color;
  final Widget content; // Modificado para aceitar um Widget

  const CardWidget({
    Key? key,
    required this.color,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: content, // Utilize o widget fornecido como conteúdo
    );
  }
}
String formatarData(String data) {
  // Supondo que a data esteja no formato "yyyy-MM-dd"
  DateTime dateTime = DateTime.parse(data);
  return DateFormat('dd/MM/yyyy').format(dateTime);
}
