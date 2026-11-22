import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', themeMode.toString());
    notifyListeners();
  }

  Future<void> loadThemeMode() async {
    var prefs = await SharedPreferences.getInstance();
    var themeModeString = prefs.getString('themeMode') ?? ThemeMode.light.toString();
    _themeMode = ThemeMode.values.firstWhere(
          (element) => element.toString() == themeModeString,
      orElse: () => ThemeMode.light,
    );
    notifyListeners();
  }
}

