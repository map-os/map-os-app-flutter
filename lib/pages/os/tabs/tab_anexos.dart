import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:image_picker/image_picker.dart';

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
    _getAnexosOs();
    initializeNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? Center(child: CircularProgressIndicator())
        : Stack(
      children: [
        osData.isNotEmpty
            ? GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: osData.length,
          itemBuilder: (BuildContext context, int index) {
            String fileExtension =
            osData[index]['anexo']
                .split('.')
                .last
                .toLowerCase();
            Widget fileWidget;
            if (fileExtension == 'jpg' ||
                fileExtension == 'jpeg' ||
                fileExtension == 'png') {
              fileWidget = GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullScreenImage(
                            imageUrl:
                            '${osData[index]['url']}/${osData[index]['anexo']}',
                          ),
                    ),
                  );
                },
                child: Image.network(
                    '${osData[index]['url']}/${osData[index]['anexo']}'),
              );
            } else if (fileExtension == 'pdf') {
              fileWidget = Image.asset('lib/assets/images/pdf.png');
            } else {
              fileWidget = Icon(Icons
                  .insert_drive_file); // Ícone padrão para outros tipos de arquivos
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
                          _downloadFile(osData[index]['url'],
                              osData[index]['anexo']);
                        },
                        icon: Icon(Icons.file_download),
                        color: Colors.blue[700],
                      ),
                      IconButton(
                        onPressed: () {
                          _excluirAnexo(osData[index]['idAnexos']);
                        },
                        icon: Icon(Icons.delete),
                        color: Colors.red,
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
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _pickFile,
            child: Icon(Icons.add),
            backgroundColor: Color(0xffe9dcfe),
          ),
        ),
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            onPressed: _takePicture,
            child: Icon(Icons.camera_alt_rounded),
            backgroundColor: Color(0xffe9dcfe),
          ),
        ),
      ],
    );
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

  Future<Map<String, dynamic>> _getCiKeyAndPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _getAnexosOs() async {
    setState(() {
      _loading = true;
    });

    try {
      Map<String, dynamic> keyAndPermissions =
      await _getCiKeyAndPermissions();
      String ciKey = keyAndPermissions['ciKey'] ?? '';
      Map<String, String> headers = {'X-API-KEY': ciKey};
      var url = '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}?X-API-KEY=$ciKey';

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
        _getAnexosOs();
      } else {}
    } catch (e) {
      print('Erro durante a exclusão $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'png',
          'gif',
          'jpeg',
          'JPG',
          'PNG',
          'GIF',
          'JPEG',
          'pdf',
          'PDF',
          'cdr',
          'CDR',
          'docx',
          'DOCX',
          'txt'
        ],
      );

      if (result != null) {
        PlatformFile file = result.files.first;

        print('Arquivo selecionado: ${file.name}');

        await _uploadFile(file);
      } else {
        print('Nenhum arquivo selecionado.');
      }
    } catch (e) {
      print('Erro ao selecionar o arquivo: $e');
    }
  }


  Future<void> _takePicture() async {
    try {
      XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        PlatformFile platformFile = PlatformFile(
          name: pickedFile.name,
          path: pickedFile.path!,
          size: (await pickedFile.length()).toInt(),
        );

        print('Imagem capturada: ${pickedFile.path}');
        await _uploadFile(platformFile);
      } else {
        print('Nenhuma imagem capturada.');
      }
    } catch (e) {
      print('Erro ao capturar a imagem: $e');
    }
  }


  Future<void> _uploadFile(PlatformFile file) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String ciKey = prefs.getString('token') ?? '';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget
            .os['idOs']}/anexos'),
      );

      request.headers['X-API-KEY'] = ciKey;

      request.files.add(
        http.MultipartFile(
          'userfile',
          File(file.path!).readAsBytes().asStream(),
          file.size,
          filename: file.name,
          contentType: http_parser.MediaType.parse('application/octet-stream'),
        ),
      );
      var response = await request.send();
      if (response.statusCode == 201) {
        print('Arquivo enviado com sucesso!');
        _getAnexosOs();
      } else {
        print('Erro ao enviar o arquivo: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Erro durante o envio do arquivo: $e');
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
