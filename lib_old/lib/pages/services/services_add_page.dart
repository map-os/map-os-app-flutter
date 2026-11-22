import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:mapos_app/controllers/services/servicesController.dart';
import 'package:mapos_app/pages/services/services_page.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

class AdicionarServicoPage extends StatefulWidget {
  @override
  _AdicionarServicoPageState createState() => _AdicionarServicoPageState();
}

class _AdicionarServicoPageState extends State<AdicionarServicoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late MoneyMaskedTextController _precoController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _descricaoController = TextEditingController();
    _precoController = MoneyMaskedTextController(
      decimalSeparator: ',', // Separador decimal
      thousandSeparator: '.', // Separador de milhar
      leftSymbol: 'R\$ ', // Símbolo à esquerda
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Serviço'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAllMd,
        child: Form(
          key: _formKey,
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
                      Icon(Icons.add, color: AppColors.primary, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Adicionar Serviço',
                        style: AppTypography.h1Style(AppColors.primary),
                      ),
                    ],
                  ),
                  Divider(height: 30, color: AppColors.primary),
                  _buildTextField('Nome', _nomeController),
                  SizedBox(height: 10),
                  _buildTextField('Descrição', _descricaoController),
                  SizedBox(height: 10),
                  _buildTextField('Preço', _precoController, keyboardType: TextInputType.number),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _addService();
                          }
                        },
                        icon: Icon(Icons.save, color: Colors.white),
                        label: Text('Salvar'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppColors.primary,
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

  void _addService() async {
    try {
      // Removendo a máscara para obter apenas o valor numérico.
      String precoText = _precoController.text.replaceAll(RegExp(r'[R$\s\.]'), '').replaceAll(',', '.');

      double preco = double.parse(precoText);

      bool success = await ControllerServices().addService(
        _nomeController.text,
        _descricaoController.text,
        preco,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Serviço adicionado com sucesso!')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ServicesList()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao adicionar o serviço')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }
}