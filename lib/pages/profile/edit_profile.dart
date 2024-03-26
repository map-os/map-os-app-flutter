import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  EditProfileScreen({required this.profileData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _cpfController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _numberController;
  late TextEditingController _districtController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileData['nome']);
    _cpfController = TextEditingController(text: widget.profileData['cpf']);
    _emailController = TextEditingController(text: widget.profileData['email']);
    _phoneController = TextEditingController(text: widget.profileData['telefone']);
    _streetController = TextEditingController(text: widget.profileData['rua']);
    _numberController = TextEditingController(text: widget.profileData['numero']);
    _districtController = TextEditingController(text: widget.profileData['bairro']);
    _cityController = TextEditingController(text: widget.profileData['cidade']);
    _stateController = TextEditingController(text: widget.profileData['estado']);
    _zipCodeController = TextEditingController(text: widget.profileData['cep']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Perfil' ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _cpfController,
              decoration: InputDecoration(labelText: 'C.P.F'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Telefone'),
            ),
            TextField(
              controller: _streetController,
              decoration: InputDecoration(labelText: 'Rua'),
            ),
            TextField(
              controller: _numberController,
              decoration: InputDecoration(labelText: 'Número'),
            ),
            TextField(
              controller: _districtController,
              decoration: InputDecoration(labelText: 'Bairro'),
            ),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(labelText: 'Cidade'),
            ),
            TextField(
              controller: _stateController,
              decoration: InputDecoration(labelText: 'Estado'),
            ),
            TextField(
              controller: _zipCodeController,
              decoration: InputDecoration(labelText: 'CEP'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    // Implemente a lógica para salvar as alterações
    String name = _nameController.text;
    String cpf = _cpfController.text;
    String email = _emailController.text;
    String phone = _phoneController.text;
    String street = _streetController.text;
    String number = _numberController.text;
    String district = _districtController.text;
    String city = _cityController.text;
    String state = _stateController.text;
    String zipCode = _zipCodeController.text;


    print('Nome: $name, C.P.F: $cpf, E-mail: $email, Telefone: $phone');
    print('Rua: $street, Número: $number, Bairro: $district, Cidade: $city, Estado: $state, CEP: $zipCode');

    // Após salvar as alterações, você pode navegar de volta para a tela de perfil ou qualquer outra tela necessária.
    Navigator.pop(context); // Navega de volta para a tela anterior
  }
  Future<void> _updateUser({int page = 0}) async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
    };

    var url = '${APIConfig.baseURL}${APIConfig.profileEndpoint}';

    var response = await http.post(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      setState(() {

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
  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }
}
