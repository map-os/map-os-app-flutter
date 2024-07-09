import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:mapos_app/controllers/services/servicesController.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mapos_app/pages/services/services_view_page.dart';

class EditarServicosPage extends StatefulWidget {
  final int idServicos;

  EditarServicosPage({required this.idServicos});

  @override
  _EditarServicosPageState createState() => _EditarServicosPageState();
}

class _EditarServicosPageState extends State<EditarServicosPage> {
  late Future<Map<String, dynamic>> futureService;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late MoneyMaskedTextController _precoController;

  @override
  void initState() {
    super.initState();
    futureService = ControllerServices().getServiceById(widget.idServicos);
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
        title: Text('Editar Serviço'),
        backgroundColor: Color(0xfffaf3fb),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureService,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}', style: TextStyle(color: Colors.red, fontSize: 18)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum detalhe do serviço encontrado', style: TextStyle(fontSize: 18)));
          } else {
            final service = snapshot.data!;
            _nomeController.text = service['nome'];
            _descricaoController.text = service['descricao'];
            _precoController.text = service['preco'].toString().replaceAll('.', ',');

            return SingleChildScrollView(
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
                            Icon(Icons.edit, color: Color(0xff333649), size: 28),
                            SizedBox(width: 10),
                            Text(
                                'Editando o Serviço #${widget.idServicos}',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff333649)),
                            ),
                          ],
                        ),
                        Divider(height: 30, color: Color(0xff333649)),
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
                                  _saveService();
                                }
                              },
                              icon: Icon(Icons.save, color: Colors.white),
                              label: Text('Salvar'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xff333649), // Cor do texto
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
            );
          }
        },
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

  void _saveService() async {
    try {
      // Removendo a máscara para obter apenas o valor numérico.
      String precoText = _precoController.text.replaceAll(RegExp(r'[R$\s\.]'), '').replaceAll(',', '.');
      double preco = double.parse(precoText);

      bool success = await ControllerServices().updateService(
        widget.idServicos,
        _nomeController.text,
        _descricaoController.text,
        preco,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: Colors.green,
                content: Text('Serviço atualizado com sucesso!')
            )
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VisualizarServicosPage(idServicos: widget.idServicos),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao atualizar o serviço')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: 200,
                          height: 24,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Divider(height: 30, color: Color(0xff333649)),
                    _buildShimmerRow(),
                    SizedBox(height: 10),
                    _buildShimmerRow(),
                    SizedBox(height: 10),
                    _buildShimmerRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 16,
          color: Colors.white,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
