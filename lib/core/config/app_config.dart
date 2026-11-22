import 'package:flutter/foundation.dart';

/// Constantes globais do aplicativo.
abstract final class AppConfig {
  static const String appName = 'MAP-OS';
  static const String appVersion = '3.0.0';
  static const String apiPrefix = '/api/v1';

  static const Duration requestTimeout = Duration(seconds: 20);
  static const int pageSize = 20;

  static const String projectUrl = 'https://github.com/map-os/map-os-app-flutter';
  static const String appSiteUrl = 'https://map-os.github.io/map-os-app-flutter';
  static const String communityUrl = 'https://chat.whatsapp.com/GVSg8tPQzXy0grfYpRfQps';

  /// Normaliza a URL digitada pelo usuário:
  /// adiciona https://, remove barras finais e o sufixo /api/v1.
  static String normalizeBaseUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (kIsWeb && url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith(apiPrefix)) {
      url = url.substring(0, url.length - apiPrefix.length);
    }
    return url;
  }
}
