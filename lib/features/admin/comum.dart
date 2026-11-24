import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/ui.dart';
import '../../data/repositories/cadastros_repository.dart';

class ControlesDeEndereco {
  ControlesDeEndereco(Map<String, String> inicial) {
    for (final c in campos) {
      controles[c] = TextEditingController(text: inicial[c] ?? '');
    }
  }

  static const campos = ['cep', 'rua', 'numero', 'complemento', 'bairro', 'cidade', 'estado'];
  final controles = <String, TextEditingController>{};

  Map<String, String> get valores => {for (final c in campos) c: controles[c]!.text.trim()};

  void dispose() {
    for (final c in controles.values) {
      c.dispose();
    }
  }
}

class CamposDeEndereco extends StatefulWidget {
  const CamposDeEndereco({super.key, required this.endereco, this.erros = const {}});

  final ControlesDeEndereco endereco;
  final Map<String, String> erros;

  @override
  State<CamposDeEndereco> createState() => _CamposDeEnderecoState();
}

class _CamposDeEnderecoState extends State<CamposDeEndereco> {
  bool _buscando = false;

  TextEditingController _c(String campo) => widget.endereco.controles[campo]!;

  Future<void> _buscarCep() async {
    setState(() => _buscando = true);
    final r = await context.read<ClientesRepository>().buscarCep(_c('cep').text).catchError((_) => null);
    if (!mounted) return;
    setState(() => _buscando = false);
    if (r == null) {
      Toast.error(context, 'CEP não encontrado.');
      return;
    }
    _c('rua').text = '${r['logradouro'] ?? ''}';
    _c('bairro').text = '${r['bairro'] ?? ''}';
    _c('cidade').text = '${r['localidade'] ?? ''}';
    _c('estado').text = '${r['uf'] ?? ''}';
  }

  Widget _campo(String campo, String rotulo, {TextInputType? teclado, Widget? sufixo}) => Padding(
        padding: const EdgeInsets.only(bottom: Gaps.md),
        child: TextField(
          controller: _c(campo),
          keyboardType: teclado,
          textCapitalization: teclado == null ? TextCapitalization.words : TextCapitalization.none,
          onChanged: campo == 'cep'
              ? (v) {
                  if (Fmt.onlyDigits(v).length == 8) _buscarCep();
                }
              : null,
          decoration: InputDecoration(labelText: rotulo, errorText: widget.erros['endereco.$campo'] ?? widget.erros[campo], suffixIcon: sufixo),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _campo(
            'cep',
            'CEP',
            teclado: TextInputType.number,
            sufixo: _buscando
                ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(tooltip: 'Buscar CEP', icon: const Icon(Icons.search_rounded), onPressed: _buscarCep),
          ),
          _campo('rua', 'Rua'),
          Row(
            children: [
              Expanded(child: _campo('numero', 'Número', teclado: TextInputType.text)),
              const SizedBox(width: Gaps.md),
              Expanded(flex: 2, child: _campo('complemento', 'Complemento')),
            ],
          ),
          _campo('bairro', 'Bairro'),
          Row(
            children: [
              Expanded(flex: 3, child: _campo('cidade', 'Cidade')),
              const SizedBox(width: Gaps.md),
              Expanded(child: _campo('estado', 'UF')),
            ],
          ),
        ],
      );
}

Widget campoDeTexto(TextEditingController c, String rotulo, Map<String, String> erros, String chave, {TextInputType? teclado, bool senha = false, String? ajuda, int linhas = 1}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: Gaps.md),
      child: TextField(
        controller: c,
        keyboardType: teclado,
        obscureText: senha,
        maxLines: senha ? 1 : linhas,
        decoration: InputDecoration(labelText: rotulo, helperText: ajuda, helperMaxLines: 3, errorText: erros[chave]),
      ),
    );
