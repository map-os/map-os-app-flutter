import 'package:flutter/material.dart';
import 'package:mapos_app/controllers/services/servicesController.dart';
import 'package:mapos_app/widgets/bottom_nav_menu.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mapos_app/pages/services/services_view_page.dart';
import 'package:mapos_app/pages/services/services_add_page.dart';

class ServicesList extends StatefulWidget {
  @override
  _ServicesListState createState() => _ServicesListState();
}

class _ServicesListState extends State<ServicesList> {
  final ScrollController _controller = ScrollController();
  List<dynamic> services = [];
  bool isLoading = false;
  int currentPage = 0;
  int _selectedIndex = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoreServices();
    _loadData();
    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent && !isLoading) {
        _loadMoreServices();
      }
    });
  }

  void _loadData() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMoreServices() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      List<dynamic> newServices = await ControllerServices().getAllServices(currentPage);
      setState(() {
        services.addAll(newServices);
        currentPage++;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Serviços'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdicionarServicoPage()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        controller: _controller,
        itemCount: services.length,
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
            services[index]['idServicos'].toString(),
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          services[index]['nome'],
          style: TextStyle(color: Colors.black87),
        ),
        subtitle: Text(
          services[index]['descricao'],
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'R\$ ${services[index]['preco']}',
              style: TextStyle(color: Color(0xff333649), fontSize: 16),
            ),
            IconButton(
              icon: Icon(Icons.visibility, color: Color(0xff333649)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisualizarServicosPage(idServicos: int.parse(services[index]['idServicos'].toString())),
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
