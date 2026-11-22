import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CacheHelper {
  static const List<String> _cacheKeys = [
    'cached_Clients',
    'cached_OrdemServico',
    'cached_services',
    'cached_products',
    'cached_Chamados',
    'cached_events',
    'dashboard_data',
  ];

  static Future<bool> safeSetString(
    SharedPreferences prefs,
    String key,
    String value,
  ) async {
    try {
      return await prefs.setString(key, value);
    } catch (e) {
      if (kIsWeb) {
        debugPrint('Cache cheio, limpando dados antigos...');
        await _clearOldestCaches(prefs);
        try {
          return await prefs.setString(key, value);
        } catch (e2) {
          debugPrint('Falha ao salvar mesmo apos limpeza: $e2');
          return false;
        }
      }
      rethrow;
    }
  }

  static Future<void> _clearOldestCaches(SharedPreferences prefs) async {
    for (final key in _cacheKeys) {
      await prefs.remove(key);
    }
  }
}