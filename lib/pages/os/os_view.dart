import 'package:flutter/material.dart';
import 'package:mapos_app/pages/os/tabs/tab_anexos.dart';
import 'package:mapos_app/pages/os/tabs/tab_anotacoes.dart';
import 'package:mapos_app/pages/os/tabs/tab_descontos.dart';
import 'package:mapos_app/pages/os/tabs/tab_detalhes.dart';
import 'package:mapos_app/pages/os/tabs/tab_produtos.dart';
import 'package:mapos_app/pages/os/tabs/tab_servicos.dart';
import 'package:mapos_app/providers/calcTotal.dart'; // provider onde é feito o calculo da ordem de serviço
import 'package:intl/intl.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';

class OsManager extends StatefulWidget {
  final Map<String, dynamic> os;

  const OsManager({required this.os, Key? key}) : super(key: key); // Add const constructor

  @override
  _OsManagerState createState() => _OsManagerState();
}

class _OsManagerState extends State<OsManager> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedIndex;
  String _calctotal = '0.0'; // Initializing with a default value as a String
  late OsCalculator osCalculator;

  @override
  void initState() {
    super.initState();
    osCalculator = OsCalculator();
    _tabController = TabController(vsync: this, length: 6);
    _selectedIndex = 0;
    _tabController.addListener(_handleTabSelection);
    _initializeCalcTotal();
  }

  void _handleTabSelection() {
    setState(() {
      _selectedIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeCalcTotal() async {
    try {
      await osCalculator.getCalcTotal(widget.os);
      setState(() {
        _calctotal = osCalculator.calcTotal; // Assign the calcTotal directly
      });
    } catch (error) {
      // Handle potential errors during calculation retrieval
      print('Error fetching calcTotal: $error');
      // Consider notifying the user or taking appropriate actions (e.g., displaying an error message)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('OS ${widget.os['idOs']}'),
            const SizedBox(width: 20),
            Text(
              _formatCurrency(_calctotal), // No need to convert to double
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            color: const Color(0xff333649), // Use const for unchanging colors
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                    50), // Adjust border radius as needed
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.symmetric(horizontal: 12),
              // Adjust horizontal padding
              indicatorWeight: 1,
              // Adjust the thickness of the indicator
              unselectedLabelColor: Colors.white,
              labelColor: Color(0xff333649),
              tabs: [
                _buildTab(Boxicons.bxs_file, 0),
                _buildTab(Icons.local_offer, 1),
                _buildTab(Icons.shopping_cart, 2),
                _buildTab(Icons.room_service, 3),
                _buildTab(Icons.attach_file, 4),
                _buildTab(Icons.note, 5),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TabDetalhes(os: widget.os),
                TabDescontos(os: widget.os),
                TabProdutos(os: widget.os),
                TabServicos(os: widget.os),
                TabAnexos(os: widget.os),
                TabAnotacoes(os: widget.os),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(IconData iconData, int index) {
    return Tab(
      icon: Icon(
        iconData,
        size: 30,
      ),
    );
  }
}
  String _formatCurrency(String amount) {
  final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  return formatter.format(double.parse(amount)); // Format currency from String amount
}
