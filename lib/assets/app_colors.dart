import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class TemaPrimario {
  static Color primaryColor = Color(0xFF333649);
  static Color secondaryColor = Color(0xFFDC7902);
  static Color ColorText = Color(0xFFFFFFFF);
  static Color gradienteColor1 = Color(0xff1b2446);
  static Color gradienteColor2 = Color(0xff191d25);
  static Color backgroundColor = Color(0xff464c73);
  static Color colorBusca = Color(0xff464c73);
  static Color iconColor = Color(0xFFDC7902);
  static Color titleTextColor = Color(0xFFFFFFFF);
  static Color titleBackgrounColor = Color(0xFF333649);
  static Color snackBarBackgrounColorErro = Color(0xFFD70000);
  static Color snackBarBackgrounColorSuccess = Color(0xFF52A200);
  static Color inputColor = Color(0xff69779b);
  static Color inputBorderColor = Color(0xFFDC7902);
  static Color labelColor = Color(0xFFFFFFFF);
  static Color botaoBackgroudColor = Color(0xFFDC7902);
  static Color botaoTextColor = Color(0xFFFFFFFF);
  static Color botaoDisabledColor = Color(0xFFEFC8A9);
}

class TemaSecundario {
  static Color primaryColor = Color(0xFF333649);
  static Color secondaryColor = Color(0xFFFFFFFF);
  static Color ColorText = Color(0xFF333649);
  static Color ColorTextID = Color(0xFFFFFFFF);
  static Color gradienteColor1 = Color(0xFFF6F1F8);
  static Color gradienteColor2 = Color(0xFFF6F1F8);
  static Color backgroundColor = Color(0xFFFFFFFF);
  static Color colorBusca = Color(0xff464c73);
  static Color iconColor = Color(0xFF333649);
  static Color titleTextColor = Color(0xFFFFFFFF);
  static Color titleBackgrounColor = Color(0xFF333649);
  static Color gradienteColorTwo1 = Color(0xFF333649);
  static Color gradienteColorTwo2 = Color(0xFF333649);
  static Color snackBarBackgrounColorErro = Color(0xFFD70000);
  static Color snackBarBackgrounColorSuccess = Color(0xFF52A200);
  static Color inputColor = Color(0xffe9f0fc);
  static Color inputBorderColor = Color(0xff333960);
  static Color labelColor = Color(0xFF333649);
  static Color botaoBackgroudColor = Color(0xFF2F965E);
  static Color botaoTextColor = Color(0xFFFFFFFF);
  static Color botaoDisabledColor = Color(0xffa1a1a1);
}
class ThemePreferences {
  static const String themeKey = 'theme';

  Future<ThemeMode> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Retorna o tema salvo ou o tema claro como padrão
    return ThemeMode.values[prefs.getInt(themeKey) ?? ThemeMode.system.index];
  }


  Future<void> setTheme(ThemeMode theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeKey, theme.index);
  }
}