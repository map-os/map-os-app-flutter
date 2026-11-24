import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/gestao.dart';
import '../../data/repositories/gestao_repository.dart';

const _periodos = [('dia', 'Hoje'), ('semana', 'Semana'), ('mes', 'Este mês'), ('mes_anterior', 'Mês passado'), ('mes_posterior', 'Próximo mês'), ('ano', 'Ano')];

class FinanceiroPage extends StatefulWidget {
  const FinanceiroPage({super.key});

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  String _periodo = 'mes';
  String? _tipo;
  String? _situacao;
  TotaisFinanceiros _totais = const TotaisFinanceiros();
  late Future<ResumoFinanceiro> _resumo = context.read<LancamentosRepository>().resumo();

  late final PagedController<Lancamento> _ctrl = PagedController(
    fetch: (page, search) async {
      final (itens, totais) = await context.read<LancamentosRepository>().list(page: page, search: search, tipo: _tipo, situacao: _situacao, periodo: _periodo);
      if (mounted && page == 0) setState(() => _totais = totais);
      return itens;
    },
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _recarregar() {
    setState(() => _resumo = context.read<LancamentosRepository>().resumo());
    _ctrl.refresh();
  }

  Future<void> _abrir([Lancamento? l]) async {
    final salvou = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => LancamentoFormPage(lancamento: l)));
    if (salvou == true) _recarregar();
  }

  Widget _filtro<T>(String rotulo, T? atual, List<(T?, String)> opcoes, ValueChanged<T?> mudar) => PopupMenuButton<int>(
        onSelected: (i) {
          mudar(opcoes[i].$1);
          _ctrl.refresh();
        },
        itemBuilder: (_) => [for (final (i, o) in opcoes.indexed) CheckedPopupMenuItem(value: i, checked: o.$1 == atual, child: Text(o.$2))],
        tooltip: rotulo,
        child: Chip(
          label: Text(opcoes.firstWhere((o) => o.$1 == atual, orElse: () => opcoes.first).$2),
          avatar: const Icon(Icons.expand_more_rounded, size: 18),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final podeAdicionar = context.watch<AuthState>().permissions.canAdd('Lancamento');
    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro')),
      floatingActionButton: podeAdicionar ? FloatingActionButton.extended(onPressed: _abrir, icon: const Icon(Icons.add_rounded), label: const Text('Lançamento')) : null,
      body: PagedListView<Lancamento>(
        controller: _ctrl,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
          child: ContentWidthScroll(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FutureBuilder<ResumoFinanceiro>(
                  future: _resumo,
                  builder: (context, snap) {
                    final r = snap.data;
                    if (r == null) return const SizedBox.shrink();
                    return Row(
                      children: [
                        Expanded(child: _Valor(rotulo: 'Saldo realizado', valor: r.saldoRealizado, cor: r.saldoRealizado >= 0 ? AppColors.success : AppColors.danger)),
                        const SizedBox(width: Gaps.sm),
                        Expanded(child: _Valor(rotulo: 'A receber', valor: r.aReceber, cor: AppColors.info)),
                        const SizedBox(width: Gaps.sm),
                        Expanded(child: _Valor(rotulo: 'A pagar', valor: r.aPagar, cor: AppColors.warning)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: Gaps.md),
                SearchField(hint: 'Descrição ou cliente/fornecedor', onChanged: _ctrl.setSearch),
                const SizedBox(height: Gaps.sm),
                Wrap(
                  spacing: Gaps.sm,
                  children: [
                    _filtro<String>('Período', _periodo, [for (final p in _periodos) (p.$1, p.$2)], (v) => setState(() => _periodo = v ?? 'mes')),
                    _filtro<String>('Tipo', _tipo, const [(null, 'Receitas e despesas'), ('receita', 'Receitas'), ('despesa', 'Despesas')], (v) => setState(() => _tipo = v)),
                    _filtro<String>('Situação', _situacao, const [(null, 'Todas as situações'), ('pendente', 'Pendentes'), ('pago', 'Pagos'), ('vencido', 'Vencidos')], (v) => setState(() => _situacao = v)),
                  ],
                ),
                const SizedBox(height: Gaps.sm),
                Text(
                  'Receitas ${Fmt.money(_totais.receitas)} · Despesas ${Fmt.money(_totais.despesas)} · Saldo ${Fmt.money(_totais.saldo)}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ),
        empty: (buscando) => const EmptyView(icon: Icons.account_balance_wallet_outlined, title: 'Nenhum lançamento', message: 'Nada neste período com esses filtros.'),
        itemBuilder: (context, l) => _LancamentoCard(lancamento: l, onTap: () => _abrir(l)),
      ),
    );
  }
}

class _Valor extends StatelessWidget {
  const _Valor({required this.rotulo, required this.valor, required this.cor});

  final String rotulo;
  final double valor;
  final Color cor;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(Gaps.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rotulo, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            FittedBox(child: Text(Fmt.money(valor), style: context.text.titleMedium?.copyWith(color: cor, fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

class _LancamentoCard extends StatelessWidget {
  const _LancamentoCard({required this.lancamento, required this.onTap});

  final Lancamento lancamento;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = lancamento;
    final (rotulo, cor) = switch (l.situacao) {
      'pago' => ('Pago', AppColors.success),
      'vencido' => ('Vencido', AppColors.danger),
      _ => ('Pendente', AppColors.warning),
    };
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Gaps.lg),
      child: Row(
        children: [
          IconBadge(l.receita ? Icons.south_west_rounded : Icons.north_east_rounded, color: l.receita ? AppColors.success : AppColors.danger, size: 40),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.descricao, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (l.clienteFornecedor.isNotEmpty) Text(l.clienteFornecedor, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(['vence ${Fmt.date(l.vencimento)}', if (l.formaPagamento.isNotEmpty) l.formaPagamento].join(' · '), style: context.text.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${l.receita ? '' : '- '}${Fmt.money(l.valorLiquido > 0 ? l.valorLiquido : l.valor)}', style: context.text.titleSmall?.copyWith(color: l.receita ? AppColors.success : AppColors.danger)),
              const SizedBox(height: Gaps.xs),
              Text(rotulo, style: context.text.labelSmall?.copyWith(color: cor, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class LancamentoFormPage extends StatefulWidget {
  const LancamentoFormPage({super.key, this.lancamento});

  final Lancamento? lancamento;

  @override
  State<LancamentoFormPage> createState() => _LancamentoFormPageState();
}

class _LancamentoFormPageState extends State<LancamentoFormPage> {
  Lancamento? get _l => widget.lancamento;
  late String _tipo = _l?.tipo ?? 'receita';
  late final _descricao = TextEditingController(text: _l?.descricao ?? '');
  late final _pessoa = TextEditingController(text: _l?.clienteFornecedor ?? '');
  final _pessoaFoco = FocusNode();
  late int? _clienteId = _l?.clienteId;
  late String _nomeDoCliente = _l?.clienteId == null ? '' : _l!.clienteFornecedor;
  late final _valor = TextEditingController(text: _l == null ? '' : _l!.valor.toStringAsFixed(2).replaceAll('.', ','));
  late final _desconto = TextEditingController(text: _l == null || _l!.desconto == 0 ? '' : _l!.desconto.toStringAsFixed(2).replaceAll('.', ','));
  late final _observacoes = TextEditingController(text: _l?.observacoes ?? '');
  final _parcelas = TextEditingController(text: '1');
  late DateTime _vencimento = _l?.vencimento ?? DateTime.now();
  late bool _pago = _l?.pago ?? false;
  late DateTime _dataPagamento = _l?.pagamento ?? DateTime.now();
  late String? _forma = (_l?.formaPagamento ?? '').isEmpty ? null : _l!.formaPagamento;
  bool _salvando = false;
  Map<String, String> _erros = const {};

  @override
  void dispose() {
    for (final c in [_descricao, _pessoa, _valor, _desconto, _observacoes, _parcelas]) {
      c.dispose();
    }
    _pessoaFoco.dispose();
    super.dispose();
  }

  String _decimal(TextEditingController c) => Fmt.parseMoney(c.text).toStringAsFixed(2);

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erros = const {};
    });
    final dados = {
      'tipo': _tipo,
      'descricao': _descricao.text.trim(),
      'cliente_fornecedor': _pessoa.text.trim(),
      'cliente_id': _clienteId,
      'valor': _decimal(_valor),
      'desconto': _decimal(_desconto),
      'data_vencimento': Fmt.apiDate(_vencimento),
      'pago': _pago,
      'data_pagamento': _pago ? Fmt.apiDate(_dataPagamento) : null,
      if (_forma != null) 'forma_pagamento': _forma,
      'observacoes': _observacoes.text.trim(),
      if (_l == null && (int.tryParse(_parcelas.text) ?? 1) > 1) 'parcelas': int.parse(_parcelas.text),
    };
    try {
      final repo = context.read<LancamentosRepository>();
      _l == null ? await repo.create(dados) : await repo.update(_l!.id, dados);
      if (!mounted) return;
      Toast.success(context, 'Lançamento salvo.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erros = e.erros);
      if (mounted && e.erros.isEmpty) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final ok = await confirmDialog(context, title: 'Excluir o lançamento?', message: _l!.descricao, confirmLabel: 'Excluir', destructive: true);
    if (!ok || !mounted) return;
    if (await runAction(context, () => context.read<LancamentosRepository>().delete(_l!.id), success: 'Lançamento excluído.') && mounted) Navigator.pop(context, true);
  }

  Widget _campo(TextEditingController c, String rotulo, String chave, {TextInputType? teclado, int linhas = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: Gaps.md),
        child: TextField(
          controller: c,
          keyboardType: teclado,
          maxLines: linhas,
          textCapitalization: teclado == null ? TextCapitalization.sentences : TextCapitalization.none,
          decoration: InputDecoration(labelText: rotulo, errorText: _erros[chave]),
        ),
      );

  Widget _campoDePessoa(BuildContext context) => RawAutocomplete<({int? clienteId, String nome, String detalhe})>(
        textEditingController: _pessoa,
        focusNode: _pessoaFoco,
        displayStringForOption: (o) => o.nome,
        optionsBuilder: (valor) async {
          if (valor.text.trim().length < 2) return const [];
          try {
            return await context.read<LancamentosRepository>().sugestoes(valor.text);
          } catch (_) {
            return const [];
          }
        },
        onSelected: (o) => setState(() {
          _clienteId = o.clienteId;
          _nomeDoCliente = o.clienteId == null ? '' : o.nome;
        }),
        fieldViewBuilder: (context, controle, foco, enviar) => TextField(
          controller: controle,
          focusNode: foco,
          textCapitalization: TextCapitalization.words,
          onChanged: (texto) {
            if (_clienteId != null && texto != _nomeDoCliente) setState(() => _clienteId = null);
          },
          decoration: InputDecoration(
            labelText: _tipo == 'receita' ? 'Cliente' : 'Fornecedor',
            helperText: _clienteId != null ? 'Cliente cadastrado' : 'Digite para buscar nos clientes ou escreva um nome livre.',
            prefixIcon: Icon(_clienteId != null ? Icons.how_to_reg_rounded : Icons.person_search_outlined),
            errorText: _erros['cliente_fornecedor'] ?? _erros['cliente_id'],
          ),
        ),
        optionsViewBuilder: (context, escolher, opcoes) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(Gaps.radiusSm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 560),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final o in opcoes)
                    ListTile(
                      leading: Icon(o.clienteId != null ? Icons.person_rounded : Icons.history_rounded),
                      title: Text(o.nome),
                      subtitle: o.detalhe.isEmpty ? null : Text(o.detalhe),
                      onTap: () => escolher(o),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final perms = context.watch<AuthState>().permissions;
    final podeSalvar = _l == null ? perms.canAdd('Lancamento') : perms.canEdit('Lancamento');
    final dinheiro = const TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(
        title: Text(_l == null ? 'Novo lançamento' : 'Lançamento #${_l!.id}'),
        actions: [
          if (_l != null && perms.canDelete('Lancamento')) IconButton(tooltip: 'Excluir', icon: const Icon(Icons.delete_outline_rounded), onPressed: _excluir),
        ],
      ),
      bottomNavigationBar: podeSalvar ? BottomActionBar(child: LoadingButton(label: 'Salvar', icon: Icons.check_rounded, loading: _salvando, onPressed: _salvar)) : null,
      body: ListView(
        padding: Gaps.pageOf(context),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'receita', icon: Icon(Icons.south_west_rounded), label: Text('Receita')),
                    ButtonSegment(value: 'despesa', icon: Icon(Icons.north_east_rounded), label: Text('Despesa')),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (s) => setState(() => _tipo = s.first),
                ),
                const SizedBox(height: Gaps.lg),
                _campo(_descricao, 'Descrição', 'descricao'),
                Padding(padding: const EdgeInsets.only(bottom: Gaps.md), child: _campoDePessoa(context)),
                Row(
                  children: [
                    Expanded(child: _campo(_valor, 'Valor (R\$)', 'valor', teclado: dinheiro)),
                    const SizedBox(width: Gaps.md),
                    Expanded(child: _campo(_desconto, 'Desconto (R\$)', 'desconto', teclado: dinheiro)),
                  ],
                ),
                DateField(label: _l == null && (int.tryParse(_parcelas.text) ?? 1) > 1 ? 'Vencimento da 1ª parcela' : 'Vencimento', value: _vencimento, onChanged: (d) => setState(() => _vencimento = d)),
                if (_erros['data_vencimento'] != null) Text(_erros['data_vencimento']!, style: TextStyle(color: context.colors.error)),
                const SizedBox(height: Gaps.md),
                DropdownButtonFormField<String>(
                  initialValue: _forma,
                  decoration: InputDecoration(labelText: 'Forma de pagamento', errorText: _erros['forma_pagamento']),
                  items: [for (final f in formasDeLancamento) DropdownMenuItem(value: f, child: Text(f))],
                  onChanged: (v) => setState(() => _forma = v),
                ),
                if (_l == null) ...[
                  const SizedBox(height: Gaps.md),
                  TextField(
                    controller: _parcelas,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: 'Parcelas', helperText: 'Mais de uma cria um lançamento por mês.', errorText: _erros['parcelas']),
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_tipo == 'receita' ? 'Recebido' : 'Pago'),
                  value: _pago,
                  onChanged: (v) => setState(() => _pago = v),
                ),
                if (_pago) ...[
                  DateField(label: 'Data do pagamento', value: _dataPagamento, onChanged: (d) => setState(() => _dataPagamento = d)),
                  if (_erros['data_pagamento'] != null) Text(_erros['data_pagamento']!, style: TextStyle(color: context.colors.error)),
                  const SizedBox(height: Gaps.md),
                ],
                _campo(_observacoes, 'Observações', 'observacoes', linhas: 3),
                if (_l?.vendaId != null) Text('Gerado pela venda #${_l!.vendaId}.', style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
