import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapos_app/controllers/logout_controller.dart';
import 'package:mapos_app/pages/login/login_page.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:mapos_app/widgets/bottom_nav_menu.dart';
import 'package:mapos_app/widgets/dashboard_status_widget.dart';
import 'package:mapos_app/widgets/calendar_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'dashboard_controller.dart';
import 'package:http/http.dart' as http;
import 'package:mapos_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final LogoutController logoutController = LogoutController();
  final DashboardController dashboardController = DashboardController();
  int _selectedIndex = 2;
  bool _isLoading = true;
  bool _hasInternet = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _checkInternetConnection();
    _timer = Timer.periodic(Duration(seconds: 30), (_) => _checkInternetConnection());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _loadDashboardData() async {
    try {
      await dashboardController.fetchDashboardData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao carregar dados do dashboard'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _logout() async {
    await logoutController.logout();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _checkInternetConnection() async {
    final hasInternet = await hasInternetConnection();
    setState(() {
      _hasInternet = hasInternet;
    });
  }


  Future<bool> hasInternetConnection() async {
    try {
      final result = await http.get(Uri.parse('http://clients3.google.com/generate_204'));
      if (result.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Dashboard"),
        actions: [
          FutureBuilder<bool>(
            future: hasInternetConnection(),
            builder: (context, snapshot) {
              String statusText;
              Color backgroundColor;

              if (snapshot.connectionState == ConnectionState.waiting) {
                statusText = "Checando...";
                backgroundColor = Colors.blue;
              } else if (snapshot.hasError || (snapshot.hasData && !snapshot.data!)) {
                statusText = "Offline";
                backgroundColor = Colors.red;
              } else if (snapshot.hasData && snapshot.data == true) {
                statusText = "Online";
                backgroundColor = Colors.green;
              } else {
                statusText = "Offline";
                backgroundColor = Colors.red;
              }

              return InkWell(
                onTap: () {
                  _checkInternetConnection();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),

          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.nights_stay : Icons.sunny),
            onPressed: () {
              if (themeProvider.themeMode == ThemeMode.dark) {
                themeProvider.setThemeMode(ThemeMode.light);
              } else {
                themeProvider.setThemeMode(ThemeMode.dark);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
        body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchField(),
              const SizedBox(height: 16),
              _buildInfoCardsRow(),
              const SizedBox(height: 16),
              _buildStatusWidget(),
              const SizedBox(height: 16),
              _buildCalendarWidget(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        activeIndex: _selectedIndex,
        onTap: _onItemTapped, context: context,
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Digite o numero de uma OS',
          icon: Icon(Icons.search),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildInfoCardsRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoCard(_isLoading ? null : '${dashboardController.clientes}', 'Clientes', Color(0xff32a8f6), Boxicons.bxs_group),
            _buildInfoCard(_isLoading ? null : '${dashboardController.produtos}', 'Produtos', const Color(0xfffab12a), Boxicons.bxs_package),
            _buildInfoCard(_isLoading ? null : '${dashboardController.servicos}', 'Serviços', const Color(0xff2cc5c5), Boxicons.bxs_stopwatch),
          ],
        ),
        SizedBox(height: 16.0), // Espaço entre as linhas de cartões
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoCard(_isLoading ? null : '${dashboardController.countOs}', 'Ordens', Color(0xfffd6987), Boxicons.bxs_spreadsheet),
            _buildInfoCard(_isLoading ? null : '${dashboardController.garantias}', 'Garantias', Color(0xff966abd), Boxicons.bxs_receipt),
            _buildInfoCard(_isLoading ? null : '${dashboardController.vendas}', 'Vendas', Color(0xff15b597), Icons.shopping_cart),
          ],
        ),
      ],
    );
  }



  Widget _buildStatusWidget() {
    return _isLoading
        ? Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 100,
        width: double.infinity,
        color: Colors.white,
      ),
    )
        : DashboardStatusWidget(
      openOrders: dashboardController.osAbertas.length,
      inProgressOrders: dashboardController.osAndamento.length,
      lowStockProducts: dashboardController.estoqueBaixo.length,
      openOrdersItems: dashboardController.osAbertas,
      inProgressOrdersItems: dashboardController.osAndamento,
      lowStockProductsItems: dashboardController.estoqueBaixo,
    );
  }

  Widget _buildCalendarWidget() {
    return _isLoading
        ? Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    )
        : CalendarWidget();
  }

  Widget _buildInfoCard(String? value, String description, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            SizedBox(height: 8),
            value == null
                ? Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.6),
              highlightColor: Colors.white.withOpacity(0.2),
              child: Container(
                width: double.infinity,
                height: 20,
                color: Colors.white,
              ),
            )
                : Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
