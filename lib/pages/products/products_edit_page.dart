import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:mapos_app/controllers/products/productsController.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mapos_app/pages/products/products_view_page.dart';

class EditarProdutosPage extends StatefulWidget {
  final int idProdutos;

  EditarProdutosPage({required this.idProdutos});

  @override
  _EditarProdutosPageState createState() => _EditarProdutosPageState();
}

class _EditarProdutosPageState extends State<EditarProdutosPage> {
  late Future<Map<String, dynamic>> futureProduct;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codDeBarrasController;
  late TextEditingController _descricaoController;
  late MoneyMaskedTextController _precoVendaController;
  late MoneyMaskedTextController _precoCompraController;
  late TextEditingController _estoqueController;
  late TextEditingController _estoqueMinimoController;

  @override
  void initState() {
    super.initState();
    futureProduct = ControllerProducts().getProductById(widget.idProdutos);
    _estoqueMinimoController = TextEditingController();
    _descricaoController = TextEditingController();
    _precoVendaController = MoneyMaskedTextController(
        decimalSeparator: ',',
        thousandSeparator: '.',
        leftSymbol: 'R\$ '
    );
    _precoCompraController = MoneyMaskedTextController(
        decimalSeparator: ',',
        thousandSeparator: '.',
        leftSymbol: 'R\$ '
    );
    _estoqueController = TextEditingController();
    _codDeBarrasController = TextEditingController();
  }

  @override
  void dispose() {
    _estoqueMinimoController.dispose();
    _descricaoController.dispose();
    _precoVendaController.dispose();
    _precoCompraController.dispose();
    _estoqueController.dispose();
    _codDeBarrasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Produto'),
        backgroundColor: Color(0xfffcf5fd),
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
            _codDeBarrasController.text = product['codDeBarras'] ?? '0';
            _descricaoController.text = product['descricao'] ?? '';
            _precoVendaController.updateValue(double.parse(product['precoVenda'].toString()));
            _precoCompraController.updateValue(double.parse(product['precoCompra'].toString()));
            _estoqueController.text = product['estoque'] ?? 'NaN';
            _estoqueMinimoController.text = product['estoqueMinimo'];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_basket_rounded, color: Color(0xff333649), size: 28),
                            SizedBox(width: 10),
                            Text(
                              'Editando Produto #${product['idProdutos'].toString()}',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff333649)),
                            ),
                          ],
                        ),
                        const Divider(height: 30, color: Color(0xff333649)),
                        SizedBox(height: 20),
                        _buildTextField('Descrição', _descricaoController),
                        SizedBox(height: 10),
                        _buildTextField('Preço de Venda', _precoVendaController, keyboardType: TextInputType.number),
                        SizedBox(height: 10),
                        _buildTextField('Preço de Compra', _precoCompraController, keyboardType: TextInputType.number),
                        SizedBox(height: 10),
                        _buildTextField('Estoque', _estoqueController, keyboardType: TextInputType.number),
                        SizedBox(height: 10),
                        _buildTextField('Estoque Minimo', _estoqueMinimoController),
                        SizedBox(height: 10),
                        _buildTextField('Código de Barras', _codDeBarrasController),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _saveProduct();
                                }
                              },
                              icon: Icon(Icons.save, color: Colors.white),
                              label: Text('Salvar'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xff333649), // Cor do botão
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }


  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, insira $label';
        }
        return null;
      },
    );
  }

  void _saveProduct() async {
    try {
      double precoVenda = double.parse(_precoVendaController.text.replaceAll(RegExp(r'[R$\s\.]'), '').replaceAll(',', '.'));
      double precoCompra = double.parse(_precoCompraController.text.replaceAll(RegExp(r'[R$\s\.]'), '').replaceAll(',', '.'));
      int estoque = int.parse(_estoqueController.text.replaceAll(',', ''));
      int estoqueMinimo = int.parse(_estoqueMinimoController.text.replaceAll(',', ''));
      String codDeBarras = _codDeBarrasController.text;

      bool success = await ControllerProducts().updateProduct(
          widget.idProdutos,
          codDeBarras,
          _descricaoController.text,
          precoCompra,
          precoVenda,
          estoque,
          estoqueMinimo,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: Colors.green,
                content: Text('Produto atualizado com sucesso!')
            )
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VisualizarProdutosPage(idProdutos: widget.idProdutos),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao atualizar o produto')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(5, (index) => _buildShimmerRow()),
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
}
