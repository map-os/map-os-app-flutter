import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_state.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/gestao.dart';
import '../../data/repositories/gestao_repository.dart';

typedef _Linha = Map<String, dynamic>;

String _t(_Linha l, String k) => (l[k] ?? '').toString();
String _dinheiro(_Linha l, String k) => Fmt.money(double.tryParse(_t(l, k)) ?? 0);
String _data(_Linha l, String k) => Fmt.date(DateTime.tryParse(_t(l, k)));

class TipoDeRelatorio {
  const TipoDeRelatorio({
    required this.id,
    required this.titulo,
    required this.icone,
    required this.cor,
    required this.permissao,
    required this.titulo1,
    required this.detalhe,
    this.valor,
    this.porPeriodo = true,
  });

  final String id;
  final String titulo;
  final IconData icone;
  final Color cor;
  final String permissao;
  final String Function(_Linha) titulo1;
  final String Function(_Linha) detalhe;
  final String Function(_Linha)? valor;
  final bool porPeriodo;
}

final tiposDeRelatorio = <TipoDeRelatorio>[
  TipoDeRelatorio(
    id: 'os',
    titulo: 'Ordens de serviço',
    icone: Icons.assignment_outlined,
    cor: AppColors.os,
    permissao: 'rOs',
    titulo1: (l) => 'OS #${_t(l, 'id_os')} · ${_t(l, 'nome_cliente')}',
    detalhe: (l) => '${_t(l, 'status')} · ${_data(l, 'data_inicial')}',
    valor: (l) => _dinheiro(l, 'valor_total'),
  ),
  TipoDeRelatorio(
    id: 'vendas',
    titulo: 'Vendas',
    icone: Icons.point_of_sale_outlined,
    cor: AppColors.vendas,
    permissao: 'rVenda',
    titulo1: (l) => 'Venda #${_t(l, 'id_vendas')} · ${_t(l, 'nome_cliente')}',
    detalhe: (l) => [_data(l, 'data_venda'), _t(l, 'nome')].where((s) => s.isNotEmpty).join(' · '),
    valor: (l) => _dinheiro(l, 'valor_total'),
  ),
  TipoDeRelatorio(
    id: 'financeiro',
    titulo: 'Financeiro',
    icone: Icons.account_balance_wallet_outlined,
    cor: AppColors.success,
    permissao: 'rFinanceiro',
    titulo1: (l) => _t(l, 'descricao'),
    detalhe: (l) => [
      _t(l, 'tipo') == 'receita' ? 'Receita' : 'Despesa',
      _t(l, 'cliente_fornecedor'),
      'vence ${_data(l, 'data_vencimento')}',
      _t(l, 'baixado') == '1' ? 'pago' : 'pendente',
    ].where((s) => s.isNotEmpty).join(' · '),
    valor: (l) => _dinheiro(l, 'valor'),
  ),
  TipoDeRelatorio(
    id: 'clientes',
    titulo: 'Clientes',
    icone: Icons.people_outline_rounded,
    cor: AppColors.clientes,
    permissao: 'rCliente',
    titulo1: (l) => _t(l, 'nome_cliente'),
    detalhe: (l) => [_t(l, 'documento'), _t(l, 'celular').isEmpty ? _t(l, 'telefone') : _t(l, 'celular'), _t(l, 'email')].where((s) => s.isNotEmpty).join(' · '),
  ),
  TipoDeRelatorio(
    id: 'produtos',
    titulo: 'Produtos e estoque',
    icone: Icons.inventory_2_outlined,
    cor: AppColors.produtos,
    permissao: 'rProduto',
    porPeriodo: false,
    titulo1: (l) => _t(l, 'descricao'),
    detalhe: (l) => 'Estoque ${_t(l, 'estoque')} (mínimo ${_t(l, 'estoque_minimo')}) · ${_dinheiro(l, 'valor_estoque')} em estoque',
    valor: (l) => _dinheiro(l, 'preco_venda'),
  ),
  TipoDeRelatorio(
    id: 'servicos',
    titulo: 'Serviços',
    icone: Icons.handyman_outlined,
    cor: AppColors.servicos,
    permissao: 'rServico',
    porPeriodo: false,
    titulo1: (l) => _t(l, 'nome'),
    detalhe: (l) => Fmt.plain(_t(l, 'descricao')),
    valor: (l) => _dinheiro(l, 'preco'),
  ),
  TipoDeRelatorio(
    id: 'sku',
    titulo: 'Produtos vendidos por cliente',
    icone: Icons.qr_code_rounded,
    cor: AppColors.garantias,
    permissao: 'rProduto',
    titulo1: (l) => '${_t(l, 'descricao')} × ${_t(l, 'quantidade')}',
    detalhe: (l) => '${_t(l, 'nome_cliente')} · ${_t(l, 'origem') == 'os' ? 'OS' : 'Venda'} #${_t(l, 'id_relacionado')} · ${_data(l, 'data_ocorrencia')}',
    valor: (l) => _dinheiro(l, 'preco_total'),
  ),
];

class RelatoriosPage extends StatelessWidget {
  const RelatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final perms = context.watch<AuthState>().permissions;
    final tipos = tiposDeRelatorio.where((t) => perms.can(t.permissao)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: tipos.isEmpty
          ? const EmptyView(icon: Icons.lock_outline_rounded, title: 'Sem acesso a relatórios', message: 'Peça ao administrador a permissão de relatórios.')
          : ListView(
              padding: Gaps.pageOf(context),
              children: [
                ContentWidth(
                  child: Column(
                    children: [
                      for (final t in tipos) ...[
                        AppCard(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _RelatorioPage(tipo: t))),
                          padding: const EdgeInsets.all(Gaps.lg),
                          child: Row(
                            children: [
                              IconBadge(t.icone, color: t.cor, size: 40),
                              const SizedBox(width: Gaps.md),
                              Expanded(child: Text(t.titulo, style: context.text.titleSmall)),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                        const SizedBox(height: Gaps.sm),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _RelatorioPage extends StatefulWidget {
  const _RelatorioPage({required this.tipo});

  final TipoDeRelatorio tipo;

  @override
  State<_RelatorioPage> createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<_RelatorioPage> {
  late DateTimeRange _periodo = DateTimeRange(start: DateTime(DateTime.now().year, DateTime.now().month), end: DateTime.now());
  bool _estoqueBaixo = false;
  late Future<Relatorio> _relatorio = _gerar();

  Map<String, dynamic> get _filtros => {
        if (widget.tipo.porPeriodo) 'de': Fmt.apiDate(_periodo.start),
        if (widget.tipo.porPeriodo) 'ate': Fmt.apiDate(_periodo.end),
        if (widget.tipo.id == 'produtos' && _estoqueBaixo) 'estoque_baixo': 'true',
      };

  Future<Relatorio> _gerar() => context.read<RelatoriosRepository>().gerar(widget.tipo.id, _filtros);

  void _atualizar() => setState(() => _relatorio = _gerar());

  Future<void> _escolherPeriodo() async {
    final p = await showDateRangePicker(context: context, firstDate: DateTime(2015), lastDate: DateTime.now().add(const Duration(days: 365)), initialDateRange: _periodo);
    if (p != null) {
      _periodo = p;
      _atualizar();
    }
  }

  Future<void> _exportar(String formato) async {
    final bytes = await runWithProgress(context, () => context.read<RelatoriosRepository>().exportar(widget.tipo.id, _filtros, formato));
    if (bytes == null) return;
    final nome = 'relatorio-${widget.tipo.id}-${Fmt.apiDate(DateTime.now())}.$formato';
    final mime = formato == 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: nome, mimeType: mime)], fileNameOverrides: [nome], subject: widget.tipo.titulo));
  }

  String _rotulo(String chave) {
    final s = chave.replaceAll('_', ' ');
    return s[0].toUpperCase() + s.substring(1);
  }

  String _valorDoTotal(String chave, dynamic v) => chave == 'quantidade' ? '$v' : Fmt.money(double.tryParse('$v') ?? 0);

  @override
  Widget build(BuildContext context) {
    final t = widget.tipo;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.titulo),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Exportar',
            icon: const Icon(Icons.ios_share_rounded),
            onSelected: _exportar,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
              PopupMenuItem(value: 'xlsx', child: Text('Exportar planilha (XLSX)')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _atualizar(),
        child: FutureBuilder<Relatorio>(
          future: _relatorio,
          builder: (context, snap) {
            final r = snap.data;
            return ListView(
              padding: Gaps.pageOf(context),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (t.porPeriodo)
                        OutlinedButton.icon(
                          onPressed: _escolherPeriodo,
                          icon: const Icon(Icons.date_range_rounded),
                          label: Text('${Fmt.date(_periodo.start)} a ${Fmt.date(_periodo.end)}'),
                        ),
                      if (t.id == 'produtos')
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Só estoque baixo'),
                          value: _estoqueBaixo,
                          onChanged: (v) {
                            _estoqueBaixo = v;
                            _atualizar();
                          },
                        ),
                      const SizedBox(height: Gaps.md),
                      if (snap.hasError)
                        ErrorView(error: snap.error!, onRetry: _atualizar)
                      else if (r == null)
                        const Padding(padding: EdgeInsets.all(Gaps.xl), child: Center(child: CircularProgressIndicator()))
                      else ...[
                        AppCard(
                          padding: const EdgeInsets.all(Gaps.lg),
                          child: Wrap(
                            spacing: Gaps.xl,
                            runSpacing: Gaps.md,
                            children: [
                              _Total(rotulo: 'Registros', valor: '${r.linhas.length}'),
                              for (final e in r.totais.entries.where((e) => e.key != 'quantidade')) _Total(rotulo: _rotulo(e.key), valor: _valorDoTotal(e.key, e.value)),
                            ],
                          ),
                        ),
                        const SizedBox(height: Gaps.md),
                        if (r.linhas.isEmpty)
                          const EmptyView(icon: Icons.insights_outlined, title: 'Nada neste filtro', message: 'Mude o período ou os filtros.')
                        else
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (final (i, l) in r.linhas.indexed) ...[
                                  if (i > 0) const Divider(height: 1),
                                  ListTile(
                                    title: Text(t.titulo1(l), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text(t.detalhe(l), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    trailing: t.valor == null ? null : Text(t.valor!(l), style: context.text.titleSmall),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [Text(rotulo, style: context.text.bodySmall), Text(valor, style: context.text.titleMedium)],
      );
}
