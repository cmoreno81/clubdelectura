import 'dart:async';

import 'package:club_lectura_app/services/library_refresh_notifier.dart';
import 'package:flutter/material.dart';

import '../models/catalog_book.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/cursor_pagination_controller.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../navigation/book_detail_navigation.dart';
import '../widgets/common/libro_finalizado_celebration.dart';
import '../widgets/common/optimized_network_image.dart';
import '../widgets/libros/add_book_sheet.dart';
import '../widgets/libros/apply_initial_status.dart';
import '../widgets/libros/libro_acciones_rapidas.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';
import '../widgets/common/screen_hint_banner.dart';

class ExploreCatalogPage extends StatefulWidget {
  const ExploreCatalogPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<ExploreCatalogPage> createState() => _ExploreCatalogPageState();
}

class _ExploreCatalogPageState extends State<ExploreCatalogPage> {
  late final TextEditingController _searchController;
  late final CursorPaginationController<CatalogBook> _pagination;
  final ScrollController _scrollController = ScrollController();
  List<CatalogBook> _books = const [];
  bool _loading = false;
  String? _error;
  String? _addingId;
  bool _longPressing = false;
  Timer? _debounce;
  final RequestGeneration _searchGeneration = RequestGeneration();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _pagination = CursorPaginationController(
      loadPage: (cursor) => ApiService().getCatalogoGeneralPage(cursor: cursor),
      keyOf: (book) => '${book.source}:${book.id}',
    );
    _scrollController.addListener(_onScroll);
    if (widget.initialQuery.trim().isEmpty) {
      _pagination.loadFirst();
    } else {
      _load(widget.initialQuery);
    }
  }

  void _onScroll() {
    if (_searchController.text.trim().isNotEmpty ||
        !_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter < 400) {
      _pagination.loadMore();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _pagination.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load([String query = '']) async {
    final normalized = query.trim();
    final generation = _searchGeneration.begin();
    if (normalized.isEmpty) {
      setState(() {
        _books = const [];
        _loading = false;
        _error = null;
      });
      await _pagination.loadFirst();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await ApiService().getCatalogoGeneral(query: normalized);
      if (mounted && _searchGeneration.isCurrent(generation)) {
        setState(() => _books = _deduplicate(books));
      }
    } on ApiException catch (error) {
      if (mounted && _searchGeneration.isCurrent(generation)) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted && _searchGeneration.isCurrent(generation)) {
        setState(() => _error = 'No se ha podido cargar la biblioteca.');
      }
    } finally {
      if (mounted && _searchGeneration.isCurrent(generation)) {
        setState(() => _loading = false);
      }
    }
  }

  List<CatalogBook> _deduplicate(Iterable<CatalogBook> books) {
    final result = <String, CatalogBook>{};
    for (final book in books) {
      result.putIfAbsent('${book.source}:${book.id}', () => book);
    }
    return result.values.toList(growable: false);
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(value));
  }

  Future<void> _add(CatalogBook book) async {
    final preferences = await showAddBookSheet(
      context,
      title: book.title,
      author: book.authorLabel,
      coverUrl: book.coverUrl,
      showStatusPicker: true,
    );
    if (preferences == null || !mounted) return;
    setState(() => _addingId = book.id);
    try {
      await ApiService().importarLibroCatalogo(
        book: book,
        prioridad: preferences.priority,
        formato: preferences.format,
      );
      // importarLibroCatalogo siempre crea como pendiente: si se eligió otro
      // estado inicial, lo aplicamos reutilizando la lógica ya validada de
      // actualizarEstado. El libro ya quedó añadido en la llamada anterior,
      // así que un fallo aquí solo deja el estado en "sigue pendiente".
      var estadoFinal = 'PENDIENTE';
      if (preferences.status != 'PENDIENTE' && mounted) {
        final usuario = await UsuarioService().obtenerUsuario();
        if (usuario != null && usuario.trim().isNotEmpty && mounted) {
          estadoFinal = await aplicarEstadoInicial(
            context,
            usuario: usuario,
            libro: book.title,
            estadoElegido: preferences.status,
            formato: preferences.format,
          );
        }
      }
      if (!mounted) return;
      LibraryRefreshNotifier.instance.invalidate();

      setState(() {
        _books = _books
            .map(
              (item) => item.id == book.id && item.source == book.source
                  ? item.copyWith(inMyLibrary: true, status: estadoFinal)
                  : item,
            )
            .toList(growable: false);
      });
      _pagination.replace(
        '${book.source}:${book.id}',
        (item) => item.copyWith(inMyLibrary: true, status: estadoFinal),
      );
      if (estadoFinal == 'FINALIZADO') {
        await mostrarCelebracionFinalizado(
          context,
          titulo: book.title,
          coverUrl: book.coverUrl,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${book.title} está ya en tu biblioteca')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se ha podido añadir')),
        );
      }
    } finally {
      if (mounted) setState(() => _addingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Explorar libros')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Título, autor o ISBN',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Borrar',
                    onPressed: () {
                      _debounce?.cancel();
                      _searchController.clear();
                      _load();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
              onChanged: _onQueryChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                _load(value);
              },
            ),
          ),
          ScreenHintBanner(
            featureKey: 'hint_catalogo_v2',
            titulo: 'Explorar el catálogo',
            tips: const [
              ScreenHintTip('🔍', 'Busca por título, autor o ISBN para encontrar cualquier libro'),
              ScreenHintTip('📚', 'Pulsa un libro para ver la ficha y añadirlo a tu biblioteca'),
              ScreenHintTip('✋', 'Pulsación larga para cambiar su estado (leyendo, leído, TBR…) directamente'),
            ],
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _pagination,
              builder: (_, _) => _content(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    final browsing = _searchController.text.trim().isEmpty;
    final loading = browsing ? _pagination.initialLoading : _loading;
    final error = browsing ? _pagination.initialError?.toString() : _error;
    final books = browsing ? _pagination.items : _books;
    if (loading && books.isEmpty) {
      return const CoverListSkeleton();
    }
    if (error != null && books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: browsing
                    ? _pagination.loadFirst
                    : () => _load(_searchController.text),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (books.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No encontramos ese libro. Prueba con el título o el ISBN.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final hasRefreshError = error != null && books.isNotEmpty;
    final hasFooter =
        (browsing &&
            (_pagination.loadingMore ||
                _pagination.loadMoreError != null ||
                _pagination.hasContentError)) ||
        hasRefreshError;
    return Stack(
      children: [
        ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          itemCount: books.length + (hasFooter ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, index) {
            if (index == books.length) {
              if (hasRefreshError || _pagination.hasContentError) {
                return Center(
                  child: TextButton.icon(
                    onPressed: browsing
                        ? _pagination.loadFirst
                        : () => _load(_searchController.text),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('No se pudo actualizar. Reintentar'),
                  ),
                );
              }
              return Center(
                child: _pagination.loadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton.icon(
                        onPressed: _pagination.loadMore,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('No se pudo cargar más. Reintentar'),
                      ),
              );
            }
            return _bookCard(books[index]);
          },
        ),
        if (loading && books.isNotEmpty)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  Future<void> _openDetail(CatalogBook book) async {
    final changed = await openCatalogBookDetail(
      context,
      title: book.title,
      bookId: book.id,
      coverUrl: book.coverUrl,
      genre: book.genre,
      globalStats: true,
    );
    if (changed && mounted) _pagination.loadFirst();
  }

  Future<void> _onLongPress(CatalogBook book) async {
    if (_longPressing) return;
    _longPressing = true;
    try {
      final changed = await mostrarAccionesRapidasLibro(
        context,
        bookId: book.id,
        titulo: book.title,
        autor: book.authorLabel,
        genero: book.genre,
        coverUrl: book.coverUrl,
        abrirFicha: (_) => _openDetail(book),
      );
      if (changed && mounted) {
        LibraryRefreshNotifier.instance.invalidate();
        // Actualizar el libro en la lista local
        CatalogBook updater(CatalogBook b) =>
            b.id == book.id && b.source == book.source
                ? b.copyWith(inMyLibrary: true)
                : b;
        setState(() {
          _books = _books.map(updater).toList(growable: false);
        });
        _pagination.replace(
          '${book.source}:${book.id}',
          updater,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar la información del libro.'),
          ),
        );
      }
    } finally {
      _longPressing = false;
    }
  }

  Widget _bookCard(CatalogBook book) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(book),
        onLongPress: () => _onLongPress(book),
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 94,
                child: OptimizedNetworkImage(
                  url: book.coverUrl,
                  width: 64,
                  height: 94,
                  fallback: Container(
                    color: AppColors.primary.withValues(alpha: .1),
                    child: const Icon(Icons.auto_stories_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.authorLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.sourceLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (book.inMyLibrary)
              const Tooltip(
                message: 'Ya está en tu biblioteca',
                child: Icon(
                  Icons.bookmark_added_rounded,
                  color: AppColors.success,
                ),
              )
            else if (_addingId == book.id)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton.filledTonal(
                tooltip: 'Añadir a mi biblioteca',
                onPressed: () => _add(book),
                icon: const Icon(Icons.add_rounded),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
