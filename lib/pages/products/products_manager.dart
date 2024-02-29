import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapos_app/config/constants.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class ProductEditScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  ProductEditScreen({required this.product});

  @override
  _ProductEditScreenState createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  late TextEditingController _productNameController;
  late TextEditingController _productCodController;
  late TextEditingController _productPriceController;
  late TextEditingController _productPrecoCompraController;
  // late TextEditingController _productUnidadeController;
  late TextEditingController _productEstoqueController;
  late TextEditingController _productEstoqueMinimoController;


  @override
  void initState() {
    super.initState();
    _productNameController =
        TextEditingController(text: widget.product['descricao'] ?? '');
    _productCodController =
        TextEditingController(text: widget.product['codDeBarra'] ?? '');
    _productPrecoCompraController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
      initialValue: double.tryParse(widget.product['precoCompra'] ?? '0.00') ?? 0.00,
    );
    _productPriceController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
      initialValue: double.tryParse(widget.product['precoVenda'] ?? '0.00') ?? 0.00,
    );
    // _productUnidadeController =
    //     TextEditingController(text: widget.product['unidade'] ?? 'UNID');
    _productEstoqueController =
        TextEditingController(text: widget.product['estoque'] ?? '');
    _productEstoqueMinimoController =
        TextEditingController(text: widget.product['estoqueMinimo'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ID do Produto: ${widget.product['idProdutos'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productNameController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productCodController,
                decoration: InputDecoration(
                  labelText: 'COD de Barras',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productPrecoCompraController,
                decoration: InputDecoration(
                  labelText: 'Preço de compra',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productPriceController,
                decoration: InputDecoration(
                  labelText: 'Preço de Venda',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productEstoqueController,
                decoration: InputDecoration(
                  labelText: 'Estoque',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productEstoqueMinimoController,
                decoration: InputDecoration(
                  labelText: 'Estoque Minimo',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
          Container(
            height: 50.0,
            decoration: BoxDecoration(
              color: Color(0xfffa9e10), // Cor de fundo do botão
              borderRadius: BorderRadius.circular(8.0), // Borda arredondada
            ),
            child:
            ElevatedButton(
                onPressed: () async {
                  String precoCompra = _productPrecoCompraController.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
                  String precoVenda = _productPriceController.text.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');

                  Map<String, dynamic> updatedProduct = {
                    'idProdutos': widget.product['idProdutos'],
                    'descricao': _productNameController.text,
                    'codDeBarra': _productCodController.text,
                    'precoVenda': precoVenda,
                    'precoCompra': precoCompra,
                    'unidade': 'UNID',
                    'estoque': _productEstoqueController.text,
                    'estoqueMinimo': _productEstoqueMinimoController.text,
                    'entrada': '',
                    'saida': '',
                  };


                  bool success = await _updateProduct(updatedProduct);
                  if (success) {
                    _showSnackBar('Produto atualizado com sucesso',
                        backgroundColor: Colors.green,
                        textColor: Colors.white);
                  } else {
                    _showSnackBar('Falha ao atualizar o produto',
                        backgroundColor: Colors.red,
                        textColor: Colors.white);
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xfffa9e10),
                ),
                child: Text('Salvar Alterações'),
              ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message,
      {Color backgroundColor = Colors.black, Color textColor = Colors.white}) {
    final snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: textColor)),
      backgroundColor: backgroundColor,
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<String> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    return ciKey;
  }

  Future<bool> _updateProduct(Map<String, dynamic> updatedProduct) async {
    String ciKey = await _getCiKey();

    var url =
        '${APIConfig.baseURL}${APIConfig.prodtuostesEndpoint}/${widget.product['idProdutos']}';

    try {
      var response = await http.put(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-API-KEY': ciKey,
        },
        body: jsonEncode(updatedProduct),
      );
      print(jsonEncode(updatedProduct));
      if (response.statusCode == 200) {
        print('Produto atualizado com sucesso');
        return true;
      } else {
        print('Falha ao atualizar o produto: ${response.reasonPhrase}');
        return false;
      }
    } catch (error) {
      print('Erro ao enviar solicitação PUT: $error');
      return false;
    }
  }
}
