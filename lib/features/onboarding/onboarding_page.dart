import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/network/server_probe.dart';
import '../../core/widgets/ui.dart';

/// Onboarding do primeiro acesso: apresenta o app e configura o servidor.
///
/// Com [serverOnly], abre direto na configuração do servidor (ex.: "Alterar"
/// na tela de login) e, ao concluir, faz `pop` devolvendo a URL testada.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.serverOnly = false, this.initialUrl});

  final bool serverOnly;
  final String? initialUrl;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

enum _Step { intro, serverType, serverUrl, done }

class _Slide {
  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
    this.orbit = const [],
    this.useLogo = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;
  final List<IconData> orbit;
  final bool useLogo;
}

const _slides = [
  _Slide(
    icon: Icons.handyman_rounded,
    color: AppColors.accent,
    useLogo: true,
    title: 'Bem-vindo ao\nMAP-OS Mobile',
    text: 'Seu sistema de ordens de serviço no bolso, sincronizado com o MAP-OS da sua empresa.',
    orbit: [Icons.assignment_outlined, Icons.people_alt_outlined, Icons.inventory_2_outlined],
  ),
  _Slide(
    icon: Icons.assignment_rounded,
    color: AppColors.os,
    title: 'Ordens de serviço\nna palma da mão',
    text: 'Abra, acompanhe e atualize OS em campo: status, produtos, serviços, anotações e fotos.',
    orbit: [Icons.photo_camera_outlined, Icons.checklist_rounded, Icons.receipt_long_outlined],
  ),
  _Slide(
    icon: Icons.people_alt_rounded,
    color: AppColors.clientes,
    title: 'Clientes, estoque\ne agenda',
    text: 'Ligue ou chame no WhatsApp com um toque, consulte produtos e serviços e veja sua agenda.',
    orbit: [Icons.phone_in_talk_outlined, Icons.calendar_month_outlined, Icons.inventory_2_outlined],
  ),
  _Slide(
    icon: Icons.dns_rounded,
    color: AppColors.servicos,
    title: 'Direto no\nseu servidor',
    text: 'O app conversa só com o seu MAP-OS, sem intermediários. E o que você já abriu continua disponível sem internet.',
    orbit: [Icons.lock_outline_rounded, Icons.wifi_off_rounded, Icons.cloud_done_outlined],
  ),
];

class _OnboardingPageState extends State<OnboardingPage> {
  final _pager = PageController();
  final _url = TextEditingController();
  final _urlFocus = FocusNode();

  late final List<_Step> _steps = [
    if (!widget.serverOnly) ...List.filled(_slides.length, _Step.intro),
    _Step.serverType,
    _Step.serverUrl,
    if (!widget.serverOnly) _Step.done,
  ];

  int _page = 0;
  ServerMode? _mode;
  bool _testing = false;
  ProbeResult? _result;
  String? _formatError;
  bool _finishing = false;

  _Step get _step => _steps[_page];
  int get _firstServerPage => _steps.indexOf(_Step.serverType);
  String get _builtUrl => _mode == null ? '' : ServerProbe.buildUrl(_url.text, _mode!);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialUrl ?? '';
    if (initial.isNotEmpty) {
      _mode = initial.startsWith('http://') ? ServerMode.local : ServerMode.hosted;
      _url.text = initial.replaceFirst(RegExp(r'^https?://'), '');
    }
  }

  @override
  void dispose() {
    _pager.dispose();
    _url.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navegação
  // ---------------------------------------------------------------------------

  void _goTo(int page) {
    FocusScope.of(context).unfocus();
    _pager.animateToPage(page, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    // Chegou na tela de endereço sem nada digitado: já abre o teclado.
    if (_steps[page] == _Step.serverUrl && _url.text.isEmpty) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && _step == _Step.serverUrl) _urlFocus.requestFocus();
      });
    }
  }

  void _back() {
    if (_page == 0) {
      if (widget.serverOnly) Navigator.of(context).pop();
      return;
    }
    _goTo(_page - 1);
  }

  Future<void> _primary() async {
    switch (_step) {
      case _Step.intro:
      case _Step.serverType:
        _goTo(_page + 1);
      case _Step.serverUrl:
        if (_result?.ok ?? false) {
          _confirmServer(_result!.url);
        } else {
          await _test();
        }
      case _Step.done:
        await _finish();
    }
  }

  void _confirmServer(String url) {
    if (widget.serverOnly) {
      Navigator.of(context).pop(url);
    } else {
      _goTo(_page + 1);
    }
  }

  Future<void> _finish() async {
    final url = _result?.url ?? _builtUrl;
    setState(() => _finishing = true);
    await context.read<AuthState>().completeOnboarding(url);
  }

  // ---------------------------------------------------------------------------
  // Servidor
  // ---------------------------------------------------------------------------

  void _selectMode(ServerMode mode) {
    setState(() {
      _mode = mode;
      _result = null;
      _formatError = null;
    });
  }

  void _onUrlChanged(String value) {
    // Colou "http://..." ou "https://..."? Ajusta o tipo e limpa o protocolo.
    final match = RegExp(r'^\s*(https?)://', caseSensitive: false).firstMatch(value);
    if (match != null) {
      final detected = match.group(1)!.toLowerCase() == 'https' ? ServerMode.hosted : ServerMode.local;
      final rest = value.substring(match.end);
      _url.value = TextEditingValue(text: rest, selection: TextSelection.collapsed(offset: rest.length));
      if (detected != _mode) {
        Toast.info(
          context,
          detected == ServerMode.hosted
              ? 'Endereço com HTTPS: mudamos para "Hospedado".'
              : 'Endereço com HTTP: mudamos para "Rede local".',
        );
      }
      _mode = detected;
    }
    setState(() {
      _result = null;
      _formatError = null;
    });
  }

  Future<void> _test() async {
    final mode = _mode;
    if (mode == null) return;
    final error = ServerProbe.validate(_url.text, mode);
    if (error != null) {
      setState(() => _formatError = error);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _testing = true;
      _result = null;
      _formatError = null;
    });
    final started = DateTime.now();
    final result = await ServerProbe.test(ServerProbe.buildUrl(_url.text, mode));
    // Tempo mínimo para a animação de teste não "piscar".
    final wait = const Duration(milliseconds: 700) - DateTime.now().difference(started);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _result = result;
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  Color get _pageColor {
    switch (_step) {
      case _Step.intro:
        return _slides[_page].color;
      case _Step.serverType:
        return _mode == ServerMode.local ? AppColors.servicos : AppColors.clientes;
      case _Step.serverUrl:
        if (_result == null) return AppColors.accent;
        return _result!.ok ? AppColors.success : AppColors.danger;
      case _Step.done:
        return AppColors.success;
    }
  }

  (String, IconData?, bool) get _primaryAction {
    switch (_step) {
      case _Step.intro:
        return _page == _firstServerPage - 1
            ? ('Configurar servidor', Icons.arrow_forward_rounded, true)
            : ('Próximo', Icons.arrow_forward_rounded, true);
      case _Step.serverType:
        return ('Continuar', Icons.arrow_forward_rounded, _mode != null);
      case _Step.serverUrl:
        if (_result?.ok ?? false) {
          return (widget.serverOnly ? 'Usar este servidor' : 'Continuar', Icons.arrow_forward_rounded, true);
        }
        return (_result == null ? 'Testar conexão' : 'Testar novamente', Icons.wifi_tethering_rounded, !_testing);
      case _Step.done:
        return ('Fazer login', Icons.login_rounded, !_finishing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (context) => PopScope(
          canPop: _page == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: Scaffold(
            backgroundColor: AppColors.brandDeep,
            body: Stack(
              children: [
                _Backdrop(color: _pageColor, page: _page),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        children: [
                          _topBar(context),
                          Expanded(
                            child: PageView.builder(
                              controller: _pager,
                              itemCount: _steps.length,
                              physics: _page < _firstServerPage
                                  ? const BouncingScrollPhysics()
                                  : const NeverScrollableScrollPhysics(),
                              onPageChanged: _onPageChanged,
                              itemBuilder: (context, i) => _buildPage(context, i),
                            ),
                          ),
                          _bottomBar(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final showSkip = _step == _Step.intro;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gaps.xl, Gaps.md, Gaps.md, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            if (widget.serverOnly)
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              )
            else
              Image.asset('assets/images/logo.png', height: 28),
            const Spacer(),
            AnimatedOpacity(
              opacity: showSkip ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !showSkip,
                child: TextButton(
                  onPressed: () => _goTo(_firstServerPage),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Pular'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final (label, icon, enabled) = _primaryAction;
    final busy = (_step == _Step.serverUrl && _testing) || (_step == _Step.done && _finishing);
    final canGoBack = _page > 0 && _step != _Step.done;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gaps.xl, Gaps.md, Gaps.xl, Gaps.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dots(count: _steps.length, index: _page, color: _pageColor),
          const SizedBox(height: Gaps.xl),
          Row(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: canGoBack
                    ? Padding(
                        padding: const EdgeInsets.only(right: Gaps.md),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: IconButton.filledTonal(
                            tooltip: 'Voltar',
                            onPressed: _back,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: enabled && !busy ? _primary : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                      disabledForegroundColor: Colors.white38,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: busy
                          ? const SizedBox(
                              key: ValueKey('busy'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : Row(
                              key: ValueKey(label),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(label),
                                if (icon != null) ...[const SizedBox(width: Gaps.sm), Icon(icon, size: 20)],
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, int i) {
    switch (_steps[i]) {
      case _Step.intro:
        return _IntroSlide(slide: _slides[i]);
      case _Step.serverType:
        return _serverTypePage(context);
      case _Step.serverUrl:
        return _serverUrlPage(context);
      case _Step.done:
        return _donePage(context);
    }
  }

  // ---- Tipo de servidor -----------------------------------------------------

  Widget _serverTypePage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Gaps.xl, Gaps.xl, Gaps.xl, Gaps.lg),
      child: _Entrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepLabel('Passo 1 de 2'),
            const SizedBox(height: Gaps.sm),
            Text('Onde está o seu\nMAP-OS?', style: _titleStyle(context)),
            const SizedBox(height: Gaps.md),
            Text(
              'Isso define como o app vai se conectar ao seu servidor.',
              style: _bodyStyle(context),
            ),
            const SizedBox(height: Gaps.xl),
            _ModeCard(
              selected: _mode == ServerMode.hosted,
              onTap: () => _selectMode(ServerMode.hosted),
              icon: Icons.cloud_outlined,
              color: AppColors.clientes,
              title: 'Hospedado na internet',
              text: 'Em um domínio, hospedagem ou VPS. Acessível de qualquer lugar.',
              badgeIcon: Icons.lock_rounded,
              badge: 'HTTPS · conexão segura',
              example: 'minhaempresa.com.br/mapos',
            ),
            const SizedBox(height: Gaps.md),
            _ModeCard(
              selected: _mode == ServerMode.local,
              onTap: () => _selectMode(ServerMode.local),
              icon: Icons.router_outlined,
              color: AppColors.servicos,
              title: 'Na rede local',
              text: 'Num computador ou servidor da empresa (XAMPP, WAMP, Docker…).',
              badgeIcon: Icons.wifi_rounded,
              badge: 'HTTP · mesma rede Wi-Fi',
              example: '192.168.0.10/mapos',
            ),
          ],
        ),
      ),
    );
  }

  // ---- URL + teste ----------------------------------------------------------

  Widget _serverUrlPage(BuildContext context) {
    final mode = _mode ?? ServerMode.hosted;
    final local = mode == ServerMode.local;
    final scheme = local ? 'http://' : 'https://';
    final warning = ServerProbe.localhostWarning(_url.text, mode);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Gaps.xl, Gaps.xl, Gaps.xl, Gaps.lg),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: _Entrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepLabel('Passo 2 de 2'),
            const SizedBox(height: Gaps.sm),
            Text('Qual o endereço\ndo servidor?', style: _titleStyle(context)),
            const SizedBox(height: Gaps.md),
            Text(
              local
                  ? 'Informe o IP do computador que roda o MAP-OS e, se houver, a porta e a pasta.'
                  : 'Use o mesmo endereço que você abre no navegador para acessar o MAP-OS.',
              style: _bodyStyle(context),
            ),
            const SizedBox(height: Gaps.xl),
            _ModeSwitch(mode: mode, onChanged: _selectMode),
            const SizedBox(height: Gaps.md),
            TextField(
              controller: _url,
              focusNode: _urlFocus,
              enabled: !_testing,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.go,
              autofillHints: const [AutofillHints.url],
              onChanged: _onUrlChanged,
              onSubmitted: (_) => _primary(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                hintText: local ? '192.168.0.10/mapos' : 'minhaempresa.com.br/mapos',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.w500),
                errorText: _formatError,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: Gaps.lg, right: Gaps.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        local ? Icons.lan_outlined : Icons.lock_rounded,
                        size: 18,
                        color: local ? Colors.white54 : AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(scheme, style: const TextStyle(color: Colors.white54, fontSize: 16)),
                    ],
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minHeight: 56),
                suffixIcon: _url.text.isEmpty || _testing
                    ? null
                    : IconButton(
                        tooltip: 'Limpar',
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _url.clear();
                          _onUrlChanged('');
                          _urlFocus.requestFocus();
                        },
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: Gaps.lg),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
                ),
              ),
            ),
            const SizedBox(height: Gaps.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.xs),
              child: Text(
                local
                    ? 'Dica: o celular precisa estar no mesmo Wi-Fi do servidor.'
                    : 'Não precisa digitar "https://" nem "/api/v1".',
                style: context.text.bodySmall?.copyWith(color: Colors.white54),
              ),
            ),
            if (warning != null) ...[
              const SizedBox(height: Gaps.md),
              _Notice(icon: Icons.warning_amber_rounded, color: AppColors.warning, text: warning),
            ],
            const SizedBox(height: Gaps.lg),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: _testing
                    ? _TestingCard(key: const ValueKey('testing'), url: _builtUrl)
                    : _result != null
                        ? _ResultCard(
                            key: ValueKey(_result),
                            result: _result!,
                            onUseAnyway: _result!.ok ? null : () => _confirmServer(_result!.url),
                          )
                        : const SizedBox(key: ValueKey('empty'), width: double.infinity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Concluído ------------------------------------------------------------

  Widget _donePage(BuildContext context) {
    final url = _result?.url ?? _builtUrl;
    final local = url.startsWith('http://');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Gaps.xl, Gaps.xxl, Gaps.xl, Gaps.lg),
      child: Column(
        children: [
          const SizedBox(height: Gaps.xl),
          const _SuccessBurst(),
          const SizedBox(height: Gaps.xxl),
          _Entrance(
            delay: const Duration(milliseconds: 250),
            child: Column(
              children: [
                Text('Tudo pronto!', style: _titleStyle(context), textAlign: TextAlign.center),
                const SizedBox(height: Gaps.md),
                Text(
                  'Seu servidor está configurado. Agora é só entrar com o seu usuário do MAP-OS.',
                  style: _bodyStyle(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Gaps.xl),
                _GlassCard(
                  child: Row(
                    children: [
                      IconBadge(
                        local ? Icons.router_outlined : Icons.cloud_done_outlined,
                        color: local ? AppColors.servicos : AppColors.clientes,
                        size: 44,
                      ),
                      const SizedBox(width: Gaps.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              local ? 'Rede local · HTTP' : 'Hospedado · HTTPS',
                              style: context.text.bodySmall?.copyWith(color: Colors.white54),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              url.replaceFirst(RegExp(r'^https?://'), ''),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleSmall?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle? _titleStyle(BuildContext context) => context.text.headlineMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.8,
    );

TextStyle? _bodyStyle(BuildContext context) => context.text.bodyLarge?.copyWith(
      color: Colors.white.withValues(alpha: 0.68),
      height: 1.45,
    );

// =============================================================================
// Componentes
// =============================================================================

/// Fundo navy com brilhos que mudam de cor e posição a cada passo.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.color, required this.page});

  final Color color;
  final int page;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 900);
    final alignments = [
      const Alignment(1.2, -1.0),
      const Alignment(-1.3, -0.6),
      const Alignment(1.3, -0.3),
      const Alignment(-1.2, -0.9),
    ];
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.brand, AppColors.brandDeep, Color(0xFF13152A)],
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: duration,
              curve: Curves.easeInOutCubic,
              alignment: alignments[page % alignments.length],
              child: _GlowBlob(color: color, size: 420),
            ),
            AnimatedAlign(
              duration: duration,
              curve: Curves.easeInOutCubic,
              alignment: Alignment(alignments[(page + 2) % alignments.length].x * -1, 1.1),
              child: const _GlowBlob(color: AppColors.accent, size: 300, alpha: 0.14),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size, this.alpha = 0.32});

  final Color color;
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: const Duration(milliseconds: 900),
      builder: (context, c, _) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [(c ?? color).withValues(alpha: alpha), (c ?? color).withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Indicador de progresso em pílulas.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.color});

  final int count;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 26 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index
                  ? color
                  : i < index
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// Fade + slide de entrada.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;
  static const double offset = 24;

  @override
  Widget build(BuildContext context) {
    final total = const Duration(milliseconds: 550) + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, child) {
        final v = Curves.easeOutCubic.transform(((t - start) / (1 - start)).clamp(0.0, 1.0));
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, offset * (1 - v)), child: child),
        );
      },
      child: child,
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        style: context.text.labelSmall?.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gaps.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gaps.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: Gaps.sm),
          Expanded(
            child: Text(text, style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
          ),
        ],
      ),
    );
  }
}

// ---- Slides -----------------------------------------------------------------

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final heroSize = math.min(c.maxWidth * 0.78, c.maxHeight * 0.48).clamp(180.0, 340.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _OrbitHero(slide: slide, size: heroSize)),
                const SizedBox(height: Gaps.xxl),
                _Entrance(
                  delay: const Duration(milliseconds: 120),
                  child: Text(slide.title, style: _titleStyle(context)),
                ),
                const SizedBox(height: Gaps.md),
                _Entrance(
                  delay: const Duration(milliseconds: 220),
                  child: Text(slide.text, style: _bodyStyle(context)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ilustração: ícone central com anéis e ícones orbitando.
class _OrbitHero extends StatefulWidget {
  const _OrbitHero({required this.slide, required this.size});

  final _Slide slide;
  final double size;

  @override
  State<_OrbitHero> createState() => _OrbitHeroState();
}

class _OrbitHeroState extends State<_OrbitHero> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 18));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final color = widget.slide.color;
    final core = s * 0.36;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: Opacity(opacity: ((scale - 0.6) / 0.4).clamp(0.0, 1.0), child: child),
      ),
      child: SizedBox(
        width: s,
        height: s,
        child: AnimatedBuilder(
          animation: _spin,
          builder: (context, _) {
            final t = _spin.value * 2 * math.pi;
            final orbitR = s * 0.40;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Anéis
                for (final f in const [1.0, 0.72])
                  Container(
                    width: s * f * 0.92,
                    height: s * f * 0.92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: f == 1 ? 0.06 : 0.1)),
                    ),
                  ),
                // Brilho
                Container(
                  width: core * 2,
                  height: core * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0)]),
                  ),
                ),
                // Núcleo
                Transform.translate(
                  offset: Offset(0, math.sin(t * 3) * 4),
                  child: Container(
                    width: core,
                    height: core,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(core * 0.3),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.lerp(color, Colors.white, 0.15)!, color],
                      ),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 32, offset: const Offset(0, 12)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: widget.slide.useLogo
                        ? Padding(
                            padding: EdgeInsets.all(core * 0.18),
                            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                          )
                        : Icon(widget.slide.icon, color: Colors.white, size: core * 0.5),
                  ),
                ),
                // Satélites
                for (var i = 0; i < widget.slide.orbit.length; i++)
                  Builder(builder: (context) {
                    final a = t + i * 2 * math.pi / widget.slide.orbit.length - math.pi / 2;
                    final chip = s * 0.17;
                    return Transform.translate(
                      offset: Offset(math.cos(a) * orbitR, math.sin(a) * orbitR * 0.92),
                      child: Container(
                        width: chip,
                        height: chip,
                        decoration: BoxDecoration(
                          color: const Color(0xFF262A45),
                          borderRadius: BorderRadius.circular(chip * 0.32),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Icon(widget.slide.orbit[i], color: Colors.white.withValues(alpha: 0.9), size: chip * 0.46),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---- Servidor ---------------------------------------------------------------

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
    required this.badgeIcon,
    required this.badge,
    required this.example,
  });

  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  final IconData badgeIcon;
  final String badge;
  final String example;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1 : 0.98,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.1),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8))]
              : const [],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(Gaps.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: selected ? 0.28 : 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: Gaps.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.text.titleMedium?.copyWith(color: Colors.white)),
                        const SizedBox(height: Gaps.xs),
                        Text(
                          text,
                          style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.6), height: 1.4),
                        ),
                        const SizedBox(height: Gaps.md),
                        Wrap(
                          spacing: Gaps.sm,
                          runSpacing: Gaps.xs,
                          children: [
                            _Pill(icon: badgeIcon, text: badge, color: color),
                            _Pill(icon: Icons.link_rounded, text: example, color: Colors.white54),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gaps.sm),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? color : Colors.transparent,
                      border: Border.all(color: selected ? color : Colors.white30, width: 2),
                    ),
                    child: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: context.text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}

/// Alternador compacto Hospedado / Local na tela de endereço.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final ServerMode mode;
  final ValueChanged<ServerMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(ServerMode m, IconData icon, String label) {
      final selected = m == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(m),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: selected ? Colors.white : Colors.white54),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: context.text.labelLarge?.copyWith(color: selected ? Colors.white : Colors.white54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          option(ServerMode.hosted, Icons.cloud_outlined, 'Hospedado'),
          option(ServerMode.local, Icons.router_outlined, 'Rede local'),
        ],
      ),
    );
  }
}

class _TestingCard extends StatelessWidget {
  const _TestingCard({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          const _Radar(),
          const SizedBox(width: Gaps.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Testando conexão…', style: context.text.titleSmall?.copyWith(color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ondas pulsando enquanto o teste roda.
class _Radar extends StatefulWidget {
  const _Radar();

  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 2; i++)
              Builder(builder: (context) {
                final v = (_c.value + i * 0.5) % 1;
                return Container(
                  width: 16 + 28 * v,
                  height: 16 + 28 * v,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent.withValues(alpha: (1 - v) * 0.8), width: 2),
                  ),
                );
              }),
            const Icon(Icons.wifi_tethering_rounded, color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({super.key, required this.result, this.onUseAnyway});

  final ProbeResult result;
  final VoidCallback? onUseAnyway;

  @override
  Widget build(BuildContext context) {
    final color = result.ok ? AppColors.success : AppColors.danger;
    return _GlassCard(
      borderColor: color.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
                  child: Icon(result.ok ? Icons.check_rounded : Icons.close_rounded, color: color, size: 24),
                ),
              ),
              const SizedBox(width: Gaps.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.title, style: context.text.titleSmall?.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      result.message,
                      style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.ok) ...[
            const SizedBox(height: Gaps.md),
            _Pill(icon: Icons.link_rounded, text: result.url, color: AppColors.success),
          ],
          if (result.tips.isNotEmpty) ...[
            const SizedBox(height: Gaps.md),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: Gaps.md),
            Text(
              'O que verificar',
              style: context.text.labelMedium?.copyWith(color: Colors.white54, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Gaps.sm),
            for (final tip in result.tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: Gaps.sm),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (onUseAnyway != null) ...[
            const SizedBox(height: Gaps.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onUseAnyway,
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
                child: const Text('Usar mesmo assim'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Check animado com anéis expandindo.
class _SuccessBurst extends StatelessWidget {
  const _SuccessBurst();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      builder: (context, t, _) {
        final pop = Curves.elasticOut.transform((t / 0.7).clamp(0.0, 1.0));
        final ring = Curves.easeOutCubic.transform(t);
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110 + 90 * ring,
                height: 110 + 90 * ring,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.5 * (1 - ring)), width: 2),
                ),
              ),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.success.withValues(alpha: 0.35 * ring), AppColors.success.withValues(alpha: 0)],
                  ),
                ),
              ),
              Transform.scale(
                scale: pop,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF34D399), AppColors.success],
                    ),
                    boxShadow: [
                      BoxShadow(color: AppColors.success.withValues(alpha: 0.45), blurRadius: 32, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 58),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
