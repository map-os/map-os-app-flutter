import 'package:flutter/material.dart';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:photo_view/photo_view.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'dart:isolate';
import 'dart:io';
import 'dart:ui';

class AnexosTab extends StatefulWidget {
  final Map<String, dynamic>? ordemServico;


  AnexosTab({
    this.ordemServico,

  });

  @override
  _AnexosTabState createState() => _AnexosTabState();
}

class _AnexosTabState extends State<AnexosTab> with SingleTickerProviderStateMixin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  ReceivePort _port = ReceivePort();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  List<dynamic> _anexosList = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initDownloader();
    _initNotifications();
    _loadAnexos();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  void _loadAnexos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.ordemServico != null && widget.ordemServico!['idOs'] != null) {
        // Se tiver a lista local de anexos, use-a
        if (widget.ordemServico!['anexos'] != null) {
          _anexosList = List.from(widget.ordemServico!['anexos']);
        } else {
          // Caso contrário, carregue da API
          await _fetchAnexosFromApi();
        }
      } else {
        _anexosList = [];
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar anexos: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAnexosFromApi() async {
    try {
      // Obter o token de acesso
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final ordemServicoId = widget.ordemServico!['id'];
      final Uri uri = Uri.parse('${APIConfig.baseURL}/os/$ordemServicoId');
      print(uri);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result']['anexos'] != null) {
          setState(() {
            _anexosList = List.from(data['data']);
          });
        }
      } else {
        throw Exception('Falha ao carregar anexos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar anexos: $e');
    }
  }

  void _initDownloader() {
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      DownloadTaskStatus status = DownloadTaskStatus.values[data[1]];
      if (status == DownloadTaskStatus.complete) {
        _showNotification();
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  void _initNotifications() {
    var initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  Future<void> _showNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'downloads_channel',
      'Downloads',
      channelDescription: 'Notificações de downloads de anexos',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

      if (sdkInt >= 33) {
        await [
          Permission.photos,
          Permission.videos,
          Permission.notification,
          Permission.camera,
        ].request();
      } else {
        await [
          Permission.storage,
          Permission.camera,
        ].request();
      }
    } else if (Platform.isIOS) {
      await [
        Permission.photos,
        Permission.camera,
      ].request();
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    print(url);
    try {
      final status = Platform.isAndroid
          ? await Permission.storage.status
          : await Permission.photos.status;

      if (!status.isGranted) {
        await (Platform.isAndroid ? Permission.storage : Permission.photos).request();
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final String savedDir = directory?.path ?? '/storage/emulated/0/Download';

      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: savedDir,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download iniciado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao baixar: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      // Fazer upload para a API
      final bool success = await _uploadFileToServer(File(pickedFile.path));

      if (success) {
        // Recarregar os anexos após um upload bem-sucedido
        _loadAnexos();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anexo enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<bool> _uploadFileToServer(File file) async {
    try {
      // Obter o token de acesso
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }
      final ordemServicoId = widget.ordemServico!['idOs'];

      // Preparar a URL para upload
      final Uri uri = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/$ordemServicoId/anexos');
      print(uri);
      var request = http.MultipartRequest('POST', uri);

      // Adicionar o cabeçalho de autorização
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Adicionar o ID da ordem de serviço se disponível
      if (widget.ordemServico != null && widget.ordemServico!['id'] != null) {
        request.fields['ordem_servico_id'] = widget.ordemServico!['id'].toString();
      }

      // Adicionar o arquivo
      final fileName = path.basename(file.path);
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      final multipartFile = http.MultipartFile(
        'key', // Nome do campo esperado pela API
        fileStream,
        fileLength,
        filename: fileName,
      );

      request.files.add(multipartFile);

      // Enviar a requisição
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print(response.body);

      // Verificar a resposta
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse da resposta
        Map<String, dynamic> responseData = jsonDecode(response.body);
        print('Upload bem-sucedido: $responseData');
        return true;
      } else {
        print('Erro no upload. Código: ${response.statusCode}, Resposta: ${response.body}');
        throw Exception('Falha no upload. Código: ${response.statusCode}');
      }
    } catch (e) {
      print('Exceção ao fazer upload: $e');
      throw e;
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              title: Text('Câmera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              title: Text('Galeria'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: _showImageSourceDialog,
        child: _isUploading
            ? CircularProgressIndicator(color: Colors.white)
            : Icon(Icons.add_photo_alternate, color: Colors.white),
        tooltip: 'Adicionar Anexo',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAnexos,
              child: Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_anexosList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 72,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum anexo disponível',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Toque no botão "+" para adicionar um anexo',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadAnexos();
      },
      child: _buildAnexosGrid(),
    );
  }

  Widget _buildAnexosGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.7,
      ),
      itemCount: _anexosList.length,
      itemBuilder: (context, index) {
        final anexo = _anexosList[index];
        final bool isNew = anexo['isNew'] == true;

        return Hero(
          tag: 'anexo_$index',
          child: Material(
            borderRadius: BorderRadius.circular(12.0),
            elevation: 4.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: isNew ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 5,
                    spreadRadius: 1,
                  )
                ] : null,
              ),
              child: _buildAnexoCard(anexo, index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnexoCard(Map<String, dynamic> anexo, int index) {
    return InkWell(
      onTap: () => _showFullScreenImage(anexo, index),
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                  child: Image.network(
                    '${anexo['url']}/thumbs/${anexo['thumb']}',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12.0),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                anexo['anexo'].toString().split('/').last,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (anexo['isNew'] == true)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Novo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.visibility, color: Theme.of(context).primaryColor),
                    onPressed: () => _showFullScreenImage(anexo, index),
                    tooltip: 'Visualizar',
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(Map<String, dynamic> anexo, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.9),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.download, color: Colors.white),
                  onPressed: () {
                    final fileName = anexo['anexo'].toString().split('/').last;
                    _downloadFile(
                      '${anexo['url']}/${anexo['anexo']}',
                      fileName,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // Implementar compartilhamento aqui
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Função de compartilhamento não implementada')),
                    );
                  },
                ),
              ],
            ),
            body: Hero(
              tag: 'anexo_$index',
              child: Center(
                child: PhotoView(
                  imageProvider: NetworkImage(
                    '${anexo['url']}/${anexo['anexo']}',
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  backgroundDecoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  loadingBuilder: (context, event) => Center(
                    child: CircularProgressIndicator(
                      value: event == null
                          ? 0
                          : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }
}