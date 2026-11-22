import 'dart:js_interop';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:intl/intl.dart' as intlBR;
import 'package:mapos_app/controllers/os/osController.dart';
import 'package:mapos_app/pages/os/os_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapos_app/helpers/format.dart';
import 'package:mapos_app/pages/os/os_edit_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';


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
        backgroundColor: AppColors.appBarView,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: futureOrder,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final order = snapshot.data!;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.print, color: AppColors.primary),
                    tooltip: 'Imprimir',
                    onPressed: () => _printOs(order),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: AppColors.primary),
                    tooltip: 'Compartilhar',
                    onPressed: () => _shareOs(order),
                  ),
                  if (order['contato'] != null)
                    IconButton(
                      icon: const Icon(Boxicons.bxl_whatsapp, color: Colors.green),
                      tooltip: 'WhatsApp',
                      onPressed: () async {
                        String celular = order['celular'] ?? '';
                        String cleanedCelular = celular.replaceAll(RegExp(r'[^\d+]'), '');
                        if (cleanedCelular.isNotEmpty) {
                          final Uri whatsappUrl = Uri.parse(
                            'https://api.whatsapp.com/send?phone=+55$cleanedCelular&text=${Uri.encodeComponent(order['textoWhatsApp'] ?? '')}',
                          );
                          await _launchInBrowser(whatsappUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Numero de celular nao disponivel'), backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                ],
              );
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Ordem de serviço não encontrada',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Não conseguimos encontrar a ordem que você pesquisou, revise o Nº da OS e tente novamente',
                    style: const TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );

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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Detalhes da OS #${order['idOs']}',
                    style: AppTypography.h1Style(AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            Divider(height: 30, color: AppColors.primary),

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
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
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
            style: AppTypography.bodyBold(AppColors.primary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyStyle(AppColors.textMuted),
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
          style: AppTypography.bodyBold(AppColors.primary),
        ),
        const SizedBox(height: 5),
        isEmpty
            ? const Text(
          'Não informado',
          style: TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
        )
            : ExpandableText(
          value,
          style: AppTypography.bodyStyle(AppColors.textMuted),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                    Icon(Icons.shopping_basket, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Produtos',
                      style: AppTypography.h1Style(AppColors.primary),
                    ),
                  ],
                ),
                Text(
                  Format.formatCurrency.format(total),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 30, color: AppColors.primary),
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
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.miscellaneous_services, color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Serviços',
                    style: AppTypography.h1Style(AppColors.primary),
                  ),
                ],
              ),
              Divider(height: 30, color: AppColors.primary),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                    Icon(Icons.build, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Serviços',
                      style: AppTypography.h1Style(AppColors.primary),
                    ),
                  ],
                ),
                Text(
                  Format.formatCurrency.format(total),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 30, color: AppColors.primary),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
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
                      color: AppColors.accent,
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
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
              borderRadius: BorderRadius.circular(10),
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
                  borderRadius: BorderRadius.circular(12)),
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
                    Divider(height: 30, color: AppColors.primary),
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
                  borderRadius: BorderRadius.circular(12)),
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

  void _printOs(Map<String, dynamic> order) {
    final produtos = order['produtos'] as List? ?? [];
    final servicos = order['servicos'] as List? ?? [];
    num calcTotal = 0;
    try {
      String s = order['calcTotal']?.toString() ?? '0';
      s = s.replaceAll(',', '');
      calcTotal = intlBR.NumberFormat.decimalPattern().parse(s);
    } catch (_) {}

    String produtosHtml = '';
    for (var p in produtos) {
      final qtd = int.tryParse(p['quantidade']?.toString() ?? '1') ?? 1;
      final preco = double.tryParse(p['preco']?.toString() ?? '0') ?? 0;
      produtosHtml += '<tr><td>${p['descricao'] ?? ''}</td><td>$qtd</td><td>R\$ ${preco.toStringAsFixed(2)}</td><td>R\$ ${(preco * qtd).toStringAsFixed(2)}</td></tr>';
    }

    String servicosHtml = '';
    for (var s in servicos) {
      final preco = double.tryParse(s['preco']?.toString() ?? '0') ?? 0;
      final qtd = s['quantidade'] is int ? s['quantidade'] : (int.tryParse(s['quantidade']?.toString() ?? '1') ?? 1);
      servicosHtml += '<tr><td>${s['nome'] ?? ''}</td><td>$qtd</td><td>R\$ ${preco.toStringAsFixed(2)}</td><td>R\$ ${(preco * qtd).toStringAsFixed(2)}</td></tr>';
    }

    final html = '''<!DOCTYPE html><html><head><title>OS #${order['idOs']}</title>
<style>
  body{font-family:Arial,sans-serif;padding:20px;color:#333}
  h1{color:#333649;border-bottom:2px solid #333649;padding-bottom:8px}
  h2{color:#333649;margin-top:24px}
  table{width:100%;border-collapse:collapse;margin:10px 0}
  td,th{border:1px solid #ddd;padding:8px;text-align:left}
  th{background:#333649;color:#fff}
  .info-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin:12px 0}
  .info-label{font-weight:bold;color:#333649}
  .total-box{text-align:right;font-size:18px;font-weight:bold;margin-top:16px;padding:12px;background:#f5f5f5;border-radius:8px}
  @media print{body{padding:0}}
</style></head><body>
<h1>Ordem de Servico #${order['idOs']}</h1>
<div class="info-grid">
  <div><span class="info-label">Cliente:</span> ${order['nomeCliente'] ?? ''}</div>
  <div><span class="info-label">Status:</span> ${order['status'] ?? ''}</div>
  <div><span class="info-label">Entrada:</span> ${order['dataInicial'] != null ? intlBR.DateFormat('dd/MM/yyyy').format(DateTime.parse(order['dataInicial'])) : ''}</div>
  <div><span class="info-label">Prev. Saida:</span> ${order['dataFinal'] != null ? intlBR.DateFormat('dd/MM/yyyy').format(DateTime.parse(order['dataFinal'])) : ''}</div>
  <div><span class="info-label">Responsavel:</span> ${order['nome'] ?? ''}</div>
  <div><span class="info-label">Desconto:</span> R\$ ${double.tryParse(order['desconto']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}</div>
</div>
<h2>Dados Tecnicos</h2>
<p><b>Descricao:</b> ${removeHtmlTags(order['descricaoProduto'])}</p>
<p><b>Defeito:</b> ${removeHtmlTags(order['defeito'])}</p>
<p><b>Laudo Tecnico:</b> ${removeHtmlTags(order['laudoTecnico'])}</p>
<p><b>Observacoes:</b> ${removeHtmlTags(order['observacoes'])}</p>
${produtos.isNotEmpty ? '<h2>Produtos</h2><table><tr><th>Descricao</th><th>Qtd</th><th>Preco Unit.</th><th>Subtotal</th></tr>$produtosHtml</table>' : ''}
${servicos.isNotEmpty ? '<h2>Servicos</h2><table><tr><th>Nome</th><th>Qtd</th><th>Preco Unit.</th><th>Subtotal</th></tr>$servicosHtml</table>' : ''}
<div class="total-box">Valor Total: R\$ ${Format.formatCurrency.format(calcTotal)}</div>
<script>window.onload=function(){window.print();}</script>
</body></html>''';

    final win = web.window.open('', '_blank');
    if (win != null) {
      win.document.write(html.toJS);
      win.document.close();
    }
  }

  void _shareOs(Map<String, dynamic> order) {
    final produtos = order['produtos'] as List? ?? [];
    final servicos = order['servicos'] as List? ?? [];

    String text = 'Ordem de Servico #${order['idOs']}\n';
    text += 'Cliente: ${order['nomeCliente'] ?? ''}\n';
    text += 'Status: ${order['status'] ?? ''}\n';
    text += 'Entrada: ${order['dataInicial'] != null ? intlBR.DateFormat('dd/MM/yyyy').format(DateTime.parse(order['dataInicial'])) : ''}\n';
    text += 'Responsavel: ${order['nome'] ?? ''}\n\n';

    if (produtos.isNotEmpty) {
      text += '--- Produtos ---\n';
      for (var p in produtos) {
        final qtd = int.tryParse(p['quantidade']?.toString() ?? '1') ?? 1;
        final preco = double.tryParse(p['preco']?.toString() ?? '0') ?? 0;
        text += '${p['descricao'] ?? ''} x$qtd - R\$ ${(preco * qtd).toStringAsFixed(2)}\n';
      }
      text += '\n';
    }

    if (servicos.isNotEmpty) {
      text += '--- Servicos ---\n';
      for (var s in servicos) {
        final preco = double.tryParse(s['preco']?.toString() ?? '0') ?? 0;
        text += '${s['nome'] ?? ''} - R\$ ${preco.toStringAsFixed(2)}\n';
      }
      text += '\n';
    }

    num calcTotal = 0;
    try {
      String s = order['calcTotal']?.toString() ?? '0';
      s = s.replaceAll(',', '');
      calcTotal = intlBR.NumberFormat.decimalPattern().parse(s);
    } catch (_) {}
    text += 'Valor Total: R\$ ${Format.formatCurrency.format(calcTotal)}';

    Share.share(text);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Text('Ordem de Serviço excluida com Sucesso'),
        ));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OrdemServicoList()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text('Erro ao excluir Ordem de serviço'),
        ));
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
                      color: AppColors.accent,
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