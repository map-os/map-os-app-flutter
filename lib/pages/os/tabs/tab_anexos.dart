import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';

class TabAnexos extends StatefulWidget {
  final Map<String, dynamic> os;

  TabAnexos({required this.os});

  @override
  _TabAnexosState createState() => _TabAnexosState();
}

class _TabAnexosState extends State<TabAnexos> {
  List<dynamic> osData = [];
  bool _loading = false;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _getProdutosOs();
    initializeNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? Center(child: CircularProgressIndicator())
        : osData.isNotEmpty
        ? GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: osData.length,
      itemBuilder: (BuildContext context, int index) {
        String fileExtension = osData[index]['anexo'].split('.').last.toLowerCase();
        Widget fileWidget;
        if (fileExtension == 'jpg' || fileExtension == 'jpeg' || fileExtension == 'png') {
          fileWidget = GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImage(
                    imageUrl: '${osData[index]['url']}/${osData[index]['anexo']}',
                  ),
                ),
              );
            },
            child: Image.network('${osData[index]['url']}/${osData[index]['anexo']}'),
          );

        } else if (fileExtension == 'pdf') {
          fileWidget = Image.asset('lib/assets/images/pdf.png');
        } else {
          fileWidget = Icon(Icons.insert_drive_file); // Ícone padrão para outros tipos de arquivos
        }
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: fileWidget,
              ),
              ButtonBar(
                alignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      _downloadFile(osData[index]['url'], osData[index]['anexo']);
                    },
                    icon: Icon(Icons.file_download),
                    color: Colors.green[700],
                  ),
                  IconButton(
                    onPressed: () {
                      _excluirAnexo(osData[index]['idAnexos']);
                    },
                    icon: Icon(Icons.delete),
                    color: Colors.red,
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImage(
                            imageUrl: '${osData[index]['url']}/${osData[index]['anexo']}',
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.remove_red_eye),
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    )
        : Center(
      child: Text('Nenhum anexo encontrado'),
    );
  }



  Future<Map<String, dynamic>> _getCiKeyAndPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _getProdutosOs() async {
    setState(() {
      _loading = true;
    });

    try {
      Map<String, dynamic> keyAndPermissions =
      await _getCiKeyAndPermissions();
      String ciKey = keyAndPermissions['ciKey'] ?? '';
      Map<String, String> headers = {'X-API-KEY': ciKey};
      var url =
          '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget
          .os['idOs']}?X-API-KEY=$ciKey';

      var response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('result') &&
            data['result'].containsKey('anexos')) {
          setState(() {
            osData = data['result']['anexos'];
            _loading = false;
          });
        } else {
          setState(() {
            osData = [];
            _loading = false;
          });
          print('Key "anexos" not found in API response');
        }
      } else {
        setState(() {
          _loading = false;
        });
        print('Failed to load os');
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      print('Error: $e');
    }
  }

  void initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      var response = await http.get(Uri.parse('$url/$fileName'));
      if (response.statusCode == 200) {
        Directory? directory = await getExternalStorageDirectory();
        String downloadPath = '/storage/emulated/0/Download';

        if (!Directory(downloadPath).existsSync()) {
          Directory(downloadPath).createSync(recursive: true);
        }

        String filePath = '$downloadPath/$fileName';

        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print('Arquivo baixado com sucesso na Pasta Dowload');

        await _showDownloadNotification(filePath);
      } else {
        print('Falha ao baixar o arquivo: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro durante o download: $e');
    }
  }

  Future<void> _showDownloadNotification(String filePath) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      'Download Concluído',
      'Arquivo baixado na pasta Dowload',
      platformChannelSpecifics,
    );
  }

  Future<void> _excluirAnexo(idAnexos) async {
    try {
      Map<String, dynamic> keyAndPermissions = await _getCiKeyAndPermissions();
      String ciKey = keyAndPermissions['ciKey'] ?? '';

      var url =
          '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget
          .os['idOs']}/anexos/$idAnexos';

      var response = await http.delete(
        Uri.parse(url),
        headers: {'X-API-KEY': ciKey},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        {
          print('problema com sua sessão, faça login novamente!');
        }
        // ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        //   SnackBar(
        //     content: Text('Produto excluído com sucesso!'),
        //     backgroundColor: Colors.green,
        //     duration: Duration(seconds: 2),
        //   ),
        // );
        _getProdutosOs();
      } else {}
    } catch (e) {
      print('Erro durante a exclusão $e');
    }
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}