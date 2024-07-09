import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:mapos_app/controllers/products/productsController.dart';
import 'package:mapos_app/pages/products/products_view_page.dart';
import 'package:mapos_app/pages/products/products_page.dart';

class AdicionarProdutosPage extends StatefulWidget {
  @override
  _AdicionarProdutosPageState createState() => _AdicionarProdutosPageState();
}

class _AdicionarProdutosPageState extends State<AdicionarProdutosPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _codDeBarrasController = TextEditingController();
  TextEditingController _descricaoController = TextEditingController();
  MoneyMaskedTextController _precoVendaController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'R\$ ',
  );
  MoneyMaskedTextController _precoCompraController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'R\$ ',
  );
  TextEditingController _estoqueController = TextEditingController();
  TextEditingController _estoqueMinimoController = TextEditingController();

  @override
  void dispose() {
    _codDeBarrasController.dispose();
    _descricaoController.dispose();
    _precoVendaController.dispose();
    _precoCompraController.dispose();
    _estoqueController.dispose();
    _estoqueMinimoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Novo Produto'),
        backgroundColor: Colors.purple[100],
      ),
      body: SingleChildScrollView(
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
                        'Adicionar Produto',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff333649)),
                      ),
                    ],
                  ),
                  Divider(height: 30, color: Color(0xff333649)),
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
                  _buildTextField('Código de Barras', _codDeBarrasController, ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _addProduct();
                          }
                        },
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text('Adicionar'),
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

  void _addProduct() async {
    try {
      double precoVenda = double.parse(_precoVendaController.text.replaceAll(RegExp(r'[R$\s\.]'), '').replaceAll(',', '.'));
      double precoCompra = double.parse(_precoCompraController.text.replaceAll(RegExp(r'[R$\s\.]'), '').replaceAll(',', '.'));
      int estoque = int.parse(_estoqueController.text.replaceAll(',', ''));
      int estoqueMinimo = int.parse(_estoqueMinimoController.text.replaceAll(',', ''));
      String codDeBarras = _codDeBarrasController.text;

      bool success = await ControllerProducts().addProduct(
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
                content: Text('Produto adicionado com sucesso!')
            )
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => productsList(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao adicionar o produto')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }
}
