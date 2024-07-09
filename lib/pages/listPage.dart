import 'package:flutter/material.dart';

class ItemListPage extends StatelessWidget {
  final String title;
  final List<dynamic> items;

  const ItemListPage({Key? key, required this.title, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("Items received: ${items.length}");

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          var item = items[index];
          if (item.containsKey('idOs')) {
            return _buildOrderServiceCard(item);
          } else if (item.containsKey('idProdutos')) {
            return _buildLowStockProductCard(item);
          } else {
            return Card(
              child: ListTile(
                title: Text("Item desconhecido"),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildOrderServiceCard(Map<dynamic, dynamic> item) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(item['nomeCliente'] ?? "Cliente não especificado"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID OS: ${item['idOs']}"),
            SelectableText(item['descricaoProduto']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '') ?? ''),
            Text("Status: ${item['status']}"),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildLowStockProductCard(Map<dynamic, dynamic> item) {
    return Card(
      elevation: 4.0, // Sombra para dar profundidade
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xff333649),
                borderRadius: BorderRadius.circular(5.0),
              ),
              padding: EdgeInsets.all(13.0),
              margin: EdgeInsets.only(top: 15),
              child: Text(
                "${item['idProdutos']}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descrição do produto
                  Text(
                    item['descricao'] ?? "Produto não especificado",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Estoque: ${item['estoque']}",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            Text(
                              "Estoque Mínimo: ${item['estoqueMinimo']}",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Compra: R\$ ${item['precoCompra']}",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            Text(
                              "Venda: R\$ ${item['precoVenda']}",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.0),
            IconButton(
              padding: EdgeInsets.only(top: 10.0, left: 9.0),
              icon: Icon(Icons.edit, color: Color(0xff333649)),
              onPressed: () {
                // ............
              },
            ),
          ],
        ),
      ),
    );
  }
}
