import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapos_app/config/constants.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mapos_app/providers/calcTotal.dart';

class TabDetalhes extends StatefulWidget {
  final Map<String, dynamic> os;

  TabDetalhes({required this.os});

  @override
  _TabDetalhesState createState() => _TabDetalhesState();
}

class _TabDetalhesState extends State<TabDetalhes> {
  late String UsuariosId;
  late String ClientesId;
  late TextEditingController _idOsController;
  late TextEditingController _nomeClienteController;
  late TextEditingController _dataInicialController;
  late TextEditingController _dataFinalController;
  late TextEditingController _statusController;
  late TextEditingController _descricaoProdutoController;
  late TextEditingController _defeitoController;
  late TextEditingController _observacoesController;
  late TextEditingController _laudoTecnicoController;
  late HtmlEditorController _htmlEditorController;
  late HtmlEditorController _htmlDefeitoController;
  late HtmlEditorController  _htmlLaudoController;
  late String observacoesHTML;
  late String defeitoHTML;
  late String laudoHTML;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _getOs();
    _idOsController = TextEditingController();
    _nomeClienteController = TextEditingController();
    _dataInicialController = TextEditingController();
    _dataFinalController = TextEditingController();
    _statusController = TextEditingController();
    _descricaoProdutoController = TextEditingController();
    _defeitoController = TextEditingController();
    _observacoesController = TextEditingController();
    _laudoTecnicoController = TextEditingController();
    _htmlEditorController = HtmlEditorController();
    _htmlDefeitoController = HtmlEditorController();
    _htmlLaudoController = HtmlEditorController();
    observacoesHTML = ''; // Inicialize a variável observacoesHTML
    defeitoHTML = '';
    laudoHTML = '';

  }

  @override
  void dispose() {
    _idOsController.dispose();
    _nomeClienteController.dispose();
    _dataInicialController.dispose();
    _dataFinalController.dispose();
    _statusController.dispose();
    _descricaoProdutoController.dispose();
    _defeitoController.dispose();
    _observacoesController.dispose();
    _laudoTecnicoController.dispose();
    observacoesHTML.toString();
    defeitoHTML.toString();
    super.dispose();
  }

  Future<void> _getOs() async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
    };
    var url =
        '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        setState(() {
          UsuariosId = data['result']['usuarios_id'];
          ClientesId = data['result']['clientes_id'];
          _idOsController.text = data['result']['idOs'];
          _nomeClienteController.text = data['result']['nomeCliente'];
          _dataInicialController.text = data['result']['dataInicial'];
          _dataFinalController.text = data['result']['dataFinal'];
          _statusController.text = data['result']['status'];
          _descricaoProdutoController.text = data['result']['descricaoProduto'];
          _defeitoController.text = data['result']['defeito'];
          _observacoesController.text = data['result']['observacoes'];
          _laudoTecnicoController.text = data['result']['laudoTecnico'];
        });
      } else {
        print('API não retornou nenhum dado');
      }
    } else {
      print('Falha ao carregar dados');
    }
  }

  void _salvarDados() async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
      'Content-Type': 'application/json',
    };
    Map<String, dynamic> requestBody = {
      'dataInicial': _dataInicialController.text,
      'dataFinal': _dataFinalController.text,
      'status': _selectedStatus ?? _statusController.text,
      'clientes_id': ClientesId,
      'usuarios_id': UsuariosId,
      'descricaoProduto': observacoesHTML,
      'defeito': defeitoHTML,
      'observacoes': '',
      'laudoTecnico': laudoHTML,
    };

    var url = '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}';
    print(jsonEncode(requestBody));
    var response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(requestBody), // Atribuir o corpo à requisição PUT
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('OS atualizada com sucesso'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Falha ao atualizar OS'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cliente: ' + _nomeClienteController.text,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Entrada: ' + _dataInicialController.text,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Prev. Saída: ' + _dataFinalController.text,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedStatus ?? _statusController.text,
                onChanged: (newValue) {
                  setState(() {
                    _selectedStatus = newValue ?? _statusController.text;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Status',
                  filled: true,
                  fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 5.0, horizontal: 9.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Color(0xff333649), width: 2.0),
                  ),
                ),
                items: <String>[
                  'Aberto',
                  'Orçamento',
                  'Aprovado',
                  'Negociação',
                  'Em Andamento',
                  'Aguardando Peças',
                  'Finalizado',
                  'Cancelado',
                  'Faturado',
                ]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Descrição: ',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xecf0f1ff),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HtmlEditor(
                  controller: _htmlEditorController,
                  htmlEditorOptions: HtmlEditorOptions(
                    hint: "Digite a descrição...",
                    initialText: _descricaoProdutoController.text,
                  ),
                  otherOptions: OtherOptions(
                    height: 200,
                  ),
                  callbacks: Callbacks(onInit: () {
                    _htmlEditorController.editorController!.evaluateJavascript(source: "document.getElementsByClassName('note-editable')[0].style.backgroundColor='#EAF1FD';");
                  }),
                  htmlToolbarOptions: HtmlToolbarOptions(
                    defaultToolbarButtons: [
                      FontButtons(
                        clearAll: false,
                        strikethrough: false,
                        subscript: false,
                        superscript: false,
                      ),
                      ColorButtons(), // Adicione o ColorButtons aqui
                      ParagraphButtons(
                        alignCenter: true,
                        decreaseIndent: false,
                        caseConverter: false,
                        textDirection: false,
                        increaseIndent: false,
                        lineHeight: false,
                      )
                    ],
                    toolbarPosition: ToolbarPosition.aboveEditor,
                  ),
                ),
              ),

              SizedBox(height: 16.0),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Defeito: ',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xecf0f1ff),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HtmlEditor(
                  controller: _htmlDefeitoController,
                  htmlEditorOptions: HtmlEditorOptions(
                    hint: "Digite o defeito aqui ...",
                    initialText: _defeitoController.text,
                  ),
                  otherOptions: OtherOptions(
                    height: 200,
                  ),
                  callbacks: Callbacks(onInit: () {
                    _htmlDefeitoController.editorController!.evaluateJavascript(source: "document.getElementsByClassName('note-editable')[0].style.backgroundColor='#EAF1FD';");
                  }),
                  htmlToolbarOptions: HtmlToolbarOptions(
                    defaultToolbarButtons: [
                      FontButtons(
                        clearAll: false,
                        strikethrough: false,
                        subscript: false,
                        superscript: false,
                      ),
                      ColorButtons(), // Adicione o ColorButtons aqui
                      ParagraphButtons(
                        alignCenter: true,
                        decreaseIndent: false,
                        caseConverter: false,
                        textDirection: false,
                        increaseIndent: false,
                        lineHeight: false,
                      )
                    ],
                    toolbarPosition: ToolbarPosition.aboveEditor,
                  ),
                ),
              ),

              SizedBox(height: 16.0),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Laudo Técnico: ',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xecf0f1ff),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HtmlEditor(
                  controller: _htmlLaudoController,
                  htmlEditorOptions: HtmlEditorOptions(
                    hint: "Digite o Laudo Técnico aqui ...",
                    initialText: _laudoTecnicoController.text,
                  ),
                  otherOptions: OtherOptions(
                    height: 200,
                  ),
                  callbacks: Callbacks(onInit: () {
                    _htmlLaudoController.editorController!.evaluateJavascript(source: "document.getElementsByClassName('note-editable')[0].style.backgroundColor='#EAF1FD';");
                  }),
                  htmlToolbarOptions: HtmlToolbarOptions(
                    defaultToolbarButtons: [
                      FontButtons(
                        clearAll: false,
                        strikethrough: false,
                        subscript: false,
                        superscript: false,
                      ),
                      ColorButtons(), // Adicione o ColorButtons aqui
                      ParagraphButtons(
                        alignCenter: true,
                        decreaseIndent: false,
                        caseConverter: false,
                        textDirection: false,
                        increaseIndent: false,
                        lineHeight: false,
                      )
                    ],
                    toolbarPosition: ToolbarPosition.aboveEditor,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  observacoesHTML = await _htmlEditorController.getText();
                  defeitoHTML = await _htmlDefeitoController.getText();
                  laudoHTML = await _htmlLaudoController.getText();
                  _salvarDados();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2c9b5b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  minimumSize: Size(430, 60),
                ),
                child: Text(
                  'Salvar Alterações',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
