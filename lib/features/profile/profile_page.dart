import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/ui.dart';
import '../../data/models/conta.dart';
import '../../data/repositories/cadastros_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<(Usuario, Emitente?)> _future = _load();

  Future<(Usuario, Emitente?)> _load() async {
    final repo = context.read<ContaRepository>();
    final u = await repo.perfil();
    Emitente? e;
    try {
      e = await repo.emitente();
    } catch (_) {}
    return (u, e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: AsyncView<(Usuario, Emitente?)>(
        future: _future,
        onRetry: () => setState(() => _future = _load()),
        builder: (context, data) {
          final (u, e) = data;
          return ListView(
            padding: Gaps.pageOf(context),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: Gaps.lg),
                    Center(child: InitialsAvatar(u.nome, size: 96, imageUrl: u.fotoUrl)),
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
                    const SizedBox(height: Gaps.lg),
                    Text(
                      'Para alterar seus dados ou senha, use o painel web do MAP-OS.',
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
