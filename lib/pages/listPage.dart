import 'package:flutter/material.dart';
import 'package:mapos_app/pages/os/os_view_page.dart';
import 'package:mapos_app/pages/products/products_view_page.dart';

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
        backgroundColor: const Color(0xfffdfdff),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        itemCount: items.length,
        itemBuilder: (context, index) {
          var item = items[index];
          if (item.containsKey('idOs')) {
            return _buildOrderServiceCard(context, item);
          } else if (item.containsKey('idProdutos')) {
            return _buildLowStockProductCard(context, item);
          } else {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12.0),
              child: const ListTile(
                title: Text("Item desconhecido"),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildOrderServiceCard(BuildContext context, Map<dynamic, dynamic> item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['nomeCliente'] ?? "Cliente não especificado",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "ID OS: ${item['idOs']}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            SelectableText(
              item['descricaoProduto']?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '') ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              "Status: ${item['status']}",
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text("Visualizar"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xff333649),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  textStyle: const TextStyle(fontSize: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VisualizarOrdemServicoPage(idOrdemServico: int.parse(item['idOs'].toString())),
                      ),
                    );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockProductCard(BuildContext context, Map<dynamic, dynamic> item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge ID
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff333649),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Text(
                    "${item['idProdutos']}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12.0),
                // Descrição
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['descricao'] ?? "Produto não especificado",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
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
                          const SizedBox(width: 12),
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
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text("Visualizar"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xff333649),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  textStyle: const TextStyle(fontSize: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisualizarProdutosPage(idProdutos: int.parse(item['idProdutos'].toString())),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
