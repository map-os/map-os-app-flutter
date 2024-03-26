import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:mapos_app/config/constants.dart';

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
  late TextEditingController _productEstoqueController;
  late TextEditingController _productEstoqueMinimoController;

  bool _isEditing = false;

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
      initialValue:
          double.tryParse(widget.product['precoCompra'] ?? '0.00') ?? 0.00,
    );
    _productPriceController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
      initialValue:
          double.tryParse(widget.product['precoVenda'] ?? '0.00') ?? 0.00,
    );
    _productEstoqueController =
        TextEditingController(text: widget.product['estoque'] ?? '');
    _productEstoqueMinimoController =
        TextEditingController(text: widget.product['estoqueMinimo'] ?? '');
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Produto'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.edit_note_sharp : Icons.edit),
            onPressed: () async {
              Map<String, dynamic> permissionsMap = await _getCiKey();
              List<dynamic> permissoes = permissionsMap['permissoes'];
              bool hasPermissionToEdit = false;
              for (var permissao in permissoes) {
                if (permissao['eProduto'] == '1') {
                  hasPermissionToEdit = true;
                  break;
                }
              }
              if (hasPermissionToEdit) {
                setState(() {
                  _isEditing = !_isEditing;
                  ;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content:
                        Text('Você não tem permissões para editar serviços.'),
                  ),
                );
              }
            },
          ),
        ],
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
                enabled: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productCodController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  labelText: 'COD de Barras',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productPrecoCompraController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Preço de compra',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productPriceController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Preço de Venda',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productEstoqueController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Estoque',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _productEstoqueMinimoController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Estoque Minimo',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide:
                        BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _isEditing
                    ? () async {
                        String precoCompra = _productPrecoCompraController.text
                            .replaceAll('R\$ ', '')
                            .replaceAll('.', '')
                            .replaceAll(',', '.');
                        String precoVenda = _productPriceController.text
                            .replaceAll('R\$ ', '')
                            .replaceAll('.', '')
                            .replaceAll(',', '.');

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
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2c9b5b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  minimumSize: Size(200, 50),
                ),
                child: Text(
                  'Salvar Alterações',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
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

  Future<bool> _updateProduct(Map<String, dynamic> updatedProduct) async {
    Map<String, dynamic> ciKey = await _getCiKey();

    var url =
        '${APIConfig.baseURL}${APIConfig.prodtuostesEndpoint}/${widget.product['idProdutos']}';

    try {
      var response = await http.put(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-API-KEY': ciKey['ciKey'],
        },
        body: jsonEncode(updatedProduct),
      );
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
