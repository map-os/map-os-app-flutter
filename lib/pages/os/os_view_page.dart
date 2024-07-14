import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:intl/intl.dart';
import 'package:mapos_app/controllers/os/osController.dart';
import 'package:mapos_app/pages/os/os_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapos_app/helpers/format.dart';
import 'package:mapos_app/pages/os/os_edit_page.dart';

class VisualizarOrdemServicoPage extends StatefulWidget {
  final int idOrdemServico;

  VisualizarOrdemServicoPage({required this.idOrdemServico});

  @override
  _VisualizarOrdemServicoPageState createState() =>
      _VisualizarOrdemServicoPageState();
}

class _VisualizarOrdemServicoPageState
    extends State<VisualizarOrdemServicoPage> {
  late Future<Map<String, dynamic>> futureOrder;

  @override
  void initState() {
    super.initState();
    futureOrder = ControllerOs().getOrdemServicotById(widget.idOrdemServico);
  }

  String removeHtmlTags(String htmlString) {
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
        title: Text('Visualizar Ordem de Serviço'),
        backgroundColor: Color(0xfffcf5fd),
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: futureOrder,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  snapshot.data!['contato'] != null) {
                final contato = snapshot.data!['contato'];
                return IconButton(
                  icon: Icon(
                    Boxicons.bxl_whatsapp,
                    color: Colors.green,
                  ),
                  onPressed: () async {
                    String celular = snapshot.data!['celular'];
                    String cleanedCelular =
                        celular.replaceAll(RegExp(r'[^\d+]'), '');
                    final Uri whatsappUrl = Uri.parse(
                      'https://api.whatsapp.com/send?phone=+55$cleanedCelular&text=${snapshot.data!['textoWhatsApp']}',
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
        future: futureOrder,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Erro: ${snapshot.error}',
                    style: TextStyle(color: Colors.red, fontSize: 18)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('Nenhum detalhe da ordem de serviço encontrado',
                    style: TextStyle(fontSize: 18)));
          } else {
            final order = snapshot.data!;
            String calcTotalString = order['calcTotal'].toString();
            calcTotalString = calcTotalString.replaceAll(',', '');
            NumberFormat format = NumberFormat.decimalPattern();
            num calcTotal = format.parse(calcTotalString);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 8.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.build,
                                  color: Color(0xff333649), size: 28),
                              SizedBox(width: 10),
                              Text(
                                'Detalhes da OS #${order['idOs']}',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff333649)
                                    ),
                              ),
                            ],
                          ),
                          Divider(height: 30, color: Color(0xff333649)),
                          _buildDetailRow('Cliente:', order['nomeCliente']),
                          SizedBox(height: 5),
                          _buildDetailRow(
                              'Entrada:',
                              DateFormat('dd/MM/yyyy').format(
                                  DateTime.parse(order['dataInicial']))),
                          SizedBox(height: 5),
                          _buildDetailRow(
                            
                              'Prev. Saída:',
                              DateFormat('dd/MM/yyyy')
                                  .format(DateTime.parse(order['dataFinal']))),
                          SizedBox(height: 5),
                          _buildDetailRow('Status:', order['status']),
                          SizedBox(height: 5),
                          _buildDetailRow('Responsavel:', order['nome']),
                           SizedBox(height: 5),
                          _buildDetailRow('Desconto : -',Format.formatCurrency.format(double.parse(order['desconto'].toString()))),
                          SizedBox(height: 5),
                          _buildDetailRow('Valor da ordem:',  Format.formatCurrency.format(calcTotal)),
                          SizedBox(height: 30),
                          const Row(
                            children: [
                              Icon(Icons.receipt_long,
                                  color: Color(0xff333649), size: 28),
                              SizedBox(width: 10),
                              Text(
                                'Dados Tecnicos',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff333649)),
                              ),
                            ],
                          ),
                          Divider(height: 30, color: Color(0xff333649)),
                          _buildDetailRow(
                              'Descrição',
                              removeHtmlTags(order['descricaoProduto'].isEmpty
                                  ? 'Não informado'
                                  : removeHtmlTags(order['descricaoProduto']))),
                          SizedBox(height: 5),
                          _buildDetailRow(
                              'Defeito',
                              removeHtmlTags(order['defeito'].isEmpty
                                  ? 'Não informado'
                                  : removeHtmlTags(order['defeito']))),
                          SizedBox(height: 5),
                          _buildDetailRow(
                              'Laudo Técnico',
                              order['laudoTecnico'].isEmpty
                                  ? 'Não informado'
                                  : removeHtmlTags(order['laudoTecnico'])),
                          SizedBox(height: 5),
                          _buildDetailRow('Observações',
                              removeHtmlTags(order['observacoes'])),
                          SizedBox(height: 30),
                          _buildProdutosList(order['produtos']),
                          SizedBox(height: 30),
                          _buildServicosList(order['servicos']),
                          SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditarOsPage(idOs: int.parse(order['idOs'])),
                                      ),
                                    );
                                },
                                icon:
                                    const Icon(Icons.edit, color: Colors.white),
                                label: const Text('Editar'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xffff7e15),
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
                                icon: Icon(Icons.delete, color: Colors.white),
                                label: Text('Excluir'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.red,
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
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 8.0,
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
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff333649)),
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

  Widget _buildProdutosList(List<dynamic>? produtos) {
    if (produtos == null || produtos.isEmpty) return Container();

    double total = produtos.fold(
      0,
      (sum, produto) =>
          sum +
          (double.parse(produto['preco']) * int.parse(produto['quantidade'])),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // alinha os elementos ao redor
          children: [
            const Row(
              children: [
                Icon(Icons.shopping_basket, color: Color(0xff333649), size: 28),
                SizedBox(width: 10),
                Text(
                  'Produtos',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff333649)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Format.formatCurrency.format(total),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        Divider(height: 30, color: Color(0xff333649)),
        // Listagem de cards de produtos
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: produtos.map((produto) {
            return _buildProdutoCard(
              quantidade: int.parse(produto['quantidade']),
              descricao: produto['descricao'],
              preco: double.parse(produto['preco']),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProdutoCard(
      {required int quantidade,
      required String descricao,
      required double preco}) {
    return Container(
      width: double.infinity,
      height: 100, // altura desejada
      child: Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$quantidade x $descricao',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'R\$ $preco cada',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicosList(List<dynamic>? servicos) {
    if (servicos == null || servicos.isEmpty) {
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.miscellaneous_services,
                    color: Color(0xff333649), size: 28),
                SizedBox(width: 10),
                Text(
                  'Serviços',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff333649)),
                ),
              ],
            ),
            Divider(height: 30, color: Color(0xff333649)),
            Text(
              'Nenhum serviço executado.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    double total = 0;

    total = servicos.fold(0, (sum, servico) {
      if (servico['preco'] != null) {
        return sum + double.parse(servico['preco']);
      }
      return sum;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.build, color: Color(0xff333649), size: 28),
            SizedBox(width: 10),
            Text(
              'Serviços',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff333649)),
            ),
            Spacer(),
            Text(
              Format.formatCurrency.format(total),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Divider(height: 30, color: Color(0xff333649)),
        // Listagem de cards de serviços
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: servicos.map((servico) {
            return _buildServicoCard(
              quantidade: servico['quantidade'] ?? 1,
              nome: servico['nome'] ?? 'Nome não disponível',
              preco: double.tryParse(servico['preco'] ?? '0') ?? 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildServicoCard(
      {required String nome, required double preco, required quantidade}) {
    return Container(
      width: double.infinity,
      height: 100,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'R\$ $preco',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
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
              Text(
                  'Tem certeza de que deseja excluir esta ordem de serviço? Essa ação é irreversivel 😢'),
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
                  border: OutlineInputBorder(),
                  labelText: 'Resposta',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final answer = int.tryParse(answerController.text);
                if (answer == mathQuestion['answer']) {
                  _deleteOrder();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Resposta incorreta! Por favor, tente novamente.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Confirmar'),
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
      'question': '$num1 + $num2',
      'answer': num1 + num2,
    };
  }

  Future<void> _deleteOrder() async {
    try {
      await ControllerOs().deleteOrdemServico(widget.idOrdemServico);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ordem de serviço excluída com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => OrdemServicoList()),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir ordem de serviço: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
