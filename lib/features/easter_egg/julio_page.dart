import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// 🐺 Easter egg.
///
/// 1. O app é "invadido": um terminal digita um hack completamente sério.
/// 2. Mini-game "Pegue o Lobo": a cara do Julio quica pela tela tipo o logo
///    do DVD. Cada toque rende uma desculpa clássica de dev, ele acelera, e
///    acertar o cantinho vale bônus. Pegou 10 vezes? Certificado oficial.
class JulioLoboPage extends StatefulWidget {
  const JulioLoboPage({super.key});

  @override
  State<JulioLoboPage> createState() => _JulioLoboPageState();
}

class _JulioLoboPageState extends State<JulioLoboPage> {
  bool _hacked = false;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 1.08, end: 1.0).animate(anim), child: child),
          ),
          child: _hacked
              ? const _CatchTheWolf(key: ValueKey('game'))
              : _HackTerminal(key: const ValueKey('terminal'), onDone: () => setState(() => _hacked = true)),
        ),
      ),
    );
  }
}

const _avatarUrl = 'https://avatars.githubusercontent.com/u/13459803?v=4';
const _green = Color(0xFF39FF14);

// =============================================================================
// Fase 1 — terminal
// =============================================================================

class _HackTerminal extends StatefulWidget {
  const _HackTerminal({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<_HackTerminal> createState() => _HackTerminalState();
}

class _HackTerminalState extends State<_HackTerminal> {
  static const _script = [
    r'$ ssh root@seu-celular',
    '> conectando... conectado (a senha era 123456)',
    '> baixando mais memória RAM........ 100%',
    '> convertendo café em código ☕☕☕ ok',
    '> trocando todos os bugs por features... ok',
    '> git push --force na main... ✓ ninguém viu',
    '> removendo os testes (eles falhavam)... ok',
    '> instalando o node_modules... 42 GB',
    '> invocando o desenvolvedor lendário...',
    '',
    '⚠  ALERTA: UM LOBO FOI DETECTADO NO SISTEMA',
  ];

  late final String _full = _script.join('\n');
  int _shown = 0;
  Timer? _timer;
  bool _cursor = true;
  Timer? _blink;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_shown >= _full.length) {
        _timer?.cancel();
        Future.delayed(const Duration(milliseconds: 1100), _finish);
        return;
      }
      // Linhas "rápidas" (comando) e pausa dramática antes do alerta.
      final next = _full[_shown];
      var n = (_shown + (next == '\n' ? 1 : 2)).clamp(0, _full.length);
      // Nunca corta um par surrogate (emoji) no meio.
      if (n < _full.length && _full.codeUnitAt(n - 1) >= 0xD800 && _full.codeUnitAt(n - 1) <= 0xDBFF) n++;
      setState(() => _shown = n);
    });
    _blink = Timer.periodic(const Duration(milliseconds: 450), (_) => setState(() => _cursor = !_cursor));
  }

  void _finish() {
    if (!mounted) return;
    _timer?.cancel();
    _blink?.cancel();
    HapticFeedback.vibrate();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blink?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _full.substring(0, _shown);
    final alert = text.contains('ALERTA');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Stack(
        children: [
          const Positioned.fill(child: _Scanlines()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'julio@lobo:~',
                    style: TextStyle(fontFamily: 'monospace', color: _green.withValues(alpha: 0.5), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: text),
                            TextSpan(text: _cursor ? '█' : ' '),
                          ],
                        ),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.6,
                          color: alert ? const Color(0xFFFF3B3B) : _green,
                          shadows: [Shadow(color: (alert ? Colors.red : _green).withValues(alpha: 0.7), blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'toque para pular',
                      style: TextStyle(fontFamily: 'monospace', color: _green.withValues(alpha: 0.35), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Scanlines extends StatelessWidget {
  const _Scanlines();

  @override
  Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(painter: _ScanlinePainter()));
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _green.withValues(alpha: 0.035);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.5), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// Fase 2 — Pegue o Lobo
// =============================================================================

class _CatchTheWolf extends StatefulWidget {
  const _CatchTheWolf({super.key});

  @override
  State<_CatchTheWolf> createState() => _CatchTheWolfState();
}

class _Burst {
  _Burst(this.origin, this.emojis, this.start);

  final Offset origin;
  final List<(String, double, double)> emojis; // emoji, ângulo, velocidade
  final Duration start;
}

class _CatchTheWolfState extends State<_CatchTheWolf> with SingleTickerProviderStateMixin {
  static const _goal = 10;
  static const _size = 96.0;

  static const _excuses = [
    'Ai! Isso doeu no back-end 😵',
    'Funciona na minha máquina! 🖥️',
    'Não é bug, é feature 🐛✨',
    'Deve ser o cache. Sempre é o cache.',
    'Quem mexeu no meu .env?! 😤',
    'Deploy na sexta? Claro, o que pode dar errado?',
    'Eu ia escrever os testes... amanhã.',
    'A API tá fora? Culpa do DNS 🌐',
    'Esse código não é meu, é do Felipe 👀',
    'Ok, ok... eu arrumo o endpoint 😅',
    'Só mais um café e eu resolvo ☕',
    'Commit "ajustes finais (agora vai)" 🙏',
  ];

  final _rand = math.Random();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Duration _now = Duration.zero;

  Size _area = Size.zero;
  Offset _pos = const Offset(40, 120);
  Offset _vel = const Offset(170, 140);
  Duration? _lastBounceX;
  Duration? _lastBounceY;
  Color _tint = _green;

  int _score = 0;
  int _corners = 0;
  int _misses = 0;
  Duration _startedAt = Duration.zero;
  Duration? _wonAt;

  String? _phrase;
  Duration _phraseAt = Duration.zero;
  String? _banner;
  Duration _bannerAt = Duration.zero;
  final List<_Burst> _bursts = [];

  @override
  void initState() {
    super.initState();
    // Inicia o loop do jogo já na criação (um `late` nunca lido não roda).
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _now = elapsed;
    if (_area == Size.zero || dt <= 0 || dt > 0.1) {
      setState(() {});
      return;
    }

    var p = _pos + _vel * dt;
    var v = _vel;
    final maxX = _area.width - _size;
    final maxY = _area.height - _size;
    var bounced = false;

    if (p.dx <= 0 || p.dx >= maxX) {
      v = Offset(-v.dx, v.dy);
      p = Offset(p.dx.clamp(0, maxX), p.dy);
      _lastBounceX = elapsed;
      bounced = true;
    }
    if (p.dy <= 0 || p.dy >= maxY) {
      v = Offset(v.dx, -v.dy);
      p = Offset(p.dx, p.dy.clamp(0, maxY));
      _lastBounceY = elapsed;
      bounced = true;
    }

    if (bounced) {
      _tint = HSVColor.fromAHSV(1, _rand.nextDouble() * 360, 0.8, 1).toColor();
      // Bateu nas duas paredes quase juntas = cantinho! 🎯
      final bx = _lastBounceX, by = _lastBounceY;
      if (bx != null && by != null && (bx - by).abs() < const Duration(milliseconds: 90)) {
        _lastBounceX = null;
        _lastBounceY = null;
        _corners++;
        _score++;
        HapticFeedback.heavyImpact();
        _showBanner('🎯 NO CANTINHO! +1');
        _burst(Offset(p.dx + _size / 2, p.dy + _size / 2), ['🎉', '✨', '🎯', '🥳'], 18);
      }
    }

    _bursts.removeWhere((b) => elapsed - b.start > const Duration(milliseconds: 1200));
    if (_score >= _goal && _wonAt == null) _wonAt = elapsed;

    setState(() {
      _pos = p;
      _vel = v;
    });
  }

  void _showBanner(String text) {
    _banner = text;
    _bannerAt = _now;
  }

  void _burst(Offset at, List<String> emojis, int count) {
    _bursts.add(_Burst(
      at,
      [
        for (var i = 0; i < count; i++)
          (emojis[_rand.nextInt(emojis.length)], _rand.nextDouble() * 2 * math.pi, 120 + _rand.nextDouble() * 220),
      ],
      _now,
    ));
  }

  /// Toque na arena: acertou o círculo do Julio (com folga de 12px) ou errou.
  void _onArenaDown(PointerDownEvent e) {
    if (_wonAt != null) return;
    final center = _pos + const Offset(_size / 2, _size / 2);
    final hit = (e.localPosition - center).distance <= _size / 2 + 12;
    setState(hit ? _registerCatch : _registerMiss);
  }

  void _registerCatch() {
    HapticFeedback.mediumImpact();
    _score++;
    _phrase = _excuses[_rand.nextInt(_excuses.length)];
    _phraseAt = _now;
    _burst(_pos + const Offset(_size / 2, _size / 2), ['🐺', '💥', '⭐', '😂'], 12);

    // Foge pro lado oposto, mais rápido (com limite pra continuar jogável).
    final speed = (_vel.distance * 1.13).clamp(0.0, 900.0);
    final angle = _rand.nextDouble() * 2 * math.pi;
    _vel = Offset(math.cos(angle), math.sin(angle)) * speed;
    if (_vel.dx.abs() < 60) _vel = Offset(_vel.dx.sign * 120 + 1, _vel.dy);
  }

  void _registerMiss() {
    _misses++;
    if (_misses % 5 == 0) {
      _phrase = ['Errou! O Julio riu de você 🤭', 'Tá difícil, hein? 🐺💨', 'Ele é rápido igual deploy de sexta'][
          _rand.nextInt(3)];
      _phraseAt = _now;
    }
  }

  void _restart() {
    setState(() {
      _score = 0;
      _corners = 0;
      _misses = 0;
      _wonAt = null;
      _startedAt = _now;
      _phrase = 'Round 2! Agora ele tá bravo 😠';
      _phraseAt = _now;
      _vel = Offset(_vel.dx.sign * 260, _vel.dy.sign * 220);
    });
  }

  double _fade(Duration since, int ms) => (1 - (_now - since).inMilliseconds / ms).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final won = _wonAt != null;
    final phraseOpacity = _phrase == null ? 0.0 : _fade(_phraseAt, 2200);
    final bannerOpacity = _banner == null ? 0.0 : _fade(_bannerAt, 1500);

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 1.4,
          colors: [Color(0xFF1A1340), Color(0xFF0B0B1E), Colors.black],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Barra superior
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Fugir',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'PEGUE O LOBO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🐺 $_score / $_goal',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_score / _goal).clamp(0.0, 1.0),
                  minHeight: 4,
                  color: _tint,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
            // Arena
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final size = Size(c.maxWidth, c.maxHeight);
                  if (_area != size) {
                    _area = size;
                    if (_startedAt == Duration.zero) _startedAt = _now;
                  }
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _onArenaDown,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Dica
                        if (_score == 0 && !won)
                          Center(
                            child: Text(
                              'Toque no Julio antes que ele\nsuba mais código sem testar!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 15),
                            ),
                          ),
                        // Frase
                        Align(
                          alignment: const Alignment(0, -0.7),
                          child: Opacity(
                            opacity: phraseOpacity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _phrase ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                        // Banner do cantinho
                        Align(
                          alignment: const Alignment(0, 0.6),
                          child: Opacity(
                            opacity: bannerOpacity,
                            child: Transform.scale(
                              scale: 1 + (1 - bannerOpacity) * 0.4,
                              child: Text(
                                _banner ?? '',
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  shadows: [Shadow(color: Colors.amber.withValues(alpha: 0.8), blurRadius: 20)],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Explosões de emoji
                        for (final b in _bursts)
                          for (final (emoji, angle, speed) in b.emojis)
                            Builder(builder: (context) {
                              final t = (_now - b.start).inMilliseconds / 1000;
                              final dx = math.cos(angle) * speed * t;
                              final dy = math.sin(angle) * speed * t + 300 * t * t; // gravidade
                              return Positioned(
                                left: b.origin.dx + dx - 12,
                                top: b.origin.dy + dy - 12,
                                child: IgnorePointer(
                                  child: Opacity(
                                    opacity: (1 - t / 1.2).clamp(0.0, 1.0),
                                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                                  ),
                                ),
                              );
                            }),
                        // O Lobo
                        if (!won)
                          Positioned(
                            left: _pos.dx,
                            top: _pos.dy,
                            child: IgnorePointer(
                              child: _WolfFace(tint: _tint, spin: _now.inMilliseconds / 1000),
                            ),
                          ),
                        if (won)
                          _Certificate(
                            score: _score,
                            corners: _corners,
                            misses: _misses,
                            seconds: ((_wonAt! - _startedAt).inMilliseconds / 1000),
                            onAgain: _restart,
                            onExit: () => Navigator.of(context).pop(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WolfFace extends StatelessWidget {
  const _WolfFace({required this.tint, required this.spin});

  final Color tint;
  final double spin;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.sin(spin * 3) * 0.18,
      child: Container(
        width: _CatchTheWolfState._size,
        height: _CatchTheWolfState._size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: tint, width: 3),
          boxShadow: [BoxShadow(color: tint.withValues(alpha: 0.6), blurRadius: 24, spreadRadius: 2)],
        ),
        child: ClipOval(
          child: Image.network(
            _avatarUrl,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF2A2350),
              alignment: Alignment.center,
              child: const Text('🐺', style: TextStyle(fontSize: 52)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Certificate extends StatelessWidget {
  const _Certificate({
    required this.score,
    required this.corners,
    required this.misses,
    required this.seconds,
    required this.onAgain,
    required this.onExit,
  });

  final int score;
  final int corners;
  final int misses;
  final double seconds;
  final VoidCallback onAgain;
  final VoidCallback onExit;

  String get _rank {
    if (seconds < 15) return 'Caçador Lendário de Lobos 🏆';
    if (seconds < 30) return 'Domador de Devs 🦸';
    if (seconds < 60) return 'Estagiário Promissor 🧑‍💻';
    return 'Paciência de Code Review 🐢';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4A017), width: 4),
              boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 40)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                const Text(
                  'CERTIFICADO OFICIAL',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, color: Color(0xFF8B6914)),
                ),
                const SizedBox(height: 4),
                Text(
                  _rank,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2B2E4A)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Certificamos que você capturou o Julio $score vezes '
                  'em ${seconds.toStringAsFixed(1)}s'
                  '${corners > 0 ? ', acertou $corners cantinho${corners > 1 ? 's' : ''}' : ''}'
                  ' e errou só $misses toque${misses == 1 ? '' : 's'}.\n\n'
                  'Em troca, ele prometeu nunca mais subir código sem testar.\n'
                  '(Spoiler: ele mentiu.)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF4A4A4A), height: 1.45),
                ),
                const SizedBox(height: 16),
                const Text(
                  '— assinado: Julio Lobo, sob protesto 🐺',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF8B6914), fontSize: 12),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onExit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2B2E4A),
                          side: const BorderSide(color: Color(0xFF2B2E4A)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Voltar ao trabalho'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: onAgain,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF3742F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Mais uma! 🔥'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
