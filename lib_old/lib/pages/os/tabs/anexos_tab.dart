import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mapos_app/api/apiConfig.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'dart:ui';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

// Conditional imports for native-only packages
import 'package:image_picker/image_picker.dart';

class AnexosTab extends StatefulWidget {
  final Map<String, dynamic>? ordemServico;

  AnexosTab({
    this.ordemServico,
  });

  @override
  _AnexosTabState createState() => _AnexosTabState();
}

class _AnexosTabState extends State<AnexosTab> with SingleTickerProviderStateMixin {
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
    if (!kIsWeb) {
      _requestPermissions();
    }
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
        if (widget.ordemServico!['anexos'] != null) {
          _anexosList = List.from(widget.ordemServico!['anexos']);
        } else {
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('Token de acesso nao encontrado');
      }

      final ordemServicoId = widget.ordemServico!['idOs'];
      final Uri uri = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/$ordemServicoId');

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
            _anexosList = List.from(data['result']['anexos']);
          });
        }
      } else {
        throw Exception('Falha ao carregar anexos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar anexos: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Native-only: permissions not available on web
  }

  Future<void> _downloadFile(String url, String fileName) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download nao suportado no navegador'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    // Native download handled by platform-specific code
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

      if (kIsWeb) {
        // Web upload using bytes
        final bytes = await pickedFile.readAsBytes();
        final bool success = await _uploadBytesToServer(bytes, pickedFile.name);

        if (success) {
          _loadAnexos();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Anexo enviado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Native upload handled by platform-specific code
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload nao disponivel nesta plataforma'),
            backgroundColor: Colors.orange,
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

  Future<bool> _uploadBytesToServer(List<int> bytes, String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('Token de acesso nao encontrado');
      }
      final ordemServicoId = widget.ordemServico!['idOs'];

      final Uri uri = Uri.parse('${APIConfig.baseURL}${APIConfig.osEndpoint}/$ordemServicoId/anexos');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'key',
          bytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Falha no upload. Codigo: ${response.statusCode}');
      }
    } catch (e) {
      return false;
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
              title: Text('Camera'),
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
              'Nenhum anexo disponivel',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Toque no botao "+" para adicionar um anexo',
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
      padding: AppSpacing.paddingAllMd,
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