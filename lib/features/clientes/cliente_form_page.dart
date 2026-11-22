import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/input_masks.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/cliente.dart';
import '../../data/repositories/cadastros_repository.dart';

/// Formulário de criação/edição de cliente. Retorna `true` ao salvar.
class ClienteFormPage extends StatefulWidget {
  const ClienteFormPage({super.key, this.cliente});

  final Cliente? cliente;

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final _form = GlobalKey<FormState>();
  late final Cliente? _c = widget.cliente;
  late final _nome = TextEditingController(text: _c?.nome);
  late final _documento = TextEditingController(text: _c?.documento);
  late final _celular = TextEditingController(text: _c?.celular);
  late final _telefone = TextEditingController(text: _c?.telefone);
  late final _email = TextEditingController(text: _c?.email);
  late final _contato = TextEditingController(text: _c?.contato);
  late final _cep = TextEditingController(text: _c?.cep);
  late final _rua = TextEditingController(text: _c?.rua);
  late final _numero = TextEditingController(text: _c?.numero);
  late final _complemento = TextEditingController(text: _c?.complemento);
  late final _bairro = TextEditingController(text: _c?.bairro);
  late final _cidade = TextEditingController(text: _c?.cidade);
  late final _estado = TextEditingController(text: _c?.estado);
  late final _senha = TextEditingController();
  late bool _pessoaFisica = _c?.pessoaFisica ?? true;
  late bool _fornecedor = _c?.fornecedor ?? false;
  bool _saving = false;
  bool _loadingCep = false;

  bool get _editing => _c != null;

  @override
  void dispose() {
    for (final c in [_nome, _documento, _celular, _telefone, _email, _contato, _cep, _rua, _numero, _complemento, _bairro, _cidade, _estado, _senha]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _buscarCep() async {
    setState(() => _loadingCep = true);
    final r = await context.read<ClientesRepository>().buscarCep(_cep.text);
    if (!mounted) return;
    setState(() => _loadingCep = false);
    if (r == null) {
      Toast.error(context, 'CEP não encontrado.');
      return;
    }
    _rua.text = '${r['logradouro'] ?? ''}';
    _bairro.text = '${r['bairro'] ?? ''}';
    _cidade.text = '${r['localidade'] ?? ''}';
    _estado.text = '${r['uf'] ?? ''}';
    if (_complemento.text.isEmpty) _complemento.text = '${r['complemento'] ?? ''}';
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final cliente = Cliente(
      id: _c?.id ?? 0,
      nome: _nome.text.trim(),
      pessoaFisica: _pessoaFisica,
      documento: _documento.text.trim(),
      celular: _celular.text.trim(),
      telefone: _telefone.text.trim(),
      email: _email.text.trim(),
      contato: _contato.text.trim(),
      cep: _cep.text.trim(),
      rua: _rua.text.trim(),
      numero: _numero.text.trim(),
      complemento: _complemento.text.trim(),
      bairro: _bairro.text.trim(),
      cidade: _cidade.text.trim(),
      estado: _estado.text.trim().toUpperCase(),
      fornecedor: _fornecedor,
    );
    final repo = context.read<ClientesRepository>();
    try {
      if (_editing) {
        await repo.update(cliente, senha: _senha.text);
      } else {
        await repo.create(cliente, senha: _senha.text);
      }
      if (!mounted) return;
      Toast.success(context, _editing ? 'Cliente atualizado.' : 'Cliente cadastrado.');
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
      appBar: AppBar(title: Text(_editing ? 'Editar cliente' : 'Novo cliente')),
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
                    title: 'Identificação',
                    icon: Icons.badge_outlined,
                    children: [
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: true, label: Text('Pessoa física')),
                          ButtonSegment(value: false, label: Text('Pessoa jurídica')),
                        ],
                        selected: {_pessoaFisica},
                        onSelectionChanged: (s) => setState(() => _pessoaFisica = s.first),
                      ),
                      AppTextField(
                        controller: _nome,
                        label: _pessoaFisica ? 'Nome completo' : 'Razão social',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => Validators.required(v, 'Nome'),
                      ),
                      AppTextField(
                        controller: _documento,
                        label: _pessoaFisica ? 'CPF' : 'CNPJ',
                        icon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [PatternMask.cpfCnpj()],
                      ),
                      SwitchListTile(
                        value: _fornecedor,
                        onChanged: (v) => setState(() => _fornecedor = v),
                        title: const Text('Também é fornecedor'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: Gaps.md),
                  FormSection(
                    title: 'Contato',
                    icon: Icons.contact_phone_outlined,
                    children: [
                      AppTextField(
                        controller: _celular,
                        label: 'Celular',
                        icon: Icons.smartphone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PatternMask.phone()],
                      ),
                      AppTextField(
                        controller: _telefone,
                        label: 'Telefone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PatternMask.phone()],
                      ),
                      AppTextField(
                        controller: _email,
                        label: 'E-mail',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      AppTextField(controller: _contato, label: 'Pessoa de contato', icon: Icons.person_pin_outlined),
                    ],
                  ),
                  const SizedBox(height: Gaps.md),
                  FormSection(
                    title: 'Endereço',
                    icon: Icons.location_on_outlined,
                    children: [
                      AppTextField(
                        controller: _cep,
                        label: 'CEP',
                        icon: Icons.markunread_mailbox_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [PatternMask.cep()],
                        onChanged: (v) {
                          if (Fmt.onlyDigits(v).length == 8) _buscarCep();
                        },
                        suffix: _loadingCep
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : IconButton(tooltip: 'Buscar CEP', icon: const Icon(Icons.search_rounded), onPressed: _buscarCep),
                      ),
                      AppTextField(controller: _rua, label: 'Rua', icon: Icons.signpost_outlined),
                      Row(
                        children: [
                          Expanded(flex: 2, child: AppTextField(controller: _numero, label: 'Número')),
                          const SizedBox(width: Gaps.md),
                          Expanded(flex: 3, child: AppTextField(controller: _complemento, label: 'Complemento')),
                        ],
                      ),
                      AppTextField(controller: _bairro, label: 'Bairro'),
                      Row(
                        children: [
                          Expanded(flex: 4, child: AppTextField(controller: _cidade, label: 'Cidade')),
                          const SizedBox(width: Gaps.md),
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              controller: _estado,
                              label: 'UF',
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: Gaps.md),
                  FormSection(
                    title: 'Área do cliente',
                    icon: Icons.lock_outline_rounded,
                    children: [
                      AppTextField(
                        controller: _senha,
                        label: _editing ? 'Nova senha (opcional)' : 'Senha de acesso (opcional)',
                        icon: Icons.key_outlined,
                        obscure: true,
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
