import 'package:flutter/material.dart';
import 'package:mapos_app/controllers/products/productsController.dart';
import 'package:mapos_app/widgets/bottom_nav_menu.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mapos_app/pages/products/products_view_page.dart';
import 'package:mapos_app/pages/products/products_add_page.dart';

class productsList extends StatefulWidget {
  @override
  _productsListState createState() => _productsListState();
}

class _productsListState extends State<productsList> {
  final ScrollController _controller = ScrollController();
  List<dynamic> products = [];
  bool isLoading = false;
  int currentPage = 0;
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoreproducts();
    _loadData();
    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent && !isLoading) {
        _loadMoreproducts();
      }
    });
  }

  void _loadData() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMoreproducts() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      List<dynamic> newproducts = await ControllerProducts().getAllProducts(currentPage);
      setState(() {
        products.addAll(newproducts);
        currentPage++;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Produtos'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdicionarProdutosPage()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        controller: _controller,
        itemCount: products.length,
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
            products[index]['idProdutos'].toString(),
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          products[index]['descricao'],
          style: TextStyle(color: Colors.black87),
        ),
        subtitle: Text(
          products[index]['estoque'],
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'R\$ ${products[index]['precoVenda']}',
              style: TextStyle(color: Color(0xff333649), fontSize: 16),
            ),
            IconButton(
              icon: Icon(Icons.visibility, color: Color(0xff333649)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisualizarProdutosPage(idProdutos: int.parse(products[index]['idProdutos'].toString())),
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
