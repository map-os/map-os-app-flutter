import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapos_app/controllers/chamados/chamadosController.dart';
import 'package:mapos_app/pages/chamados/chamados_view_page.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

class AdicionarChamadoPage extends StatefulWidget {
  @override
  _AdicionarChamadoPageState createState() => _AdicionarChamadoPageState();
}

class _AdicionarChamadoPageState extends State<AdicionarChamadoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _defeitoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _dataInicialController = TextEditingController();
  final TextEditingController _dataFinalController = TextEditingController();

  final ControllerChamados _chamadosController = ControllerChamados();

  String? _selectedClienteId;
  String? _selectedUsuarioId;
  String _selectedStatus = 'Aberto';
  List<dynamic> _usuarios = [];
  bool _isLoadingUsuarios = true;
  bool _isSubmitting = false;

  // Debounce + local filter for client search
  Timer? _debounce;
  List<dynamic> _allClientes = [];
  bool _isLoadingClientes = false;

  final List<String> _statusOptions = [
    'Aberto', 'Orçamento', 'Negociação', 'Aprovado',
    'Aguardando Peças', 'Em Andamento', 'Finalizado', 'Faturado', 'Cancelado'
  ];

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
    _loadClientes();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _dataInicialController.text = today;
    _dataFinalController.text = today;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _descricaoController.dispose();
    _defeitoController.dispose();
    _observacoesController.dispose();
    _clienteController.dispose();
    _dataInicialController.dispose();
    _dataFinalController.dispose();
    super.dispose();
  }

  Future<void> _loadUsuarios() async {
    // Try loading from cache first
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cached = prefs.getString('cached_usuarios');
      if (cached != null) {
        setState(() {
          _usuarios = jsonDecode(cached);
          _isLoadingUsuarios = false;
        });
      }
    } catch (_) {}

    // Then refresh from API
    try {
      List<dynamic> usuarios = await _chamadosController.getUsuarios();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_usuarios', jsonEncode(usuarios));
      setState(() {
        _usuarios = usuarios;
        _isLoadingUsuarios = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsuarios = false;
      });
      if (mounted && _usuarios.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Erro ao carregar tecnicos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadClientes() async {
    setState(() { _isLoadingClientes = true; });
    try {
      _allClientes = await _chamadosController.getClientes('');
      debugPrint('Clientes carregados: ${_allClientes.length}');
    } catch (e) {
      debugPrint('Erro ao carregar clientes: $e');
    }
    setState(() { _isLoadingClientes = false; });
  }

  Future<List<dynamic>> _filterClientes(String pattern) async {
    if (_allClientes.isEmpty) return [];
    if (pattern.isEmpty) return _allClientes.take(20).toList();
    final query = pattern.toLowerCase();
    return _allClientes.where((c) {
      final nome = (c['nomeCliente'] ?? '').toString().toLowerCase();
      final doc = (c['documento'] ?? '').toString().toLowerCase();
      final tel = (c['telefone'] ?? c['celular_cliente'] ?? '').toString().toLowerCase();
      return nome.contains(query) || doc.contains(query) || tel.contains(query);
    }).toList();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submitChamado() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text('Selecione um cliente'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedUsuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text('Selecione um tecnico'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dataInicial = DateFormat('yyyy-MM-dd').format(
        DateFormat('dd/MM/yyyy').parse(_dataInicialController.text),
      );
      final dataFinal = DateFormat('yyyy-MM-dd').format(
        DateFormat('dd/MM/yyyy').parse(_dataFinalController.text),
      );

      Map<String, dynamic> chamadoData = {
        'dataInicial': dataInicial,
        'dataFinal': dataFinal,
        'status': _selectedStatus,
        'clientes_id': _selectedClienteId,
        'usuarios_id': _selectedUsuarioId,
        'descricaoProduto': _descricaoController.text,
        'defeito': _defeitoController.text,
        'observacoes': _observacoesController.text,
      };

      var result = await _chamadosController.addChamado(chamadoData);

      if (result['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Chamado aberto com sucesso!', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );

        if (result['result'] != null && result['result']['idOs'] != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VisualizarChamadoPage(
                idChamado: int.parse(result['result']['idOs'].toString()),
              ),
            ),
          );
        } else {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Falha ao abrir chamado: ${result['message'] ?? 'Erro desconhecido'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Erro ao abrir chamado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Abrir Chamado'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAllMd,
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: AppSpacing.paddingAllLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.headset_mic, color: AppColors.primary, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Abrir Chamado',
                        style: AppTypography.h1Style(AppColors.primary),
                      ),
                    ],
                  ),
                  Divider(height: 30, color: AppColors.divider),

                  // Cliente (autocomplete local)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TypeAheadField<dynamic>(
                      controller: _clienteController,
                      debounceDuration: Duration(milliseconds: 150),
                      hideOnEmpty: false,
                      builder: (context, controller, focusNode) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Cliente *',
                            hintText: 'Buscar por nome, CNPJ ou telefone...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            suffixIcon: _isLoadingClientes
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(Icons.search),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, selecione um cliente';
                            }
                            if (_selectedClienteId == null) {
                              return 'Selecione um cliente da lista';
                            }
                            return null;
                          },
                        );
                      },
                      loadingBuilder: (context) => Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      emptyBuilder: (context) => ListTile(
                        leading: Icon(Icons.info_outline, color: Colors.grey),
                        title: Text('Nenhum cliente encontrado'),
                        subtitle: Text('Tente buscar por nome, CNPJ ou telefone'),
                      ),
                      suggestionsCallback: (pattern) {
                        return _filterClientes(pattern);
                      },
                      itemBuilder: (context, dynamic suggestion) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              (suggestion['nomeCliente'] ?? '?')[0].toUpperCase(),
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                          title: Text(
                            suggestion['nomeCliente'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${suggestion['documento'] ?? ''}  |  ${suggestion['telefone'] ?? suggestion['celular_cliente'] ?? ''}',
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      },
                      onSelected: (dynamic suggestion) {
                        _clienteController.text = suggestion['nomeCliente'] ?? '';
                        _selectedClienteId = suggestion['idClientes'].toString();
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),

                  // Tecnico (dropdown com cache)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _isLoadingUsuarios && _usuarios.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : DropdownButtonFormField<String>(
                      value: _selectedUsuarioId,
                      decoration: InputDecoration(
                        labelText: 'Tecnico *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: _isLoadingUsuarios
                            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : null,
                      ),
                      items: _usuarios.map<DropdownMenuItem<String>>((dynamic usuario) {
                        return DropdownMenuItem<String>(
                          value: usuario['idUsuarios'].toString(),
                          child: Text(usuario['nome'] ?? 'Tecnico'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedUsuarioId = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione um tecnico';
                        }
                        return null;
                      },
                    ),
                  ),

                  // Data Inicial
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      controller: _dataInicialController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Data Inicial *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(_dataInicialController),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione a data inicial';
                        }
                        return null;
                      },
                    ),
                  ),

                  // Data Final
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      controller: _dataFinalController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Data Final *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(_dataFinalController),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione a data final';
                        }
                        return null;
                      },
                    ),
                  ),

                  // Status
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _statusOptions.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStatus = newValue!;
                        });
                      },
                    ),
                  ),

                  // Descricao
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      controller: _descricaoController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descricao do Produto/Servico',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  // Defeito
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      controller: _defeitoController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Defeito',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  // Observacoes
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      controller: _observacoesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observacoes',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: 350,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitChamado,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? CircularProgressIndicator(color: Colors.white)
                            : const Text('Abrir Chamado'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}