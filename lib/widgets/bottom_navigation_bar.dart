import 'package:flutter/material.dart';
import 'package:mapos_app/widgets/ButtonMenu.dart';
import 'package:mapos_app/pages/dashboard_screen.dart';
import 'package:mapos_app/pages/services/services_screen.dart';
import 'package:mapos_app/pages/clients/clients_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:mapos_app/pages/products/products_screen.dart';
import  'package:mapos_app/pages/os/os_screen.dart';


class BottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      child: CircleNavBar(
        activeIndex: activeIndex,
        onTap: _handleTap,
        activeIcons: [
          Icon(Icons.shopping_cart, color: Color(0xffffffff)),
          Icon(Icons.construction, color: Color(0xffffffff)),
          Icon(Icons.home, color: Color(0xffffffff)),
          Icon(Icons.supervisor_account, color: Color(0xffffffff)),
          Icon(Icons.description, color: Color(0xffffffff)),
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
        color: Color(0xff333649),
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
      if (index == 0) {
        Navigator.push(
            context,
            PageTransition(
              child: ProductsScreen(),
              type: PageTransitionType.leftToRight,
            )
        );
      }
      if (index == 1) {
        Navigator.push(
            context,
            PageTransition(
              child: ServicesScreen(),
              type: PageTransitionType.leftToRight,
            )
        );
      }
      if (index == 2) {
        Navigator.push(
          context,
            PageTransition(
              child: DashboardScreen(),
              type: PageTransitionType.leftToRight,
            )
        );
      }
      if (index == 3) {
        Navigator.push(
          context,
            PageTransition(
              child: ClientesScreen(),
              type: PageTransitionType.leftToRight,
            )
        );
      }
      if (index == 4) {
        Navigator.push(
            context,
            PageTransition(
              child: OsScreen(),
              type: PageTransitionType.leftToRight,
            )
        );
      }
    }
  }
}