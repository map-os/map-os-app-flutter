import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/conta.dart';
import '../../data/repositories/cadastros_repository.dart';
import 'seguranca_pages.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<(Conta, Emitente?)> _future = _load();

  Future<(Conta, Emitente?)> _load() async {
    final repo = context.read<ContaRepository>();
    final c = await repo.conta();
    Emitente? e;
    try {
      e = await repo.emitente();
    } catch (_) {}
    return (c, e);
  }

  void _recarregar() => setState(() => _future = _load());

  Future<void> _abrir(Widget pagina) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pagina));
    if (mounted) _recarregar();
  }

  Future<void> _trocarFoto() async {
    final arquivo = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (arquivo == null || !mounted) return;
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    final ok = await runAction(context, () => context.read<ContaRepository>().trocarFoto(bytes, arquivo.name), success: 'Foto alterada.');
    if (ok) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: AsyncView<(Conta, Emitente?)>(
        future: _future,
        onRetry: _recarregar,
        builder: (context, data) {
          final (conta, e) = data;
          final u = conta.usuario;
          final podeFoto = context.read<AuthState>().permissions.can('cUsuario');
          return ListView(
            padding: Gaps.pageOf(context),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: Gaps.lg),
                    Center(
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: podeFoto ? _trocarFoto : null,
                        child: InitialsAvatar(u.nome, size: 96, imageUrl: u.fotoUrl),
                      ),
                    ),
                    if (podeFoto) Center(child: TextButton(onPressed: _trocarFoto, child: const Text('Trocar foto'))),
                    const SizedBox(height: Gaps.lg),
                    Text(u.nome, style: context.text.headlineSmall, textAlign: TextAlign.center),
                    Text(u.email, style: context.text.bodyMedium?.copyWith(color: context.tokens.muted), textAlign: TextAlign.center),
                    const SectionHeader('Dados pessoais'),
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.xs),
                      child: Column(
                        children: [
                          InfoRow(icon: Icons.badge_outlined, label: 'CPF', value: u.cpf),
                          InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: u.telefone),
                          InfoRow(icon: Icons.smartphone_outlined, label: 'Celular', value: u.celular),
                          InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Cidade',
                            value: [u.cidade, u.estado].where((s) => s.isNotEmpty).join(' / '),
                          ),
                          InfoRow(
                            icon: Icons.event_available_outlined,
                            label: 'Acesso válido até',
                            value: u.dataExpiracao == null || u.dataExpiracao!.year >= 2999 ? 'Sem expiração' : Fmt.date(u.dataExpiracao),
                          ),
                        ],
                      ),
                    ),
                    if (e != null && e.nome.isNotEmpty) ...[
                      const SectionHeader('Empresa'),
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.xs),
                        child: Column(
                          children: [
                            InfoRow(icon: Icons.storefront_outlined, label: 'Razão social', value: e.nome),
                            InfoRow(icon: Icons.description_outlined, label: 'CNPJ', value: e.cnpj),
                            InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: e.telefone),
                            InfoRow(icon: Icons.mail_outline_rounded, label: 'E-mail', value: e.email),
                            InfoRow(
                              icon: Icons.location_city_outlined,
                              label: 'Cidade',
                              value: [e.cidade, e.uf].where((s) => s.isNotEmpty).join(' / '),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SectionHeader('Segurança'),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.password_rounded),
                            title: const Text('Trocar senha'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _abrir(const TrocarSenhaPage()),
                          ),
                          ListTile(
                            leading: Icon(conta.doisFatoresAtivo ? Icons.verified_user_rounded : Icons.shield_outlined, color: conta.doisFatoresAtivo ? AppColors.success : null),
                            title: const Text('Verificação em duas etapas'),
                            subtitle: Text(conta.doisFatoresAtivo ? 'Ativa' : (conta.doisFatoresExigido ? 'Exigida pelo seu grupo: ative agora' : 'Desativada')),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _abrir(const DoisFatoresPage()),
                          ),
                          ListTile(
                            leading: const Icon(Icons.devices_rounded),
                            title: const Text('Sessões ativas'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _abrir(const SessoesPage()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Gaps.lg),
                    Text(
                      'Para alterar nome, e-mail e outros dados pessoais, fale com o administrador do MAP-OS.',
                      style: context.text.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
