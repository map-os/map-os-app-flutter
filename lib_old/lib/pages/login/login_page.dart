import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/url_controller.dart';
import 'package:mapos_app/controllers/login_controller.dart';
import 'package:mapos_app/pages/dashboard/dashboard_page.dart';
import 'package:mapos_app/widgets/TutorialWidget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapos_app/widgets/egg.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Uri _urlGithub = Uri(scheme: 'https', host: 'github.com', path: 'ramonsilva20/mapos/');
  final Uri _urlWhatsapp = Uri(scheme: 'https', host: 'chat.whatsapp.com', path: '/GVSg8tPQzXy0grfYpRfQps');

  final UrlController _settingsController = UrlController();
  final LoginController _loginController = LoginController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initURL();
  }

  Future<void> _initURL() async {
    String? currentURL = await _settingsController.getBaseURL();
    if (currentURL == null || currentURL.isEmpty) {
      await _settingsController.saveBaseURL('https://exemplo.com/mapos/index.php');
    }
  }

  void _showTutorial(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => TutorialScreen()));
  }

  void _showSettingsDialog(BuildContext context) async {
    TextEditingController urlController = TextEditingController();
    String? currentURL = await _settingsController.getBaseURL();
    urlController.text = currentURL ?? "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    "URL API",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: "URL",
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Ex: https://seudominio.com/mapos/index.php",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () async {
                    String url = urlController.text.trim();
                    if (url.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('A URL não pode estar vazia'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    if (!url.startsWith('http://') && !url.startsWith('https://')) {
                      url = 'https://$url';
                    }
                    if (kIsWeb && url.startsWith('http://')) {
                      url = url.replaceFirst('http://', 'https://');
                    }
                    Uri? parsed;
                    try {
                      parsed = Uri.parse(url);
                    } catch (_) {}
                    if (parsed == null || parsed.host.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('URL inválida. Verifique o formato.'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    await _settingsController.saveBaseURL(url);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    "Salvar",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Aviso!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Cole a URL base do seu MAP-OS. O /api/v1 é adicionado automaticamente.",
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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor, preencha todos os campos'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var email = _emailController.text;
    var password = _passwordController.text;

    try {
      var loginResult = await _loginController.login(email, password);

      if (loginResult['success']) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => DashboardPage())
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loginResult['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro de conexão. Verifique sua internet ou a URL da API'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Não foi possível abrir a URL: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.loginBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: height * 0.1),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: height * 0.04),
                  margin: EdgeInsets.symmetric(horizontal: width * 0.05),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 25,
                        offset: Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Tutorial button
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.help_outline, color: Colors.lightBlue, size: 26),
                          tooltip: 'Tutorial',
                          onPressed: () => _showTutorial(context),
                        ),
                      ),
                      // GitHub button
                      Positioned(
                        left: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Boxicons.bxl_github, color: Colors.white, size: 26),
                          tooltip: 'GitHub',
                          onPressed: () => _launchInBrowser(_urlGithub),
                        ),
                      ),
                      // WhatsApp button
                      Positioned(
                        left: 40,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Boxicons.bxl_whatsapp, color: Colors.green, size: 26),
                          tooltip: 'WhatsApp',
                          onPressed: () => _launchInBrowser(_urlWhatsapp),
                        ),
                      ),
                      // Settings button
                      Positioned(
                        right: 40,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white, size: 26),
                          tooltip: 'Configurações',
                          onPressed: () => _showSettingsDialog(context),
                        ),
                      ),
                      Column(
                        children: <Widget>[
                          const SizedBox(height: 30),
                          Hero(
                            tag: 'logo',
                            child: Container(
                              height: height * 0.15,
                              width: width * 0.5,
                              alignment: Alignment.center,
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.04),
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: AppColors.textLight),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w600,
                                fontSize: width * 0.04,
                              ),
                              prefixIcon: const Icon(Icons.email, color: AppColors.textLight),
                              filled: true,
                              fillColor: AppColors.inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.025),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: AppColors.textLight),
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              labelStyle: TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w600,
                                fontSize: width * 0.04,
                              ),
                              prefixIcon: const Icon(Icons.lock, color: AppColors.textLight),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: AppColors.textLight,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: AppColors.inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.04),
                          ElevatedButton(
                            onPressed: _isLoading ? null : () => _attemptLogin(context),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.accent,
                              minimumSize: Size(width * 0.8, height * 0.065),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'ENTRAR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.035),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '© 2025 - MAP-OS APP V ${APIConfig.appVersion}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Desenvolvido por ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 0.5,

                            ),
                          ),
                          const Text(
                            'Felipe Santt, ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,

                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => JulioLoboPage(),
                              ));
                            },
                            child: const Text(
                              'Julio Lobo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,

                              ),
                            ),
                          const Text(
                            ' & ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Text(
                            'N4m3r',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),


                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
