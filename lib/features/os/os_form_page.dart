import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/ui.dart';
import '../../data/models/catalogo.dart';
import '../../data/models/conta.dart';
import '../../data/models/ordem_servico.dart';
import '../../data/repositories/cadastros_repository.dart';
import '../../data/repositories/os_repository.dart';

/// Cria ou edita uma OS. Retorna o id da OS salva.
class OsFormPage extends StatefulWidget {
  const OsFormPage({super.key, this.os, this.clienteId, this.clienteNome});

  final OrdemServico? os;

  /// Pré-seleciona o cliente numa OS nova (ex.: aberta pela tela do cliente).
  final int? clienteId;
  final String? clienteNome;

  @override
  State<OsFormPage> createState() => _OsFormPageState();
}

class _OsFormPageState extends State<OsFormPage> {
  final _form = GlobalKey<FormState>();
  late final OrdemServico? _os = widget.os;

  late int? _clienteId = _os?.clienteId ?? widget.clienteId;
  late String _clienteNome = _os?.nomeCliente ?? widget.clienteNome ?? '';
  late int? _usuarioId = (_os?.usuarioId ?? 0) > 0 ? _os!.usuarioId : null;
  late String _usuarioNome = _os?.responsavel ?? '';
  late String _status = _os?.status.isNotEmpty == true ? _os!.status : 'Aberto';
  late DateTime _inicio = _os?.dataInicial ?? DateTime.now();
  late DateTime _fim = _os?.dataFinal ?? DateTime.now().add(const Duration(days: 1));

  late final _descricao = TextEditingController(text: Fmt.plain(_os?.descricaoProduto));
  late final _defeito = TextEditingController(text: Fmt.plain(_os?.defeito));
  late final _observacoes = TextEditingController(text: Fmt.plain(_os?.observacoes));
  late final _laudo = TextEditingController(text: Fmt.plain(_os?.laudoTecnico));
  late final _garantia = TextEditingController(text: _os?.garantia);
  late int? _termoId = _os?.termoGarantiaId;
  late String _termoNome = _os?.termoGarantia ?? '';

  bool _saving = false;
  bool _submitted = false;

  bool get _editing => _os != null;

  @override
  void initState() {
    super.initState();
    if (_usuarioId == null) _preselectUsuario();
  }

  /// Em uma OS nova, sugere o primeiro técnico se só houver um.
  Future<void> _preselectUsuario() async {
    try {
      final users = await context.read<ContaRepository>().usuarios();
      if (mounted && users.length == 1 && _usuarioId == null) {
        setState(() {
          _usuarioId = users.first.id;
          _usuarioNome = users.first.nome;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [_descricao, _defeito, _observacoes, _laudo, _garantia]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCliente() async {
    final repo = context.read<ClientesRepository>();
    final c = await showSearchPicker<Sugestao>(
      context,
      title: 'Selecionar cliente',
      hint: 'Buscar por nome, telefone ou documento',
      fetch: repo.sugestoes,
      itemBuilder: (context, c) => ListTile(
        leading: InitialsAvatar(c.nome, size: 38),
        title: Text(c.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: c.detalhe.isEmpty ? null : Text(c.detalhe),
      ),
    );
    if (c != null) {
      setState(() {
        _clienteId = c.id;
        _clienteNome = c.nome;
      });
    }
  }

  Future<void> _pickTermo() async {
    final repo = context.read<OsRepository>();
    final t = await showSearchPicker<Sugestao>(
      context,
      title: 'Termo de garantia',
      hint: 'Buscar termo',
      fetch: repo.termosDeGarantia,
      itemBuilder: (context, t) => ListTile(leading: const Icon(Icons.verified_user_outlined), title: Text(t.nome)),
    );
    if (t != null) {
      setState(() {
        _termoId = t.id;
        _termoNome = t.nome;
      });
    }
  }

  Future<void> _pickUsuario() async {
    final repo = context.read<ContaRepository>();
    final u = await showSearchPicker<Usuario>(
      context,
      title: 'Selecionar técnico',
      hint: 'Buscar técnico',
      fetch: (s) => repo.usuarios(search: s),
      itemBuilder: (context, u) => ListTile(
        leading: InitialsAvatar(u.nome, size: 38, imageUrl: u.fotoUrl),
        title: Text(u.nome),
        subtitle: u.telefone.isEmpty ? null : Text(u.telefone),
      ),
    );
    if (u != null) {
      setState(() {
        _usuarioId = u.id;
        _usuarioNome = u.nome;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final valid = _form.currentState!.validate();
    if (!valid || _clienteId == null || _usuarioId == null) return;
    if (_fim.isBefore(_inicio)) {
      Toast.error(context, 'A data final não pode ser anterior à inicial.');
      return;
    }
    setState(() => _saving = true);
    final input = OsInput(
      clienteId: _clienteId!,
      usuarioId: _usuarioId!,
      status: _status,
      dataInicial: _inicio,
      dataFinal: _fim,
      descricaoProduto: _descricao.text.trim(),
      defeito: _defeito.text.trim(),
      observacoes: _observacoes.text.trim(),
      laudoTecnico: _laudo.text.trim(),
      garantia: _garantia.text.trim(),
      termoGarantiaId: _termoId,
    );
    final repo = context.read<OsRepository>();
    try {
      final int id;
      if (_editing) {
        await repo.update(_os!.id, input);
        id = _os.id;
      } else {
        id = await repo.create(input);
      }
      if (!mounted) return;
      Toast.success(context, _editing ? 'OS atualizada.' : 'OS #$id criada.');
      Navigator.pop(context, id);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Editar OS #${_os!.id}' : 'Nova ordem de serviço')),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: _editing ? 'Salvar alterações' : 'Criar OS',
          icon: Icons.check_rounded,
          loading: _saving,
          onPressed: _save,
        ),
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
                    title: 'Atendimento',
                    icon: Icons.assignment_ind_outlined,
                    children: [
                      PickerField(
                        label: 'Cliente',
                        icon: Icons.person_outline_rounded,
                        value: _clienteNome,
                        onTap: _pickCliente,
                        errorText: _submitted && _clienteId == null ? 'Selecione o cliente' : null,
                      ),
                      PickerField(
                        label: 'Técnico responsável',
                        icon: Icons.engineering_outlined,
                        value: _usuarioNome,
                        onTap: _pickUsuario,
                        errorText: _submitted && _usuarioId == null ? 'Selecione o técnico' : null,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: StatusColors.all.contains(_status) ? _status : null,
                        decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.flag_outlined)),
                        items: [
                          for (final s in StatusColors.all)
                            DropdownMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Icon(StatusColors.icon(s), size: 18, color: StatusColors.of(s)),
                                  const SizedBox(width: Gaps.sm),
                                  Text(s),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _status = v ?? _status),
                      ),
                      Row(
                        children: [
                          Expanded(child: DateField(label: 'Início', value: _inicio, onChanged: (d) => setState(() => _inicio = d))),
                          const SizedBox(width: Gaps.md),
                          Expanded(child: DateField(label: 'Previsão', value: _fim, onChanged: (d) => setState(() => _fim = d))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: Gaps.md),
                  FormSection(
                    title: 'Equipamento e problema',
                    icon: Icons.build_circle_outlined,
                    children: [
                      AppTextField(
                        controller: _descricao,
                        label: 'Descrição do produto/equipamento',
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      AppTextField(
                        controller: _defeito,
                        label: 'Defeito relatado',
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      AppTextField(
                        controller: _observacoes,
                        label: 'Observações',
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                  if (_editing) ...[
                    const SizedBox(height: Gaps.md),
                    FormSection(
                      title: 'Conclusão',
                      icon: Icons.fact_check_outlined,
                      children: [
                        AppTextField(
                          controller: _laudo,
                          label: 'Laudo técnico',
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        AppTextField(controller: _garantia, label: 'Garantia (dias)', icon: Icons.verified_user_outlined, keyboardType: TextInputType.number),
                        PickerField(
                          label: 'Termo de garantia',
                          icon: Icons.gavel_outlined,
                          value: _termoNome,
                          onTap: _pickTermo,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
