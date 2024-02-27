import 'package:flutter/material.dart';
import 'package:mapos_app/widgets/ButtonMenu.dart';
import 'package:mapos_app/pages/dashboard_screen.dart';
import 'package:mapos_app/pages/services/services_screen.dart';
import 'package:mapos_app/pages/clients/clients_screen.dart';


class BottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
      ),
      body: Container(
        // Seu conteúdo da página aqui
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        activeIndex: 0,
        context: context, // Pass context here
        onTap: (index) {
          // Manipule o evento onTap aqui conforme necessário
        },
      ),
    );
  }
}

class BottomNavigationBarWidget extends StatelessWidget {
  final int activeIndex;
  final Function(int index)? onTap;
  final BuildContext context; // Adicione o contexto aqui

  const BottomNavigationBarWidget({
    Key? key,
    required this.activeIndex,
    required this.context, // Atualize o construtor para aceitar o contexto
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          // BoxShadow(
          //   color: Colors.grey.withOpacity(0.5),
          //   spreadRadius: 5,
          //   blurRadius: 7,
          //   offset: Offset(0, 3),
          // ),
        ],
      ),
      child: CircleNavBar(
        activeIndex: activeIndex,
        onTap: _handleTap,
        activeIcons: [
          Icon(Icons.shopping_cart, color: Colors.white),
          Icon(Icons.construction, color: Colors.white),
          Icon(Icons.home, color: Colors.white),
          Icon(Icons.supervisor_account, color: Colors.white),
          Icon(Icons.description, color: Colors.white),
        ],
        inactiveIcons: [
          Icon(Icons.shopping_cart_outlined, color: Colors.white),
          Icon(Icons.construction_outlined, color: Colors.white),
          Icon(Icons.home_outlined, color: Colors.white),
          Icon(Icons.supervisor_account_outlined, color: Colors.white),
          Icon(Icons.description_outlined, color: Colors.white),
        ],
        height: 50,
        circleWidth: 50,
        color: Color(0xffd97b06),
        padding: EdgeInsets.symmetric(horizontal: 0.0),
        cornerRadius: BorderRadius.circular(0),
        shadowColor: Colors.transparent,
        elevation: 1,
      ),
    );
  }

  void _handleTap(int index) {
    if (onTap != null) {
      onTap!(index);
      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      }
      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ServicesScreen()),
        );
      }
      if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ClientesScreen()),
        );
      }
    }
  }
}