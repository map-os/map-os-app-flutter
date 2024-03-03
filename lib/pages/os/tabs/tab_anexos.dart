import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TabAnexos extends StatefulWidget {
  final Map<String, dynamic> os;

  TabAnexos({required this.os});

  @override
  _TabAnexosState createState() => _TabAnexosState();
}

class _TabAnexosState extends State<TabAnexos> {
  List<dynamic> osData = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _getProdutosOs();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? Center(child: CircularProgressIndicator())
        : osData.isNotEmpty
            ? ListView.builder(
                itemCount: osData.length,
                itemBuilder: (BuildContext context, int index) {
                  return ExpansionTile(
                    title: Text(' Anexo: ${osData[index]['idAnexos']}'),
                    children: [
                      Image.network(
                          '${osData[index]['url']}/${osData[index]['anexo']}'),
                    ],
                  );
                },
              )
            : Center(
                child: Text('Nenhum anexo encontrado'),
              );
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _getProdutosOs() async {
    setState(() {
      _loading = true; // Start loading indicator
    });

    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';

    var url =
        '${APIConfig.baseURL}${APIConfig.osEndpoint}/${widget.os['idOs']}?X-API-KEY=$ciKey';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('refresh_token')) {
        String refreshToken = data['refresh_token'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', refreshToken);
      } else {
        print('problema com sua sessão, faça login novamente!');
      }
      if (data.containsKey('result') && data['result'].containsKey('anexos')) {
        setState(() {
          osData = data['result']['anexos'];
          _loading = false; // Stop loading indicator
        });
      } else {
        setState(() {
          osData = [];
          _loading = false; // Stop loading indicator
        });
        print('Key "anexos" not found in API response');
      }
    } else {
      setState(() {
        _loading = false; // Stop loading indicator
      });
      print('Failed to load os');
    }
  }
}
