import 'package:flutter/material.dart';
import 'package:mapos_app/pages/os/tabs/tab_anexos.dart';
import 'package:mapos_app/pages/os/tabs/tab_anotacoes.dart';
import 'package:mapos_app/pages/os/tabs/tab_descontos.dart';
import 'package:mapos_app/pages/os/tabs/tab_detalhes.dart';
import 'package:mapos_app/pages/os/tabs/tab_produtos.dart';
import 'package:mapos_app/pages/os/tabs/tab_servicos.dart';


class OsManager extends StatefulWidget {
  final Map<String, dynamic> os;

  OsManager({required this.os});

  @override
  _OsManagerState createState() => _OsManagerState();
}

class _OsManagerState extends State<OsManager> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 6);
    _selectedIndex = 0;
    _tabController.addListener(_handleTabSelection);
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

  @override
  Widget build(BuildContext context) {
    SizedBox(height: 10);
    return Scaffold(
      appBar: AppBar(
        title: Text('Ordem de Serviço'),
      ),
      body: Column(
        children: [
          Container(
            color: Color(0xff333649),
            child:TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Color(0xffffffff), // Cor de fundo do item selecionado
                borderRadius: BorderRadius.circular(100), // Define o raio da borda
              ),
              indicatorSize: TabBarIndicatorSize.tab, // Tamanho do indicador igual ao tamanho da tab
              indicatorWeight: 2,// Espessura do indicador
              unselectedLabelColor: Colors.white, // Cor dos ícones não selecionados
              labelColor: Colors.deepOrange, // Cor do ícone selecionado
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
