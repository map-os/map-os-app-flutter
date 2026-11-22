import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/input_masks.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/catalogo.dart';
import '../../data/repositories/cadastros_repository.dart';

class ServicoFormPage extends StatefulWidget {
  const ServicoFormPage({super.key, this.servico});

  final Servico? servico;

  @override
  State<ServicoFormPage> createState() => _ServicoFormPageState();
}

class _ServicoFormPageState extends State<ServicoFormPage> {
  final _form = GlobalKey<FormState>();
  late final Servico? _s = widget.servico;
  late final _nome = TextEditingController(text: _s?.nome);
  late final _descricao = TextEditingController(text: _s?.descricao);
  late final _preco = TextEditingController(text: MoneyMask.format(_s?.preco ?? 0));
  bool _saving = false;

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _preco.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final s = Servico(
      id: _s?.id ?? 0,
      nome: _nome.text.trim(),
      descricao: _descricao.text.trim(),
      preco: Fmt.parseMoney(_preco.text),
    );
    final repo = context.read<ServicosRepository>();
    try {
      _s == null ? await repo.create(s) : await repo.update(s);
      if (!mounted) return;
      Toast.success(context, _s == null ? 'Serviço cadastrado.' : 'Serviço atualizado.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_s == null ? 'Novo serviço' : 'Editar serviço')),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(label: 'Salvar', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: Gaps.pageOf(context),
          children: [
            ContentWidth(
              child: FormSection(
                title: 'Serviço',
                icon: Icons.handyman_outlined,
                children: [
                  AppTextField(
                    controller: _nome,
                    label: 'Nome',
                    icon: Icons.label_outline_rounded,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => Validators.required(v, 'Nome'),
                  ),
                  AppTextField(
                    controller: _preco,
                    label: 'Preço',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [MoneyMask()],
                    validator: (v) => Fmt.parseMoney(v ?? '') <= 0 ? 'Informe o preço' : null,
                  ),
                  AppTextField(
                    controller: _descricao,
                    label: 'Descrição',
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
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
