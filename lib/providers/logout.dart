import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String _ciKey = '';
  List<dynamic> _permissoes = [];

  String get ciKey => _ciKey;
  List<dynamic> get permissoes => _permissoes;

  Future<void> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    _permissoes = jsonDecode(permissoesString);
    notifyListeners(); // Notifica os ouvintes sobre a atualização dos dados do usuário
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('permissoes');
    notifyListeners(); // Notifica os ouvintes sobre a atualização dos dados do usuário
  }
}
