import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../network/api_exception.dart';
import '../theme/app_theme.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gaps.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: context.tokens.subtle, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: context.tokens.muted),
            ),
            const SizedBox(height: Gaps.lg),
            Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: Gaps.xs),
              Text(message!, style: context.text.bodySmall, textAlign: TextAlign.center),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: Gaps.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = error is ApiException && (error as ApiException).isNetwork;
    return EmptyView(
      icon: offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: offline ? 'Sem conexão' : 'Não foi possível carregar',
      message: friendlyError(error),
      actionLabel: 'Tentar novamente',
      onAction: onRetry,
    );
  }
}

/// Esqueleto de carregamento para listas.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 8, this.padding = Gaps.page});

  final int count;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final base = context.isDark ? const Color(0xFF1E2230) : const Color(0xFFE9EBF1);
    final hi = context.isDark ? const Color(0xFF2A2F40) : const Color(0xFFF6F7FA);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: hi,
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: Gaps.sm),
        itemBuilder: (_, __) => Container(
          height: 76,
          decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(Gaps.radius)),
        ),
      ),
    );
  }
}

/// Carregador genérico para telas de detalhe.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.future,
    required this.builder,
    required this.onRetry,
  });

  final Future<T>? future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) return ErrorView(error: snap.error!, onRetry: onRetry);
        if (!snap.hasData) return const SkeletonList(count: 5);
        return builder(context, snap.data as T);
      },
    );
  }
}
