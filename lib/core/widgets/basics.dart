import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Card base: superfície com borda sutil, sem sombra pesada.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gaps.lg),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Título de seção com ação opcional à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.padding});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(4, Gaps.xl, 4, Gaps.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: context.text.labelMedium?.copyWith(
                color: context.tokens.muted,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// Ícone dentro de um quadrado arredondado com tom suave.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Avatar com iniciais e cor estável derivada do nome.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 42, this.imageUrl});

  final String name;
  final double size;
  final String? imageUrl;

  static const _palette = [
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFD97706),
    Color(0xFF16A34A),
    Color(0xFFF3742F),
    Color(0xFF475569),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[name.hashCode.abs() % _palette.length];
    final fallback = Text(
      Fmt.initials(name),
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: size * 0.36),
    );
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.2 : 0.12),
        shape: BoxShape.circle,
      ),
      child: (imageUrl ?? '').isEmpty
          ? fallback
          : Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

/// Chip de status de OS.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = StatusColors.of(status);
    final fg = context.isDark ? Color.lerp(color, Colors.white, 0.35)! : color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            status.isEmpty ? '—' : status,
            style: TextStyle(color: fg, fontSize: dense ? 11 : 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Linha "rótulo: valor" com ícone, usada nas telas de detalhe.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    return InkWell(
      onTap: empty ? null : onTap,
      borderRadius: BorderRadius.circular(Gaps.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.tokens.muted),
            const SizedBox(width: Gaps.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.text.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    empty ? 'Não informado' : value,
                    style: context.text.bodyLarge?.copyWith(
                      color: empty ? context.tokens.muted : null,
                      fontStyle: empty ? FontStyle.italic : null,
                    ),
                  ),
                ],
              ),
            ),
            if (!empty && trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Bloco de texto longo (descrição, defeito, laudo...).
class TextBlock extends StatelessWidget {
  const TextBlock({super.key, required this.title, required this.text, this.icon});

  final String title;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final content = Fmt.plain(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: context.tokens.muted),
              const SizedBox(width: Gaps.sm),
            ],
            Text(title, style: context.text.titleSmall),
          ],
        ),
        const SizedBox(height: Gaps.sm),
        Text(
          content.isEmpty ? 'Nada registrado.' : content,
          style: context.text.bodyMedium?.copyWith(
            color: content.isEmpty ? context.tokens.muted : null,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// Botão principal com estado de carregamento.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: Gaps.sm)],
                Text(label),
              ],
            ),
    );
  }
}

/// Limita a largura do conteúdo em telas grandes (tablet/web).
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}
