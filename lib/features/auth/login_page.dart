import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_state.dart';
import '../../core/storage/session_store.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/input_masks.dart';
import '../../core/widgets/ui.dart';
import '../easter_egg/julio_page.dart';
import '../onboarding/onboarding_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _server = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _codigo = TextEditingController();
  String? _desafio;
  late TipoDeConta _tipo = context.read<AuthState>().tipoPreferido;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    _server.text = auth.serverUrl ?? '';
    _email.text = auth.lastEmail ?? '';
  }

  @override
  void dispose() {
    _server.dispose();
    _email.dispose();
    _password.dispose();
    _codigo.dispose();
    super.dispose();
  }

  /// Abre a configuração de servidor (com teste de conexão).
  Future<void> _changeServer() async {
    final url = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OnboardingPage(serverOnly: true, initialUrl: _server.text),
      ),
    );
    if (!mounted) return;
    final tipo = context.read<AuthState>().tipoPreferido;
    if (url != null) await context.read<AuthState>().setServer(url);
    if (!mounted) return;
    setState(() {
      if (url != null) _server.text = url;
      if (tipo != _tipo) _error = null;
      _tipo = tipo;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthState>();
      final desafio = _desafio == null
          ? await auth.login(serverUrl: _server.text, email: _email.text, password: _password.text, tipo: _tipo)
          : await auth.confirmarSegundoFator(desafio: _desafio!, codigo: _codigo.text);
      if (mounted && desafio != null) {
        setState(() {
          _desafio = desafio;
          _codigo.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          if (e is ApiException && e.codigo == 'desafio_invalido') _desafio = null;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final form = _buildForm(context);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            const Expanded(child: _BrandPanel(expanded: true)),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Gaps.xxl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [form, const SizedBox(height: Gaps.xxl), const _Credits()],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile: o painel da marca encolhe quando o teclado abre, e a folha do
    // formulário ocupa o resto da tela (rolando só se não couber).
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: AppColors.brandDeep,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                _BrandPanel(expanded: false, compact: keyboardOpen),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      Gaps.xl,
                      Gaps.xxl,
                      Gaps.xl,
                      Gaps.lg + Gaps.systemBottom(context),
                    ),
                    child: Column(
                      children: [
                        form,
                        const Spacer(),
                        const SizedBox(height: Gaps.xl),
                        const _Credits(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    if (_desafio != null) return _buildSegundoFator(context);
    return Form(
      key: _form,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Entrar', style: context.text.headlineSmall),
            const SizedBox(height: Gaps.xs),
            Text(
              _tipo == TipoDeConta.cliente ? 'Acompanhe suas OS, compras e cobranças.' : 'Acesse sua conta do MAP-OS para continuar.',
              style: context.text.bodyMedium?.copyWith(color: context.tokens.muted),
            ),
            const SizedBox(height: Gaps.xl),
            _serverField(context),
            const SizedBox(height: Gaps.md),
            AppTextField(
              controller: _email,
              label: 'E-mail',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email, AutofillHints.username],
              validator: Validators.requiredEmail,
            ),
            const SizedBox(height: Gaps.md),
            AppTextField(
              controller: _password,
              label: 'Senha',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (v) => Validators.required(v, 'Senha'),
              suffix: IconButton(
                tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: Gaps.lg),
              Container(
                padding: const EdgeInsets.all(Gaps.md),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Gaps.radiusSm),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: Gaps.sm),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: Gaps.xl),
            SizedBox(height: 52, child: LoadingButton(label: 'Entrar', loading: _loading, onPressed: _submit)),
          ],
        ),
      ),
    );
  }

  Widget _buildSegundoFator(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Verificação em duas etapas', style: context.text.headlineSmall),
          const SizedBox(height: Gaps.xs),
          Text(
            'Digite o código de 6 dígitos do aplicativo autenticador ou um código de recuperação.',
            style: context.text.bodyMedium?.copyWith(color: context.tokens.muted),
          ),
          const SizedBox(height: Gaps.xl),
          AppTextField(
            controller: _codigo,
            label: 'Código',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            validator: (v) => Validators.required(v, 'Código'),
          ),
          if (_error != null) ...[
            const SizedBox(height: Gaps.lg),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: Gaps.xl),
          SizedBox(height: 52, child: LoadingButton(label: 'Confirmar', loading: _loading, onPressed: _submit)),
          const SizedBox(height: Gaps.sm),
          TextButton(
            onPressed: _loading ? null : () => setState(() {
              _desafio = null;
              _error = null;
            }),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _serverField(BuildContext context) {
    final empty = _server.text.isEmpty;
    final local = _server.text.startsWith('http://');
    final cliente = _tipo == TipoDeConta.cliente;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.md, vertical: Gaps.sm),
      onTap: _loading ? null : _changeServer,
      child: Row(
        children: [
          IconBadge(
            empty ? Icons.dns_outlined : (cliente ? Icons.person_outline_rounded : Icons.engineering_outlined),
            color: empty ? AppColors.accent : (cliente ? AppColors.clientes : AppColors.os),
            size: 36,
          ),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [cliente ? 'Cliente' : 'Assistência', if (!empty) local ? 'rede local' : 'hospedado'].join(' · '),
                  style: context.text.bodySmall,
                ),
                Text(
                  empty ? 'Toque para configurar' : _server.text.replaceFirst(RegExp(r'^https?://'), ''),
                  style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(empty ? 'Configurar' : 'Alterar', style: context.text.labelLarge?.copyWith(color: AppColors.accent)),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.expanded, this.compact = false});

  final bool expanded;

  /// Teclado aberto: mostra só o logo para sobrar espaço ao formulário.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDeep],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -40,
            child: _Glow(size: expanded ? 360 : 220),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Gaps.xl,
                expanded ? Gaps.xxl : (compact ? Gaps.lg : Gaps.xxl),
                Gaps.xl,
                expanded ? Gaps.xxl : (compact ? Gaps.lg : Gaps.xl + 8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  if (expanded) const Spacer(),
                  Image.asset('assets/images/logo.png', height: expanded ? 56 : 40),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topLeft,
                    child: compact
                        ? const SizedBox(width: double.infinity)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: expanded ? Gaps.xxl : Gaps.xl),
                              Text(
                                'Suas ordens de serviço,\nonde você estiver.',
                                style: (expanded ? context.text.headlineMedium : context.text.headlineSmall)?.copyWith(
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: Gaps.sm),
                              Text(
                                'Clientes, produtos, serviços e OS sincronizados com o seu MAP-OS.',
                                style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                  ),
                  if (expanded) const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [AppColors.accent.withValues(alpha: 0.35), AppColors.accent.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Créditos dos devs.
class _Credits extends StatefulWidget {
  const _Credits();

  @override
  State<_Credits> createState() => _CreditsState();
}

class _CreditsState extends State<_Credits> {
  // Os dois nomes usam o mesmo estilo e o mesmo tipo de span: nada denuncia
  // qual deles faz alguma coisa.
  late final TapGestureRecognizer _secret = TapGestureRecognizer()..onTap = _onSecretTap;

  @override
  void dispose() {
    _secret.dispose();
    super.dispose();
  }

  void _onSecretTap() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => const JulioLoboPage(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.text.bodySmall;
    final strong = muted?.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface);

    Widget link(IconData icon, String tooltip, String url, Color color) => IconButton(
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon, size: 20, color: color),
          onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            link(Icons.code_rounded, 'Projeto no GitHub', AppConfig.projectUrl, context.tokens.muted),
            link(Icons.forum_outlined, 'Comunidade no WhatsApp', AppConfig.communityUrl, const Color(0xFF25D366)),
            link(Icons.public_rounded, 'Site do app', AppConfig.appSiteUrl, context.tokens.muted),
          ],
        ),
        const SizedBox(height: Gaps.xs),
        Text.rich(
          TextSpan(
            style: muted,
            children: [
              const TextSpan(text: 'Desenvolvido por '),
              TextSpan(text: 'Felipe Santt', style: strong),
              const TextSpan(text: ' & '),
              TextSpan(
                text: 'Julio Lobo',
                style: strong,
                recognizer: _secret,
                mouseCursor: SystemMouseCursors.basic,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text('© ${DateTime.now().year} · MAP-OS Mobile v${AppConfig.appVersion}', style: muted, textAlign: TextAlign.center),
      ],
    );
  }
}
