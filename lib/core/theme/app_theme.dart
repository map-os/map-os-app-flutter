import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Espaçamentos e raios padronizados.
abstract final class Gaps {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radiusSm = 10;
  static const double radius = 14;
  static const double radiusLg = 20;

  static const EdgeInsets page = EdgeInsets.fromLTRB(lg, md, lg, xl);

  /// Espaço da barra de navegação do sistema (gestos/botões).
  /// Já vem 0 quando o Scaffold tem `bottomNavigationBar` ou o teclado está aberto.
  static double systemBottom(BuildContext context) => MediaQuery.paddingOf(context).bottom;

  /// [page] + espaço para a barra do sistema — use em listas roláveis de tela cheia.
  static EdgeInsets pageOf(BuildContext context) =>
      page.copyWith(bottom: page.bottom + systemBottom(context));

  /// Base inferior para bottom sheets: teclado (se aberto) + barra do sistema.
  static double sheetBottom(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom;
}

/// Extensão de tema com tokens que o Material não cobre.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({required this.border, required this.muted, required this.subtle});

  final Color border;
  final Color muted;
  final Color subtle; // fundo de áreas secundárias

  @override
  AppTokens copyWith({Color? border, Color? muted, Color? subtle}) => AppTokens(
        border: border ?? this.border,
        muted: muted ?? this.muted,
        subtle: subtle ?? this.subtle,
      );

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
    );
  }
}

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final surface = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = dark ? AppColors.borderDark : AppColors.borderLight;
    final onSurface = dark ? AppColors.textDark : AppColors.textLight;
    final muted = dark ? AppColors.mutedDark : AppColors.mutedLight;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xFFB9BEF0) : AppColors.brand,
      onPrimary: dark ? AppColors.brandDeep : Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: muted,
      surfaceContainerLowest: bg,
      surfaceContainerLow: dark ? const Color(0xFF131621) : const Color(0xFFF9FAFC),
      surfaceContainer: dark ? const Color(0xFF1C2030) : const Color(0xFFF1F2F7),
      surfaceContainerHigh: dark ? const Color(0xFF222738) : const Color(0xFFEBEDF3),
      outline: border,
      outlineVariant: border,
      error: AppColors.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );

    final text = base.textTheme.apply(bodyColor: onSurface, displayColor: onSurface).copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: onSurface,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: onSurface,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: onSurface),
          titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: onSurface),
          titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: onSurface),
          labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          bodySmall: base.textTheme.bodySmall?.copyWith(color: muted),
        );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Gaps.radiusSm),
      borderSide: BorderSide(color: border),
    );

    return base.copyWith(
      textTheme: text,
      extensions: [AppTokens(border: border, muted: muted, subtle: scheme.surfaceContainer)],
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 20),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Gaps.radius),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: scheme.primary, width: 1.6)),
        errorBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder:
            inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.danger, width: 1.6)),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted.withValues(alpha: 0.7)),
        prefixIconColor: muted,
        suffixIconColor: muted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radiusSm)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size(64, 50),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radiusSm)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? scheme.primary : AppColors.brand,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radius)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accent.withValues(alpha: 0.14),
        height: 68,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? onSurface : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? AppColors.accent : muted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.14),
        selectedIconTheme: const IconThemeData(color: AppColors.accent),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: TextStyle(fontWeight: FontWeight.w700, color: onSurface, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: muted, fontSize: 12),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w500),
        selectedColor: AppColors.brand,
        secondarySelectedColor: AppColors.brand,
        checkmarkColor: Colors.white,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: onSurface,
        unselectedLabelColor: muted,
        indicatorColor: AppColors.accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: border,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabAlignment: TabAlignment.start,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radiusSm)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Gaps.radiusLg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radiusLg)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF2A2F42) : AppColors.brandDeep,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radiusSm)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radiusSm)),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.accent),
    );
  }
}
