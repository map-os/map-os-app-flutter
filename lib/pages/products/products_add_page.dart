import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:mapos_app/controllers/products/productsController.dart';
import 'package:mapos_app/pages/products/products_page.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

class AdicionarProdutosPage extends StatefulWidget {
  const AdicionarProdutosPage({Key? key}) : super(key: key);

  @override
  _AdicionarProdutosPageState createState() => _AdicionarProdutosPageState();
}

class _AdicionarProdutosPageState extends State<AdicionarProdutosPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _codDeBarrasController = TextEditingController();
  final TextEditingController _estoqueController = TextEditingController();
  final TextEditingController _estoqueMinimoController = TextEditingController();

  final MoneyMaskedTextController _precoVendaController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'R\$ ',
  );

  final MoneyMaskedTextController _precoCompraController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'R\$ ',
  );

  @override
  void dispose() {
    // Liberar os recursos dos controllers
    _descricaoController.dispose();
    _codDeBarrasController.dispose();
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
        title: const Text('Adicionar Novo Produto'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAllMd,
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: AppSpacing.paddingAllLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const Divider(height: 30, color: AppColors.primary),
                  _buildFormFields(),
                  const SizedBox(height: 20),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Icon(Icons.shopping_basket_rounded, color: AppColors.primary, size: 28),
        SizedBox(width: 10),
        Text(
          'Adicionar Produto',
          style: AppTypography.h1Style(AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField('Descrição', _descricaoController),
        const SizedBox(height: 16),
        _buildTextField(
          'Preço de Venda',
          _precoVendaController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Preço de Compra',
          _precoCompraController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Estoque',
          _estoqueController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Estoque Mínimo',
          _estoqueMinimoController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildTextField('Código de Barras', _codDeBarrasController),
      ],
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        contentPadding: AppSpacing.paddingH_mdV_sm,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, insira $label';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: _submitForm,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Adicionar'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.primary,
            padding: AppSpacing.paddingH_mdV_sm,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _addProduct();
    }
  }

  Future<void> _addProduct() async {
    try {
      // Processamento dos valores
      final double precoVenda = _parseMoneyValue(_precoVendaController.text);
      final double precoCompra = _parseMoneyValue(_precoCompraController.text);
      final int estoque = int.parse(_estoqueController.text.replaceAll(',', ''));
      final int estoqueMinimo = int.parse(_estoqueMinimoController.text.replaceAll(',', ''));
      final String codDeBarras = _codDeBarrasController.text;
      final String descricao = _descricaoController.text;

      final bool success = await ControllerProducts().addProduct(
        codDeBarras,
        descricao,
        precoCompra,
        precoVenda,
        estoque,
        estoqueMinimo,
      );

      _handleResponse(success);
    } catch (e) {
      _showErrorMessage('Erro: $e');
    }
  }

  double _parseMoneyValue(String value) {
    return double.parse(
      value.replaceAll(RegExp(r'[R$\s\.]'), '').replaceAll(',', '.'),
    );
  }

  void _handleResponse(bool success) {
    if (success) {
      // Mostrar mensagem e navegar após o SnackBar ser exibido
      _showSuccessMessageAndNavigate();
    } else {
      _showErrorMessage('Falha ao adicionar o produto');
    }
  }

  void _showSuccessMessageAndNavigate() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final snackBar = const SnackBar(
      backgroundColor: Colors.green,
      content: Text('Produto adicionado com sucesso!'),
      duration: Duration(seconds: 1),
    );

    scaffoldMessenger
        .showSnackBar(snackBar)
        .closed
        .then((_) {
    });
  }

  void _showErrorMessage(String message) {
    // É seguro mostrar mensagem de erro sem navegar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

}