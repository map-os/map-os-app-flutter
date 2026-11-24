import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/admin.dart';
import '../../data/repositories/admin_repository.dart';

const _icones = {
  'geral': Icons.tune_rounded,
  'os': Icons.assignment_outlined,
  'vendas': Icons.point_of_sale_outlined,
  'financeiro': Icons.account_balance_wallet_outlined,
  'email': Icons.mail_outline_rounded,
  'pagamentos': Icons.payments_outlined,
  'api': Icons.api_rounded,
};

class ConfiguracoesDoSistemaPage extends StatefulWidget {
  const ConfiguracoesDoSistemaPage({super.key});

  @override
  State<ConfiguracoesDoSistemaPage> createState() => _ConfiguracoesDoSistemaPageState();
}

class _ConfiguracoesDoSistemaPageState extends State<ConfiguracoesDoSistemaPage> {
  late Future<List<AbaDeConfiguracao>> _abas = context.read<AdminRepository>().configuracoes();

  void _recarregar() => setState(() => _abas = context.read<AdminRepository>().configuracoes());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Configurações do sistema')),
        body: AsyncView<List<AbaDeConfiguracao>>(
          future: _abas,
          onRetry: _recarregar,
          builder: (context, abas) => ListView(
            padding: Gaps.pageOf(context),
            children: [
              ContentWidth(
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, a) in abas.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          leading: Icon(_icones[a.id] ?? Icons.settings_outlined),
                          title: Text(a.nome),
                          subtitle: Text('${a.campos.length} opções'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            final salvou = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => _AbaPage(aba: a)));
                            if (salvou == true) _recarregar();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _AbaPage extends StatefulWidget {
  const _AbaPage({required this.aba});

  final AbaDeConfiguracao aba;

  @override
  State<_AbaPage> createState() => _AbaPageState();
}

class _AbaPageState extends State<_AbaPage> {
  final _valores = <String, dynamic>{};
  final _textos = <String, TextEditingController>{};
  final _alterados = <String>{};
  bool _salvando = false;
  Map<String, String> _erros = const {};

  @override
  void initState() {
    super.initState();
    for (final c in widget.aba.campos) {
      switch (c.tipo) {
        case 'texto' || 'area' || 'numero' || 'segredo':
          _textos[c.chave] = TextEditingController(text: c.tipo == 'segredo' ? '' : '${c.valor ?? ''}');
        case 'status':
          _valores[c.chave] = <String>{...(c.valor as List? ?? const []).map((e) => e.toString())};
        case 'sim_nao' || 'bool_env' || 'gerar_jwt':
          _valores[c.chave] = c.valor == true;
        default:
          _valores[c.chave] = c.valor?.toString();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _textos.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _mudar(String chave, dynamic valor) => setState(() {
        _valores[chave] = valor;
        _alterados.add(chave);
      });

  Future<void> _salvar() async {
    final envio = <String, dynamic>{
      for (final chave in _alterados)
        chave: _textos.containsKey(chave) ? _textos[chave]!.text : (_valores[chave] is Set ? (_valores[chave] as Set).toList() : _valores[chave]),
    };
    if (envio.isEmpty) {
      Navigator.pop(context, false);
      return;
    }
    if (envio['API_JWT_KEY'] == true) {
      final ok = await confirmDialog(context, title: 'Gerar uma chave nova?', message: 'Todos os aparelhos saem da conta, inclusive este. Você vai precisar entrar de novo.', confirmLabel: 'Gerar chave', destructive: true);
      if (!ok) return;
    }
    if (envio['API_ENABLED'] == false) {
      if (!mounted) return;
      final ok = await confirmDialog(context, title: 'Desligar a API?', message: 'O aplicativo para de funcionar para todos, inclusive aqui. Só dá para ligar de novo pelo painel web.', confirmLabel: 'Desligar', destructive: true);
      if (!ok) return;
    }
    setState(() {
      _salvando = true;
      _erros = const {};
    });
    try {
      if (!mounted) return;
      await context.read<AdminRepository>().salvarConfiguracoes(widget.aba.id, envio);
      if (!mounted) return;
      Toast.success(context, 'Configurações salvas.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erros = e.erros);
      if (mounted && e.erros.isEmpty) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _campo(CampoDeConfiguracao c) {
    final erro = _erros[c.chave];
    final ajuda = c.ajuda.isEmpty ? null : c.ajuda;
    switch (c.tipo) {
      case 'sim_nao' || 'bool_env':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(c.rotulo),
          subtitle: erro != null ? Text(erro, style: TextStyle(color: context.colors.error)) : (ajuda == null ? null : Text(ajuda)),
          value: _valores[c.chave] == true,
          onChanged: (v) => _mudar(c.chave, v),
        );
      case 'gerar_jwt':
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(c.rotulo),
          subtitle: ajuda == null ? null : Text(ajuda),
          value: _valores[c.chave] == true,
          onChanged: (v) => _mudar(c.chave, v == true),
        );
      case 'status':
        final marcados = _valores[c.chave] as Set<String>;
        return Padding(
          padding: const EdgeInsets.only(bottom: Gaps.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.rotulo, style: context.text.titleSmall),
              if (ajuda != null) Text(ajuda, style: context.text.bodySmall),
              const SizedBox(height: Gaps.sm),
              Wrap(
                spacing: Gaps.sm,
                runSpacing: Gaps.xs,
                children: [
                  for (final (valor, nome) in c.opcoes)
                    FilterChip(
                      label: Text(nome),
                      selected: marcados.contains(valor),
                      onSelected: (v) => _mudar(c.chave, {...marcados}..removeWhere((e) => !v && e == valor)..addAll(v ? [valor] : const [])),
                    ),
                ],
              ),
              if (erro != null) Text(erro, style: TextStyle(color: context.colors.error)),
            ],
          ),
        );
      case 'opcao':
        return Padding(
          padding: const EdgeInsets.only(bottom: Gaps.md),
          child: DropdownButtonFormField<String>(
            initialValue: c.opcoes.any((o) => o.$1 == _valores[c.chave]) ? _valores[c.chave] as String : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: c.rotulo, helperText: ajuda, helperMaxLines: 3, errorText: erro),
            items: [for (final (valor, nome) in c.opcoes) DropdownMenuItem(value: valor, child: Text(nome, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => _mudar(c.chave, v),
          ),
        );
      default:
        final segredo = c.tipo == 'segredo';
        return Padding(
          padding: const EdgeInsets.only(bottom: Gaps.md),
          child: TextField(
            controller: _textos[c.chave],
            obscureText: segredo,
            keyboardType: c.tipo == 'numero' ? TextInputType.number : null,
            minLines: c.tipo == 'area' ? 3 : 1,
            maxLines: c.tipo == 'area' ? 8 : 1,
            onChanged: (_) => _alterados.add(c.chave),
            decoration: InputDecoration(
              labelText: c.rotulo,
              hintText: segredo && c.segredoDefinido ? '•••••••• (definido)' : null,
              helperText: segredo ? (c.segredoDefinido ? 'Deixe em branco para manter o atual.' : 'Ainda não definido.') : ajuda,
              helperMaxLines: 3,
              errorText: erro,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupos = <String, List<CampoDeConfiguracao>>{};
    for (final c in widget.aba.campos) {
      grupos.putIfAbsent(c.grupo, () => []).add(c);
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.aba.nome)),
      bottomNavigationBar: BottomActionBar(child: LoadingButton(label: 'Salvar', icon: Icons.check_rounded, loading: _salvando, onPressed: _salvar)),
      body: ListView(
        padding: Gaps.pageOf(context),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final g in grupos.entries) ...[
                  if (g.key.isNotEmpty) SectionHeader(g.key),
                  for (final c in g.value) _campo(c),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
