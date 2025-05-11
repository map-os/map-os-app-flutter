import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' as intlBR;
import 'package:mapos_app/controllers/os/osController.dart';
import 'package:mapos_app/pages/os/os_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapos_app/helpers/format.dart';
import 'package:mapos_app/pages/os/os_edit_page.dart';
import 'package:mapos_app/pages/os/os_page.dart';


class VisualizarOrdemServicoPage extends StatefulWidget {
  final int idOrdemServico;

  const VisualizarOrdemServicoPage({Key? key, required this.idOrdemServico}) : super(key: key);

  @override
  _VisualizarOrdemServicoPageState createState() =>
      _VisualizarOrdemServicoPageState();
}

class _VisualizarOrdemServicoPageState
    extends State<VisualizarOrdemServicoPage> {
  late Future<Map<String, dynamic>> futureOrder;
  final Color primaryColor = const Color(0xff333649);
  final Color accentColor = const Color(0xffff7e15);

  @override
  void initState() {
    super.initState();
    futureOrder = ControllerOs().getOrdemServicotById(widget.idOrdemServico);
  }

  String removeHtmlTags(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) {
      return '';
    }

    String withoutHtml = '';
    bool insideTag = false;

    for (int i = 0; i < htmlString.length; i++) {
      if (htmlString[i] == '<') {
        insideTag = true;
      } else if (htmlString[i] == '>') {
        insideTag = false;
      } else if (!insideTag) {
        withoutHtml += htmlString[i];
      }
    }

    return withoutHtml.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualizar Ordem de Serviço'),
        backgroundColor: const Color(0xfffcf5fd),
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: futureOrder,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  snapshot.data!['contato'] != null) {
                return IconButton(
                  icon: const Icon(
                    Boxicons.bxl_whatsapp,
                    color: Colors.green,
                  ),
                  onPressed: () async {
                    String celular = snapshot.data!['celular'] ?? '';
                    String cleanedCelular =
                    celular.replaceAll(RegExp(r'[^\d+]'), '');
                    if (cleanedCelular.isNotEmpty) {
                      final Uri whatsappUrl = Uri.parse(
                        'https://api.whatsapp.com/send?phone=+55$cleanedCelular&text=${Uri.encodeComponent(snapshot.data!['textoWhatsApp'] ?? '')}',
                      );
                      await _launchInBrowser(whatsappUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Número de celular não disponível'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
        future: futureOrder,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 18)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Nenhum detalhe da ordem de serviço encontrado',
                    style: TextStyle(fontSize: 18)));
          } else {
            final order = snapshot.data!;
            // Tratamento seguro do valor total
            num calcTotal = 0;
            try {
              String calcTotalString = order['calcTotal']?.toString() ?? '0';
              calcTotalString = calcTotalString.replaceAll(',', '');
              intlBR.NumberFormat format = intlBR.NumberFormat.decimalPattern();
              calcTotal = format.parse(calcTotalString);
            } catch (e) {
              calcTotal = 0;
              debugPrint('Erro ao converter valor total: $e');
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildMainInfoCard(order, calcTotal),
                  const SizedBox(height: 16),
                  if (order['produtos'] != null && (order['produtos'] as List).isNotEmpty)
                    _buildProductsCard(order['produtos']),
                  const SizedBox(height: 16),
                  _buildServicesCard(order['servicos']),
                  const SizedBox(height: 20),
                  _buildActionButtons(order, context),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildMainInfoCard(Map<String, dynamic> order, num calcTotal) {
    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: primaryColor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Detalhes da OS #${order['idOs']}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            Divider(height: 30, color: primaryColor),

            // Informações do cliente
            _buildSectionTitle('Informações Gerais', Icons.person),
            const SizedBox(height: 10),
            _buildDetailRow('Cliente:', order['nomeCliente'] ?? 'Não informado'),
            const SizedBox(height: 5),
            _buildDetailRow(
                'Entrada:',
                order['dataInicial'] != null
                    ? intlBR.DateFormat('dd/MM/yyyy').format(DateTime.parse(order['dataInicial']))
                    : 'Não informado'
            ),
            const SizedBox(height: 5),
            _buildDetailRow(
                'Prev. Saída:',
                order['dataFinal'] != null
                    ? intlBR.DateFormat('dd/MM/yyyy').format(DateTime.parse(order['dataFinal']))
                    : 'Não informado'
            ),
            const SizedBox(height: 5),
            _buildDetailRow('Status:', order['status'] ?? 'Não informado'),
            const SizedBox(height: 5),
            _buildDetailRow('Responsável:', order['nome'] ?? 'Não informado'),
            const SizedBox(height: 5),
            _buildDetailRow('Desconto: -',
                Format.formatCurrency.format(double.tryParse(order['desconto']?.toString() ?? '0') ?? 0)
            ),
            const SizedBox(height: 5),
            _buildDetailRow('Valor da ordem:', Format.formatCurrency.format(calcTotal)),

            const SizedBox(height: 30),

            // Dados Técnicos
            _buildSectionTitle('Dados Técnicos', Icons.receipt_long),
            const SizedBox(height: 10),
            _buildExpandableDetailRow(
                'Descrição:',
                removeHtmlTags(order['descricaoProduto'])
            ),
            const SizedBox(height: 10),
            _buildExpandableDetailRow(
                'Defeito:',
                removeHtmlTags(order['defeito'])
            ),
            const SizedBox(height: 10),
            _buildExpandableDetailRow(
                'Laudo Técnico:',
                removeHtmlTags(order['laudoTecnico'])
            ),
            const SizedBox(height: 10),
            _buildExpandableDetailRow(
                'Observações:',
                removeHtmlTags(order['observacoes'])
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Color(0xff555555)),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableDetailRow(String label, String value) {
    final isEmpty = value.isEmpty || value == 'Não informado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 5),
        isEmpty
            ? const Text(
          'Não informado',
          style: TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
        )
            : ExpandableText(
          value,
          style: const TextStyle(fontSize: 16, color: Color(0xff555555)),
        ),
        const Divider(height: 20),
      ],
    );
  }

  Widget _buildProductsCard(List<dynamic> produtos) {
    double total = produtos.fold(
      0,
          (sum, produto) {
        final price = double.tryParse(produto['preco']?.toString() ?? '0') ?? 0;
        final quantity = int.tryParse(produto['quantidade']?.toString() ?? '1') ?? 1;
        return sum + (price * quantity);
      },
    );

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_basket, color: primaryColor, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      'Produtos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff333649),
                      ),
                    ),
                  ],
                ),
                Text(
                  Format.formatCurrency.format(total),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 30, color: primaryColor),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: produtos.length,
              itemBuilder: (context, index) {
                final produto = produtos[index];
                return _buildProdutoCard(
                  quantidade: int.tryParse(produto['quantidade']?.toString() ?? '1') ?? 1,
                  descricao: produto['descricao'] ?? 'Produto sem descrição',
                  preco: double.tryParse(produto['preco']?.toString() ?? '0') ?? 0,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesCard(List<dynamic>? servicos) {
    if (servicos == null || servicos.isEmpty) {
      return Card(
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.miscellaneous_services, color: primaryColor, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'Serviços',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff333649),
                    ),
                  ),
                ],
              ),
              Divider(height: 30, color: primaryColor),
              const Text(
                'Nenhum serviço executado.',
                style: TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }

    double total = servicos.fold(0, (sum, servico) {
      final price = double.tryParse(servico['preco']?.toString() ?? '0') ?? 0;
      return sum + price;
    });

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.build, color: primaryColor, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      'Serviços',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff333649),
                      ),
                    ),
                  ],
                ),
                Text(
                  Format.formatCurrency.format(total),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 30, color: primaryColor),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: servicos.length,
              itemBuilder: (context, index) {
                final servico = servicos[index];
                return _buildServicoCard(
                  nome: servico['nome'] ?? 'Serviço sem nome',
                  preco: double.tryParse(servico['preco']?.toString() ?? '0') ?? 0,
                  quantidade: servico['quantidade'] ?? 1,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutoCard({
    required int quantidade,
    required String descricao,
    required double preco,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$quantidade x',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    descricao,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preço unitário: ${Format.formatCurrency.format(preco)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  'Total: ${Format.formatCurrency.format(preco * quantidade)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicoCard({
    required String nome,
    required double preco,
    required dynamic quantidade,
  }) {
    int qtd = 1;
    if (quantidade != null) {
      if (quantidade is int) {
        qtd = quantidade;
      } else if (quantidade is String) {
        qtd = int.tryParse(quantidade) ?? 1;
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (qtd > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$qtd x',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (qtd > 1) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preço unitário: ${Format.formatCurrency.format(preco)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (qtd > 1)
                  Text(
                    'Total: ${Format.formatCurrency.format(preco * qtd)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditarOsPage(
                  idOs: int.tryParse(order['idOs']?.toString() ?? '0') ?? 0,
                ),
              ),
            );
          },
          icon: const Icon(Icons.edit, color: Colors.white),
          label: const Text('Editar'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {
            _confirmDelete(context);
          },
          icon: const Icon(Icons.delete, color: Colors.white),
          label: const Text('Excluir'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
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
              elevation: 1.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0)),
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
                        const SizedBox(width: 10),
                        Container(
                          width: 200,
                          height: 24,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Divider(height: 30, color: primaryColor),
                    _buildShimmerRow(),
                    const SizedBox(height: 10),
                    _buildShimmerRow(),
                    const SizedBox(height: 10),
                    _buildShimmerRow(),
                    const SizedBox(height: 30),
                    _buildShimmerRow(),
                    const SizedBox(height: 10),
                    _buildShimmerRow(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0)),
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
                        const SizedBox(width: 10),
                        Container(
                          width: 150,
                          height: 24,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    _buildShimmerCard(),
                    _buildShimmerCard(),
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
          width: 100,
          height: 16,
          color: Colors.white,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Future<void> _launchInBrowser(Uri url) async {
    try {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Não foi possível abrir a URL: $url');
      }
    } catch (e) {
      debugPrint('Erro ao abrir URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    final mathQuestion = generateMathQuestion();
    final TextEditingController answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Confirmar Exclusão',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Tem certeza de que deseja excluir esta ordem de serviço? Essa ação é irreversível 😢'),
              const SizedBox(height: 20),
              const Text('Responda a seguinte conta para confirmar:'),
              const SizedBox(height: 10),
              Text(
                mathQuestion['question']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: answerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Resposta',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final answer = int.tryParse(answerController.text);
                if (answer == mathQuestion['answer']) {
                  _deleteOrder();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Resposta incorreta! Por favor, tente novamente.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> generateMathQuestion() {
    final rand = Random();
    int num1 = rand.nextInt(10) + 1;
    int num2 = rand.nextInt(10) + 1;
    return {
      'question': '$num1 + $num2 = ?',
      'answer': num1 + num2,
    };
  }

  Future<void> _deleteOrder() async {
    try {
      await ControllerOs().deleteOrdemServico(widget.idOrdemServico);
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Ordem de Serviço exluida com Sucesso',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,

        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OrdemServicoList()),
        );
      }
    } catch (error) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Erro ao exluir Ordem de serviço',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,

        );
      }
    }
  }
}

// Widget para texto expansível que lida com textos longos
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int maxLines;

  const ExpandableText(
      this.text, {
        Key? key,
        required this.style,
        this.maxLines = 3,
      }) : super(key: key);

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textSpan = TextSpan(text: widget.text, style: widget.style);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Garantindo que textDirection seja sempre um valor válido
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr, // Corrected: use 'ltr' instead of 'LTR'
          maxLines: widget.maxLines,
        );

        textPainter.layout(maxWidth: constraints.maxWidth);

        final isTextOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (isTextOverflowing)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _expanded ? "Mostrar menos" : "Mostrar mais",
                    style: TextStyle(
                      color: const Color(0xffff7e15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}