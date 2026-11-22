import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/TokenController.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

class DetalhesTab extends StatefulWidget {
  final Map<String, dynamic>? ordemServico;

  const DetalhesTab({Key? key, this.ordemServico}) : super(key: key);

  @override
  _DetalhesTabState createState() => _DetalhesTabState();
}

class _DetalhesTabState extends State<DetalhesTab> {
  late TextEditingController _nomeClienteController;
  late TextEditingController _dataInicialController;
  late TextEditingController _dataFinalController;
  late TextEditingController _descricaoProdutoController;
  late TextEditingController _defeitoController;
  late TextEditingController _laudoTecnicoController;
  late TextEditingController _observacoesController;
  late MoneyMaskedTextController _valorController;

  late String _selectedStatus;
  bool _isLoading = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final List<String> _statusOptions = [
    'Orçamento',
    'Aberto',
    'Em Andamento',
    'Faturado',
    'Negociação',
    'Finalizado',
    'Cancelado',
    'Aguardando Peças',
    'Aprovado'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    _nomeClienteController = TextEditingController(text: widget.ordemServico?['nomeCliente'] ?? '');
    _dataInicialController = TextEditingController(
        text: widget.ordemServico?['dataInicial'] != null
            ? dateFormat.format(DateTime.parse(widget.ordemServico!['dataInicial']))
            : '');
    _dataFinalController = TextEditingController(
        text: widget.ordemServico?['dataFinal'] != null
            ? dateFormat.format(DateTime.parse(widget.ordemServico!['dataFinal']))
            : '');
    _descricaoProdutoController = TextEditingController(text: _removeHtmlTags(widget.ordemServico?['descricaoProduto'] ?? ''));
    _defeitoController = TextEditingController(text: _removeHtmlTags(widget.ordemServico?['defeito'] ?? ''));
    _laudoTecnicoController = TextEditingController(text: _removeHtmlTags(widget.ordemServico?['laudoTecnico'] ?? ''));
    _observacoesController = TextEditingController(text: _removeHtmlTags(widget.ordemServico?['observacoes'] ?? ''));

    String calcTotalString = widget.ordemServico?['calcTotal'].toString().replaceAll(',', '') ?? '0';

    // Tratando possível erro de formatação
    double valorTotal = 0.0;
    try {
      NumberFormat format = NumberFormat.decimalPattern();
      num calcTotal = format.parse(calcTotalString);
      valorTotal = calcTotal.toDouble();
    } catch (e) {
      debugPrint('Erro ao converter valor: $e');
      // Tenta converter diretamente para double como fallback
      valorTotal = double.tryParse(calcTotalString) ?? 0.0;
    }

    _valorController = MoneyMaskedTextController(
      initialValue: valorTotal,
      leftSymbol: 'R\$ ',
      decimalSeparator: ',',
      thousandSeparator: '.',
    );

    _selectedStatus = widget.ordemServico?['status'] ?? _statusOptions.first;
  }

  @override
  void dispose() {
    _nomeClienteController.dispose();
    _dataInicialController.dispose();
    _dataFinalController.dispose();
    _descricaoProdutoController.dispose();
    _defeitoController.dispose();
    _laudoTecnicoController.dispose();
    _observacoesController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  String _removeHtmlTags(String htmlString) {
    final document = html_parser.parse(htmlString);
    return document.body?.text ?? '';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // Usando o contexto atual diretamente
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _salvarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        _showSnackBar('Token de acesso não encontrado.', isError: true);
        return;
      }

      final DateFormat inputFormat = DateFormat('dd/MM/yyyy');
      final idOs = widget.ordemServico?['idOs'];

      if (idOs == null) {
        _showSnackBar('ID da Ordem de Serviço não encontrado.', isError: true);
        return;
      }

      final url = "${APIConfig.baseURL}${APIConfig.osEndpoint}/$idOs";

      final Map<String, dynamic> dados = {
        // campos fixos
        'idOs': idOs,
        'clientes_id': widget.ordemServico?['clientes_id'],
        'usuarios_id': widget.ordemServico?['usuarios_id'],
        'dataInicial': widget.ordemServico?['dataInicial'] != null
            ? DateTime.parse(widget.ordemServico!['dataInicial']).toIso8601String()
            : null,
        'faturado': widget.ordemServico?['faturado'],
        'garantia': widget.ordemServico?['garantia'],
        'ref_os': widget.ordemServico?['ref_os'],
        'valorTotal': widget.ordemServico?['valorTotal'],
        'desconto': widget.ordemServico?['desconto'],
        'subTotal': widget.ordemServico?['subTotal'],
        'status': _selectedStatus,

        // campos que podem ser alterados pelo usuário
        'dataFinal': _dataFinalController.text.isNotEmpty
            ? inputFormat.parse(_dataFinalController.text).toIso8601String()
            : null,
        'descricaoProduto': _descricaoProdutoController.text,
        'defeito': _defeitoController.text,
        'laudoTecnico': _laudoTecnicoController.text,
        'observacoes': _observacoesController.text,
      };

      var response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'App-Version': APIConfig.appVersion,
        },
        body: jsonEncode(dados),
      );

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        token = prefs.getString('access_token');
        response = await http.put(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'App-Version': APIConfig.appVersion,
          },
          body: jsonEncode(dados),
        );
      }

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Text(data['message']),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(data['message']),
        ));
        try {
          final errorResponse = jsonDecode(response.body);
          if (errorResponse['error'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              content: Text(errorResponse['error']),
            ));
          }
        } catch (e) {
          // catch vaizo kkkkkkkkk
        }
        // foda-se
      }
    } catch (e) {
      debugPrint('Erro na requisição: $e');
      _showSnackBar('Erro na requisição: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.ordemServico == null
        ? _buildShimmerEffect()
        : ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Padding(
        padding: AppSpacing.paddingAllMd,
        child: SingleChildScrollView(
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ordem de Serviço N° ${widget.ordemServico!['idOs']}',
                    style: AppTypography.h1Style(AppColors.primary)),
                SizedBox(height: 16),
                _buildNonEditableField('Cliente', _nomeClienteController),
                Row(
                  children: [
                    Expanded(child: _buildNonEditableField('Data inicial', _dataInicialController)),
                    SizedBox(width: 16),
                    Expanded(child: _buildDatePickerField('Data final', _dataFinalController)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Status', _selectedStatus, _statusOptions)),
                    SizedBox(width: 16),
                    Expanded(child: _buildHighlightedNonEditableField('', _valorController)),
                  ],
                ),
                _buildMultilineEditableField('Descrição', _descricaoProdutoController),
                _buildMultilineEditableField('Defeito', _defeitoController),
                _buildMultilineEditableField('Laudo Técnico', _laudoTecnicoController),
                _buildMultilineEditableField('Observações', _observacoesController),
                SizedBox(height: 24),
                Center(
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton.icon(
                    onPressed: _salvarDados,
                    icon: Icon(Icons.save, color: Colors.white),
                    label: Text(
                      "Salvar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      // padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      minimumSize: Size(350, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(8, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              width: double.infinity,
              height: 24.0,
              color: Colors.white,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNonEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.shimmerHighlight,
        ),
      ),
    );
  }

  Widget _buildMultilineEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: null,
        minLines: 3,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String selectedValue, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        style: TextStyle(color: Colors.black),
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedStatus = newValue!;
          });
        },
      ),
    );
  }

  Widget _buildHighlightedNonEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          color: AppColors.primary,
        ),
        child: TextFormField(
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 16,
          ),
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );

          if (pickedDate != null) {
            setState(() {
              controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
            });
          }
        },
      ),
    );
  }
}