import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//tema primario = tema escuro -- tema secundario/padrão = tema claro

class TemaPrimario {
  //dashboard e cores primarias ------------------------------------------------
  static Color primaryColor = Color(0xFF333649);
  static Color secondaryColor = Color(0xff181f36);
  static Color ColorText = Color(0xFFFFFFFF);
  static Color gradienteColor1 = Color(0xff181f36);
  static Color gradienteColor2 = Color(0xff0c0d0e);
  static Color backgroundColor = Color(0xff464c73);
  // fim dashboard -------------------------------------------------------------

  static Color colorBusca = Color(0xff464c73);
  static Color iconColor = Color(0xFFDC7902);
  static Color iconColorCliente = Color(0xFF4DB3F7);
  static Color iconColorServicos = Color(0xFF4CC2C2);
  static Color iconColorProdutos = Color(0xFFFDC259);
  static Color titleTextColor = Color(0xFFFFFFFF);
  static Color titleBackgrounColor = Color(0xFF333649);

  //snack bar ------------------------------------------------------------------
  static Color snackBarBackgrounColorErro = Color(0xFFD70000);
  static Color snackBarBackgrounColorSuccess = Color(0xFF52A200);
  //fim snackbar ---------------------------------------------------------------

  static Color inputColor = Color(0xff69779b);
  static Color inputBorderColor = Color(0xFFDC7902);
  static Color labelColor = Color(0xFFFFFFFF);
  static Color botaoBackgroudColor = Color(0xFFDC7902);
  static Color botaoTextColor = Color(0xFFFFFFFF);
  static Color botaoDisabledColor = Color(0xFFEFC8A9);
  static Color borderDash = Color(0xd5d5d5);
  static Color editbackColor = Color(0xff464c73);

  // tela de listagem
  static Color listagemCard = Color(0xff181f36);
  static Color listagemTextColor = Color(0xffffffff);
  static Color listagemBackground = Color(0xff464c73);
  static Color backId = Color(0xFFDC7902);
  static Color idColor = Color(0xffffffff);
  static Color buscaBack = Color(0xff464c73);
  static Color buscaFont = Color(0xffffffff);
  static Color appBar = Color(0xffffffff);

  //status color
  // static Color listagemCard = Color(0xff181f36);
  // static Color listagemTextColor = Color(0xffffffff);
  // static Color listagemBackground = Color(0xff464c73);
  // static Color backId = Color(0xFFDC7902);
  // static Color idColor = Color(0xffffffff);
  // static Color buscaBack = Color(0xff464c73);
  // static Color buscaFont = Color(0xffffffff);
  // static Color appBar = Color(0xffffffff);

}

class TemaSecundario {
  static Color primaryColor = Color(0xFFEFEFEF);
  static Color secondaryColor = Color(0xFFE0E0E0);

  static Color ColorText = Color(0xFF29292A);
  static Color ColorTextID = Color(0xFFFFFFFF);
  static Color gradienteColor1 = Color(0xFFFFFFFF);
  static Color gradienteColor2 = Color(0xFFD5D5D5);
  static Color backgroundColor = Color(0xFFD6D6EF);
  static Color colorBusca = Color(0xff464c73);
  static Color iconColor = Color(0xFF333649);
  static Color iconColorCliente = Color(0xFF4DB3F7);
  static Color iconColorServicos = Color(0xFF4CC2C2);
  static Color iconColorProdutos = Color(0xFFFDC259);
  static Color iconColorOs = Color(0xFFFD6987);
  static Color iconColorGarantias = Color(0xFF966ABD);
  static Color iconColorVendas = Color(0xFF15B597);
  static Color titleTextColor = Color(0xFF333649);
  static Color titleBackgrounColor = Color(0xffffffff);
  static Color gradienteColorTwo1 = Color(0xFFFFFFFF);
  static Color gradienteColorTwo2 = Color(0xFFD5D5D5);

  //snack bar----------------------------------------------------------------------
  static Color snackBarBackgrounColorErro = Color(0xFFD70000);
  static Color snackBarBackgrounColorSuccess = Color(0xFF52A200);

  //fim snack bar-----------------------------------------------------------------

  //edit screens--------------------------------------------------------------------
  static Color inputColor = Color(0xffe9f0fc);
  static Color inputBorderColor = Color(0xff333960);
  static Color labelColor = Color(0xFF333649);
  static Color botaoBackgroudColor = Color(0xFF2F965E);
  static Color botaoTextColor = Color(0xFFFFFFFF);
  static Color botaoDisabledColor = Color(0xffa1a1a1);
  static Color borderDash = Colors.transparent;
  static Color editbackColor = Color(0xFFEFEFEF);

  //fim edit screens--------------------------------------------------------------

  //telas de listagem---------------------------------------------------------------
  static Color listagemCard = Color(0xffffffff);
  static Color listagemTextColor = Color(0xff000000);
  static Color listagemBackground = Color(0xffe8ebf5);
  static Color backId = Color(0xff171717);
  static Color idColor = Color(0xffffffff);
  static Color buscaBack = Color(0xffd0cece);
  static Color buscaFont = Color(0xff171717);
  static Color appBar = Color(0xffffffff);
//fim telas de listagem ------------------------------------------------------
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