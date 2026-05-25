import 'package:flutter/material.dart';
import 'package:mapos_app/controllers/chamados/chamadosController.dart';
import 'package:mapos_app/widgets/bottom_nav_menu.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/pages/chamados/chamados_view_page.dart';
import 'package:mapos_app/pages/chamados/chamados_add_page.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_status_colors.dart';

class ChamadosList extends StatefulWidget {
  @override
  _ChamadosListState createState() => _ChamadosListState();
}

class _ChamadosListState extends State<ChamadosList> {
  final ScrollController _controller = ScrollController();
  List<dynamic> Chamados = [];
  List<dynamic> filteredChamados = [];
  bool isLoading = false;
  int currentPage = 0;
  int _selectedIndex = 4;
  bool _isLoading = true;
  int perPage = 10;
  final List<int> perPageOptions = [10, 20, 100, 200];
  String searchQuery = "";
  String selectedStatus = "Todos";
  final List<String> statusOptions = [
    "Todos", "Aberto", "Orçamento", "Negociação", "Aprovado",
    "Aguardando Peças", "Em Andamento", "Finalizado", "Faturado", "Cancelado"
  ];
  bool showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadPerPagePreference();
    _loadMoreChamados();
    _loadData();
    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent && !isLoading) {
        _loadMoreChamados();
      }
    });
  }

  void _loadData() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadPerPagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      perPage = prefs.getInt('perPageChamados') ?? 10;
    });
  }

  Future<void> _savePerPagePreference(int perPage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('perPageChamados', perPage);
  }

  Future<void> _loadMoreChamados() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      List<dynamic> newChamados = await ControllerChamados().getAllChamados(currentPage, perPage);
      setState(() {
        Chamados.addAll(newChamados);
        filteredChamados = Chamados;
        currentPage++;
        isLoading = false;
      });
    }
  }

  void _filterChamados() {
    setState(() {
      filteredChamados = Chamados.where((chamado) {
        final nomeClienteLower = (chamado['nomeCliente'] ?? '').toString().toLowerCase();
        final searchQueryLower = searchQuery.toLowerCase();
        final statusMatches = selectedStatus == "Todos" || chamado['status'] == selectedStatus;
        return nomeClienteLower.contains(searchQueryLower) && statusMatches;
      }).toList();
    });
  }

  Future<void> _refreshChamados() async {
    setState(() {
      Chamados.clear();
      filteredChamados.clear();
      currentPage = 0;
    });
    await _loadMoreChamados();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chamados'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: perPage,
                  items: perPageOptions.map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value por pagina'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      perPage = newValue!;
                      Chamados.clear();
                      currentPage = 0;
                      _savePerPagePreference(perPage);
                      _loadMoreChamados();
                    });
                  },
                  icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdicionarChamadoPage()),
                    ).then((_) => _refreshChamados());
                  },
                  icon: Icon(Icons.add),
                  label: Text('Abrir Chamado'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _refreshChamados();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Atualizar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      showFilters = !showFilters;
                    });
                  },
                  icon: Icon(showFilters ? Icons.filter_list_off : Icons.filter_list),
                  label: Text(showFilters ? 'Esconder' : 'Filtrar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: showFilters,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar por nome do cliente',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        _filterChamados();
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Filtrar por status',
                      border: OutlineInputBorder(),
                    ),
                    items: statusOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedStatus = newValue!;
                        _filterChamados();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshChamados,
              child: ListView.builder(
                controller: _controller,
                itemCount: filteredChamados.length,
                itemBuilder: (BuildContext context, int index) {
                  if (_isLoading) {
                    return _buildShimmerEffect(context);
                  } else {
                    return _buildCard(context, index);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdicionarChamadoPage()),
          ).then((_) => _refreshChamados());
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        activeIndex: _selectedIndex,
        onTap: _onItemTapped,
        context: context,
      ),
    );
  }

  Widget _buildShimmerEffect(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Card(
        margin: EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white,
          ),
          title: Container(
            height: 20,
            color: Colors.white,
          ),
          subtitle: Container(
            height: 20,
            color: Colors.white,
          ),
          trailing: Container(
            height: 20,
            width: 60,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, int index) {
    final chamado = filteredChamados[index];
    final String status = chamado['status'] ?? '';
    return Card(
      margin: EdgeInsets.all(5.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            chamado['idOs'].toString(),
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          chamado['nomeCliente'] ?? 'N/A',
          style: TextStyle(color: AppColors.textMuted),
        ),
        subtitle: Text(
          chamado['celular_cliente'] ?? '',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: AppStatusColors.getStatusColor(status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            IconButton(
              icon: Icon(Icons.visibility, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisualizarChamadoPage(idChamado: int.parse(chamado['idOs'].toString())),
                  ),
                ).then((_) => _refreshChamados());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}