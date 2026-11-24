import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/input_masks.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/conta.dart';
import '../../data/repositories/cadastros_repository.dart';

class TrocarSenhaPage extends StatefulWidget {
  const TrocarSenhaPage({super.key});

  @override
  State<TrocarSenhaPage> createState() => _TrocarSenhaPageState();
}

class _TrocarSenhaPageState extends State<TrocarSenhaPage> {
  final _form = GlobalKey<FormState>();
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _salvando = false;
  Map<String, String> _erros = const {};

  @override
  void dispose() {
    for (final c in [_atual, _nova, _confirmacao]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erros = const {};
    });
    try {
      await context.read<ContaRepository>().trocarSenha(_atual.text, _nova.text);
      if (!mounted) return;
      Toast.success(context, 'Senha alterada. As outras sessões da conta foram encerradas.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erros = e.erros);
      if (mounted && e.erros.isEmpty) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trocar senha')),
      bottomNavigationBar: BottomActionBar(child: LoadingButton(label: 'Salvar', icon: Icons.check_rounded, loading: _salvando, onPressed: _salvar)),
      body: Form(
        key: _form,
        child: ListView(
          padding: Gaps.pageOf(context),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(controller: _atual, label: 'Senha atual', icon: Icons.lock_outline_rounded, obscure: true, validator: (v) => Validators.required(v, 'Senha atual')),
                  if (_erros['senha_atual'] != null) _erro(_erros['senha_atual']!),
                  const SizedBox(height: Gaps.md),
                  AppTextField(
                    controller: _nova,
                    label: 'Nova senha',
                    icon: Icons.password_rounded,
                    obscure: true,
                    validator: (v) => (v ?? '').length < 8 ? 'Use pelo menos 8 caracteres.' : null,
                  ),
                  if (_erros['nova_senha'] != null) _erro(_erros['nova_senha']!),
                  const SizedBox(height: Gaps.md),
                  AppTextField(
                    controller: _confirmacao,
                    label: 'Repita a nova senha',
                    icon: Icons.password_rounded,
                    obscure: true,
                    validator: (v) => v != _nova.text ? 'As senhas não conferem.' : null,
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

Widget _erro(String texto) => Padding(
      padding: const EdgeInsets.only(top: Gaps.xs),
      child: Text(texto, style: const TextStyle(color: AppColors.danger)),
    );

Future<String?> pedirSenha(BuildContext context, {required String titulo, String? mensagem}) async {
  final controle = TextEditingController();
  final senha = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mensagem != null) ...[Text(mensagem), const SizedBox(height: Gaps.md)],
          TextField(controller: controle, autofocus: true, obscureText: true, decoration: const InputDecoration(labelText: 'Sua senha')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, controle.text), child: const Text('Confirmar')),
      ],
    ),
  );
  controle.dispose();
  return (senha ?? '').isEmpty ? null : senha;
}

Future<void> mostrarCodigosDeRecuperacao(BuildContext context, List<String> codigos) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Códigos de recuperação'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Guarde estes códigos num lugar seguro. Cada um vale uma vez, no lugar do código do aplicativo. Eles não aparecem de novo.'),
          const SizedBox(height: Gaps.md),
          SelectableText(codigos.join('\n'), style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: codigos.join('\n'))),
          child: const Text('Copiar'),
        ),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Guardei')),
      ],
    ),
  );
}

class DoisFatoresPage extends StatefulWidget {
  const DoisFatoresPage({super.key});

  @override
  State<DoisFatoresPage> createState() => _DoisFatoresPageState();
}

class _DoisFatoresPageState extends State<DoisFatoresPage> {
  late Future<Conta> _conta = context.read<ContaRepository>().conta();
  Map<String, dynamic>? _configuracao;
  final _codigo = TextEditingController();
  bool _salvando = false;

  void _recarregar() => setState(() => _conta = context.read<ContaRepository>().conta());

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _comecar() async {
    try {
      final c = await context.read<ContaRepository>().configurarDoisFatores();
      if (mounted) setState(() => _configuracao = c);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    }
  }

  Future<void> _ativar() async {
    final senha = await pedirSenha(context, titulo: 'Confirme sua senha');
    if (senha == null || !mounted) return;
    setState(() => _salvando = true);
    try {
      final codigos = await context.read<ContaRepository>().ativarDoisFatores(
            configuracao: _configuracao!['configuracao'] as String,
            codigo: _codigo.text.trim(),
            senha: senha,
          );
      if (!mounted) return;
      context.read<AuthState>().doisFatoresAtivado();
      await mostrarCodigosDeRecuperacao(context, codigos);
      if (!mounted) return;
      setState(() => _configuracao = null);
      _recarregar();
    } catch (e) {
      if (mounted) Toast.error(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _novosCodigos() async {
    final senha = await pedirSenha(context, titulo: 'Gerar novos códigos', mensagem: 'Os códigos anteriores deixam de valer.');
    if (senha == null || !mounted) return;
    try {
      final codigos = await context.read<ContaRepository>().novosCodigos(senha);
      if (mounted) await mostrarCodigosDeRecuperacao(context, codigos);
      _recarregar();
    } catch (e) {
      if (mounted) Toast.error(context, friendlyError(e));
    }
  }

  Future<void> _desativar() async {
    final senha = await pedirSenha(context, titulo: 'Desativar a verificação em duas etapas?');
    if (senha == null || !mounted) return;
    final ok = await runAction(context, () => context.read<ContaRepository>().desativarDoisFatores(senha), success: 'Verificação em duas etapas desativada.');
    if (ok) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificação em duas etapas')),
      body: AsyncView<Conta>(
        future: _conta,
        onRetry: _recarregar,
        builder: (context, conta) => ListView(
          padding: Gaps.pageOf(context),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: conta.doisFatoresAtivo ? _ativo(conta) : _inativo(conta),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _ativo(Conta conta) => [
        const Icon(Icons.verified_user_rounded, size: 56, color: AppColors.success),
        const SizedBox(height: Gaps.md),
        Text('Ativa', style: context.text.headlineSmall, textAlign: TextAlign.center),
        Text('Códigos de recuperação restantes: ${conta.codigosRestantes}', textAlign: TextAlign.center),
        const SizedBox(height: Gaps.xl),
        OutlinedButton.icon(onPressed: _novosCodigos, icon: const Icon(Icons.refresh_rounded), label: const Text('Gerar novos códigos de recuperação')),
        const SizedBox(height: Gaps.md),
        if (conta.doisFatoresExigido)
          Text('Seu grupo de permissão exige a verificação em duas etapas: ela não pode ser desativada.', style: context.text.bodySmall, textAlign: TextAlign.center)
        else
          TextButton.icon(
            onPressed: _desativar,
            icon: const Icon(Icons.no_encryption_outlined, color: AppColors.danger),
            label: const Text('Desativar', style: TextStyle(color: AppColors.danger)),
          ),
      ];

  List<Widget> _inativo(Conta conta) {
    final c = _configuracao;
    if (c == null) {
      return [
        const Icon(Icons.shield_outlined, size: 56),
        const SizedBox(height: Gaps.md),
        Text(conta.doisFatoresExigido ? 'Seu grupo exige a verificação em duas etapas' : 'Proteja sua conta', style: context.text.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: Gaps.sm),
        const Text('Além da senha, o login vai pedir um código de 6 dígitos do aplicativo autenticador (Google Authenticator, Authy, 2FAS...).', textAlign: TextAlign.center),
        const SizedBox(height: Gaps.xl),
        FilledButton.icon(onPressed: _comecar, icon: const Icon(Icons.qr_code_rounded), label: const Text('Configurar')),
      ];
    }
    final qr = Uri.tryParse(c['qr_code'] as String? ?? '')?.data?.contentAsBytes();
    return [
      const Text('1. No aplicativo autenticador, leia o QR code ou digite o segredo.'),
      const SizedBox(height: Gaps.md),
      if (qr != null)
        Center(
          child: Container(
            padding: const EdgeInsets.all(Gaps.md),
            color: Colors.white,
            child: Image.memory(qr, width: 200, height: 200),
          ),
        ),
      const SizedBox(height: Gaps.sm),
      Center(child: SelectableText(c['segredo'] as String? ?? '', style: const TextStyle(fontFamily: 'monospace'))),
      const SizedBox(height: Gaps.xl),
      const Text('2. Digite o código que o aplicativo mostra.'),
      const SizedBox(height: Gaps.md),
      AppTextField(controller: _codigo, label: 'Código de 6 dígitos', icon: Icons.pin_outlined, keyboardType: TextInputType.number),
      const SizedBox(height: Gaps.xl),
      LoadingButton(label: 'Ativar', icon: Icons.check_rounded, loading: _salvando, onPressed: _ativar),
    ];
  }
}

class SessoesPage extends StatefulWidget {
  const SessoesPage({super.key});

  @override
  State<SessoesPage> createState() => _SessoesPageState();
}

class _SessoesPageState extends State<SessoesPage> {
  late Future<List<Sessao>> _sessoes = context.read<ContaRepository>().sessoes();

  void _recarregar() => setState(() => _sessoes = context.read<ContaRepository>().sessoes());

  Future<void> _encerrar(Sessao s) async {
    final ok = await runAction(context, () => context.read<ContaRepository>().encerrarSessao(s.id), success: 'Sessão encerrada.');
    if (ok) _recarregar();
  }

  Future<void> _encerrarOutras() async {
    final confirmou = await confirmDialog(context, title: 'Encerrar as outras sessões?', message: 'Os outros aparelhos vão precisar entrar de novo.', confirmLabel: 'Encerrar');
    if (!confirmou || !mounted) return;
    final ok = await runAction(context, () => context.read<ContaRepository>().encerrarOutrasSessoes(), success: 'Outras sessões encerradas.');
    if (ok) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessões ativas')),
      body: AsyncView<List<Sessao>>(
        future: _sessoes,
        onRetry: _recarregar,
        builder: (context, sessoes) => ListView(
          padding: Gaps.pageOf(context),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final s in sessoes)
                          ListTile(
                            leading: Icon(s.atual ? Icons.smartphone_rounded : Icons.devices_other_outlined),
                            title: Text(s.rotulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text([if (s.atual) 'Este aparelho', 'Último uso ${Fmt.dateTime(s.ultimoUso)}', if (s.ip.isNotEmpty) s.ip].join(' · ')),
                            trailing: s.atual ? null : IconButton(tooltip: 'Encerrar', icon: const Icon(Icons.logout_rounded), onPressed: () => _encerrar(s)),
                          ),
                      ],
                    ),
                  ),
                  if (sessoes.length > 1) ...[
                    const SizedBox(height: Gaps.lg),
                    OutlinedButton.icon(onPressed: _encerrarOutras, icon: const Icon(Icons.phonelink_erase_rounded), label: const Text('Encerrar todas as outras')),
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
