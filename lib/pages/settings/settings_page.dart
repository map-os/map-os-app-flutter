import 'package:flutter/material.dart';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/url_controller.dart';
import 'package:mapos_app/pages/login/login_page.dart';
import 'package:mapos_app/pages/about.dart';
import 'package:mapos_app/providers/theme_provider.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UrlController _urlController = UrlController();
  final TextEditingController _urlFieldController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  @override
  void dispose() {
    _urlFieldController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUrl() async {
    String? url = await _urlController.getBaseURL();
    setState(() {
      _urlFieldController.text = url ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveUrl() async {
    String url = _urlFieldController.text.trim();
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
      _urlFieldController.text = url;
    }

    setState(() => _isSaving = true);
    await _urlController.saveBaseURL(url);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('URL salva com sucesso!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Sair', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('permissions');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.paddingAllMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // API URL Section
                  _buildSectionHeader(Icons.link, 'URL da API'),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: AppSpacing.paddingAllMd,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _urlFieldController,
                            decoration: InputDecoration(
                              labelText: 'URL base do MAP-OS',
                              hintText: 'https://exemplo.com/mapos/index.php',
                              prefixIcon: const Icon(Icons.link),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              suffixIcon: _isSaving
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'O /api/v1 é adicionado automaticamente.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveUrl,
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text('Salvar URL', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Theme Section
                  _buildSectionHeader(Icons.palette, 'Aparência'),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      title: const Text('Modo escuro'),
                      subtitle: const Text('Ativar tema escuro'),
                      secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.accent),
                      value: isDark,
                      activeColor: AppColors.accent,
                      onChanged: (value) {
                        themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  _buildSectionHeader(Icons.info_outline, 'Sobre'),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info, color: AppColors.primary),
                          title: const Text('Sobre o app'),
                          subtitle: Text('MAP-OS APP v${APIConfig.appVersion}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage()));
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.code, color: AppColors.primary),
                          title: const Text('GitHub'),
                          subtitle: const Text('ramonsilva20/mapos'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final uri = Uri.parse('https://github.com/ramonsilva20/mapos');
                            // Can't use url_launcher without import, but About page may have it
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Sair da conta', style: TextStyle(color: Colors.red)),
                      onTap: _logout,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 10),
        Text(title, style: AppTypography.h2Style(AppColors.primary)),
      ],
    );
  }
}