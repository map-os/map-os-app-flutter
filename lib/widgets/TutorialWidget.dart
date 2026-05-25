import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialStep> _steps = [
    TutorialStep(
      title: "Bem-vindo ao Tutorial!",
      description: "Vamos te ensinar como configurar a URL da API do MAP-OS para conectar o aplicativo ao seu sistema.",
      icon: Icons.waving_hand,
      iconColor: Colors.amber,
      isIntro: true,
    ),
    TutorialStep(
      title: "1. Acesse seu MAP-OS",
      description: "Entre no seu sistema MAP-OS através do navegador usando suas credenciais de administrador.",
      icon: Icons.computer,
      iconColor: Colors.blue,
      image: "assets/images/1.png",
    ),
    TutorialStep(
      title: "2. Vá para Configurações",
      description: "Na Barra superior do sistema Clique na engrenagem",
      icon: Icons.settings,
      iconColor: Colors.grey,
      image: "assets/images/2.png",
      highlights: ["Procure por 'Sistema' no Dropdown", "Geralmente é a primeira opção"],
    ),
    TutorialStep(
      title: "3. Acesse a opção 'Sistema'",
      description: "",
      icon: Icons.dns,
      iconColor: Colors.orange,
      highlights: ["Configurações > Sistema"],
    ),
    TutorialStep(
      title: "4. Encontre a seção 'API'",
      description: "Role a página até encontrar a seção de configurações da API. Aqui você verá a URL da API do seu sistema.",
      icon: Icons.api,
      iconColor: Colors.green,
      highlights: ["Procure por 'API'", "Copie a URL base do sistema (sem /api/v1)"],
    ),
    TutorialStep(
      title: "5. Copie a URL da API",
      description: "Copie a URL base do sistema. O app adiciona /api/v1 automaticamente. Use apenas o domínio e caminho base, ex: https://seudominio.com/mapos/index.php",
      icon: Icons.content_copy,
      iconColor: Colors.purple,
      example: "https://exemplo.com/mapos/index.php",
      isExample: true,
    ),
    TutorialStep(
      title: "6. Configure no App",
      description: "Volte para o app, toque no ícone de configurações (⚙️) na tela de login e cole a URL copiada.",
      icon: Icons.mobile_friendly,
      iconColor: Colors.indigo,
      highlights: ["Ícone de engrenagem na tela de login", "Cole exatamente como copiou", "Não esqueça de salvar!"],
    ),
    TutorialStep(
      title: "Pronto! 🎉",
      description: "Agora você pode fazer login no aplicativo usando suas credenciais do MAP-OS. Se tiver problemas, verifique se a URL está correta.",
      icon: Icons.check_circle,
      iconColor: Colors.green,
      isSuccess: true,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginBg,
      appBar: AppBar(
        title: const Text(
          'Primeiros passos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Passo ${_currentPage + 1} de ${_steps.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${((_currentPage + 1) / _steps.length * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (_currentPage + 1) / _steps.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  minHeight: 6,
                ),
              ],
            ),
          ),

          // Page indicators (dots)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                    (index) => GestureDetector(
                  onTap: () => _goToPage(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? AppColors.accent
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tutorial content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: TutorialStepWidget(step: _steps[index]),
                );
              },
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                _currentPage > 0
                    ? ElevatedButton.icon(
                  onPressed: _previousPage,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                )
                    : const SizedBox(width: 100),

                // Next/Finish button
                ElevatedButton.icon(
                  onPressed: _currentPage < _steps.length - 1
                      ? _nextPage
                      : () => Navigator.of(context).pop(),
                  icon: Icon(_currentPage < _steps.length - 1
                      ? Icons.arrow_forward
                      : Icons.check),
                  label: Text(_currentPage < _steps.length - 1
                      ? 'Próximo'
                      : 'Finalizar'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String? image;
  final List<String>? highlights;
  final String? example;
  final bool isIntro;
  final bool isExample;
  final bool isSuccess;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    this.image,
    this.highlights,
    this.example,
    this.isIntro = false,
    this.isExample = false,
    this.isSuccess = false,
  });
}

class TutorialStepWidget extends StatelessWidget {
  final TutorialStep step;

  const TutorialStepWidget({Key? key, required this.step}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: step.iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.icon,
                size: 40,
                color: step.iconColor,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              step.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              step.description,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Example URL (if applicable)
            if (step.isExample && step.example != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Exemplo de URL:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              step.example!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'monospace',
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: step.example!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('URL copiada!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, color: AppColors.accent),
                          tooltip: 'Copiar exemplo',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Highlights (if applicable)
            if (step.highlights != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xfff0f8ff),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Dicas importantes:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...step.highlights!.map((highlight) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(
                            child: Text(
                              highlight,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],

            // Success message
            if (step.isSuccess) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.celebration, color: Colors.green, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Parabéns! Você configurou com sucesso a URL da API do MAP-OS!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Image placeholder (if applicable)
            if (step.image != null && step.image!.isNotEmpty) ...[
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  step.image!,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}