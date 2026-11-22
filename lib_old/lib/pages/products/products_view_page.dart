import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mapos_app/controllers/products/productsController.dart';
import 'package:mapos_app/pages/products/products_edit_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mapos_app/pages/products/products_page.dart';
import 'package:mapos_app/helpers/format.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

class VisualizarProdutosPage extends StatefulWidget {
  final int idProdutos;

  VisualizarProdutosPage({required this.idProdutos});

  @override
  _VisualizarProdutosPageState createState() => _VisualizarProdutosPageState();
}

class _VisualizarProdutosPageState extends State<VisualizarProdutosPage> {
  late Future<Map<String, dynamic>> futureProduct;

  @override
  void initState() {
    super.initState();
    futureProduct = ControllerProducts().getProductById(widget.idProdutos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualizar Produto'),
        backgroundColor: AppColors.appBarView,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureProduct,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}', style: TextStyle(color: Colors.red, fontSize: 18)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum detalhe do produto encontrado', style: TextStyle(fontSize: 18)));
          } else {
            final product = snapshot.data!;
            return SingleChildScrollView(
              padding: AppSpacing.paddingAllMd,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: AppSpacing.paddingAllLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_basket_rounded, color: AppColors.primary, size: 28),
                          SizedBox(width: 10),
                          Text(
                            'Detalhes do Produto #${product['idProdutos'].toString()}',
                            style: AppTypography.h1Style(AppColors.primary),
                          ),
                        ],
                      ),
                      const Divider(height: 30, color: AppColors.primary),
                      _buildDetailRow('Nome:', product['descricao']),
                      const SizedBox(height: 5),
                      _buildDetailRow('Cod Barras:', product['codDeBarra'] ?? 'Não cadastrado'),
                      const SizedBox(height: 5),
                      _buildDetailRow('Preço de Compra:', Format.formatCurrency.format(double.parse(product['precoCompra'].toString()))),
                      const SizedBox(height: 5),
                      _buildDetailRow('Preço de Venda:', Format.formatCurrency.format(double.parse(product['precoVenda'].toString()))),
                      const SizedBox(height: 5),
                      _buildDetailRow('Estoque:', product['estoque']),
                      const SizedBox(height: 5),
                      _buildDetailRow('Estoque Minimo:', product['estoqueMinimo']),
                      const SizedBox(height: 5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditarProdutosPage(idProdutos: widget.idProdutos),
                                ),
                              );
                            },
                            icon: Icon(Icons.edit, color: Colors.white),
                            label: Text('Editar'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.accent, // Cor do texto
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              _confirmDelete(context);
                            },
                            icon: Icon(Icons.delete, color: Colors.white),
                            label: Text('Excluir'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red, // Cor do texto
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingAllMd,
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: AppSpacing.paddingAllLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: 200,
                          height: 24,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Divider(height: 30, color: AppColors.primary),
                    _buildShimmerRow(),
                    SizedBox(height: 10),
                    _buildShimmerRow(),
                    SizedBox(height: 10),
                    _buildShimmerRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 16,
          color: Colors.white,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    final mathQuestion = generateMathQuestion();
    TextEditingController answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            'Confirmar Exclusão',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tem certeza de que deseja excluir este produto?'),
              SizedBox(height: 20),
              Text('Responda a seguinte conta para confirmar:'),
              SizedBox(height: 10),
              Text(
                mathQuestion['question'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: answerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Resposta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () {
                if (int.tryParse(answerController.text) == mathQuestion['answer']) {
                  Navigator.of(context).pop();
                  _deleteProduct();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Resposta incorreta.')),
                  );
                }
              },
              child: Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct() async {
    try {
      bool success = await ControllerProducts().deleteProduct(widget.idProdutos);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('produto excluído com sucesso!')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => productsList(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao excluir o produto')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Map<String, dynamic> generateMathQuestion() {
    Random random = Random();
    int a = random.nextInt(10);
    int b = random.nextInt(10);
    String question = '$a + $b';
    int answer = a + b;
    return {'question': question, 'answer': answer};
  }
}
