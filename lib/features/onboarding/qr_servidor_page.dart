import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/config/app_config.dart';

String? enderecoDoQr(String? conteudo) {
  final texto = (conteudo ?? '').trim();
  final uri = Uri.tryParse(texto);
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) return null;
  final semConsulta = uri.replace(query: '', fragment: '').toString().replaceAll(RegExp(r'[?#]+$'), '');
  return AppConfig.normalizeBaseUrl(semConsulta);
}

class QrServidorPage extends StatefulWidget {
  const QrServidorPage({super.key});

  @override
  State<QrServidorPage> createState() => _QrServidorPageState();
}

class _QrServidorPageState extends State<QrServidorPage> {
  final _controle = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _lido = false;
  String? _aviso;

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  void _detectou(BarcodeCapture captura) {
    if (_lido) return;
    for (final codigo in captura.barcodes) {
      final endereco = enderecoDoQr(codigo.rawValue);
      if (endereco != null) {
        _lido = true;
        Navigator.of(context).pop(endereco);
        return;
      }
    }
    setState(() => _aviso = 'Esse QR code não tem o endereço de um MAP-OS.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ler QR code do servidor'),
        actions: [
          IconButton(tooltip: 'Lanterna', icon: const Icon(Icons.flashlight_on_outlined), onPressed: () => _controle.toggleTorch()),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controle,
            onDetect: _detectou,
            errorBuilder: (context, erro) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  erro.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Permita o uso da câmera nas configurações do aparelho para ler o QR code.'
                      : 'Não foi possível abrir a câmera.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              _aviso ?? 'No painel do MAP-OS, abra Configurações › API e aponte a câmera para o QR code.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15, shadows: [Shadow(blurRadius: 8)]),
            ),
          ),
        ],
      ),
    );
  }
}
