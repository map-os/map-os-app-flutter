import 'package:flutter/material.dart';
import 'dart:math' as math;

class JulioLoboPage extends StatefulWidget {
  const JulioLoboPage({Key? key}) : super(key: key);

  @override
  State<JulioLoboPage> createState() => _JulioLoboPageState();
}

class _JulioLoboPageState extends State<JulioLoboPage>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _slideController;

  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _slideAnimation;

  bool _isActivated = false;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(
      begin: -20.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Inicia a animação de entrada
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (_pulseAnimation.value - 0.8) * 0.3,
              child: const Text(
                '👽 EASTER EGG SUPREMO ATIVADO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.greenAccent,
                      blurRadius: 10,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xff0a0a2e),
              Color(0xff16213e),
              Color(0xff0f3460),
              Color(0xff533483),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Partículas de fundo
            ...List.generate(20, (index) =>
                AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) => _buildParticle(index),
                ),
            ),

            // Círculos rotativos de fundo
            Center(
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Center(
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_rotationAnimation.value * 0.7,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.cyanAccent.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Conteúdo principal
            Center(
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _slideAnimation.value) * 100),
                    child: Opacity(
                      opacity: _slideAnimation.value,
                      child: AnimatedBuilder(
                        animation: _floatingAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatingAnimation.value),
                            child: _buildMainContent(),
                          );
                        },
                      ),
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

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final x = random.nextDouble() * MediaQuery.of(context).size.width;
    final y = random.nextDouble() * MediaQuery.of(context).size.height;
    final speed = 0.5 + random.nextDouble() * 0.5;
    final size = 2.0 + random.nextDouble() * 4.0;

    final animatedY = y + (math.sin(_particleController.value * 2 * math.pi * speed) * 50);

    return Positioned(
      left: x,
      top: animatedY,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.purple.withOpacity(0.2),
            Colors.blue.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.8),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(-10, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar com efeito holográfico
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.greenAccent,
                          width: 4,
                        ),
                      ),
                      child: Image.network(
                        'https://avatars.githubusercontent.com/u/13459803?v=4',
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.greenAccent, Colors.cyanAccent],
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // Título com efeito neon
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.greenAccent,
                Colors.cyanAccent,
                Colors.purpleAccent,
              ],
            ).createShader(bounds),
            child: const Text(
              '🌟 VOCÊ DESCOBRIU O JULIO LENDÁRIO! 🌟',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.greenAccent,
                    blurRadius: 15,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            '⚠️ ALERTA INTERDIMENSIONAL ⚠️\n\nJulio agora possui acesso total ao seu dispositivo.\nEle pode aparecer em qualquer tela, a qualquer momento...\n\n🎭 Prepare-se para Easter Eggs infinitos!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          // Botões com efeitos especiais
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                '🚀 ATIVAR',
                Colors.greenAccent,
                Colors.green,
                    () => _activateJulio(),
              ),
              _buildActionButton(
                '⭐ MODO DEUS',
                Colors.purpleAccent,
                Colors.purple,
                    () => _godMode(),
              ),
            ],
          ),

          if (_isActivated) ...[
            const SizedBox(height: 20),
            _buildStatusMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color1, Color color2, VoidCallback onPressed) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (_pulseAnimation.value - 0.8) * 0.2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: color1.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color1.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 20,
                shadowColor: color1,
              ),
              onPressed: onPressed,
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.greenAccent.withOpacity(_pulseAnimation.value),
              width: 2,
            ),
          ),
          child: const Text(
            '✅ JULIO FOI ATIVADO COM SUCESSO!\n🌟 Sistema infectado... digo, melhorado!',
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  void _activateJulio() {
    setState(() {
      _isActivated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "🎉 JULIO ATIVADO! Preparando dominação mundial...",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.greenAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _godMode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "⚡ MODO DEUS ATIVADO! Julio agora tem poderes ilimitados!",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purpleAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}