import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:isolate';
import 'dart:io';
import 'dart:ui';

class AnexosTab extends StatefulWidget {
  final Map<String, dynamic>? ordemServico;

  AnexosTab({this.ordemServico});

  @override
  _AnexosTabState createState() => _AnexosTabState();
}

class _AnexosTabState extends State<AnexosTab> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = DownloadTaskStatus.values[data[1]];
      int progress = data[2];

      if (status == DownloadTaskStatus.complete) {
        _showNotification();
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);

    var initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);


  }

  static void downloadCallback(
      String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  Future<void> _showNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channelId',
      'channelName',
      channelDescription: 'channelDescription',
      importance: Importance.max,
      priority: Priority.high,
    );
    var platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Download completo',
      'O arquivo foi baixado com sucesso.',
      platformChannelSpecifics,
    );
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) { // Android 13 (API 33) ou superior
        // No Android 13+ (API 33+), usamos as novas permissões específicas
        await [
          Permission.photos,       // Para fotos
          Permission.videos,      // Para vídeos
          Permission.notification // Se precisar de notificações
        ].request();
      } else {
        // Para versões anteriores ao Android 13
        await [
          Permission.storage,
          Permission.camera,      // Se precisar da câmera
        ].request();
      }
    } else if (Platform.isIOS) {
      // Permissões para iOS
      await [
        Permission.photos,
        Permission.camera,
      ].request();
    }
  }


  void _downloadFile(String url) async {
    final status = await Permission.photos.status;
    if (!status.isGranted) {
      await Permission.videos.request();
    }

    final Directory? externalStorageDir = await getExternalStorageDirectory();
    final String savedDir = externalStorageDir?.path ?? '/storage/emulated/0/Download';

    await FlutterDownloader.enqueue(
      url: url,
      savedDir: savedDir,
      showNotification: true,
      openFileFromNotification: true,
      saveInPublicStorage: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ordemServico == null || widget.ordemServico!['anexos'] == null) {
      return Center(
        child: Text(
          'Nenhum anexo disponível',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    List<dynamic> anexos = widget.ordemServico!['anexos'];

    return GridView.builder(
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.7,
      ),
      itemCount: anexos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.0),
                        child: PhotoView(
                          imageProvider: NetworkImage(
                              '${anexos[index]['url']}/${anexos[index]['anexo']}'),
                          backgroundDecoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(12.0)),
                    child: Image.network(
                      '${anexos[index]['url']}/thumbs/${anexos[index]['thumb']}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ButtonBar(
                    alignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.download, color: Colors.blue),
                        onPressed: () {
                          _downloadFile(
                              '${anexos[index]['url']}/${anexos[index]['anexo']}');
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Lógica para excluir
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
