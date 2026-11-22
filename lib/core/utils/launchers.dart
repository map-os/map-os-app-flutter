import 'package:url_launcher/url_launcher.dart';

import 'formatters.dart';

/// Atalhos para abrir apps externos.
abstract final class Launch {
  static Future<bool> phone(String number) =>
      launchUrl(Uri(scheme: 'tel', path: Fmt.onlyDigits(number)));

  static Future<bool> email(String address) => launchUrl(Uri(scheme: 'mailto', path: address));

  static Future<bool> whatsapp(String number, {String text = ''}) {
    var digits = Fmt.onlyDigits(number);
    if (digits.length <= 11) digits = '55$digits';
    final uri = Uri.https('wa.me', '/$digits', text.isEmpty ? null : {'text': text});
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> maps(String address) => launchUrl(
        Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': address}),
        mode: LaunchMode.externalApplication,
      );
}
