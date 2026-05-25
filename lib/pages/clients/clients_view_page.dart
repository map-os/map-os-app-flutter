import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:intl/intl.dart';
import 'package:mapos_app/controllers/clients/clientsController.dart';
import 'package:mapos_app/pages/clients/clients_edit_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mapos_app/pages/clients/clients_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapos_app/pages/os/os_view_page.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

class VisualizarClientesPage extends StatefulWidget {
  final int idClientes;

  VisualizarClientesPage({required this.idClientes});

  @override
  _VisualizarClientesPageState createState() => _VisualizarClientesPageState();
}

class _VisualizarClientesPageState extends State<VisualizarClientesPage> {
  late Future<Map<String, dynamic>> futureclient;

  @override
  void initState() {
    super.initState();
    futureclient = ControllerClients().getClientById(widget.idClientes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualizar Cliente'),
        backgroundColor: AppColors.appBarView,
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: futureclient,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  snapshot.data!['celular'] != null) {
                return IconButton(
                  icon: Icon(Boxicons.bxl_whatsapp),
                  onPressed: () async {
                    String celular = snapshot.data!['celular'];
                    String cleanedCelular = celular.replaceAll(RegExp(r'[^\d+]'), ''); // Remove tudo que não é número
                    final Uri whatsappUrl = Uri.parse(
                      'https://wa.me/+55$cleanedCelular',
                    );
                    await _launchInBrowser(whatsappUrl);
                  },
                );

              } else {
                return Container();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureclient,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}', style: TextStyle(color: Colors.red, fontSize: 18)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum detalhe do cliente encontrado', style: TextStyle(fontSize: 18)));
          } else {
            final client = snapshot.data!;
            final ordensServicos = client['ordensServicos'];
            return SingleChildScrollView(
              padding: AppSpacing.paddingAllMd,
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: AppSpacing.paddingAllLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.build, color: AppColors.primary, size: 28),
                              SizedBox(width: 10),
                              Text(
                                'Detalhes do cliente #${client['idClientes']}',
                                style: AppTypography.h1Style(AppColors.primary),
                              ),
                            ],
                          ),
                          Divider(height: 30, color: AppColors.primary),
                          _buildDetailRow('Nome:', client['nomeCliente']),
                          SizedBox(height: 10),
                          _buildDetailRow('CPF/CNPJ:', client['documento']),
                          SizedBox(height: 10),
                          _buildDetailRow('Tipo:', client['fornecedor'] == '1' ? 'Fornecedor' : 'Cliente'),
                          SizedBox(height: 10),
                          _buildDetailRow('Data do Cadastro:', DateFormat('dd/MM/yyyy').format(DateTime.parse(client['dataCadastro']))),
                          SizedBox(height: 10),
                          Divider(height: 30, color: AppColors.divider),
                          Row(
                            children: [
                              Icon(Icons.contact_mail, color: AppColors.primary, size: 28),
                              SizedBox(width: 10),
                              Text(
                                'Contatos',
                                style: AppTypography.h1Style(AppColors.primary),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          _buildDetailRow('Telefone:', client['telefone'] == '' ? 'Não informado' : client['telefone']),
                          SizedBox(height: 10),
                          _buildDetailRow('Celular:', client['celular'] == '' ? 'Não informado' : client['celular']),
                          SizedBox(height: 10),
                          _buildDetailRow('Email:', client['email']),
                          SizedBox(height: 10),
                          Divider(height: 30, color: AppColors.divider),
                          Row(
                            children: [
                              Icon(Icons.map, color: AppColors.primary, size: 28),
                              SizedBox(width: 10),
                              Text(
                                'Endereço',
                                style: AppTypography.h1Style(AppColors.primary),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          _buildDetailRow('CEP:', client['cep'] == '' ? 'Não informado' : client['cep']),
                          SizedBox(height: 10),
                          _buildDetailRow('Bairro:', client['bairro'] == '' ? 'Não informado' : client['bairro']),
                          SizedBox(height: 10),
                          _buildDetailRow('Rua:', '${client['rua']} N° ${client['numero']}'),
                          SizedBox(height: 10),
                          _buildDetailRow('Cidade/Estado:', '${client['cidade']} / ${client['estado']}'),
                          SizedBox(height: 30),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  final clientData = snapshot.data!;
                                  if (clientData['idClientes'] != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditarClientePage(cliente: clientData),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('ID do cliente está nulo. Não é possível editar.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(Icons.edit, color: Colors.white),
                                label: Text('Editar'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: AppColors.accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                                  backgroundColor: Colors.red,
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

                  SingleChildScrollView(
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
                                Icon(Icons.receipt_rounded, color: AppColors.primary, size: 28),
                                SizedBox(width: 10),
                                Text(
                                  'Ordens de Serviço',
                                  style: AppTypography.h1Style(AppColors.primary),
                                ),
                              ],
                            ),
                            const Divider(height: 30, color: AppColors.primary),
                            for (var ordem in ordensServicos)
                              ListTile(
                                title: Text(
                                  'OS N°: ${ordem['idOs']}',
                                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                                ),
                                subtitle: Text(
                                  'Status: ${ordem['status']}',
                                  style: TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.visibility, color: AppColors.primary),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VisualizarOrdemServicoPage(idOrdemServico: int.parse(ordem['idOs'])),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Não foi possível abrir a URL: $url');
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingAllMd,
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: AppSpacing.paddingAllLg,
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
                    Divider(height: 30, color: AppColors.primary),
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
          height: 100,
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
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
              Text('Tem certeza de que deseja excluir este cliente?'),
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
                  _deleteclient();
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

  void _deleteclient() async {
    try {
      bool success = await ControllerClients().deleteClient(widget.idClientes);
      print(success);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Text('Cliente  exluido com Sucesso'),
        ));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClientsList(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text('Ops... erro ao excluir cliente!'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        content: Text('Erro no servidor ...'),
      ));
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