import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:intl/intl.dart';
import 'package:mapos_app/pages/profile/edit_profile.dart';

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
  }

  Future<void> _getProfile({int page = 0}) async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
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
      appBar: AppBar(
        title: Text('Minha conta'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(profileData: _profileData)),
              );
            },
          ),
        ],
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
                      leading: Icon(Icons.person),
                      title: Text(
                        'Nome',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(_profileData['nome']),
                    ),
                    ListTile(
                      leading: Icon(Boxicons.bxs_id_card),
                      title: Text(
                        'C.P.F',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(_profileData['cpf']),
                    ),
                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text(
                        'E-mail',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(_profileData['email']),
                    ),
                    ListTile(
                      leading: Icon(Icons.phone),
                      title: Text(
                        'Telefone',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(_profileData['telefone']),
                    ),
                    ListTile(
                      leading: Icon(Icons.location_on),
                      title: Text(
                        'Endereço',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${_profileData['rua']}, ${_profileData['numero']}, ${_profileData['bairro']}, ${_profileData['cidade']}, ${_profileData['estado']}, ${_profileData['cep']}',
                      ),
                    ),
                    ListTile(
                      leading: Icon(Boxicons.bxs_hourglass),
                      title: Text(
                        'Data de Expiração',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.parse(_profileData['dataExpiracao'])),
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
