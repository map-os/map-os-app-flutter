import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/controllers/TokenController.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

class DescontosTab extends StatefulWidget {
  final Map<String, dynamic>? ordemServico;

  const DescontosTab({Key? key, this.ordemServico}) : super(key: key);

  @override
  _DescontosTabState createState() => _DescontosTabState();
}

class _DescontosTabState extends State<DescontosTab> {
  String tipoDescontoDropdown = 'R\$';
  final TextEditingController valorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double valorTotalOS = 0.0;
  double totalProdutos = 0.0;
  double totalServicos = 0.0;
  double valorComDesconto = 0.0;
  double valorDesconto = 0.0;

  String _apiToDropdown(String? apiValue) {
    if (apiValue == 'real') return 'R\$';
    if (apiValue == 'porcento') return '%';
    return 'R\$';
  }

  String _dropdownToApi(String dropdownValue) {
    if (dropdownValue == 'R\$') return 'real';
    if (dropdownValue == '%') return 'porcento';
    return 'real';
  }

  @override
  void initState() {
    super.initState();
    if (widget.ordemServico != null) {
      tipoDescontoDropdown = _apiToDropdown(widget.ordemServico!['tipo_desconto']);
      valorController.text = widget.ordemServico!['desconto']?.toString() ?? '';
      totalProdutos = double.tryParse(widget.ordemServico!['totalProdutos']?.toString() ?? '0') ?? 0.0;
      totalServicos = double.tryParse(widget.ordemServico!['totalServicos']?.toString() ?? '0') ?? 0.0;
      valorTotalOS = totalProdutos + totalServicos;

      _calcularDesconto();

    }
  }

  void _calcularDesconto() {
    final valorDigitado = double.tryParse(valorController.text) ?? 0.0;

    setState(() {
      if (tipoDescontoDropdown == 'R\$') {
        valorDesconto = valorDigitado;
        valorComDesconto = valorTotalOS - valorDesconto;
      } else {
        valorDesconto = (valorTotalOS * valorDigitado) / 100;
        valorComDesconto = valorTotalOS - valorDesconto;
        debugPrint(valorDesconto.toString());
      }

      // Garantir que não fique negativo
      if (valorComDesconto < 0) {
        valorComDesconto = 0.0;
        valorDesconto = valorTotalOS;
      }
    });
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> salvarDesconto() async {
    if (!_formKey.currentState!.validate()) return;

    final idOs = widget.ordemServico?['idOs'];
    if (idOs == null) return;

    final url = "${APIConfig.baseURL}${APIConfig.osEndpoint}/$idOs/desconto";
    final uri = Uri.parse(url);

    var accessToken = await getAccessToken();
    if (accessToken == null) {
      _showToast('Token de acesso não encontrado!', isError: true);
      return;
    }

    try {
      var response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'App-Version': APIConfig.appVersion,
        },
        body: jsonEncode({
          'desconto': valorController.text,
          'tipo_desconto': _dropdownToApi(tipoDescontoDropdown),
          'valor_desconto': valorTotalOS - valorDesconto,
        }),
      );

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        final prefs = await SharedPreferences.getInstance();
        accessToken = prefs.getString('access_token');
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'App-Version': APIConfig.appVersion,
          },
          body: jsonEncode({
            'desconto': valorController.text,
            'tipo_desconto': _dropdownToApi(tipoDescontoDropdown),
            'valor_desconto': valorTotalOS - valorDesconto,
          }),
        );
      }

      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        _showToast('Desconto salvo com sucesso!');
      } else {
        _showToast('Erro ao salvar desconto', isError: true);
      }
    } catch (e) {
      _showToast('Erro no servidor: ${e.toString()}', isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.red : Colors.green,
      content: Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingAllLg,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: AppSpacing.paddingAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Desconto',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tipoDescontoDropdown,
                      items: ['R\$', '%'].map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(
                            tipo,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          tipoDescontoDropdown = value!;
                          _calcularDesconto();
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: AppSpacing.paddingAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipoDescontoDropdown == 'R\$' ? 'Valor em Reais' : 'Percentual',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: valorController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) => _calcularDesconto(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um valor';
                        }
                        final valor = double.tryParse(value);
                        if (valor == null) {
                          return 'Valor inválido';
                        }
                        if (tipoDescontoDropdown == '%' && (valor < 0 || valor > 100)) {
                          return 'Percentual deve ser entre 0 e 100';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: tipoDescontoDropdown == 'R\$' ? 'R\$' : '%',
                        border: const OutlineInputBorder(),
                        suffixText: tipoDescontoDropdown == 'R\$' ? 'R\$' : '%',
                        suffixStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card com os cálculos
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: AppSpacing.paddingAllMd,
                child: Column(
                  children: [
                    _buildInfoRow('Valor Total:', _formatCurrency(valorTotalOS)),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Desconto:',
                      '${tipoDescontoDropdown == '%' ? '${valorController.text}%' : _formatCurrency(valorDesconto)}',
                      isDiscount: true,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Valor com Desconto:',
                      _formatCurrency(valorComDesconto),
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Botão de salvar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: salvarDesconto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, size: 22, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "SALVAR DESCONTO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: isDiscount ? Colors.red : (isTotal ? Colors.green : Colors.black87),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}