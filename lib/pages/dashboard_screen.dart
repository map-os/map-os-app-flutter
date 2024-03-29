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
   late String adataInicial;
   late String dataFinal;
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
          .map((os) => '${os.id} - ${os.nomeCliente} - ${os.dataInicial} - ${os.dataFinal}')
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
       appBar: AppBar(
         title: Text('Dashboard'),
       ),
       drawer: MenuLateral(),
       body: SingleChildScrollView(
         child: Column(
           children: [
             Container(
               decoration: BoxDecoration(
                 color: Color(0xff333649),
                 borderRadius: BorderRadius.only(
                   bottomLeft: Radius.circular(20.0),
                   bottomRight: Radius.circular(20.0),
                 ),
               ),
               child: SingleChildScrollView(
                 scrollDirection: Axis.horizontal,
                 child: Padding(
                   padding: EdgeInsets.all(
                     MediaQuery.of(context).size.width * 0.01,
                   ),
                   child: Row(
                     children: [
                       SizedBox(
                         width: MediaQuery.of(context).size.width * 0.98,
                         child: GridView.count(
                           shrinkWrap: true,
                           crossAxisSpacing:
                           (MediaQuery.of(context).size.width * 0.020),
                           crossAxisCount: 3,
                           mainAxisSpacing: 9.0,
                           childAspectRatio: 0.99,
                           children: [
                             _buildCard(
                               'Clientes',
                               Boxicons.bx_group,
                               clientes.toString(),
                                   () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => ClientesScreen(),
                                   ),
                                 );
                               },
                             ),
                             _buildCard(
                               'Serviços',
                               Boxicons.bx_wrench,
                               servicos.toString(),
                                   () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => ServicesScreen(),
                                   ),
                                 );
                               },
                             ),
                             _buildCard(
                               'Produtos',
                               Boxicons.bx_basket,
                               produtos.toString(),
                                   () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => ProductsScreen(),
                                   ),
                                 );
                               },
                             ),
                             _buildCard(
                               'O.S',
                               Boxicons.bx_file,
                               countOs.toString(),
                                   () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => OsScreen(),
                                   ),
                                 );
                               },
                             ),
                             _buildCard(
                               'Garantias',
                               Boxicons.bx_receipt,
                               garantias.toString(),
                                   () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => ServicesScreen(),
                                   ),
                                 );
                               },
                             ),
                             _buildCard(
                               'Vendas',
                               Icons.shopping_cart_outlined,
                               vendas.toString(),
                                   () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => Audit(),
                                   ),
                                 );
                               },
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
             SizedBox(height: 20),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Padding(
                   padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                   child: Text(
                     'Os em Aberto',
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 16.0,
                     ),
                   ),
                 ),
                 SizedBox(
                   width: double.infinity,
                   child: SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     child: Container(
                       color: Colors.grey[200], // Cor de fundo da tabela
                       child: DataTable(
                         columnSpacing: (MediaQuery.of(context).size.width * 0.070),
                         headingTextStyle: TextStyle(
                           fontWeight: FontWeight.bold,
                           fontSize: 14.0,
                           color: Colors.black,
                         ),
                         dataRowHeight: 48.0,
                         columns: [
                           DataColumn(label: Text('ID')),
                           DataColumn(label: Text('Cliente')),
                           DataColumn(label: Text('Entrada')),
                           DataColumn(label: Text('Data final')),
                         ],
                         rows: osAbertasList.map((os) {
                           final splitData = os.split(' - ');
                           if (splitData.length != 4) {
                             return DataRow(cells: [
                               DataCell(Text('Erro ao processar dados')),
                               DataCell(Text('Erro ao processar dados')),
                               DataCell(Text('Erro ao processar dados')),
                               DataCell(Text('Erro ao processar dados'))
                             ]);
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

                           return DataRow(cells: [
                             DataCell(Text(id)),
                             DataCell(Text(nomeFormatado)),
                             DataCell(Text(formatarData(dataInicial))),
                             DataCell(Text(formatarData(dataFinal))),
                           ]);
                         }).toList(),
                       ),
                     ),
                   ),
                 ),
               ],
             ),

           ],
         ),
       ),
       bottomNavigationBar: BottomNavigationBarWidget(
         activeIndex: _selectedIndex,
         context: context,
         onTap: _onItemTapped,
       ),
     );
   }

   Widget _buildCard(String title, IconData icon, String data, Function() onTap) {
     return GestureDetector(
       onTap: onTap,
       child: Container(
         decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(20.0),
           color: Colors.white,
         ),
         child: Padding(
           padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(
                 icon,
                 size: (MediaQuery.of(context).size.width * 0.09),
                 color: Color(0xff333649),
               ),
               SizedBox(height: (MediaQuery.of(context).size.width * 0.001)),
               Text(
                 title,
                 style: TextStyle(
                     fontSize: (MediaQuery.of(context).size.width * 0.04),
                     fontWeight: FontWeight.bold,
                     color: Color(0xff333649)),
               ),
               SizedBox(height: (MediaQuery.of(context).size.width * 0.001)),
               Text(
                 data,
                 style: TextStyle(
                     fontSize: (MediaQuery.of(context).size.width * 0.05),
                     fontWeight: FontWeight.bold,
                     color: Color(0xff333649)),
               ),
             ],
           ),
         ),
       ),
     );
   }

   void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
String formatarData(String data) {
  // Supondo que a data esteja no formato "yyyy-MM-dd"
  DateTime dateTime = DateTime.parse(data);
  return DateFormat('dd/MM/yyyy').format(dateTime);
}
