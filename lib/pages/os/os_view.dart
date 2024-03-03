import 'package:flutter/material.dart';
import 'package:mapos_app/pages/os/tabs/tab_anexos.dart';
import 'package:mapos_app/pages/os/tabs/tab_anotacoes.dart';
import 'package:mapos_app/pages/os/tabs/tab_descontos.dart';
import 'package:mapos_app/pages/os/tabs/tab_detalhes.dart';
import 'package:mapos_app/pages/os/tabs/tab_produtos.dart';
import 'package:mapos_app/pages/os/tabs/tab_servicos.dart';
import 'package:mapos_app/providers/calcTotal.dart';
import 'package:intl/intl.dart';

class OsManager extends StatefulWidget {
  final Map<String, dynamic> os;

  OsManager({required this.os});

  @override
  _OsManagerState createState() => _OsManagerState();
}

class _OsManagerState extends State<OsManager> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedIndex;
  double _calctotal = 0.0;
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

  // Função para inicializar o cálculo total
  void _initializeCalcTotal() async {
    await osCalculator.getCalcTotal(widget.os);
    setState(() {
      _calctotal = osCalculator.calcTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('OS ${widget.os['idOs']}'),
            SizedBox(width: 10),
            Text(
              _formatCurrency(_calctotal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Color(0xff333649),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Color(0xffffffff),
                borderRadius: BorderRadius.circular(100),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 2,
              unselectedLabelColor: Colors.white,
              labelColor: Colors.deepOrange,
              tabs: [
                _buildTab(Icons.details, 0),
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
        size: 18,
      ),
    );
  }
}
String _formatCurrency(double amount) {
  final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  return formatter.format(amount);
}
