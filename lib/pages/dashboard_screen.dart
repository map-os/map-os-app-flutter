import 'package:flutter/material.dart';
import 'package:mapos_app/pages/clients/clients_screen.dart';
import 'package:mapos_app/pages/services/services_screen.dart';
import 'package:mapos_app/widgets/menu_lateral.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';


class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      drawer: MenuLateral(),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xffd97b06), // Cor de fundo desejada
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0), // Bordas inferiores arredondadas
            bottomRight: Radius.circular(20.0), // Bordas inferiores arredondadas
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: (MediaQuery.of(context).size.width * 0.030),
                  mainAxisSpacing: 9.0,
                  childAspectRatio: 1.5, // Aspect Ratio dos cartões
                  children: [
                    _buildCard('Clientes', Icons.people, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ClientesScreen()),
                      );
                    }),
                    _buildCard('Serviços', Icons.construction_outlined, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ServicesScreen()),
                      );
                    }),
                    _buildCard('Produtos', Icons.shopping_cart, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ClientesScreen()),
                      );
                    }),
                    _buildCard('O.S', Icons.description, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ServicesScreen()),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        activeIndex: _selectedIndex,
        context: context, // Passe o contexto aqui
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4, // Largura relativa à largura da tela
        height: MediaQuery.of(context).size.width * 0.4, // Altura relativa à largura da tela
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffe78046),
              Color(0xffec8506)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: (MediaQuery.of(context).size.width * 0.09),
                color: Colors.white,
              ),
              SizedBox(height: (MediaQuery.of(context).size.width * 0.01)),
              Text(
                title,
                style: TextStyle(fontSize: (MediaQuery.of(context).size.width * 0.035), fontWeight: FontWeight.bold, color: Colors.white), // Cor do texto
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
