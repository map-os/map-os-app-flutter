import 'package:flutter/material.dart';
import 'package:mapos_app/controllers/os/osController.dart';
import 'package:mapos_app/widgets/bottom_nav_menu.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/pages/os/os_view_page.dart';

class OrdemServicoList extends StatefulWidget {
  @override
  _OrdemServicoListState createState() => _OrdemServicoListState();
}

class _OrdemServicoListState extends State<OrdemServicoList> {
  final ScrollController _controller = ScrollController();
  List<dynamic> OrdemServico = [];
  bool isLoading = false;
  int currentPage = 0;
  int _selectedIndex = 4;
  bool _isLoading = true;
  int perPage = 10; // Default value for perPage
  final List<int> perPageOptions = [10, 20, 100, 200];

  final Map<String, Color> statusColors = {
    'Orçamento': Color(0xffccb27f)!,
    'Aberto': Color(0xff00cc00)!,
    'Faturado': Color(0xffb166fd)!,
    'Negociação': Color(0xffadb304)!,
    'Em Andamento': Color(0xff436ded)!,
    'Finalizado': Color(0xff225566)!,
    'Cancelado': Colors.red!,
    'Aguardando Peças': Color(0xfffd7e00)!,
    'Aprovado': Color(0xff7f7f7f)!,
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
        currentPage++;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ordens de Serviço'),
        actions: [
          DropdownButton<int>(
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
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => AdicionarClientePage()),
              // );
            },
          ),
        ],
      ),
      body: ListView.builder(
        controller: _controller,
        itemCount: OrdemServico.length,
        itemBuilder: (BuildContext context, int index) {
          if (_isLoading) {
            return _buildShimmerEffect(context);
          } else {
            return _buildCard(context, index);
          }
        },
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
            OrdemServico[index]['idOs'].toString(),
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          OrdemServico[index]['nomeCliente'],
          style: TextStyle(color: Colors.black87),
        ),
        subtitle: Text(
          OrdemServico[index]['celular_cliente'],
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                color: statusColors[OrdemServico[index]['status']] ?? Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                OrdemServico[index]['status'],
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            IconButton(
              icon: Icon(Icons.visibility, color: Color(0xff333649)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisualizarOrdemServicoPage(idOrdemServico: int.parse(OrdemServico[index]['idOs'].toString())),
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
