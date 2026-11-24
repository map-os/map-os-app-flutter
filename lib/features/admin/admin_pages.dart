import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/admin.dart';
import '../../data/models/conta.dart';
import '../../data/repositories/admin_repository.dart';
import 'configuracoes_pages.dart';
import 'emitente_page.dart';
import 'grupos_pages.dart';
import 'usuarios_pages.dart';

bool podeAdministrar(Permissions p) => ['cUsuario', 'cPermissao', 'cEmitente', 'cSistema', 'cAuditoria', 'cEmail'].any(p.can);

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AuthState>().permissions;
    final itens = [
      if (p.can('cUsuario')) (Icons.group_outlined, 'Usuários', 'Contas de acesso ao sistema', () => const UsuariosPage()),
      if (p.can('cPermissao')) (Icons.admin_panel_settings_outlined, 'Grupos de permissão', 'O que cada grupo pode fazer', () => const GruposPage()),
      if (p.can('cEmitente')) (Icons.storefront_outlined, 'Dados da empresa', 'Nome, CNPJ, endereço e logo', () => const EmitentePage()),
      if (p.can('cSistema')) (Icons.settings_outlined, 'Configurações do sistema', 'OS, vendas, e-mail, pagamentos e API', () => const ConfiguracoesDoSistemaPage()),
      if (p.can('cAuditoria')) (Icons.history_rounded, 'Auditoria', 'Quem fez o quê e quando', () => const _AuditoriaPage()),
      if (p.can('cEmail')) (Icons.outgoing_mail, 'Fila de e-mails', 'Enviados, na fila e com falha', () => const _EmailsPage()),
      if (p.can('cSistema')) (Icons.info_outline_rounded, 'Sistema', 'Versão e situação do servidor', () => const _SistemaPage()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Administração')),
      body: ListView(
        padding: Gaps.pageOf(context),
        children: [
          ContentWidth(
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, (icone, titulo, subtitulo, pagina)) in itens.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading: Icon(icone),
                      title: Text(titulo),
                      subtitle: Text(subtitulo),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => pagina())),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditoriaPage extends StatefulWidget {
  const _AuditoriaPage();

  @override
  State<_AuditoriaPage> createState() => _AuditoriaPageState();
}

class _AuditoriaPageState extends State<_AuditoriaPage> {
  late final PagedController<RegistroDeAuditoria> _ctrl = PagedController(
    pageSize: 20,
    fetch: (page, search) => context.read<AdminRepository>().auditoria(page: page, search: search),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _limpar() async {
    final ok = await confirmDialog(context, title: 'Limpar a auditoria?', message: 'Apaga os registros antigos, conforme a regra do servidor. Não dá para desfazer.', confirmLabel: 'Limpar', destructive: true);
    if (!ok || !mounted) return;
    final apagados = await runWithProgress(context, () => context.read<AdminRepository>().limparAuditoria());
    if (apagados == null || !mounted) return;
    Toast.success(context, '$apagados registros apagados.');
    _ctrl.refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Auditoria'),
          actions: [IconButton(tooltip: 'Limpar registros antigos', icon: const Icon(Icons.delete_sweep_outlined), onPressed: _limpar)],
        ),
        body: PagedListView<RegistroDeAuditoria>(
          controller: _ctrl,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
            child: ContentWidthScroll(child: SearchField(hint: 'Usuário ou ação', onChanged: _ctrl.setSearch)),
          ),
          empty: (_) => const EmptyView(icon: Icons.history_rounded, title: 'Nenhum registro'),
          itemBuilder: (context, r) => AppCard(
            padding: const EdgeInsets.all(Gaps.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.acao),
                const SizedBox(height: Gaps.xs),
                Text([r.usuario.isEmpty ? 'Sistema' : r.usuario, Fmt.dateTime(r.dataHora), if (r.ip.isNotEmpty) r.ip].join(' · '), style: context.text.bodySmall),
              ],
            ),
          ),
        ),
      );
}

class _EmailsPage extends StatefulWidget {
  const _EmailsPage();

  @override
  State<_EmailsPage> createState() => _EmailsPageState();
}

class _EmailsPageState extends State<_EmailsPage> {
  String? _status;
  late final PagedController<EmailNaFila> _ctrl = PagedController(
    pageSize: 20,
    fetch: (page, _) => context.read<AdminRepository>().emails(page: page, status: _status),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _cor(String status) => switch (status) {
        'sent' => AppColors.success,
        'failed' => AppColors.danger,
        'sending' => AppColors.info,
        _ => AppColors.warning,
      };

  Future<void> _remover(EmailNaFila e) async {
    final ok = await confirmDialog(context, title: 'Remover da fila?', message: '${e.assunto}\nPara: ${e.para}', confirmLabel: 'Remover', destructive: true);
    if (ok && mounted && await runAction(context, () => context.read<AdminRepository>().removerEmail(e.id), success: 'E-mail removido.')) _ctrl.refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Fila de e-mails')),
        body: PagedListView<EmailNaFila>(
          controller: _ctrl,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
            child: ContentWidthScroll(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final (valor, rotulo) in [(null, 'Todos'), ('pending', 'Na fila'), ('sent', 'Enviados'), ('failed', 'Com falha')])
                      Padding(
                        padding: const EdgeInsets.only(right: Gaps.sm),
                        child: ChoiceChip(
                          label: Text(rotulo),
                          selected: _status == valor,
                          onSelected: (_) {
                            setState(() => _status = valor);
                            _ctrl.refresh();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          empty: (_) => const EmptyView(icon: Icons.outgoing_mail, title: 'Nenhum e-mail'),
          itemBuilder: (context, e) => AppCard(
            padding: const EdgeInsets.fromLTRB(Gaps.lg, Gaps.md, Gaps.xs, Gaps.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.assunto.isEmpty ? '(sem assunto)' : e.assunto, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(e.para, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: e.situacao, style: TextStyle(color: _cor(e.status), fontWeight: FontWeight.w700)),
                          TextSpan(text: ' · ${Fmt.dateTime(e.dataHora)}'),
                        ]),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Remover', icon: const Icon(Icons.delete_outline_rounded), onPressed: () => _remover(e)),
              ],
            ),
          ),
        ),
      );
}

class _SistemaPage extends StatefulWidget {
  const _SistemaPage();

  @override
  State<_SistemaPage> createState() => _SistemaPageState();
}

class _SistemaPageState extends State<_SistemaPage> {
  late Future<InfoDoSistema> _info = context.read<AdminRepository>().sistema();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sistema')),
        body: AsyncView<InfoDoSistema>(
          future: _info,
          onRetry: () => setState(() => _info = context.read<AdminRepository>().sistema()),
          builder: (context, s) => ListView(
            padding: Gaps.pageOf(context),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.xs),
                      child: Column(
                        children: [
                          InfoRow(icon: Icons.verified_outlined, label: 'Versão instalada', value: s.versao),
                          InfoRow(icon: Icons.new_releases_outlined, label: 'Última versão', value: s.ultimaVersao ?? 'Não foi possível consultar'),
                          InfoRow(icon: Icons.storage_outlined, label: 'Banco de dados', value: s.migracoesPendentes == 0 ? 'Atualizado' : '${s.migracoesPendentes} atualizações pendentes'),
                        ],
                      ),
                    ),
                    if (s.temAtualizacao || s.migracoesPendentes > 0) ...[
                      const SizedBox(height: Gaps.md),
                      AppCard(
                        padding: const EdgeInsets.all(Gaps.lg),
                        child: Row(
                          children: [
                            const Icon(Icons.system_update_alt_rounded, color: AppColors.info),
                            const SizedBox(width: Gaps.md),
                            Expanded(child: Text('Atualizações do sistema e do banco são feitas pelo painel web, em Configurações › Sistema.', style: context.text.bodyMedium)),
                          ],
                        ),
                      ),
                    ],
                    if (s.problemas.isNotEmpty) ...[
                      const SectionHeader('Avisos do servidor'),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final p in s.problemas) ListTile(dense: true, leading: const Icon(Icons.warning_amber_rounded, color: AppColors.warning), title: Text(p)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
