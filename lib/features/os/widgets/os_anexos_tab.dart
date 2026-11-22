import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/ui.dart';
import '../../../data/models/ordem_servico.dart';
import '../../../data/repositories/os_repository.dart';

class OsAnexosTab extends StatelessWidget {
  const OsAnexosTab({super.key, required this.os, required this.canEdit, required this.onChanged});

  final OrdemServico os;
  final bool canEdit;
  final Future<void> Function() onChanged;

  Future<void> _add(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(Gaps.sm, 0, Gaps.sm, Gaps.lg + Gaps.systemBottom(sheet)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: source, imageQuality: 82, maxWidth: 2200);
    } catch (e) {
      if (context.mounted) Toast.error(context, 'Não foi possível acessar a câmera/galeria.');
      return;
    }
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    final name = file.name.isNotEmpty ? file.name : 'anexo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ok = await runAction(
      context,
      () => context.read<OsRepository>().uploadAnexo(os.id, bytes, name),
      success: 'Anexo enviado.',
    );
    if (ok) await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 900 ? 5 : (width >= 600 ? 4 : 3);
    return ListView(
      padding: Gaps.pageOf(context),
      children: [
        if (os.anexos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Gaps.xl),
            child: EmptyView(
              icon: Icons.photo_library_outlined,
              title: 'Nenhum anexo',
              message: 'Registre fotos do equipamento, peças e do serviço realizado.',
              actionLabel: canEdit ? 'Adicionar foto' : null,
              onAction: () => _add(context),
            ),
          )
        else ...[
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Gaps.sm,
            crossAxisSpacing: Gaps.sm,
            children: [
              for (final (i, a) in os.anexos.indexed)
                InkWell(
                  borderRadius: BorderRadius.circular(Gaps.radius),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnexoViewerPage(os: os, initialIndex: i, canDelete: canEdit, onChanged: onChanged),
                    ),
                  ),
                  child: Hero(
                    tag: 'anexo_${a.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Gaps.radius),
                      child: AuthImage(url: a.thumbUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: Gaps.lg),
            OutlinedButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Adicionar foto'),
            ),
          ],
        ],
      ],
    );
  }
}

/// Imagem protegida por token (anexos da API).
class AuthImage extends StatefulWidget {
  const AuthImage({super.key, required this.url, this.fit = BoxFit.contain});

  final String url;
  final BoxFit fit;

  static final Map<String, Uint8List> _cache = {};

  @override
  State<AuthImage> createState() => _AuthImageState();
}

class _AuthImageState extends State<AuthImage> {
  late Future<Uint8List> _future = _load();

  Future<Uint8List> _load() async {
    final cached = AuthImage._cache[widget.url];
    if (cached != null) return cached;
    final bytes = await context.read<OsRepository>().anexoBytes(widget.url);
    if (AuthImage._cache.length > 60) AuthImage._cache.clear();
    return AuthImage._cache[widget.url] = bytes;
  }

  @override
  void didUpdateWidget(covariant AuthImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasData) {
          return Image.memory(
            snap.data!,
            fit: widget.fit,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _placeholder(context, Icons.insert_drive_file_outlined),
          );
        }
        if (snap.hasError) {
          return GestureDetector(
            onTap: () => setState(() => _future = _load()),
            child: _placeholder(context, Icons.broken_image_outlined),
          );
        }
        return Container(color: context.tokens.subtle);
      },
    );
  }

  Widget _placeholder(BuildContext context, IconData icon) => Container(
        color: context.tokens.subtle,
        alignment: Alignment.center,
        child: Icon(icon, color: context.tokens.muted),
      );
}

class AnexoViewerPage extends StatefulWidget {
  const AnexoViewerPage({
    super.key,
    required this.os,
    required this.initialIndex,
    required this.canDelete,
    required this.onChanged,
  });

  final OrdemServico os;
  final int initialIndex;
  final bool canDelete;
  final Future<void> Function() onChanged;

  @override
  State<AnexoViewerPage> createState() => _AnexoViewerPageState();
}

class _AnexoViewerPageState extends State<AnexoViewerPage> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  Anexo get _current => widget.os.anexos[_index];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final a = _current;
    await runAction(context, () async {
      final bytes = await context.read<OsRepository>().anexoBytes(a.url);
      await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: a.nome, mimeType: _mime(a.nome))], text: 'OS #${widget.os.id}'));
    });
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir anexo?',
      message: 'A imagem será removida da OS.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runAction(
      context,
      () => context.read<OsRepository>().removeAnexo(widget.os.id, _current.id),
      success: 'Anexo excluído.',
    );
    if (done && mounted) {
      Navigator.pop(context);
      await widget.onChanged();
    }
  }

  static String _mime(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'image/jpeg',
    };
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.os.anexos.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} de $total', style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(tooltip: 'Compartilhar', icon: const Icon(Icons.ios_share_rounded), onPressed: _share),
          if (widget.canDelete)
            IconButton(tooltip: 'Excluir', icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: total,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final a = widget.os.anexos[i];
          return Hero(
            tag: 'anexo_${a.id}',
            child: _ZoomableAuthImage(url: a.url),
          );
        },
      ),
    );
  }
}

class _ZoomableAuthImage extends StatefulWidget {
  const _ZoomableAuthImage({required this.url});

  final String url;

  @override
  State<_ZoomableAuthImage> createState() => _ZoomableAuthImageState();
}

class _ZoomableAuthImageState extends State<_ZoomableAuthImage> {
  late final Future<Uint8List> _future = _load();

  Future<Uint8List> _load() async {
    final cached = AuthImage._cache[widget.url];
    if (cached != null) return cached;
    final bytes = await context.read<OsRepository>().anexoBytes(widget.url);
    return AuthImage._cache[widget.url] = bytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return PhotoView(
          imageProvider: MemoryImage(snap.data!),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
        );
      },
    );
  }
}
