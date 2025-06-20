import 'package:flutter/material.dart';

class EmDesenvolvimentoPage extends StatelessWidget {
  const EmDesenvolvimentoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Área em Desenvolvimento'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 80,
                color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
              ),
              const SizedBox(height: 20),
              Text(
                'Calma meu nobre!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Esta área ainda está em desenvolvimento.\n\nEm breve você poderá desfrutar dela 😉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey[300] : Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.orange.shade400 : Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
