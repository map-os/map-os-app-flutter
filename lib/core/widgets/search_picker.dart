import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'paged_list.dart';
import 'states.dart';

/// Abre uma folha com busca remota e retorna o item escolhido.
Future<T?> showSearchPicker<T>(
  BuildContext context, {
  required String title,
  required Future<List<T>> Function(String search) fetch,
  required Widget Function(BuildContext context, T item) itemBuilder,
  String hint = 'Buscar',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.88,
      child: _SearchPicker<T>(title: title, fetch: fetch, itemBuilder: itemBuilder, hint: hint),
    ),
  );
}

class _SearchPicker<T> extends StatefulWidget {
  const _SearchPicker({required this.title, required this.fetch, required this.itemBuilder, required this.hint});

  final String title;
  final Future<List<T>> Function(String search) fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String hint;

  @override
  State<_SearchPicker<T>> createState() => _SearchPickerState<T>();
}

class _SearchPickerState<T> extends State<_SearchPicker<T>> {
  late Future<List<T>> _future = widget.fetch('');
  String _search = '';

  void _onSearch(String v) => setState(() {
        _search = v;
        _future = widget.fetch(v);
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gaps.xl, 0, Gaps.xl, Gaps.md),
            child: Text(widget.title, style: context.text.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
            child: SearchField(hint: widget.hint, onChanged: _onSearch),
          ),
          const SizedBox(height: Gaps.sm),
          Expanded(
            child: FutureBuilder<List<T>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) return ErrorView(error: snap.error!, onRetry: () => _onSearch(_search));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final items = snap.data!;
                if (items.isEmpty) {
                  return const EmptyView(icon: Icons.search_off_rounded, title: 'Nada encontrado');
                }
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(Gaps.sm, 0, Gaps.sm, Gaps.xl + Gaps.systemBottom(context)),
                  itemCount: items.length,
                  itemBuilder: (context, i) => InkWell(
                    borderRadius: BorderRadius.circular(Gaps.radiusSm),
                    onTap: () => Navigator.pop(context, items[i]),
                    child: widget.itemBuilder(context, items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
