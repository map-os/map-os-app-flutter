import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:mapos_app/assets/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _getProfile();
    _getTheme();
  }
  String _currentTheme = 'TemaSecundario';

  Future<void> _getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String theme = prefs.getString('theme') ?? 'TemaSecundario';
    setState(() {
      _currentTheme = theme;
    });
  }

  Future<void> _getProfile() async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'Authorization': 'Bearaer $ciKey',
    };

    var url = '${APIConfig.baseURL}${APIConfig.profileEndpoint}';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      setState(() {
        _profileData = json.decode(response.body)['result']['usuario'];
      });
    } else {
      print('Failed to load profile');
    }
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  void _viewImageFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Image.network(_profileData['url_image_user']),
              ),
            ),
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentTheme == 'TemaPrimario'
          ? TemaPrimario.backgroundColor
          : TemaSecundario.backgroundColor,
      appBar: AppBar(
        title: Text('Minha conta'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_profileData.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_profileData['url_image_user'] != null)
                      Center(
                        child: GestureDetector(
                          onTap: _viewImageFullScreen,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(_profileData['url_image_user']),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 20),
                    ListTile(
                      leading: Icon(
                          Icons.person,
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.iconColor
                              : TemaSecundario.iconColor,
                      ),
                      title: Text(
                        'Nome',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.ColorText
                              : TemaSecundario.ColorText,
                        ),
                      ),
                        subtitle: Text(
                          _profileData['nome'],
                          style: TextStyle(
                          color: _currentTheme == 'TemaPrimario'
                          ? TemaPrimario.ColorText
                              : TemaSecundario.ColorText,
                          ),
                        ),
                    ),
                    ListTile(
                      leading: Icon(
                          Boxicons.bxs_id_card,
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.iconColor
                              : TemaSecundario.iconColor,
                      ),
                      title: Text(
                        'C.P.F',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentTheme == 'TemaPrimario'
                          ? TemaPrimario.ColorText
                              : TemaSecundario.ColorText,
                          ),
                      ),
                      subtitle: Text(
                        _profileData['cpf'],
                        style: TextStyle(
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.ColorText
                              : TemaSecundario.ColorText,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                          Icons.email,
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.iconColor
                              : TemaSecundario.iconColor,
                      ),
                      title: Text(
                        'E-mail',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _currentTheme == 'TemaPrimario'
                            ? TemaPrimario.ColorText
                                : TemaSecundario.ColorText,
                        ),
                      ),
                      subtitle: Text(
                        _profileData['email'],
                        style: TextStyle(
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.ColorText
                              : TemaSecundario.ColorText,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                          Icons.phone,
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.iconColor
                              : TemaSecundario.iconColor,
                      ),
                      title: Text(
                        'Telefone',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _currentTheme == 'TemaPrimario'
                                ? TemaPrimario.ColorText
                                : TemaSecundario.ColorText,
                        ),
                      ),
                      subtitle: Text(
                        _profileData['telefone'],
                        style: TextStyle(
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.ColorText
                              : TemaSecundario.ColorText,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                          Icons.location_on,
                          color: _currentTheme == 'TemaPrimario'
                              ? TemaPrimario.iconColor
                              : TemaSecundario.iconColor,
                      ),
                      title: Text(
                        'Endereço',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _currentTheme == 'TemaPrimario'
                                ? TemaPrimario.ColorText
                                : TemaSecundario.ColorText,
                        ),
                      ),
                      subtitle: Text(
                        '${_profileData['rua']}, ${_profileData['numero']}, ${_profileData['bairro']}, ${_profileData['cidade']}, ${_profileData['estado']}, ${_profileData['cep']}',
                          style: TextStyle(
                          color: _currentTheme == 'TemaPrimario'
                          ? TemaPrimario.ColorText
                              : TemaSecundario.ColorText,
                          ),
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
