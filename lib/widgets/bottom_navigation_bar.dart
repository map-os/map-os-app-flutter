import 'package:flutter/material.dart';
import 'package:mapos_app/widgets/ButtonMenu.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int activeIndex;
  final Function(int index)? onTap;

  const BottomNavigationBarWidget({
    Key? key,
    required this.activeIndex,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0), // Defina a margem inferior desejada aqui
      child: CircleNavBar(
        activeIndex: activeIndex,
        onTap: _handleTap,
        activeIcons: [
          Icon(Icons.home, color: Colors.white),
          Icon(Icons.money, color: Colors.white),
          Icon(Icons.search, color: Colors.white),
          Icon(Icons.notifications, color: Colors.white),
          Icon(Icons.person, color: Colors.white),
        ],
        inactiveIcons: [
          Icon(Icons.home_outlined, color: Colors.white),
          Icon(Icons.monetization_on_outlined, color: Colors.white),
          Icon(Icons.search_outlined, color: Colors.white),
          Icon(Icons.notifications_none_outlined, color: Colors.white),
          Icon(Icons.person_outline, color: Colors.white),
        ],
        height: 60,
        circleWidth: 50,
        color: Color(0xffd97b06),
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        cornerRadius: BorderRadius.circular(30),
        shadowColor: Colors.grey,
        elevation: 8,
      ),
    );
  }

  void _handleTap(int index) {
    if (onTap != null) {
      onTap!(index);
    }
  }
}
