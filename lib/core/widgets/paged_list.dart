import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'states.dart';

typedef PageFetcher<T> = Future<List<T>> Function(int page, String search);

/// Controla paginação, busca e recarga de uma lista remota.
class PagedController<T> extends ChangeNotifier {
  PagedController({required this.fetch, this.pageSize = 10, this.firstPage = 0});

  final PageFetcher<T> fetch;

  /// Tamanho mínimo esperado de uma página; se vier menos, acabou.
  final int pageSize;
  final int firstPage;

  final List<T> items = [];
  Object? error;
  bool loading = false;
  bool hasMore = true;
  String search = '';
  int _page = 0;
  int _generation = 0;

  bool get isInitialLoading => loading && items.isEmpty;

  Future<void> refresh() async {
    _generation++;
    _page = firstPage;
    hasMore = true;
    error = null;
    items.clear();
    loading = false;
    notifyListeners();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    final gen = _generation;
    loading = true;
    notifyListeners();
    try {
      final result = await fetch(_page, search);
      if (gen != _generation) return;
      items.addAll(result);
      hasMore = result.length >= pageSize && result.isNotEmpty;
      _page++;
      error = null;
    } catch (e) {
      if (gen != _generation) return;
      error = e;
      hasMore = false;
    } finally {
      if (gen == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void setSearch(String value) {
    if (value == search) return;
    search = value;
    refresh();
  }
}

/// Lista com scroll infinito e pull-to-refresh para um [PagedController].
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.empty,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(Gaps.lg, Gaps.sm, Gaps.lg, 96),
  });

  final PagedController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  /// Recebe `true` quando há busca ativa.
  final Widget Function(bool searching) empty;
  final Widget? header;
  final EdgeInsetsGeometry padding;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        widget.controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        Widget body;
        if (c.isInitialLoading) {
          body = const SkeletonList();
        } else if (c.items.isEmpty && c.error != null) {
          body = ListView(children: [
            const SizedBox(height: 60),
            ErrorView(error: c.error!, onRetry: c.refresh),
          ]);
        } else if (c.items.isEmpty) {
          body = ListView(children: [const SizedBox(height: 60), widget.empty(c.search.isNotEmpty)]);
        } else {
          body = ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: widget.padding.add(EdgeInsets.only(bottom: Gaps.systemBottom(context))),
            itemCount: c.items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: Gaps.sm),
            itemBuilder: (context, i) {
              if (i == c.items.length) {
                if (c.loading) {
                  return const Padding(
                    padding: EdgeInsets.all(Gaps.lg),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                  );
                }
                if (c.error != null) {
                  return TextButton(onPressed: c.refresh, child: const Text('Erro ao carregar. Tentar novamente'));
                }
                return const SizedBox.shrink();
              }
              return widget.itemBuilder(context, c.items[i]);
            },
          );
        }

        return Column(
          children: [
            if (widget.header != null) widget.header!,
            Expanded(
              child: RefreshIndicator(onRefresh: c.refresh, child: ContentWidthScroll(child: body)),
            ),
          ],
        );
      },
    );
  }
}

/// Mantém listas confortáveis em telas largas.
class ContentWidthScroll extends StatelessWidget {
  const ContentWidthScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: child),
    );
  }
}

/// Campo de busca com debounce.
class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.hint, required this.onChanged, this.autofocus = false});

  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _changed(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => widget.onChanged(v.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      autofocus: widget.autofocus,
      onChanged: _changed,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        suffixIcon: _ctrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _ctrl.clear();
                  _changed('');
                },
              ),
      ),
    );
  }
}
