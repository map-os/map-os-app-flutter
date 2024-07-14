import 'package:flutter/material.dart';
import 'package:mapos_app/controllers/clients/clientsController.dart';
import 'package:mapos_app/widgets/bottom_nav_menu.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mapos_app/pages/clients/clients_view_page.dart';
import 'package:mapos_app/pages/clients/clients_add_page.dart';

class ClientsList extends StatefulWidget {
  @override
  _ClientsListState createState() => _ClientsListState();
}

class _ClientsListState extends State<ClientsList> {
  final ScrollController _controller = ScrollController();
  List<dynamic> Clients = [];
  bool isLoading = false;
  int currentPage = 0;
  int _selectedIndex = 3;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoreClients();
    _loadData();
    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent && !isLoading) {
        _loadMoreClients();
      }
    });
  }

  void _loadData() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMoreClients() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      List<dynamic> newClients = await ControllerClients().getAllClients(currentPage);
      setState(() {
        Clients.addAll(newClients);
        currentPage++;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clientes'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdicionarClientePage()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        controller: _controller,
        itemCount: Clients.length,
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
            Clients[index]['idClientes'].toString(),
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          Clients[index]['nomeCliente'],
          style: TextStyle(color: Colors.black87),
        ),
        subtitle: Text(
          Clients[index]['celular'],
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text(
            //   'R\$ ${Clients[index]['preco']}',
            //   style: TextStyle(color: Color(0xff333649), fontSize: 16),
            // ),
            IconButton(
              icon: Icon(Icons.visibility, color: Color(0xff333649)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisualizarClientesPage(idClientes: int.parse(Clients[index]['idClientes'].toString())),
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
