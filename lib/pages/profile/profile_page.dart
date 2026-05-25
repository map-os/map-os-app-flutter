import 'package:flutter/material.dart';
import 'package:mapos_app/api/apiConfig.dart';
import 'package:mapos_app/controllers/profile_controller.dart';
import 'package:mapos_app/theme/app_colors.dart';
import 'package:mapos_app/theme/app_spacing.dart';
import 'package:mapos_app/theme/app_typography.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController _controller = ProfileController();
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};
  bool _isEditing = false;

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _senhaConfirmacaoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _senhaConfirmacaoController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final result = await _controller.getProfile();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _profileData = result['data'] ?? {};
          _nomeController.text = _profileData['nome'] ?? '';
          _emailController.text = _profileData['email'] ?? '';
        }
      });
      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await _controller.updateProfile(
      nome: _nomeController.text,
      email: _emailController.text,
      senha: _senhaController.text.isNotEmpty ? _senhaController.text : null,
      senhaConfirmacao: _senhaConfirmacaoController.text.isNotEmpty ? _senhaConfirmacaoController.text : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        setState(() {
          _isEditing = false;
          _profileData['nome'] = _nomeController.text;
          _profileData['email'] = _emailController.text;
          _senhaController.clear();
          _senhaConfirmacaoController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar perfil',
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                padding: AppSpacing.paddingAllMd,
                child: _isEditing ? _buildEditForm() : _buildViewForm(),
              ),
            ),
    );
  }

  Widget _buildViewForm() {
    final nome = _profileData['nome'] ?? 'Não informado';
    final email = _profileData['email'] ?? 'Não informado';
    final permissoes = _profileData['permissoes'];

    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.accent,
          child: Text(
            _getInitials(nome),
            style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Text(nome, style: AppTypography.h1Style(AppColors.primary)),
        const SizedBox(height: 4),
        Text(email, style: AppTypography.bodyStyle(AppColors.textMuted)),
        const SizedBox(height: 24),

        // Info cards
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: AppSpacing.paddingAllMd,
            child: Column(
              children: [
                _buildInfoRow(Icons.person, 'Nome', nome),
                const Divider(),
                _buildInfoRow(Icons.email, 'Email', email),
                if (_profileData['cpf'] != null) ...[
                  const Divider(),
                  _buildInfoRow(Icons.badge, 'CPF', _profileData['cpf']),
                ],
                if (_profileData['telefone'] != null) ...[
                  const Divider(),
                  _buildInfoRow(Icons.phone, 'Telefone', _profileData['telefone']),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Permissions
        if (permissoes != null)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: AppSpacing.paddingAllMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Text('Permissões', style: AppTypography.h2Style(AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _buildPermissionChips(permissoes),
                  ),
                ],
              ),
            ),
          ),

        // App version
        const SizedBox(height: 24),
        Text(
          'MAP-OS APP v${APIConfig.appVersion}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPermissionChips(Map<String, dynamic> permissoes) {
    final labels = {
      'aCliente': 'Clientes', 'eCliente': 'Editar Clientes', 'dCliente': 'Excluir Clientes',
      'vCliente': 'Visualizar Clientes',
      'aProduto': 'Produtos', 'eProduto': 'Editar Produtos', 'dProduto': 'Excluir Produtos',
      'vProduto': 'Visualizar Produtos',
      'aServico': 'Serviços', 'eServico': 'Editar Serviços', 'dServico': 'Excluir Serviços',
      'vServico': 'Visualizar Serviços',
      'aOs': 'OS', 'eOs': 'Editar OS', 'dOs': 'Excluir OS', 'vOs': 'Visualizar OS',
      'rCliente': 'Rel. Clientes', 'rProduto': 'Rel. Produtos', 'rServico': 'Rel. Serviços',
      'rOs': 'Rel. OS',
      'cUsuario': 'Config Usuários', 'cEmitente': 'Config Emitente',
      'cPermissao': 'Config Permissões', 'cSistema': 'Config Sistema',
      'vDashboard': 'Dashboard', 'vRelatorioCompleto': 'Rel. Completo',
    };

    return permissoes.entries
        .where((e) => e.value != null && e.value.toString() == '1')
        .map((e) {
      final label = labels[e.key] ?? e.key;
      return Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        backgroundColor: AppColors.accent.withOpacity(0.1),
        side: BorderSide(color: AppColors.accent.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }).toList();
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Nome
          TextFormField(
            controller: _nomeController,
            decoration: InputDecoration(
              labelText: 'Nome',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Informe o email' : null,
          ),
          const SizedBox(height: 24),

          // Divider - senha opcional
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('Alterar senha (opcional)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),

          // Senha
          TextFormField(
            controller: _senhaController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Nova senha',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // Confirmar senha
          TextFormField(
            controller: _senhaConfirmacaoController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirmar nova senha',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (v) {
              if (_senhaController.text.isNotEmpty && v != _senhaController.text) {
                return 'As senhas não coincidem';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _nomeController.text = _profileData['nome'] ?? '';
                    _emailController.text = _profileData['email'] ?? '';
                    _senhaController.clear();
                    _senhaConfirmacaoController.clear();
                  });
                },
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Salvar', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}