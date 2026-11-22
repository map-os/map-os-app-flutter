import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/config/app_config.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/conta.dart';
import '../about/about_page.dart';
import '../agenda/agenda_page.dart';
import '../settings/settings_page.dart';
import 'profile_page.dart';

/// Menu da conta (bottom sheet): perfil, atalhos, aparência e sair.
Future<void> showAccountMenu(BuildContext context, Usuario? usuario) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => _AccountSheet(usuario: usuario, parent: context),
  );
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet({required this.usuario, required this.parent});

  final Usuario? usuario;

  /// Contexto de quem abriu o menu — usado para navegar depois de fechar.
  final BuildContext parent;

  void _open(BuildContext sheet, Widget page) {
    Navigator.pop(sheet);
    Navigator.push(parent, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _logout(BuildContext sheet) async {
    Navigator.pop(sheet);
    final ok = await confirmDialog(
      parent,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente para acessar o app.',
      confirmLabel: 'Sair',
      destructive: true,
    );
    if (ok && parent.mounted) await parent.read<AuthState>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final server = (context.read<AuthState>().serverUrl ?? '').replaceFirst(RegExp(r'^https?://'), '');
    final theme = context.watch<ThemeState>();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.lg + Gaps.systemBottom(context)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cartão do usuário
              Container(
                padding: const EdgeInsets.all(Gaps.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brand, AppColors.brandDeep],
                  ),
                  borderRadius: BorderRadius.circular(Gaps.radiusLg),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent, width: 2),
                      ),
                      child: InitialsAvatar(usuario?.nome ?? 'U', size: 52, imageUrl: usuario?.fotoUrl),
                    ),
                    const SizedBox(width: Gaps.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario?.nome ?? 'Minha conta',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium?.copyWith(color: Colors.white),
                          ),
                          if ((usuario?.email ?? '').isNotEmpty)
                            Text(
                              usuario!.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          if (server.isNotEmpty) ...[
                            const SizedBox(height: Gaps.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      server,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gaps.lg),

              // Atalhos
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Gaps.sm,
                crossAxisSpacing: Gaps.sm,
                childAspectRatio: 0.92,
                children: [
                  _Shortcut(
                    icon: Icons.person_rounded,
                    label: 'Perfil',
                    color: AppColors.clientes,
                    onTap: () => _open(context, const ProfilePage()),
                  ),
                  _Shortcut(
                    icon: Icons.calendar_month_rounded,
                    label: 'Agenda',
                    color: AppColors.garantias,
                    onTap: () => _open(context, const AgendaPage()),
                  ),
                  _Shortcut(
                    icon: Icons.settings_rounded,
                    label: 'Ajustes',
                    color: AppColors.servicos,
                    onTap: () => _open(context, const SettingsPage()),
                  ),
                  _Shortcut(
                    icon: Icons.info_rounded,
                    label: 'Sobre',
                    color: AppColors.os,
                    onTap: () => _open(context, const AboutPage()),
                  ),
                ],
              ),
              const SizedBox(height: Gaps.lg),

              // Aparência
              AppCard(
                padding: const EdgeInsets.fromLTRB(Gaps.lg, Gaps.md, Gaps.md, Gaps.md),
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, color: context.tokens.muted),
                    const SizedBox(width: Gaps.md),
                    Expanded(child: Text('Aparência', style: context.text.titleSmall)),
                    _ThemeToggle(mode: theme.mode, onChanged: theme.setMode),
                  ],
                ),
              ),
              const SizedBox(height: Gaps.md),

              // Sair
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sair da conta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radius)),
                  ),
                ),
              ),
              const SizedBox(height: Gaps.md),
              Text(
                '${AppConfig.appName} Mobile · v${AppConfig.appVersion}',
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: Gaps.md, horizontal: Gaps.xs),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconBadge(icon, color: color, size: 40),
          const SizedBox(height: Gaps.sm),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelMedium),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (ThemeMode.system, Icons.brightness_auto_rounded, 'Automático'),
      (ThemeMode.light, Icons.light_mode_rounded, 'Claro'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Escuro'),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: context.tokens.subtle, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (m, icon, tip) in options)
            Tooltip(
              message: tip,
              child: GestureDetector(
                onTap: () => onChanged(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: m == mode ? context.colors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: m == mode ? context.tokens.border : Colors.transparent),
                  ),
                  child: Icon(icon, size: 18, color: m == mode ? AppColors.accent : context.tokens.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
