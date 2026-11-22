import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/widgets/ui.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _team = [
    ('Felipe Santt', 'Desenvolvimento mobile', 'https://avatars.githubusercontent.com/u/33626716?v=4'),
    ('Julio Lobo', 'API e back-end', 'https://avatars.githubusercontent.com/u/13459803?v=4'),
    ('N4m3r', 'Colaborador', ''),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) Toast.error(context, 'Não foi possível abrir o link.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: ListView(
        padding: Gaps.pageOf(context),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(Gaps.xl),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDeep]),
                    borderRadius: BorderRadius.circular(Gaps.radiusLg),
                  ),
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo.png', height: 48),
                      const SizedBox(height: Gaps.lg),
                      Text(
                        'Aplicativo oficial para o sistema MAP-OS de gestão de ordens de serviço.',
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: Gaps.md),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'v${AppConfig.appVersion}',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionHeader('Equipe'),
                Card(
                  child: Column(
                    children: [
                      for (final (i, m) in _team.indexed) ...[
                        if (i > 0) const Divider(indent: Gaps.lg, endIndent: Gaps.lg),
                        ListTile(
                          leading: InitialsAvatar(m.$1, imageUrl: m.$3),
                          title: Text(m.$1),
                          subtitle: Text(m.$2),
                        ),
                      ],
                    ],
                  ),
                ),
                const SectionHeader('Links'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const IconBadge(Icons.favorite_rounded, color: AppColors.accent, size: 36),
                        title: const Text('Apoie o projeto'),
                        subtitle: const Text('Ajude a manter o MAP-OS evoluindo'),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                        onTap: () => _open(context, AppConfig.appSiteUrl),
                      ),
                      const Divider(indent: Gaps.lg, endIndent: Gaps.lg),
                      ListTile(
                        leading: const IconBadge(Icons.code_rounded, color: AppColors.brand, size: 36),
                        title: const Text('Código-fonte do app'),
                        subtitle: const Text('github.com/map-os/map-os-app-flutter'),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                        onTap: () => _open(context, AppConfig.projectUrl),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gaps.xl),
                Text('Feito com Flutter · Licença MIT', style: context.text.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
