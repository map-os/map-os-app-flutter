import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:shimmer/shimmer.dart';

class DetalhesTab extends StatefulWidget {
  final Map<String, dynamic>? ordemServico;

  DetalhesTab({this.ordemServico});

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
    NumberFormat format = NumberFormat.decimalPattern();
    num calcTotal = format.parse(calcTotalString);
    _valorController = MoneyMaskedTextController(
      initialValue: calcTotal.toDouble(),
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

  @override
  Widget build(BuildContext context) {
    return widget.ordemServico == null
        ? _buildShimmerEffect()
        : Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ordem de Serviço N° ${widget.ordemServico!['idOs']}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 24.0,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 24.0,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 24.0,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 24.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 24.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 24.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 24.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 24.0,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 24.0,
            color: Colors.white,
          ),
        ],
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
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
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
        style: TextStyle(
          color: Colors.black
        ),
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
          color: Color(0xff36384d)
        ),
        child: TextFormField(
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
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
