import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';

class OsCalculator {
  String _calctotal = '0.0'; // Inicializado como uma string

  Future<void> getCalcTotal(Map<String, dynamic> os) async {
    try {
      final ciKey = await _getCiKey();

      final headers = {
        'X-API-KEY': ciKey,
      };

      final url = '${APIConfig.baseURL}${APIConfig.osEndpoint}/${os['idOs']}';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('result')) {
          _calctotal = data['result']['calcTotal']?.toString() ?? '0.0'; // Convertendo para String
        } else {
          throw Exception('Error: No result key in response');
        }
      } else {
        throw Exception('Failed to load OS: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during OS loading: $e');
      // Consider rethrowing or handling the exception more specifically
    }
  }

  Future<String> _getCiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  String formatCurrency() {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(double.parse(_calctotal)); // Formatando como moeda e convertendo para double
  }

  String get calcTotal => _calctotal; // Getter retorna a String diretamente
}
