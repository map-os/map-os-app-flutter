import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapos_app/config/constants.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class ProductAddScreen extends StatefulWidget {
  @override
  _ProductAddScreenState createState() => _ProductAddScreenState();
}

class _ProductAddScreenState extends State<ProductAddScreen> {
  late TextEditingController _productNameController;
  late TextEditingController _productCodController;
  late MoneyMaskedTextController _productPriceController;
  late MoneyMaskedTextController _productPrecoCompraController;
  late TextEditingController _productEstoqueController;
  late TextEditingController _productEstoqueMinimoController;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _productCodController = TextEditingController();
    _productPrecoCompraController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
    );
    _productPriceController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
    );
    _productEstoqueController = TextEditingController();
    _productEstoqueMinimoController = TextEditingController();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productCodController.dispose();
    _productPrecoCompraController.dispose();
    _productPriceController.dispose();
    _productEstoqueController.dispose();
    _productEstoqueMinimoController.dispose();
    super.dispose();
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
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
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
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productPrecoCompraController,
                decoration: InputDecoration(
                  labelText: 'Preço de compra',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productPriceController,
                decoration: InputDecoration(
                  labelText: 'Preço de Venda',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productEstoqueController,
                decoration: InputDecoration(
                  labelText: 'Estoque',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productEstoqueMinimoController,
                decoration: InputDecoration(
                  labelText: 'Estoque Minimo',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide: BorderSide.none, // Remove a linha preta
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Define o raio do border
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  bool success = await _addProduct();
                  if (success) {
                    final snackBar = SnackBar(
                      content: Text('Produto adicionado com sucesso'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  } else {
                    final snackBar = SnackBar(
                      content: Text('Falha ao adicionar o produto'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2c9b5b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  minimumSize: Size(200, 50),
                ),
                child: Text(
                  'Adicionar Produto',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    return ciKey;
  }

  Future<bool> _addProduct() async {
    String ciKey = await _getCiKey();

    var url = '${APIConfig.baseURL}${APIConfig.prodtuostesEndpoint}';
    String precoCompra = _productPrecoCompraController.text
        .replaceAll('R\$ ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    String precoVenda = _productPriceController.text
        .replaceAll('R\$ ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    Map<String, dynamic> newProduct = {
      'descricao': _productNameController.text,
      'codDeBarra': _productCodController.text,
      'precoVenda': precoCompra,
      'precoCompra': precoVenda,
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
        Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('refresh_token')) {
          String refreshToken = data['refresh_token'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', refreshToken);
        } else {
          print('problema com sua sessão, faça login novamente!');
        }
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
