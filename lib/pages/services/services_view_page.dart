import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mapos_app/controllers/services/servicesController.dart';
import 'package:mapos_app/pages/services/services_edit_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mapos_app/pages/services/services_page.dart';

class VisualizarServicosPage extends StatefulWidget {
  final int idServicos;

  VisualizarServicosPage({required this.idServicos});

  @override
  _VisualizarServicosPageState createState() => _VisualizarServicosPageState();
}

class _VisualizarServicosPageState extends State<VisualizarServicosPage> {
  late Future<Map<String, dynamic>> futureService;

  @override
  void initState() {
    super.initState();
    futureService = ControllerServices().getServiceById(widget.idServicos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualizar Serviço'),
        backgroundColor: Color(0xfffcf5fd),
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                          Icon(Icons.build, color: Color(0xff333649), size: 28),
                          SizedBox(width: 10),
                          Text(
                            'Detalhes do Serviço #${service['idServicos']}',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff333649)),
                          ),
                        ],
                      ),
                      Divider(height: 30, color: Color(0xff333649)),
                      _buildDetailRow('Nome:', service['nome']),
                      SizedBox(height: 10),
                      _buildDetailRow('Descrição:', service['descricao']),
                      SizedBox(height: 10),
                      _buildDetailRow('Preço:', 'R\$ ${service['preco']}'),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditarServicosPage(idServicos: widget.idServicos),
                                ),
                              );
                            },
                            icon: Icon(Icons.edit, color: Colors.white),
                            label: Text('Editar'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Color(0xffff7e15), // Cor do texto
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              _confirmDelete(context);
                            },
                            icon: Icon(Icons.delete, color: Colors.white),
                            label: Text('Excluir'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red, // Cor do texto
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
            );
          }
        },
      ),
    );
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff333649)),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16, color: Color(0xff555555)),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    final mathQuestion = generateMathQuestion();
    TextEditingController answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            'Confirmar Exclusão',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tem certeza de que deseja excluir este serviço?'),
              SizedBox(height: 20),
              Text('Responda a seguinte conta para confirmar:'),
              SizedBox(height: 10),
              Text(
                mathQuestion['question'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: answerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Resposta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () {
                if (int.tryParse(answerController.text) == mathQuestion['answer']) {
                  Navigator.of(context).pop();
                  _deleteService();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Resposta incorreta.')),
                  );
                }
              },
              child: Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteService() async {
    try {
      bool success = await ControllerServices().deleteService(widget.idServicos);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Serviço excluído com sucesso!')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ServicesList(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao excluir o serviço')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Map<String, dynamic> generateMathQuestion() {
    Random random = Random();
    int a = random.nextInt(10);
    int b = random.nextInt(10);
    String question = '$a + $b';
    int answer = a + b;
    return {'question': question, 'answer': answer};
  }
}
