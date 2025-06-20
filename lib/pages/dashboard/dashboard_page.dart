import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapos_app/controllers/logout_controller.dart';
import 'package:mapos_app/pages/login/login_page.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:mapos_app/widgets/bottom_nav_menu.dart';
import 'package:mapos_app/widgets/dashboard_status_widget.dart';
import 'package:mapos_app/widgets/calendar_widget.dart';
import 'package:shimmer/shimmer.dart';
import '../about.dart';
import 'dashboard_controller.dart';
import 'package:http/http.dart' as http;
import 'package:mapos_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:mapos_app/pages/os/os_view_page.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final LogoutController logoutController = LogoutController();
  final DashboardController dashboardController = DashboardController();
  int _selectedIndex = 2;
  bool _isLoading = true;
  // bool _hasInternet = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // _checkInternetConnection();
    // _timer = Timer.periodic(Duration(seconds: 30), (_) => _checkInternetConnection());
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

  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }
  //
  // Future<void> _checkInternetConnection() async {
  //   final hasInternet = await hasInternetConnection();
  //   setState(() {
  //     _hasInternet = hasInternet;
  //   });
  // }


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

  void _navigateToOsView(String osNumber) {
    if (osNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite um número de OS válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verifica se o número contém apenas dígitos
    if (!RegExp(r'^\d+$').hasMatch(osNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O número da OS deve conter apenas dígitos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final osId = int.tryParse(osNumber);
    if (osId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Número de OS inválido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navega para a página de visualização da OS
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisualizarOrdemServicoPage(idOrdemServico: osId),
      ),
    ).then((_) {
      // Atualiza o dashboard quando retornar da visualização da OS
      _loadDashboardData();
    });
  }
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Indicador de conexão (pill style)
          // FutureBuilder<bool>(
          //   future: hasInternetConnection(),
          //   builder: (context, snapshot) {
          //     String statusText = "Checando...";
          //     Color backgroundColor = Colors.blue;

              // if (snapshot.connectionState == ConnectionState.done) {
              //   if (snapshot.hasError || (snapshot.hasData && !snapshot.data!)) {
              //     statusText = "Offline";
              //     backgroundColor = Colors.redAccent;
              //   } else if (snapshot.hasData && snapshot.data == true) {
              //     statusText = "Online";
              //     backgroundColor = Colors.green;
              //   }
              // }

          //     return Container(
          //       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          //       decoration: BoxDecoration(
          //         color: backgroundColor,
          //         borderRadius: BorderRadius.circular(20),
          //       ),
          //       child: Text(
          //         statusText,
          //         style: const TextStyle(color: Colors.white, fontSize: 12),
          //       ),
          //     );
          //   },
          // ),

          Tooltip(
            message: themeProvider.themeMode == ThemeMode.dark ? 'Modo Claro' : 'Modo Escuro',
            child: IconButton(
              icon: Icon(
                themeProvider.themeMode == ThemeMode.dark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
              ),
              onPressed: () {
                themeProvider.setThemeMode(
                  themeProvider.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                );
              },
            ),
          ),

          // Avatar com Dropdown (perfil)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              icon: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'perfil':
                  case 'config':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Esta seção ainda está em desenvolvimento.')),
                    );
                    break;
                  case 'Sobre':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AboutAppPage()),
                    );
                    break;
                  case 'logout':
                    _logout();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'perfil',
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Row(
                      children: [
                        const Text('Meu Perfil'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Em Breve',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'config',
                  child: ListTile(
                    leading: const Icon(Icons.settings),
                    title: Row(
                      children: [
                        const Text('Configurações'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Em Breve',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'Sobre',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text('Sobre'),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.redAccent),
                    title: Text('Sair'),
                  ),
                ),
              ],
            ),
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
      // bottomNavigationBar: BottomNavigationBarWidget(
      //   activeIndex: _selectedIndex,
      //   onTap: _onItemTapped, context: context,
      // ),
    );
  }

  Widget _buildSearchField() {
    final TextEditingController _osSearchController = TextEditingController();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _osSearchController,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Digite o número de uma OS',
          icon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              _navigateToOsView(_osSearchController.text);
            },
          ),
        ),
        keyboardType: TextInputType.number,
        onSubmitted: (value) {
          _navigateToOsView(value);
        },
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
