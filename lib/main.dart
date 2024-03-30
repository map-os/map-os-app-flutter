import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapos_app/pages/dashboard_screen.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAP-OS',
      theme: ThemeData.light().copyWith(
          appBarTheme: AppBarTheme(
        color: Color(0xff333649),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        toolbarTextStyle: TextTheme(
          headline6: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ).bodyText2,
        titleTextStyle: TextTheme(
          headline6: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ).headline6,
      )),
      darkTheme: ThemeData.dark().copyWith(
        // Defina a cor da AppBar no tema escuro aqui
        appBarTheme: AppBarTheme(
          color: Color(
              0xff333649),
        ),
      ),
      themeMode: _themeMode,
      home: LoginPage(toggleTheme),
    );
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  LoginPage(this.toggleTheme);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _usernameController =
      TextEditingController();
  TextEditingController _passwordController =
      TextEditingController();
  bool _showPassword = false;
  @override
  void initState() {
    super.initState();
    checkLoggedIn();
  }

  void checkLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        PageTransition(
          child: DashboardScreen(),
          type: PageTransitionType.bottomToTop,
        ),
      );
    } else {
      // Verifica se baseURL está presente
      String? baseURL = prefs.getString('baseURL');
      if (baseURL == null || baseURL.isEmpty) {
        _showBaseUrlInputDialog(context);
      }
    }
  }

  _showBaseUrlInputDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String newBaseUrl = '';
        bool isButtonEnabled = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'URL do MAP-OS não definida',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Informe a URL do seu MAP-OS. ',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        newBaseUrl = value.trim(); // Remover espaços em branco
                        isButtonEnabled = newBaseUrl.isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Ex: https://mapos.com.br',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isButtonEnabled
                      ? () async {
                    // Remover a barra no final da URL, se presente
                    if (newBaseUrl.endsWith('/')) {
                      newBaseUrl = newBaseUrl.substring(0, newBaseUrl.length - 1);
                    }

                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    prefs.setString('baseURL', newBaseUrl);
                    Navigator.of(context).pop();
                    print(newBaseUrl);
                  }
                      : null,
                  child: Text(
                    'Salvar',
                    style: TextStyle(
                      color: isButtonEnabled ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _login() async {
    try {
      // Verifica se o e-mail é válido
      if (!isValidEmail(_usernameController.text)) {
        showSnackBar('E-mail inválido');
        return;
      }

      // Inicializa a baseURL se ainda não estiver inicializada
      if (APIConfig.baseURL == null) {
        await APIConfig.initBaseURL();
        if (APIConfig.baseURL == null) {
          _showBaseUrlInputDialog(context);
          showSnackBar('Erro: URL do seu MAP-OS não foi definida');
          return;
        }
      }

      final Map<String, dynamic> loginData = {
        'email': _usernameController.text,
        'password': _passwordController.text,
      };
      final response = await http.post(
        Uri.parse('${APIConfig.baseURL}${APIConfig.loginEndpoint}'),

        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(loginData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          String ciKey = data['result']['access_token'];

          List<dynamic> permissoesList = data['result']['permissions'];
          String permissoes = jsonEncode(permissoesList);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', ciKey);
          await prefs.setString('permissoes', permissoes);
          Navigator.pushReplacement(
            context,
            PageTransition(
              child: DashboardScreen(),
              type: PageTransitionType.leftToRight,
            ),
          );
        } else {
          showSnackBar('Credenciais inválidas');
        }
      } else {
        showSnackBar('Dados invalidos: ${response.statusCode}');
      }
    } catch (e) {
      showSnackBar('Erro durante a solicitação: $e');
    }
  }

  bool isValidEmail(String email) {
    String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    return RegExp(emailRegex).hasMatch(email);
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Colors.black,
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 90.0),
                      TextField(
                        controller: _usernameController,
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.grey[700]
                                    : Colors.white),
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          labelStyle: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Color(0xff333649)
                                  : Colors.white),
                          prefixIcon: Icon(Icons.email,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Color(0xff333649)
                                  : Colors.white),
                          filled: true,
                          fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 9.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                10.0), // Define o raio do border
                            borderSide:  BorderSide(color: Color(0xff333960), width: 2.0), // Remove a linha preta
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                10.0), // Define o raio do border
                            borderSide: BorderSide(
                                color: Color(0xff333649), width: 2.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        controller: _passwordController,
                        obscureText:
                            !_showPassword, // Altere o obscureText com base em _showPassword
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.grey[700]
                                  : Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          labelStyle: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Color(0xff333649)
                                    : Colors.white,
                          ),
                          prefixIcon: Icon(Icons.lock,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Color(0xff333649)
                                  : Colors.white),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Color(0xff333649)
                                  : Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Color(0xffb9dbfd).withOpacity(0.3),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 9.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide:  BorderSide(color: Color(0xff333960), width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                                color: Color(0xff333649), width: 2.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 18.0),
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xff333649),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size(
                            MediaQuery.of(context).size.width * 0.60,
                            MediaQuery.of(context).size.height * 0.070,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  (MediaQuery.of(context).size.height * 0.0200),
                              vertical: (MediaQuery.of(context).size.height *
                                  0.0200)),
                          child: Text('Entrar', style: TextStyle(fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'MAP-OS APP V. ${APIConfig.appVersion}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[700]
                        : Colors.white,
                    fontSize: (MediaQuery.of(context).size.height * 0.0250),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0),
                Text(
                  'Desenvolvido por \n Felipe Santt & \n Julio Lobo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[700]
                        : Colors.white,
                    fontSize: (MediaQuery.of(context).size.height * 0.0200),
                  ),
                ),
                SizedBox(height: 0),
                GestureDetector(
                  onTap: () {
                    final String url = 'https://github.com/Fesantt/MAPOS-OS-APP-FLUTTER';
                    _launchURL(url);
                  },
                  child: Icon(
                    Boxicons.bxl_github,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[700]
                        : Colors.white,
                    size: (MediaQuery.of(context).size.height * 0.050),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.36,
              decoration: BoxDecoration(
                color: Color(0xff333649),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'lib/assets/images/login-two.png',
                  fit: BoxFit.cover,
                  height: (MediaQuery.of(context).size.height * 1.180),
                  width: double.infinity,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 20, right: 20),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.settings, size: 30), // Adjust size as needed
                  color: Colors.deepOrange,
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showBaseUrlInputDialog(context);
                    });
                  },
                ),
              ),
            ),
          )

        ],
      ),
    );
  }
}

Future<void> _launchURL(String url) async {
  final _url = Uri.parse(url);
  if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $_url');
  }
}
