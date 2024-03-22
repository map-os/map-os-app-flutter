import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:mapos_app/pages/clients/clients_screen.dart';
import 'package:mapos_app/pages/os/os_screen.dart';
import 'package:mapos_app/pages/products/products_screen.dart';
import 'package:mapos_app/pages/services/services_screen.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';
import 'package:mapos_app/widgets/menu_lateral.dart';
import 'package:mapos_app/models/dashboardModel.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchData();
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      drawer: MenuLateral(),
      body: Column(
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
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.03),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisSpacing:
                          (MediaQuery.of(context).size.width * 0.020),
                      crossAxisCount: 3,
                      mainAxisSpacing: 9.0,
                      childAspectRatio: 0.99,
                      children: [
                        _buildCard(
                            'Clientes', Boxicons.bx_group, clientes.toString(),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ClientesScreen()),
                          );
                        }),
                        _buildCard(
                            'Serviços', Boxicons.bx_wrench, servicos.toString(),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ServicesScreen()),
                          );
                        }),
                        _buildCard(
                            'Produtos', Boxicons.bx_basket, produtos.toString(),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProductsScreen()),
                          );
                        }),
                        _buildCard('O.S', Boxicons.bx_file, countOs.toString(),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => OsScreen()),
                          );
                        }),
                        _buildCard('Garantias', Boxicons.bx_receipt,
                            garantias.toString(), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ServicesScreen()),
                          );
                        }),
                        _buildCard('Vendas', Icons.shopping_cart_outlined,
                            vendas.toString(), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ServicesScreen()),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // MeuWidgetPersonalizado(
          //   titulo: 'Meu Título',
          //   texto: '',
          // ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        activeIndex: _selectedIndex,
        context: context,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCard(
      String title, IconData icon, String data, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // width: MediaQuery.of(context).size.width * 0.4,
        // height: MediaQuery.of(context).size.width * 0.8,
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
