import 'package:flutter/material.dart';
import 'package:mapos_app/initial_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

void main() {
  initializeDateFormatting().then((_) {
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider()..loadThemeMode(),
        child: MaposApp(),
      ),
    );
  });
}

class MaposApp extends StatelessWidget {
  const MaposApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'MAP-OS APP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.themeMode,
      home: InitialPage(),
    );
  }
}
