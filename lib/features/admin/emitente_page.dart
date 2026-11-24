import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/conta.dart';
import '../../data/repositories/admin_repository.dart';
import 'comum.dart';

class EmitentePage extends StatefulWidget {
  const EmitentePage({super.key});

  @override
  State<EmitentePage> createState() => _EmitentePageState();
}

class _EmitentePageState extends State<EmitentePage> {
  final _nome = TextEditingController();
  final _cnpj = TextEditingController();
  final _ie = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  ControlesDeEndereco _endereco = ControlesDeEndereco(const {});
  Emitente? _emitente;
  Object? _erroAoCarregar;
  bool _salvando = false;
  Map<String, String> _erros = const {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erroAoCarregar = null);
    try {
      final e = await context.read<AdminRepository>().emitente();
      if (!mounted) return;
      setState(() {
        _emitente = e;
        _nome.text = e.nome;
        _cnpj.text = e.cnpj;
        _ie.text = e.ie;
        _telefone.text = e.telefone;
        _email.text = e.email;
        _endereco.dispose();
        _endereco = ControlesDeEndereco(e.endereco);
      });
    } catch (e) {
      if (mounted) setState(() => _erroAoCarregar = e);
    }
  }

  @override
  void dispose() {
    for (final c in [_nome, _cnpj, _ie, _telefone, _email]) {
      c.dispose();
    }
    _endereco.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erros = const {};
    });
    try {
      await context.read<AdminRepository>().salvarEmitente({
        'nome': _nome.text.trim(),
        'cnpj': _cnpj.text.trim(),
        'ie': _ie.text.trim(),
        'telefone': _telefone.text.trim(),
        'email': _email.text.trim(),
        'endereco': _endereco.valores,
      });
      if (!mounted) return;
      Toast.success(context, 'Dados da empresa salvos.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erros = e.erros);
      if (mounted && e.erros.isEmpty) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _trocarLogo() async {
    final arquivo = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 1200);
    if (arquivo == null || !mounted) return;
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    if (await runAction(context, () => context.read<AdminRepository>().trocarLogo(bytes, arquivo.name), success: 'Logo alterado.')) await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final e = _emitente;
    return Scaffold(
      appBar: AppBar(title: const Text('Dados da empresa')),
      bottomNavigationBar: e == null ? null : BottomActionBar(child: LoadingButton(label: 'Salvar', icon: Icons.check_rounded, loading: _salvando, onPressed: _salvar)),
      body: _erroAoCarregar != null
          ? ErrorView(error: _erroAoCarregar!, onRetry: _carregar)
          : e == null
              ? const SkeletonList()
              : ListView(
                  padding: Gaps.pageOf(context),
                  children: [
                    ContentWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppCard(
                            padding: const EdgeInsets.all(Gaps.lg),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(Gaps.radiusSm),
                                  child: e.logoUrl.isEmpty
                                      ? const IconBadge(Icons.storefront_outlined, color: AppColors.accent, size: 64)
                                      : Image.network(e.logoUrl, width: 64, height: 64, fit: BoxFit.contain, errorBuilder: (_, _, _) => const IconBadge(Icons.storefront_outlined, color: AppColors.accent, size: 64)),
                                ),
                                const SizedBox(width: Gaps.md),
                                Expanded(child: Text('O logo sai nas OS, vendas e recibos impressos.', style: context.text.bodySmall)),
                                TextButton(onPressed: _trocarLogo, child: const Text('Trocar')),
                              ],
                            ),
                          ),
                          const SizedBox(height: Gaps.lg),
                          campoDeTexto(_nome, 'Razão social ou nome', _erros, 'nome'),
                          Row(
                            children: [
                              Expanded(child: campoDeTexto(_cnpj, 'CNPJ ou CPF', _erros, 'cnpj', teclado: TextInputType.number)),
                              const SizedBox(width: Gaps.md),
                              Expanded(child: campoDeTexto(_ie, 'Inscrição estadual', _erros, 'ie')),
                            ],
                          ),
                          campoDeTexto(_telefone, 'Telefone', _erros, 'telefone', teclado: TextInputType.phone),
                          campoDeTexto(_email, 'E-mail', _erros, 'email', teclado: TextInputType.emailAddress),
                          const SectionHeader('Endereço'),
                          CamposDeEndereco(endereco: _endereco, erros: _erros),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
