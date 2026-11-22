import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/input_masks.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/catalogo.dart';
import '../../data/repositories/cadastros_repository.dart';

class ProdutoFormPage extends StatefulWidget {
  const ProdutoFormPage({super.key, this.produto});

  final Produto? produto;

  @override
  State<ProdutoFormPage> createState() => _ProdutoFormPageState();
}

class _ProdutoFormPageState extends State<ProdutoFormPage> {
  static const _unidades = ['UNID', 'PC', 'CX', 'KG', 'G', 'L', 'ML', 'M', 'M²', 'M³', 'PAR', 'KIT', 'H'];

  final _form = GlobalKey<FormState>();
  late final Produto? _p = widget.produto;
  late final _descricao = TextEditingController(text: _p?.descricao);
  late final _codigo = TextEditingController(text: _p?.codDeBarra);
  late final _compra = TextEditingController(text: MoneyMask.format(_p?.precoCompra ?? 0));
  late final _venda = TextEditingController(text: MoneyMask.format(_p?.precoVenda ?? 0));
  late final _estoque = TextEditingController(text: _p == null ? '' : Fmt.number(_p.estoque));
  late final _minimo = TextEditingController(text: _p == null ? '' : Fmt.number(_p.estoqueMinimo));
  late String _unidade = _p?.unidade ?? 'UNID';
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_descricao, _codigo, _compra, _venda, _estoque, _minimo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final produto = Produto(
      id: _p?.id ?? 0,
      descricao: _descricao.text.trim(),
      codDeBarra: _codigo.text.trim(),
      unidade: _unidade,
      precoCompra: Fmt.parseMoney(_compra.text),
      precoVenda: Fmt.parseMoney(_venda.text),
      estoque: asDouble(_estoque.text),
      estoqueMinimo: asDouble(_minimo.text),
    );
    final repo = context.read<ProdutosRepository>();
    try {
      _p == null ? await repo.create(produto) : await repo.update(produto);
      if (!mounted) return;
      Toast.success(context, _p == null ? 'Produto cadastrado.' : 'Produto atualizado.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = {..._unidades, _unidade}.toList();
    return Scaffold(
      appBar: AppBar(title: Text(_p == null ? 'Novo produto' : 'Editar produto')),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(label: 'Salvar', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: Gaps.pageOf(context),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormSection(
                    title: 'Produto',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      AppTextField(
                        controller: _descricao,
                        label: 'Descrição',
                        icon: Icons.label_outline_rounded,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => Validators.required(v, 'Descrição'),
                      ),
                      AppTextField(controller: _codigo, label: 'Código de barras', icon: Icons.qr_code_2_rounded),
                      DropdownButtonFormField<String>(
                        initialValue: _unidade,
                        decoration: const InputDecoration(labelText: 'Unidade', prefixIcon: Icon(Icons.straighten_rounded)),
                        items: [for (final u in units) DropdownMenuItem(value: u, child: Text(u))],
                        onChanged: (v) => setState(() => _unidade = v ?? 'UNID'),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gaps.md),
                  FormSection(
                    title: 'Preços',
                    icon: Icons.payments_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _compra,
                              label: 'Custo',
                              keyboardType: TextInputType.number,
                              inputFormatters: [MoneyMask()],
                            ),
                          ),
                          const SizedBox(width: Gaps.md),
                          Expanded(
                            child: AppTextField(
                              controller: _venda,
                              label: 'Venda',
                              keyboardType: TextInputType.number,
                              inputFormatters: [MoneyMask()],
                              validator: (v) => Fmt.parseMoney(v ?? '') <= 0 ? 'Informe o preço' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: Gaps.md),
                  FormSection(
                    title: 'Estoque',
                    icon: Icons.warehouse_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _estoque,
                              label: 'Atual',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                              validator: (v) => Validators.required(v, 'Estoque'),
                            ),
                          ),
                          const SizedBox(width: Gaps.md),
                          Expanded(
                            child: AppTextField(
                              controller: _minimo,
                              label: 'Mínimo',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
