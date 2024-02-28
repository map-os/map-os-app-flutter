import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapos_app/config/constants.dart';



class ProductAddScreen extends StatefulWidget {
  @override
  _ProductAddScreenState createState() => _ProductAddScreenState();
}

class _ProductAddScreenState extends State<ProductAddScreen> {
  late TextEditingController _productNameController;
  late TextEditingController _productCodController;
  late TextEditingController _productPriceController;
  late TextEditingController _productPrecoCompraController;
  late TextEditingController _productUnidadeController;
  late TextEditingController _productEstoqueController;
  late TextEditingController _productEstoqueMinimoController;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _productCodController = TextEditingController();
    _productPrecoCompraController = TextEditingController();
    _productPriceController = TextEditingController();
    _productPrecoCompraController = TextEditingController();
    _productUnidadeController = TextEditingController(text: 'UNID');
    _productEstoqueController = TextEditingController();
    _productEstoqueMinimoController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productCodController,
                decoration: InputDecoration(
                  labelText: 'COD de Barras',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productPrecoCompraController,
                decoration: InputDecoration(
                  labelText: 'Preço de compra',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productPriceController,
                decoration: InputDecoration(
                  labelText: 'Preço de Venda',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productEstoqueController,
                decoration: InputDecoration(
                  labelText: 'Estoque',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productEstoqueMinimoController,
                decoration: InputDecoration(
                  labelText: 'Estoque Minimo',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  bool success = await _addProduct();
                  if (success) {
                    _showSnackBar('Produto adicionado com sucesso',
                        backgroundColor: Colors.green,
                        textColor: Colors.white);
                  } else {
                    _showSnackBar('Falha ao adicionar o produto',
                        backgroundColor: Colors.red,
                        textColor: Colors.white);
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xfffa9e10),
                ),
                child: Text('Adicionar Produto'),
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

  Future<bool> _addProduct() async {
    String ciKey = await _getCiKey();

    var url = '${APIConfig.baseURL}${APIConfig.prodtuostesEndpoint}';

    Map<String, dynamic> newProduct = {
      'descricao': _productNameController.text,
      'codDeBarra': _productCodController.text,
      'precoVenda': _productPriceController.text,
      'precoCompra': _productPrecoCompraController.text,
      'unidade': 'UNID',
      'estoque': _productEstoqueController.text,
      'estoqueMinimo': _productEstoqueMinimoController.text,
      'entrada': '1',
      'saida': '',
    };

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-API-KEY': ciKey,
        },
        body: jsonEncode(newProduct),
      );
      if (response.statusCode == 201) {
        print('Produto adicionado com sucesso');
        return true;
      } else {
        print('Falha ao adicionar o produto: ${response.reasonPhrase}');
        return false;
      }
    } catch (error) {
      print('Erro ao enviar solicitação POST: $error');
      return false;
    }
  }
}
