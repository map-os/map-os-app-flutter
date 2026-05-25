import 'package:flutter/material.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';
import 'package:mapos_app/widgets/ButtonMenu.dart';
import 'package:page_transition/page_transition.dart';
import 'package:mapos_app/pages/services/services_page.dart';
import 'package:mapos_app/pages/dashboard/dashboard_page.dart';
import 'package:mapos_app/pages/products/products_page.dart';
import 'package:mapos_app/pages/clients/clients_page.dart';
import 'package:mapos_app/pages/os/os_page.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int activeIndex;
  final Function(int index)? onTap;
  final BuildContext context;

  const BottomNavigationBarWidget({
    Key? key,
    required this.activeIndex,
    required this.context,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final List<Color> activeCircleColors = [
      AppColors.tabProdutos,
      AppColors.tabServicos,
      Colors.white,
      AppColors.tabClientes,
      AppColors.tabOS
    ];

    return CircleNavBar(
      activeIndex: activeIndex,
      onTap: _handleTap,
      activeIcons: [
        Icon(Icons.shopping_cart, size: 24, color: Colors.white),
        Icon(Icons.construction, size: 24, color: Colors.white),
        Icon(Icons.home, size: 24, color: Colors.black87),
        Icon(Icons.supervisor_account, size: 24, color: Colors.white),
        Icon(Icons.description, size: 24, color: Colors.white),
      ],
      inactiveIcons: [
        Icon(Icons.shopping_cart_outlined, size: 24, color: Colors.white),
        Icon(Icons.construction_outlined, size: 24, color: Colors.white),
        Icon(Icons.home_outlined, size: 24, color: Colors.white),
        Icon(Icons.supervisor_account_outlined, size: 24, color: Colors.white),
        Icon(Icons.description_outlined, size: 24, color: Colors.white),
      ],
      height: 70,
      circleWidth: 60,
      color: AppColors.navBar,
      circleColor: activeCircleColors[activeIndex],
      padding: EdgeInsets.symmetric(horizontal: 0.0),
      cornerRadius: BorderRadius.circular(0),
      shadowColor: Colors.black.withOpacity(0.2),
      elevation: 8,
    );
  }

  void _handleTap(int index) {
    if (onTap != null) {
      onTap!(index);
      if (index == 0) {
        Navigator.pushReplacement(
            context,
            PageTransition(
              child: productsList(),
              type: PageTransitionType.leftToRight,
            )
        );
      }
      if (index == 1) {
        Navigator.pushReplacement(
            context,
            PageTransition(
              child: ServicesList(),
              type: PageTransitionType.leftToRight,
            )
        );
      }
      if (index == 2) {
        Navigator.pushReplacement(
            context,
            PageTransition(
              child: DashboardPage(),
              type: PageTransitionType.leftToRight,
            )
        );
      }
      if (index == 3) {
        Navigator.pushReplacement(
            context,
            PageTransition(
              child: ClientsList(),
              type: PageTransitionType.leftToRight,
            )
        );
      }
      if (index == 4) {
        Navigator.pushReplacement(
            context,
            PageTransition(
              child: OrdemServicoList(),
              type: PageTransitionType.leftToRight,
            )
        );
      }
    }
  }
}