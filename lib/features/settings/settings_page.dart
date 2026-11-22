import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/config/app_config.dart';
import '../../core/storage/session_store.dart';
import '../../core/widgets/ui.dart';
import '../about/about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final auth = context.read<AuthState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: Gaps.pageOf(context),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Aparência', padding: EdgeInsets.fromLTRB(4, Gaps.sm, 4, Gaps.sm)),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Tema', style: context.text.titleSmall),
                      const SizedBox(height: Gaps.md),
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Sistema')),
                          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Claro')),
                          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Escuro')),
                        ],
                        selected: {theme.mode},
                        onSelectionChanged: (s) => theme.setMode(s.first),
                      ),
                    ],
                  ),
                ),
                const SectionHeader('Conexão'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.dns_outlined),
                        title: const Text('Servidor'),
                        subtitle: Text(auth.serverUrl ?? 'Não configurado'),
                      ),
                      const Divider(indent: Gaps.lg, endIndent: Gaps.lg),
                      ListTile(
                        leading: const Icon(Icons.cleaning_services_outlined),
                        title: const Text('Limpar dados offline'),
                        subtitle: const Text('Remove as informações salvas para uso sem internet'),
                        onTap: () async {
                          await context.read<SessionStore>().clearCache();
                          if (context.mounted) Toast.success(context, 'Dados offline removidos.');
                        },
                      ),
                    ],
                  ),
                ),
                const SectionHeader('Conta'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: const Text('Sobre o app'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                      ),
                      const Divider(indent: Gaps.lg, endIndent: Gaps.lg),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                        title: const Text('Sair', style: TextStyle(color: AppColors.danger)),
                        subtitle: const Text('Para trocar de servidor, saia e entre novamente'),
                        onTap: () async {
                          final ok = await confirmDialog(
                            context,
                            title: 'Sair da conta?',
                            message: 'Você precisará entrar novamente para acessar o app.',
                            confirmLabel: 'Sair',
                            destructive: true,
                          );
                          if (ok && context.mounted) await context.read<AuthState>().logout();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gaps.xl),
                Text('Versão ${AppConfig.appVersion}', style: context.text.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
