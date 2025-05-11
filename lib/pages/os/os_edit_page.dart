import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapos_app/pages/os/tabs/detalhes_tab.dart';
import 'package:mapos_app/pages/os/tabs/descontos_tab.dart';
import 'package:mapos_app/pages/os/tabs/servicos_tab.dart';
import 'package:mapos_app/pages/os/tabs/produtos_tab.dart';
import 'package:mapos_app/pages/os/tabs/anexos_tab.dart';
import 'package:mapos_app/pages/os/tabs/anotacoes_tab.dart';
import 'package:mapos_app/controllers/os/osController.dart';
import 'package:mapos_app/pages/os/os_view_page.dart';

class EditarOsPage extends StatefulWidget {
  final int idOs;
  EditarOsPage({required this.idOs});

  @override
  _EditarOsPageState createState() => _EditarOsPageState();
}

class _EditarOsPageState extends State<EditarOsPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _useTopMenu = true;
  late ControllerOs controllerOs;
  Map<String, dynamic>? ordemServico;
  bool _isLoading = true;

  List<Widget> get _tabPages {
    return [
      DetalhesTab(ordemServico: ordemServico),
      DescontosTab(ordemServico: ordemServico),
      ServicosTab(
        ordemServico: ordemServico,
        onAtualizar: _getOs,
      ),
      ProdutosTab(
        // onAtualizar: _getOs,
      ),
      AnexosTab(ordemServico: ordemServico),
      AnotacoesTab()
    ];
  }


  final List<IconData> _tabIcons = [
    Icons.info,
    Icons.percent,
    Icons.build,
    Icons.shopping_cart,
    Icons.attachment,
    Icons.note
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabPages.length, vsync: this);
    _tabController?.addListener(_handleTabSelection);
    _getOs();
  }

  @override
  void dispose() {
    _tabController!.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _getOs() async {
    controllerOs = ControllerOs();
    try {
      int idOs = widget.idOs;
      Map<String, dynamic> data = await controllerOs.getOrdemServicotById(idOs);
      setState(() {
        ordemServico = data;
        _isLoading = false;

      });
    } catch (e) {
      print("Erro ao buscar a ordem de serviço: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleTabSelection() {
    if (_useTopMenu) {
      setState(() {
        _currentIndex = _tabController!.index;
      });
    }
  }

  void _toggleMenu() {
    setState(() {
      _useTopMenu = !_useTopMenu;
      if (_useTopMenu) {
        _tabController!.animateTo(_currentIndex);
      }
    });
  }

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (_useTopMenu) {
      _tabController!.animateTo(index);
    } else {
      _pageController.jumpToPage(index);
    }
  }


  @override
  Widget build(BuildContext context) {
    final int idOs = int.parse(ordemServico!['idOs']);

    return Scaffold(
      appBar: AppBar(
        actionsIconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Editando a OS N° ${ordemServico!['idOs']}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xff333649),
        elevation: 2,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => VisualizarOrdemServicoPage(idOrdemServico: idOs)),
            );
          },
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: Icon(
                _useTopMenu ? Icons.menu_open : Icons.menu,
                key: ValueKey<bool>(_useTopMenu),
              ),
            ),
            onPressed: _toggleMenu,
          ),
        ],
        bottom: _useTopMenu && !_isLoading
            ? TabBar(
          controller: _tabController,
          onTap: (index) {
            _onNavItemTap(index);
          },
          tabs: _tabIcons
              .asMap()
              .entries
              .map(
                (entry) => Tab(
              icon: Icon(
                entry.value,
                color: _currentIndex == entry.key
                    ? Color(0xfffc7504)
                    : Colors.grey,
              ),
            ),
          )
              .toList(),
        )
            : null,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _useTopMenu
          ? TabBarView(
        controller: _tabController,
        children: _tabPages,
      )
          : Row(
        children: [
          SizedBox(
            width: 60,
            child: NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onNavItemTap,
              indicatorColor: Color(0xff44475c),
              labelType: NavigationRailLabelType.selected,
              selectedIconTheme: IconThemeData(color: Color(0xfffd6e03)),
              unselectedIconTheme: IconThemeData(color: Colors.white),
              backgroundColor: Color(0xff333649),
              elevation: 2,
              destinations: _tabIcons
                  .asMap()
                  .entries
                  .map(
                    (entry) => NavigationRailDestination(
                  icon: Icon(
                    entry.value,
                  ),
                  selectedIcon: Icon(
                    entry.value,
                  ),
                  label: SizedBox.shrink(),
                ),
              )
                  .toList(),
            ),
          ),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _tabController!.animateTo(index);
              },
              children: _tabPages,
            ),
          ),
        ],
      ),
    );
  }
}
