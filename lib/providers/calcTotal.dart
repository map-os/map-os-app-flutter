import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';

class OsCalculator {
  late double _calctotal;
  Future<void> getCalcTotal(Map<String, dynamic> os) async {
    try {
      Map<String, dynamic> keyAndPermissions = await _getCiKey();
      String ciKey = keyAndPermissions['ciKey'] ?? '';
      var url =
          '${APIConfig.baseURL}${APIConfig.osEndpoint}/${os['idOs']}?X-API-KEY=$ciKey';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('refresh_token')) {
          String refreshToken = data['refresh_token'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', refreshToken);
        }
        if (data.containsKey('result')) {
          _calctotal = data['result']['calcTotal'];
        } else {
          print('Error: No result key in response');
        }
      } else {
        print('Failed to load OS: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during OS loading: $e');
    }
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  String formatCurrency() {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(_calctotal);
  }

  double get calcTotal => _calctotal;
}
