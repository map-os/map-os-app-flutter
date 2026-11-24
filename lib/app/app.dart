import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/session_store.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/area_cliente_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cadastros_repository.dart';
import '../data/repositories/gestao_repository.dart';
import '../data/repositories/os_repository.dart';
import '../features/auth/login_page.dart';
import '../features/cliente/cliente_shell.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/profile/seguranca_pages.dart';
import '../features/shell/home_shell.dart';
import 'app_state.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class MaposApp extends StatefulWidget {
  const MaposApp({super.key, required this.session});

  final SessionStore session;

  @override
  State<MaposApp> createState() => _MaposAppState();
}

class _MaposAppState extends State<MaposApp> {
  late final ApiClient _api = ApiClient(widget.session);
  late final AuthState _auth = AuthState(widget.session, AuthRepository(_api, widget.session));
  late final ThemeState _theme = ThemeState(widget.session);

  @override
  void initState() {
    super.initState();
    _api.onSessionExpired = _auth.sessionExpired;
    _api.onDoisFatoresObrigatorio = _auth.doisFatoresObrigatorio;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.session),
        Provider.value(value: _api),
        Provider(create: (_) => ClientesRepository(_api)),
        Provider(create: (_) => ProdutosRepository(_api)),
        Provider(create: (_) => ServicosRepository(_api)),
        Provider(create: (_) => OsRepository(_api)),
        Provider(create: (_) => ContaRepository(_api)),
        Provider(create: (_) => AreaClienteRepository(_api)),
        Provider(create: (_) => VendasRepository(_api)),
        Provider(create: (_) => LancamentosRepository(_api)),
        Provider(create: (_) => CobrancasRepository(_api)),
        Provider(create: (_) => GarantiasRepository(_api)),
        Provider(create: (_) => ArquivosRepository(_api)),
        Provider(create: (_) => RelatoriosRepository(_api)),
        Provider(create: (_) => AdminRepository(_api)),
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _theme),
      ],
      child: Consumer<ThemeState>(
        builder: (context, theme, _) => MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.mode,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Alterna entre Onboarding, Login e o app conforme a sessão.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AuthState, bool>((a) => a.loggedIn);
    final onboarding = context.select<AuthState, bool>((a) => a.needsOnboarding);
    final doisFatores = context.select<AuthState, bool>((a) => a.doisFatoresPendente);
    final cliente = context.select<AuthState, bool>((a) => a.isCliente);
    if (!loggedIn) {
      // Fecha telas empilhadas quando a sessão termina.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.popUntil((r) => r.isFirst);
      });
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: loggedIn && doisFatores
          ? const _DoisFatoresObrigatorio(key: ValueKey('2fa'))
          : loggedIn && cliente
          ? const ClienteShell(key: ValueKey('cliente'))
          : loggedIn
          ? const HomeShell(key: ValueKey('home'))
          : onboarding
              ? const OnboardingPage(key: ValueKey('onboarding'))
              : const LoginPage(key: ValueKey('login')),
    );
  }
}

class _DoisFatoresObrigatorio extends StatelessWidget {
  const _DoisFatoresObrigatorio({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DoisFatoresPage(),
        Positioned(
          right: 8,
          top: MediaQuery.paddingOf(context).top + 4,
          child: TextButton.icon(
            onPressed: () => context.read<AuthState>().logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair'),
          ),
        ),
      ],
    );
  }
}
