import 'package:flutter/material.dart';
import 'package:mapos_app/controllers/os/osController.dart';
import 'package:mapos_app/widgets/bottom_nav_menu.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/pages/os/os_view_page.dart';

import 'os_add_page.dart';

class OrdemServicoList extends StatefulWidget {
  @override
  _OrdemServicoListState createState() => _OrdemServicoListState();
}

class _OrdemServicoListState extends State<OrdemServicoList> {
  final ScrollController _controller = ScrollController();
  List<dynamic> OrdemServico = [];
  List<dynamic> filteredOrdemServico = [];
  bool isLoading = false;
  int currentPage = 0;
  int _selectedIndex = 4;
  bool _isLoading = true;
  int perPage = 10;
  final List<int> perPageOptions = [10, 20, 100, 200];
  String searchQuery = "";
  String selectedStatus = "Todos";
  final List<String> statusOptions = ["Todos", "Orçamento", "Aberto", "Faturado", "Negociação", "Em Andamento", "Finalizado", "Cancelado", "Aguardando Peças", "Aprovado"];
  bool showFilters = false;

  final Map<String, Color> statusColors = {
    'Orçamento': Color(0xffccb27f),
    'Aberto': Color(0xff00cc00),
    'Faturado': Color(0xffb166fd),
    'Negociação': Color(0xffadb304),
    'Em Andamento': Color(0xff436ded),
    'Finalizado': Color(0xff225566),
    'Cancelado': Colors.red,
    'Aguardando Peças': Color(0xfffd7e00),
    'Aprovado': Color(0xff7f7f7f),
  };

  @override
  void initState() {
    super.initState();
    _loadPerPagePreference();
    _loadMoreOrdemServico();
    _loadData();
    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent && !isLoading) {
        _loadMoreOrdemServico();
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
      perPage = prefs.getInt('perPage') ?? 10;
    });
  }

  Future<void> _savePerPagePreference(int perPage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('perPage', perPage);
  }

  Future<void> _loadMoreOrdemServico() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      List<dynamic> newOrdemServico = await ControllerOs().getAllOrdemServico(currentPage, perPage);
      setState(() {
        OrdemServico.addAll(newOrdemServico);
        filteredOrdemServico = OrdemServico;
        currentPage++;
        isLoading = false;
      });
    }
  }

  void _filterOrdemServico() {
    setState(() {
      filteredOrdemServico = OrdemServico.where((ordem) {
        final nomeClienteLower = ordem['nomeCliente'].toString().toLowerCase();
        final searchQueryLower = searchQuery.toLowerCase();
        final statusMatches = selectedStatus == "Todos" || ordem['status'] == selectedStatus;
        return nomeClienteLower.contains(searchQueryLower) && statusMatches;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ordens de Serviço'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: perPage,
                  items: perPageOptions.map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value por página'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      perPage = newValue!;
                      OrdemServico.clear();
                      currentPage = 0;
                      _savePerPagePreference(perPage);
                      _loadMoreOrdemServico();
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
                      MaterialPageRoute(builder: (context) => EmDesenvolvimentoPage()),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('Adicionar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xff333649),
                    side: BorderSide(color: Color(0xff333649)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      OrdemServico.clear();
                      currentPage = 0;
                      _loadMoreOrdemServico();
                    });
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Atualizar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xff333649),
                    side: BorderSide(color: Color(0xff333649)),
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
                    backgroundColor: Color(0xff333649),
                    side: BorderSide(color: Color(0xff333649)),
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
                      labelText: 'Buscar por nome',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        _filterOrdemServico();
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
                        _filterOrdemServico();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _controller,
              itemCount: filteredOrdemServico.length,
              itemBuilder: (BuildContext context, int index) {
                if (_isLoading) {
                  return _buildShimmerEffect(context);
                } else {
                  return _buildCard(context, index);
                }
              },
            ),
          ),
        ],
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
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
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
    return Card(
      margin: EdgeInsets.all(5.0),
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xff333649),
          child: Text(
            filteredOrdemServico[index]['idOs'].toString(),
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          filteredOrdemServico[index]['nomeCliente'],
          style: TextStyle(color: Colors.black87),
        ),
        subtitle: Text(
          filteredOrdemServico[index]['celular_cliente'],
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: statusColors[filteredOrdemServico[index]['status']] ?? Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                filteredOrdemServico[index]['status'],
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            IconButton(
              icon: Icon(Icons.visibility, color: Color(0xff333649)),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisualizarOrdemServicoPage(idOrdemServico: int.parse(filteredOrdemServico[index]['idOs'].toString())),
                  ),
                );
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
    // depois penso nisso
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
