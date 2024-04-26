import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapos_app/config/constants.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:mapos_app/assets/app_colors.dart';

class ServicoEditScreen extends StatefulWidget {
  final Map<String, dynamic> servico;

  ServicoEditScreen({required this.servico});

  @override
  _ServicoEditScreenState createState() => _ServicoEditScreenState();
}

class _ServicoEditScreenState extends State<ServicoEditScreen> {
  late TextEditingController _nomeServicoController;
  late TextEditingController _descricaoServicoController;
  late TextEditingController _precoServicoController;
  bool _editingEnabled = false;
  String _currentTheme = 'TemaSecundario';

  @override
  void initState() {
    _getTheme();
    super.initState();
    _nomeServicoController =
        TextEditingController(text: widget.servico['nome'] ?? '');
    _descricaoServicoController =
        TextEditingController(text: widget.servico['descricao'] ?? '');
    _precoServicoController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
      initialValue: double.tryParse(widget.servico['preco'] ?? '0.00') ?? 0.00,
    );
  }

  Future<void> _getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String theme = prefs.getString('theme') ?? 'TemaPrimario';
    setState(() {
      _currentTheme = theme;
    });
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentTheme == 'TemaPrimario'
          ? TemaPrimario.editbackColor
          : TemaSecundario.editbackColor,
      appBar: AppBar(
        title: Text('Editar Serviço'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            color: Colors.red,
            onPressed: () async {
              Map<String, dynamic> permissionsMap = await _getCiKey();
              List<dynamic> permissoes = permissionsMap['permissoes'];
              bool hasPermissionToDelete = false;
              for (var permissao in permissoes) {
                if (permissao['dProduto'] == '1') {
                  hasPermissionToDelete = true;
                  break;
                }
              }
              if (hasPermissionToDelete) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      title: Text(
                        "Confirmar exclusão",
                        style: TextStyle(
                          color: Colors.black, // Cor do título
                          fontWeight: FontWeight.bold, // Texto em negrito
                          fontSize: 18.0, // Tamanho da fonte
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Tem certeza que deseja excluir este produto?",
                            style: TextStyle(
                              fontSize: 16.0, // Tamanho da fonte
                            ),
                          ),
                          SizedBox(height: 10), // Espaçamento entre o texto e o campo de entrada
                          TextField(
                            decoration: InputDecoration(
                              hintText: "Digite 'sim' para confirmar",
                              hintStyle: TextStyle(
                                color: Colors.grey[400], // Cor do texto de dica
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black), // Cor da borda quando em foco
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey), // Cor da borda quando não está em foco
                              ),
                            ),
                            onChanged: (value) {
                              if (value.toLowerCase() == 'sim') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.green,
                                    content: Text('Produto Excluído com sucesso'),
                                  ),
                                );
                                _deleteService();
                                Navigator.of(context).pop(); // Fechar o diálogo após exclusão
                              }
                            },
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                            "Cancelar",
                            style: TextStyle(
                              color: Colors.red, // Cor do texto do botão
                              fontWeight: FontWeight.bold, // Texto em negrito
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );


                  },
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Você não tem permissões para deletar.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ID do Serviço: ${widget.servico['idServicos'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: _currentTheme == 'TemaPrimario'
                        ? TemaPrimario.ColorText
                        : TemaSecundario.ColorText),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _nomeServicoController,
                enabled: _editingEnabled,
                style: TextStyle(color: _currentTheme == 'TemaPrimario'
                    ? TemaPrimario.ColorText
                    : TemaSecundario.ColorText,
                ),
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: _currentTheme == 'TemaPrimario'
                      ? TemaPrimario.labelColor
                      : TemaSecundario.labelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                  ),
                  prefixIcon: Icon(
                    Icons.file_present, color: _currentTheme == 'TemaPrimario'
                      ? TemaPrimario.iconColor
                      : TemaSecundario.iconColor,),
                  filled: true,
                  fillColor: _currentTheme == 'TemaPrimario'
                      ? TemaPrimario.inputColor
                      : TemaSecundario.inputColor,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 2.0), // Cor da borda quando não está em foco
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 2.0), // Cor da borda quando está em foco
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 1.0), // Cor da borda quando o campo está habilitado e não está em foco
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 1.0), // Cor da borda quando o campo está desabilitado
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _descricaoServicoController,
                enabled: _editingEnabled,
                style: TextStyle(color: _currentTheme == 'TemaPrimario'
                    ? TemaPrimario.ColorText
                    : TemaSecundario.ColorText,
                ),
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  labelStyle: TextStyle(color: _currentTheme == 'TemaPrimario'
                      ? TemaPrimario.labelColor
                      : TemaSecundario.labelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                  ),
                  prefixIcon: Icon(
                    Icons.description_sharp, color: _currentTheme == 'TemaPrimario'
                      ? TemaPrimario.iconColor
                      : TemaSecundario.iconColor,),
                  filled: true,
                  fillColor: _currentTheme == 'TemaPrimario'
                      ? TemaPrimario.inputColor
                      : TemaSecundario.inputColor,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 2.0), // Cor da borda quando não está em foco
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 2.0), // Cor da borda quando está em foco
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 1.0), // Cor da borda quando o campo está habilitado e não está em foco
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 1.0), // Cor da borda quando o campo está desabilitado
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _precoServicoController,
                enabled: _editingEnabled,
                style: TextStyle(color: _currentTheme == 'TemaPrimario'
                    ? TemaPrimario.ColorText
                    : TemaSecundario.ColorText,
                ),
                decoration: InputDecoration(
                  labelText: 'Valor',
                  labelStyle: TextStyle(color: _currentTheme == 'TemaPrimario'
                      ? TemaPrimario.labelColor
                      : TemaSecundario.labelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                  ),
                  prefixIcon: Icon(
                    Icons.attach_money, color: _currentTheme == 'TemaPrimario'
                      ? TemaPrimario.iconColor
                      : TemaSecundario.iconColor,),
                  filled: true,
                  fillColor: _currentTheme == 'TemaPrimario'
                      ? TemaPrimario.inputColor
                      : TemaSecundario.inputColor,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 2.0), // Cor da borda quando não está em foco
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 2.0), // Cor da borda quando está em foco
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 1.0), // Cor da borda quando o campo está habilitado e não está em foco
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                        color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.inputBorderColor
                            : TemaSecundario.inputBorderColor,
                        width: 1.0), // Cor da borda quando o campo está desabilitado
                  ),
                ),
                keyboardType: TextInputType.number,
              ),

              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _editingEnabled ? _saveChanges : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _currentTheme == 'TemaPrimario'
                        ? TemaPrimario.botaoBackgroudColor
                        : TemaSecundario.botaoBackgroudColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    minimumSize: Size(200, 50),
                    elevation: 2
                ),
                child: Text(
                  'Salvar Alterações',
                  style: TextStyle(
                    fontSize: 18.0, color: _currentTheme == 'TemaPrimario'
                      ? TemaPrimario.botaoTextColor
                      : TemaSecundario.botaoTextColor,),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() async {
    String preco = _precoServicoController.text
        .replaceAll('R\$ ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    Map<String, dynamic> updatedServico = {
      'idServicos': widget.servico['idServico'],
      'nome': _nomeServicoController.text,
      'descricao': _descricaoServicoController.text,
      'preco': preco,
    };

    Future<bool> success = _updateServico(updatedServico);
    if (await success) {
      _showSnackBar('Serviço atualizado com sucesso',
          backgroundColor: Colors.green, textColor: Colors.white);
    } else {
      _showSnackBar('Falha ao atualizar o serviço',
          backgroundColor: Colors.red, textColor: Colors.white);
    }
  }

  void _showSnackBar(String message,
      {Color backgroundColor = Colors.black, Color textColor = Colors.white}) {
    final snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: textColor)),
      backgroundColor: backgroundColor,
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<bool> _updateServico(Map<String, dynamic> updatedServico) async {
    Map<String, dynamic> ciKey = await _getCiKey();

    var url =
        '${APIConfig.baseURL}${APIConfig.servicossEndpoint}/${widget.servico['idServicos']}';

    try {
      var response = await http.put(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ciKey['ciKey']}',
        },
        body: jsonEncode(updatedServico),
      );
      if (response.statusCode == 200) {
        print('Serviço atualizado com sucesso');
        return true;
      } else {
        print('Falha ao atualizar o serviço: ${response.reasonPhrase}');
        return false;
      }
    } catch (error) {
      print('Erro ao enviar solicitação PUT: $error');
      return false;
    }
  }

  Future<bool> _deleteService() async {
    Map<String, dynamic> ciKey = await _getCiKey();

    var url =
        '${APIConfig.baseURL}${APIConfig.servicossEndpoint}/${widget.servico['idServicos']}';

    try {
      var response = await http.delete(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ciKey['ciKey']}',
        },
      );
      if (response.statusCode == 200) {
        print('Serviço atualizado com sucesso');
        Navigator.pop(context);
        return true;
      } else {
        print('Falha ao atualizar o serviço: ${response.reasonPhrase}');
        return false;
      }
    } catch (error) {
      print('Erro ao enviar solicitação PUT: $error');
      return false;
    }
  }
}