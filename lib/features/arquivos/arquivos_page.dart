import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_state.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/gestao.dart';
import '../../data/repositories/gestao_repository.dart';

class ArquivosPage extends StatefulWidget {
  const ArquivosPage({super.key});

  @override
  State<ArquivosPage> createState() => _ArquivosPageState();
}

class _ArquivosPageState extends State<ArquivosPage> {
  late final PagedController<Arquivo> _ctrl = PagedController(
    fetch: (page, search) => context.read<ArquivosRepository>().list(page: page, search: search),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final escolha = await FilePicker.pickFiles();
    if (escolha.isEmpty || !mounted) return;
    final arquivo = escolha.single;
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    final dados = await _pedirDados(context, nome: arquivo.name.replaceFirst(RegExp(r'\.[^.]+$'), ''), titulo: 'Enviar arquivo');
    if (dados == null || !mounted) return;
    final ok = await runAction(
      context,
      () => context.read<ArquivosRepository>().enviar(bytes: bytes, nomeDoArquivo: arquivo.name, nome: dados.$1, descricao: dados.$2),
      success: 'Arquivo enviado.',
    );
    if (ok) _ctrl.refresh();
  }

  Future<void> _compartilhar(Arquivo a) async {
    final bytes = await runWithProgress(context, () => context.read<ArquivosRepository>().baixar(a.id));
    if (bytes == null) return;
    await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: a.nomeDoArquivo)], fileNameOverrides: [a.nomeDoArquivo]));
  }

  Future<void> _acoes(Arquivo a) async {
    final perms = context.read<AuthState>().permissions;
    final acao = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(a.nomeDoArquivo), subtitle: Text([a.tamanho, Fmt.date(a.data)].join(' · '))),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.ios_share_rounded), title: const Text('Abrir ou compartilhar'), onTap: () => Navigator.pop(context, 'compartilhar')),
            if (perms.canEdit('Arquivo')) ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Renomear'), onTap: () => Navigator.pop(context, 'editar')),
            if (perms.canDelete('Arquivo'))
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: const Text('Excluir', style: TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.pop(context, 'excluir'),
              ),
          ],
        ),
      ),
    );
    if (acao == null || !mounted) return;
    final repo = context.read<ArquivosRepository>();
    switch (acao) {
      case 'compartilhar':
        await _compartilhar(a);
      case 'editar':
        final dados = await _pedirDados(context, nome: a.nome, descricao: a.descricao, titulo: 'Renomear arquivo');
        if (dados != null && mounted && await runAction(context, () => repo.update(a.id, nome: dados.$1, descricao: dados.$2), success: 'Arquivo salvo.')) _ctrl.refresh();
      case 'excluir':
        final ok = await confirmDialog(context, title: 'Excluir ${a.nome}?', message: 'O arquivo é apagado do servidor.', confirmLabel: 'Excluir', destructive: true);
        if (ok && mounted && await runAction(context, () => repo.delete(a.id), success: 'Arquivo excluído.')) _ctrl.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final podeAdicionar = context.watch<AuthState>().permissions.canAdd('Arquivo');
    return Scaffold(
      appBar: AppBar(title: const Text('Arquivos')),
      floatingActionButton: podeAdicionar ? FloatingActionButton.extended(onPressed: _enviar, icon: const Icon(Icons.upload_file_rounded), label: const Text('Enviar')) : null,
      body: PagedListView<Arquivo>(
        controller: _ctrl,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
          child: ContentWidthScroll(child: SearchField(hint: 'Buscar arquivo', onChanged: _ctrl.setSearch)),
        ),
        empty: (buscando) => EmptyView(
          icon: Icons.folder_open_outlined,
          title: buscando ? 'Nenhum arquivo encontrado' : 'Nenhum arquivo',
          message: buscando ? 'Tente outro termo de busca.' : 'Guarde contratos, notas e documentos da empresa.',
        ),
        itemBuilder: (context, a) => AppCard(
          onTap: () => _acoes(a),
          padding: const EdgeInsets.all(Gaps.lg),
          child: Row(
            children: [
              IconBadge(a.imagem ? Icons.image_outlined : Icons.insert_drive_file_outlined, color: AppColors.info, size: 40),
              const SizedBox(width: Gaps.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.nome, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (a.descricao.isNotEmpty) Text(a.descricao, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text([a.extensao.toUpperCase(), a.tamanho, Fmt.date(a.data)].where((s) => s.isNotEmpty).join(' · '), style: context.text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<(String, String)?> _pedirDados(BuildContext context, {required String nome, String descricao = '', required String titulo}) {
  final nomeCtrl = TextEditingController(text: nome);
  final descricaoCtrl = TextEditingController(text: descricao);
  return showDialog<(String, String)>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nomeCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nome')),
          const SizedBox(height: Gaps.md),
          TextField(controller: descricaoCtrl, decoration: const InputDecoration(labelText: 'Descrição')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (nomeCtrl.text.trim().isEmpty) return;
            Navigator.pop(context, (nomeCtrl.text.trim(), descricaoCtrl.text.trim()));
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  ).whenComplete(() {
    nomeCtrl.dispose();
    descricaoCtrl.dispose();
  });
}
