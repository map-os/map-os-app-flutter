import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapos_app/controllers/clients/clientsController.dart';
import 'package:mapos_app/pages/clients/clients_page.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class EditarClientePage extends StatefulWidget {
  final Map<String, dynamic> cliente;

  EditarClientePage({required this.cliente});

  @override
  _EditarClientePageState createState() => _EditarClientePageState();
}

class _EditarClientePageState extends State<EditarClientePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late MaskedTextController _documentoController;
  late MaskedTextController _telefoneController;
  late MaskedTextController _celularController;
  late TextEditingController _emailController;
  late TextEditingController _cepController;
  late TextEditingController _bairroController;
  late TextEditingController _ruaController;
  late TextEditingController _numeroController;
  late TextEditingController _cidadeController;
  late TextEditingController _estadoController;
  late TextEditingController _senhaController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.cliente['nomeCliente']);
    _documentoController = MaskedTextController(
        mask: widget.cliente['documento'].length > 14 ? '00.000.000/0000-00' : '000.000.000-00',
        text: widget.cliente['documento']
    );
    _telefoneController = MaskedTextController(mask: '(00) 0000-0000', text: widget.cliente['telefone']);
    _celularController = MaskedTextController(mask: '(00) 00000-0000', text: widget.cliente['celular']);
    _emailController = TextEditingController(text: widget.cliente['email']);
    _cepController = TextEditingController(text: widget.cliente['cep']);
    _bairroController = TextEditingController(text: widget.cliente['bairro']);
    _ruaController = TextEditingController(text: widget.cliente['rua']);
    _numeroController = TextEditingController(text: widget.cliente['numero']);
    _cidadeController = TextEditingController(text: widget.cliente['cidade']);
    _estadoController = TextEditingController(text: widget.cliente['estado']);
    _senhaController = TextEditingController(); // Senha não é preenchida por segurança
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _documentoController.dispose();
    _telefoneController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _bairroController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> fetchCEP(String cep) async {
    final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));

    if (!mounted) return; // Add this check

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('erro') && jsonResponse['erro']) {
        if (mounted) { // Add this check
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CEP não encontrado')));
        }
      } else {
        setState(() {
          _ruaController.text = jsonResponse['logradouro'] ?? '';
          _bairroController.text = jsonResponse['bairro'] ?? '';
          _cidadeController.text = jsonResponse['localidade'] ?? '';
          _estadoController.text = jsonResponse['uf'] ?? '';
        });
      }
    } else {
      if (mounted) { // Add this check
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao buscar o CEP')));
      }
    }
  }

  Widget _buildCEPField() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: _cepController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'CEP',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              if (_cepController.text.length == 8) {
                fetchCEP(_cepController.text);
              } else {
                if (mounted) { // Add this check
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Digite um CEP válido'))
                  );
                }
              }
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, insira o CEP';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Cliente'),
        backgroundColor: Color(0xfff6eff8),
      ),
      body: SingleChildScrollView(
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
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.edit, color: Color(0xff333649), size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Editar cliente',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff333649)),
                      ),
                    ],
                  ),
                  Divider(height: 30, color: Color(0xff55596e)),
                  _buildTextField('Nome', _nomeController),
                  _buildDocumentField(),
                  _buildTextField('Telefone', _telefoneController),
                  _buildTextField('Celular', _celularController),
                  _buildTextField('Email', _emailController),
                  _buildPasswordField('Senha', _senhaController),
                  _buildCEPField(),
                  _buildTextField('Bairro', _bairroController),
                  _buildTextField('Rua', _ruaController),
                  _buildTextField('Número', _numeroController),
                  _buildTextField('Cidade', _cidadeController),
                  _buildTextField('Estado', _estadoController),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _updateClient();
                        }
                      },
                      icon: Icon(Icons.save, color: Colors.white), // Ícone adicionado
                      label: Text('Salvar Alterações', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff36374e),
                        minimumSize: Size(350, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentField() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: _documentoController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Documento (CPF/CNPJ)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _updateDocumentMask(value);
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, insira o documento';
          }
          // Adicione aqui validações adicionais para CPF/CNPJ se necessário
          return null;
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        validator: (value) {
          // A senha não é obrigatória para edição
          return null;
        },
      ),
    );
  }

  void _updateDocumentMask(String text) {
    if (text.length <= 14) {
      _documentoController.updateMask('000.000.000-00');
    } else {
      _documentoController.updateMask('00.000.000/0000-00');
    }
  }

  void _updateClient() async {
    try {
      Map<String, dynamic> clientData = {
        'idClientes': widget.cliente['idClientes'],
        'nomeCliente': _nomeController.text,
        'documento': _documentoController.text,
        'telefone': _telefoneController.text,
        'celular': _celularController.text,
        'email': _emailController.text,
        'cep': _cepController.text,
        'bairro': _bairroController.text,
        'rua': _ruaController.text,
        'numero': _numeroController.text,
        'cidade': _cidadeController.text,
        'estado': _estadoController.text,
        'senha': _senhaController.text.isNotEmpty ? _senhaController.text : null,
      };

      var result = await ControllerClients().updateClient(clientData);

      if (!mounted) return; // Add this check

      if (result) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClientsList(),
          ),
        );
        if (mounted) { // Add this check
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cliente atualizado com sucesso!',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'DESFAZER',
                  textColor: Colors.yellow,
                  onPressed: () {},
                ),
              )
          );
        }
      } else {
        if (mounted) { // Add this check
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Falha ao atualizar Cliente!',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              )
          );
        }
      }
    } catch (e) {
      if (mounted) { // Add this check
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Falha ao atualizar Cliente, verifique os dados preenchidos!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            )
        );
      }
    }
  }
}
