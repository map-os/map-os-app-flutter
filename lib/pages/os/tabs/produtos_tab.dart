import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/TokenController.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

class ProdutosTab extends StatefulWidget {
  final Map<String, dynamic>? ordemServico;
  final VoidCallback onAtualizar;

  ProdutosTab({required this.ordemServico, required this.onAtualizar});

  @override
  _ProdutosTabState createState() => _ProdutosTabState();
}

class _ProdutosTabState extends State<ProdutosTab> {
  List<dynamic> produtosList = [];
  bool isLoading = true;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _loadProdutos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Carregar os produtos da API
  Future<void> _loadProdutos() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        throw Exception('Token de acesso não encontrado');
      }

      var response = await http.get(
        Uri.parse("${APIConfig.baseURL}${APIConfig.produtosEndpoint}"),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'App-Version': APIConfig.appVersion,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        accessToken = prefs.getString('access_token');
        response = await http.get(
          Uri.parse("${APIConfig.baseURL}${APIConfig.produtosEndpoint}"),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'App-Version': APIConfig.appVersion,
          },
        ).timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Cache products locally
        await prefs.setString('cached_produtos_catalog', json.encode(data['result']));
        setState(() {
          produtosList = data['result'];
          isLoading = false;
        });
        widget.onAtualizar();
      } else {
        throw Exception('Erro ao carregar os produtos: ${response.statusCode}');
      }
    } catch (e) {
      // Try loading from cache on CORS/network error
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? cached = prefs.getString('cached_produtos_catalog');
        if (cached != null) {
          setState(() {
            produtosList = json.decode(cached);
            isLoading = false;
          });
          return;
        }
      } catch (_) {}
      setState(() {
        errorMessage = 'Erro ao carregar produtos. Verifique a conexao com a API.';
        isLoading = false;
      });
    }
  }

  // Exibir diálogo para selecionar quantidade e preço
  Future<Map<String, dynamic>?> _selecionarQuantidadePreco(dynamic produto) async {
    int quantidade = 1;
    double precoUnitario = double.tryParse(produto['precoVenda']?.toString() ?? produto['preco']?.toString() ?? '0') ?? 0.0;
    final precoController = TextEditingController(text: precoUnitario.toStringAsFixed(2));

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final currentPreco = double.tryParse(precoController.text) ?? 0.0;
            final total = currentPreco * quantidade;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 8,
              title: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                ),
                child: Text(
                  '${produto['descricao']}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Quantidade:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: quantidade > 1 ? Colors.red : Colors.grey[400], size: 32),
                          onPressed: quantidade > 1 ? () => setDialogState(() => quantidade--) : null,
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Text('$quantidade', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                          onPressed: () => setDialogState(() => quantidade++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Preco unitario (R\$):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: precoController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixText: 'R\$ ',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(formatoMoeda.format(total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.cardDark)),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('CANCELAR'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop({
                    'quantidade': quantidade,
                    'preco': currentPreco.toStringAsFixed(2),
                  }),
                  child: const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            );
          },
        );
      },
    );
  }

  // Adicionar produto à ordem
  Future<void> _adicionarProduto(dynamic produto) async {
    try {
      final result = await _selecionarQuantidadePreco(produto);
      if (result == null) return;

      final int quantidade = result['quantidade'];
      final String preco = result['preco'];

      final String idProduto = produto['idProdutos'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String idOs = widget.ordemServico!['idOs'];

      if (accessToken == null) {
        throw Exception('Token de acesso não encontrado');
      }

      // Verificar se o produto já está adicionado
      final produtos = widget.ordemServico!['produtos'] ?? [];
      if (produtos.any((s) => s['produtos_id'].toString() == idProduto.toString())) {
        return;
      }

      _showProgressDialog('Adicionando produto...');

      var response = await http.post(
        Uri.parse("${APIConfig.baseURL}${APIConfig.osEndpoint}/$idOs/produtos/$idProduto"),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'App-Version': APIConfig.appVersion,
        },
        body: jsonEncode({
          'idProduto': idProduto,
          'idOs': idOs,
          'quantidade': quantidade,
          'preco': preco
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        accessToken = prefs.getString('access_token');
        response = await http.post(
          Uri.parse("${APIConfig.baseURL}${APIConfig.osEndpoint}/$idOs/produtos/$idProduto"),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'App-Version': APIConfig.appVersion,
          },
          body: jsonEncode({
            'idProduto': idProduto,
            'idOs': idOs,
            'quantidade': quantidade,
            'preco': preco
          }),
        ).timeout(const Duration(seconds: 15));
      }

      Navigator.of(context, rootNavigator: true).pop();

      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        setState(() {
          if (widget.ordemServico!['produtos'] == null) {
            widget.ordemServico!['produtos'] = [];
          }
          widget.ordemServico!['produtos'].add(data['result']);
          _searchController.clear();
        });

        widget.onAtualizar();
        _showSnackBar('Produto adicionado com sucesso');
      } else {
        throw Exception('Erro ao adicionar o produto: ${data['error'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      debugPrint('Erro ao adicionar produto: ${e.toString()}');
    }
  }

  // Remover produto da OS
  Future<void> _removerServico(dynamic idProduto, produto) async {
    if (widget.ordemServico == null) {
      return;
    }

    try {

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String idOs = widget.ordemServico!['idOs'];

      if (accessToken == null) {
        throw Exception('Token de acesso não encontrado');
      }

      // Confirmar exclusão
      bool confirmar = await _confirmarExclusao(produto['descricao']);
      if (!confirmar) return;

      // Mostrar indicador de progresso
      _showProgressDialog('Removendo produto...');

      var response = await http.delete(
        Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/$idOs/produtos/$idProduto'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'App-Version': APIConfig.appVersion,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        accessToken = prefs.getString('access_token');
        response = await http.delete(
          Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/$idOs/produtos/$idProduto'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'App-Version': APIConfig.appVersion,
          },
        ).timeout(const Duration(seconds: 15));
      }

      // Fechar o diálogo de progresso
      Navigator.of(context, rootNavigator: true).pop();

      debugPrint('Resposta da API (remover): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status']) {
          setState(() {
            widget.ordemServico!['produtos'].removeWhere(
                    (item) => item['produtos_id'].toString() == idProduto
            );
          });

          widget.onAtualizar(); // Chama o callback para atualizar a OS
          _showSnackBar('produto removido com sucesso');
        } else {
          throw Exception('Erro ao remover o produto: ${data['error'] ?? 'Erro desconhecido'}');
        }
      } else {
        throw Exception('Erro ao remover o produto: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao remover produto: ${e.toString()}');
    }
  }

  // Atualizar quantidade/preco de um produto
  Future<void> _atualizarQuantidade(dynamic produto) async {
    try {
      final result = await _selecionarQuantidadePreco(produto);
      if (result == null) return;

      final int novaQuantidade = result['quantidade'];
      final String novoPreco = result['preco'];

      final String idproduto = produto['idProdutos_os'].toString();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String idOs = widget.ordemServico!['idOs'];

      if (accessToken == null) {
        throw Exception('Token de acesso não encontrado');
      }

      _showProgressDialog('Atualizando produto...');

      var response = await http.put(
        Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/$idOs/produtos/$idproduto'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'App-Version': APIConfig.appVersion,
        },
        body: jsonEncode({
          'quantidade': novaQuantidade,
          'preco': novoPreco
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 403) {
        await TokenController().regenerateToken();
        accessToken = prefs.getString('access_token');
        response = await http.put(
          Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/$idOs/produtos/$idproduto'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'App-Version': APIConfig.appVersion,
          },
          body: jsonEncode({
            'quantidade': novaQuantidade,
            'preco': novoPreco
          }),
        ).timeout(const Duration(seconds: 15));
      }

      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status']) {
          setState(() {
            final index = widget.ordemServico!['produtos'].indexWhere(
                    (item) => item['produtos_id'].toString() == idproduto
            );
            if (index != -1) {
              widget.ordemServico!['produtos'][index]['quantidade'] = novaQuantidade.toString();
              widget.ordemServico!['produtos'][index]['preco'] = novoPreco;
              double precoVal = double.tryParse(novoPreco) ?? 0;
              widget.ordemServico!['produtos'][index]['subTotal'] = (novaQuantidade * precoVal).toString();
            }
          });

          widget.onAtualizar();
          _showSnackBar('Produto atualizado com sucesso');
        } else {
          throw Exception('Erro ao atualizar: ${data['error'] ?? 'Erro desconhecido'}');
        }
      } else {
        throw Exception('Erro ao atualizar: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao atualizar produto: ${e.toString()}');
    }
  }



  void _showProgressDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // Fundo mais escuro para melhor contraste
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                      strokeWidth: 4,
                    ),
                    Icon(
                      Icons.hourglass_top,
                      size: 30,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Mensagem principal
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Por favor, aguarde...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _confirmarExclusao(String nomeProduto) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 8,
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_forever,
            size: 32,
            color: Colors.red,
          ),
        ),
        title: const Text(
          'Confirmar Exclusão',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Você está prestes a remover o produto:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                nomeProduto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[400]!),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              // elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete, size: 18),
                SizedBox(width: 6),
                Text('Confirmar'),
              ],
            ),
          ),
        ],
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        actionsPadding: const EdgeInsets.only(bottom: 16),
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Verificar se temos uma ordem de produto válida
    if (widget.ordemServico == null) {
      return const Center(
        child: Text(
          'Nenhuma informação disponível',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Obter a lista de produtos da OS
    final result = widget.ordemServico;
    final List<dynamic> produtos = result?['produtos'] ?? [];

    // Calcular valor total dos produtos
    double valorTotalProdutos = 0;
    for (var produto in produtos) {
      valorTotalProdutos += double.tryParse(produto['subTotal']?.toString() ?? produto['preco']?.toString() ?? '0') ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo de pesquisa e adição de produtos
        Padding(
          padding: AppSpacing.paddingAllMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adicionar Produto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TypeAheadField<dynamic>(
                controller: _searchController,
                debounceDuration: Duration(milliseconds: 200),
                hideOnEmpty: false,
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Pesquisar produto',
                      hintText: isLoading ? 'Carregando...' : 'Digite para buscar...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    ),
                  );
                },
                loadingBuilder: (context) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),),
                emptyBuilder: (context) => const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('Nenhum produto encontrado'),
                ),
                suggestionsCallback: (pattern) {
                  if (pattern.isEmpty) {
                    return produtosList.take(20).toList();
                  }
                  return produtosList.where((produto) {
                    final desc = (produto['descricao'] ?? '').toString().toLowerCase();
                    final cod = (produto['codDeBarra'] ?? '').toString().toLowerCase();
                    return desc.contains(pattern.toLowerCase()) || cod.contains(pattern.toLowerCase());
                  }).toList();
                },
                itemBuilder: (context, suggestion) {
                  final preco = double.tryParse(suggestion['precoVenda'] ?? suggestion['preco'] ?? '0') ?? 0.0;
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.build),
                    ),
                    title: Text(suggestion['descricao'] ?? 'produto sem nome'),
                    subtitle: Text('Preço: ${formatoMoeda.format(preco)}'),
                    trailing: const Icon(Icons.add_circle_outline),
                  );
                },
                onSelected: (suggestion) {
                  _adicionarProduto(suggestion);
                },
              ),
            ],
          ),
        ),

        // Cabeçalho da lista de produtos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.format_list_bulleted, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Produtos Registrados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${formatoMoeda.format(valorTotalProdutos)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 16, thickness: 1),

        // Lista de produtos
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : produtos.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.engineering_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum produto registrado',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: () async {
              await _loadProdutos();
              widget.onAtualizar();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: produtos.length,
              itemBuilder: (context, index) {
                final produto = produtos[index];
                final nomeProduto = produto['descricao'] ?? 'produto não especificado';
                final preco = double.tryParse(produto['preco']?.toString() ?? '0') ?? 0;
                final quantidade = int.tryParse(produto['quantidade']?.toString() ?? '1') ?? 1;
                final subtotal = double.tryParse(produto['subTotal']?.toString() ?? '0') ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 2,
                  child: Padding(
                    padding: AppSpacing.paddingAllMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              foregroundColor: Colors.blue[800],
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                nomeProduto,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _atualizarQuantidade(produto),
                              tooltip: 'Alterar quantidade',
                            ),
                            IconButton(

                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removerServico(produto['idProdutos_os'].toString(), produto),
                              tooltip: 'Remover produto',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Quantidade: ',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  '$quantidade',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Valor unitário: ${formatoMoeda.format(preco)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Subtotal: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              formatoMoeda.format(subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Resumo no rodapé
        Container(
          padding: AppSpacing.paddingAllMd,
          color: AppColors.shimmerHighlight,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total de produtos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${produtos.length} item(ns)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Valor total:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    formatoMoeda.format(valorTotalProdutos),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}