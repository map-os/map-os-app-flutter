import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:intl/intl.dart';
import 'package:mapos_app/controllers/chamados/chamadosController.dart';
import 'package:mapos_app/pages/chamados/chamados_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';
import 'package:mapos_app/theme/app_status_colors.dart';

class VisualizarChamadoPage extends StatefulWidget {
  final int idChamado;

  VisualizarChamadoPage({required this.idChamado});

  @override
  _VisualizarChamadoPageState createState() => _VisualizarChamadoPageState();
}

class _VisualizarChamadoPageState extends State<VisualizarChamadoPage> {
  late Future<Map<String, dynamic>> futureChamado;

  @override
  void initState() {
    super.initState();
    futureChamado = ControllerChamados().getChamadoById(widget.idChamado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chamado #${widget.idChamado}'),
        backgroundColor: AppColors.appBarView,
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: futureChamado,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  snapshot.data!['celular_cliente'] != null) {
                return IconButton(
                  icon: Icon(Boxicons.bxl_whatsapp),
                  onPressed: () async {
                    String celular = snapshot.data!['celular_cliente'];
                    String cleanedCelular = celular.replaceAll(RegExp(r'[^\d+]'), '');
                    final Uri whatsappUrl = Uri.parse('https://wa.me/+55$cleanedCelular');
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
        future: futureChamado,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erro: ${snapshot.error}', style: TextStyle(color: Colors.red, fontSize: 18)),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum detalhe do chamado encontrado', style: TextStyle(fontSize: 18)));
          } else {
            final chamado = snapshot.data!;
            return SingleChildScrollView(
              padding: AppSpacing.paddingAllMd,
              child: Column(
                children: [
                  _buildChamadoDetailsCard(chamado),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildChamadoDetailsCard(Map<String, dynamic> chamado) {
    final String status = chamado['status'] ?? '';
    final Color statusColor = AppStatusColors.getStatusColor(status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: AppSpacing.paddingAllLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.headset_mic, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Text(
                  'Chamado #${chamado['idOs']}',
                  style: AppTypography.h1Style(AppColors.primary),
                ),
              ],
            ),
            Divider(height: 30, color: AppColors.primary),

            // Status badge
            Row(
              children: [
                Text('Status: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            _buildDetailRow('Cliente:', chamado['nomeCliente'] ?? 'N/A'),
            SizedBox(height: 10),
            _buildDetailRow('Tecnico:', chamado['nomeUsuario'] ?? chamado['usuarios_id']?.toString() ?? 'N/A'),
            SizedBox(height: 10),
            _buildDetailRow('Data Inicial:', _formatDate(chamado['dataInicial'])),
            SizedBox(height: 10),
            _buildDetailRow('Data Final:', _formatDate(chamado['dataFinal'])),
            SizedBox(height: 10),

            Divider(height: 30, color: AppColors.divider),

            Row(
              children: [
                Icon(Icons.description, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Text(
                  'Detalhes',
                  style: AppTypography.h1Style(AppColors.primary),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildDetailRow('Descricao:', chamado['descricaoProduto'] ?? 'Nao informado'),
            SizedBox(height: 10),
            _buildDetailRow('Defeito:', chamado['defeito'] ?? 'Nao informado'),
            SizedBox(height: 10),
            _buildDetailRow('Observacoes:', chamado['observacoes'] ?? 'Nao informado'),
            SizedBox(height: 10),
            _buildDetailRow('Laudo Tecnico:', chamado['laudoTecnico'] ?? 'Nao informado'),
            SizedBox(height: 10),

            if (chamado['valorTotal'] != null) ...[
              Divider(height: 30, color: AppColors.divider),
              _buildDetailRow('Valor Total:', 'R\$ ${chamado['valorTotal']}'),
              SizedBox(height: 10),
            ],

            if (chamado['garantia'] != null && chamado['garantia'].toString().isNotEmpty) ...[
              _buildDetailRow('Garantia:', '${chamado['garantia']} dias'),
              SizedBox(height: 10),
            ],

            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(behavior: SnackBarBehavior.floating, content: Text('Edicao de chamado em desenvolvimento')),
                    );
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
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return 'Nao informado';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr.toString();
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
                        Container(width: 28, height: 28, color: Colors.white),
                        SizedBox(width: 10),
                        Container(width: 200, height: 24, color: Colors.white),
                      ],
                    ),
                    SizedBox(height: 30),
                    Divider(height: 30, color: AppColors.primary),
                    _buildShimmerRow(),
                    SizedBox(height: 10),
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
        Container(width: 80, height: 20, color: Colors.white),
        SizedBox(width: 10),
        Expanded(child: Container(height: 16, color: Colors.white)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Confirmar Exclusao', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tem certeza de que deseja excluir este chamado?'),
              SizedBox(height: 20),
              Text('Responda a seguinte conta para confirmar:'),
              SizedBox(height: 10),
              Text(
                mathQuestion['question'],
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: answerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Resposta',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
              onPressed: () {
                if (int.tryParse(answerController.text) == mathQuestion['answer']) {
                  Navigator.of(context).pop();
                  _deleteChamado();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(behavior: SnackBarBehavior.floating, backgroundColor: Colors.red, content: Text('Resposta incorreta.')),
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

  void _deleteChamado() async {
    try {
      bool success = await ControllerChamados().deleteChamado(widget.idChamado);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            content: Text('Chamado excluido com Sucesso'),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChamadosList()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Text('Erro ao excluir chamado!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text('Erro no servidor ...'),
        ),
      );
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

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Nao foi possivel abrir a URL: $url');
    }
  }
}