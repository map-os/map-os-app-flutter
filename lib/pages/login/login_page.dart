import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:mapos_app/controllers/url_controller.dart';
import 'package:mapos_app/controllers/login_controller.dart';
import 'package:mapos_app/pages/dashboard/dashboard_page.dart';
import 'package:mapos_app/widgets/TutorialWidget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapos_app/widgets/egg.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);
  final Uri urlGithub = Uri(scheme: 'https', host: 'github.com', path: 'Fesantt/');

  final Uri urlWhatsapp = Uri(scheme: 'https', host: 'chat.whatsapp.com', path: '/D571nPLqNq6JgIsmL6Gucl');

  final UrlController settingsController = UrlController();
  final LoginController loginController = LoginController();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _showTutorial(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => TutorialScreen()));
  }

  void _showSettingsDialog(BuildContext context) async {
    TextEditingController urlController = TextEditingController();
    String? currentURL = await settingsController.getBaseURL();
    urlController.text = currentURL ?? "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "URL  Api",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: "URL",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xfff1732f),
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await settingsController.saveBaseURL(urlController.text);
                    Navigator.of(context).pop();
                  },
                  child: Text("Salvar"),
                ),
                SizedBox(height: 16),
                Text(
                  "Aviso!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Lembre-se de copiar a url diretamente do seu MAP-OS em configurações>sistema>api",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _attemptLogin(BuildContext context) async {
    var email = emailController.text;
    var password = passwordController.text;
    var loginResult = await loginController.login(email, password);

    if (loginResult['success']) {
      // Salva o token em SharedPreferences já foi feito no LoginController
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => DashboardPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loginResult['message']),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Não foi possivel abrir a url: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xffe4ecfb),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: height * 0.25),
            Container(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: height * 0.04),
              margin: EdgeInsets.symmetric(horizontal: width * 0.05),
              decoration: BoxDecoration(
                color: const Color(0xff333649),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 30,
                    top: -10,
                    child: IconButton(
                      icon: Icon(Icons.help_outline, color: Colors.lightBlue, size: 30),
                      onPressed: () => _showTutorial(context),
                    ),
                  ),
                  Positioned(
                    left: -10,
                    top: -10,
                    child: IconButton(
                      icon: Icon(Boxicons.bxl_github,
                          color: Colors.white,
                          size: 30),
                      onPressed: () => _launchInBrowser(urlGithub),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: -10,
                    child: IconButton(
                      icon: Icon(Boxicons.bxl_whatsapp, color: Colors.green, size: 30),
                      onPressed: () => _launchInBrowser(urlWhatsapp),
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      Container(
                        height: height * 0.15,
                        width: width * 0.5,
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: height * 0.03),
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Color(0xffe3ebf9)),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: const Color(0xffe3ebf9),
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.04,
                          ),
                          filled: true,
                          fillColor: const Color(0xff333649),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xf1e9eaf8)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe3ebf9), width: 2.0),
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.03),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Color(0xffe3ebf9)),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          labelStyle: TextStyle(
                            color: const Color(0xffe3ebf9),
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.04,
                          ),
                          filled: true,
                          fillColor: const Color(0xff333649),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xf1e9eaf8)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe3ebf9), width: 2.0),
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.04),
                      ElevatedButton(
                        onPressed: () => _attemptLogin(context),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xfff3742f),
                          minimumSize: Size(width * 0.8, height * 0.07),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Entrar'),
                      ),
                      SizedBox(height: height * 0.02),
                      Text(
                        textAlign: TextAlign.center,
                        '2024\n © Felipe Santt && ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.03,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => JulioLoboPage(),
                          ));
                        },
                        child: Text(
                          'Julio Lobo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.03,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: -12,
                    top: -10,
                    child: IconButton(
                      icon: const Icon(Icons.settings,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => _showSettingsDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

