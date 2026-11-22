import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

abstract final class Toast {
  static void success(BuildContext context, String message) =>
      _show(context, message, Icons.check_circle_rounded, AppColors.success);

  static void error(BuildContext context, Object error) => _show(
        context,
        error is String ? error : friendlyError(error),
        Icons.error_rounded,
        const Color(0xFFF87171),
      );

  static void info(BuildContext context, String message) =>
      _show(context, message, Icons.info_rounded, const Color(0xFF93C5FD));

  static void _show(BuildContext context, String message, IconData icon, Color color) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: Gaps.md),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

/// Diálogo de confirmação. Retorna true se o usuário confirmar.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Executa uma ação assíncrona com overlay de carregamento e trata erros.
/// Retorna o resultado ou null em caso de falha.
Future<T?> runWithProgress<T>(
  BuildContext context,
  Future<T> Function() action, {
  String? success,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  try {
    final result = await action();
    navigator.pop();
    if (success != null && context.mounted) Toast.success(context, success);
    return result;
  } catch (e) {
    navigator.pop();
    if (context.mounted) Toast.error(context, e);
    return null;
  }
}

/// Variante para ações sem retorno: devolve true em caso de sucesso.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  final ok = await runWithProgress<bool>(context, () async {
    await action();
    return true;
  }, success: success);
  return ok ?? false;
}
