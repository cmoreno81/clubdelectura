import 'package:flutter/material.dart';

import '../models/catalog_book.dart';
import '../models/perfil_usuario.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/library_refresh_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/optimized_network_image.dart';
import '../widgets/sagas/series_volume_details_dialog.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

typedef SeriesCatalogSearch = Future<List<CatalogBook>> Function(String query);

class CompleteSeriesPage extends StatefulWidget {
  const CompleteSeriesPage({super.key, required this.series, this.searchBooks});

  final PerfilSaga series;
  final SeriesCatalogSearch? searchBooks;

  @override
  State<CompleteSeriesPage> createState() => _CompleteSeriesPageState();
}

class _CompleteSeriesPageState extends State<CompleteSeriesPage> {
  late final TextEditingController _searchController;
  List<CatalogBook> _books = const [];
  bool _loading = true;
  String? _error;
  String? _linkingId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: [
        widget.series.nombre,
        widget.series.autor,
      ].where((value) => value.trim().isNotEmpty).join(' '),
    );
    _search();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books =
          await (widget.searchBooks?.call(_searchController.text) ??
              ApiService().getCatalogoGeneral(query: _searchController.text));
      final linkedIds = widget.series.volumenes
          .map((volume) => volume.bookId)
          .toSet();
      if (mounted) {
        setState(() {
          _books = books
              .where((book) => !linkedIds.contains(book.id))
              .toList(growable: false);
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(CatalogBook book) async {
    final selection = await _askVolumeDetails(book);
    if (selection == null || !mounted) return;

    final order = selection.order;
    final normalizedOrder = order.trim().replaceAll(',', '.');

    final orderAlreadyExists = widget.series.volumenes.any(
      (volume) => volume.numero.trim().replaceAll(',', '.') == normalizedOrder,
    );

    if (orderAlreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El volumen $order ya existe en ${widget.series.nombre}.',
          ),
        ),
      );
      return;
    }

    setState(() => _linkingId = book.id);

    try {
      final linkedBookId = await ApiService().vincularVolumenSaga(
        sagaId: widget.series.id,
        numero: order,
        book: book,
        estado: selection.status.isEmpty ? null : selection.status,
        formato: selection.format,
        valoracion: selection.rating,
        fechaInicio: selection.startDate,
        fechaFin: selection.endDate,
      );

      LibraryRefreshNotifier.instance.invalidate();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.title} añadido a la saga')),
      );

      Navigator.pop(context, linkedBookId);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _linkingId = null);
    }
  }

  // Caso A: en biblioteca y ya finalizado → preservar todo, solo pedir número
  // Caso B: en biblioteca pero no finalizado → respetar estado actual
  // Caso C: no está en biblioteca o es externo → formulario completo
  Future<SeriesVolumeSelection?> _askVolumeDetails(CatalogBook book) async {
    final isFinished = book.status == 'FINALIZADO';
    final preservePersonalData =
        !book.isExternal && book.inMyLibrary && isFinished;

    return showModalBottomSheet<SeriesVolumeSelection>(
      context: context,
      isScrollControlled:
          true, // ← clave para que ocupe toda la altura necesaria
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.viewInsetsOf(dialogContext).bottom,
            ),
            child: SeriesVolumeDetailsDialog(
              book: book,
              preservePersonalData: preservePersonalData,
              initialOrder: _suggestedOrder().toString(),
              initialStatus: book.inMyLibrary ? book.status : 'PENDIENTE',
              initialFormat: '',
              initialRating: '',
              initialStartDate: book.startedAt,
              initialEndDate: book.finishedAt,
            ),
          ),
        ),
      ),
    );
  }

  int _suggestedOrder() {
    final numbers = widget.series.volumenes
        .map((volume) => double.tryParse(volume.numero.replaceAll(',', '.')))
        .whereType<double>()
        .where((value) => value == value.roundToDouble())
        .map((value) => value.toInt())
        .toSet();
    var candidate = 1;
    while (numbers.contains(candidate)) {
      candidate++;
    }
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Completar ${widget.series.nombre}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text(
                  'Busca y confirma únicamente los libros que pertenecen a esta saga.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SearchBar(
                  controller: _searchController,
                  leading: const Icon(Icons.search_rounded),
                  hintText: 'Saga, título o autor',
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _search(),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _books = const [];
                            _error = null;
                            _loading = false;
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    IconButton(
                      tooltip: 'Buscar',
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) return const CardListSkeleton();
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Escribe el título, la saga o el autor que quieres buscar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_books.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No encontramos más volúmenes. Puedes cambiar la búsqueda por el título concreto.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final localBooks = _books.where((book) => !book.isExternal).toList();
    final externalBooks = _books.where((book) => book.isExternal).toList();
    final items = <Object>[
      if (localBooks.isNotEmpty) const _ResultSection('Ya en ClubReaders'),
      ...localBooks,
      if (externalBooks.isNotEmpty)
        const _ResultSection('Buscar en catálogos externos'),
      ...externalBooks,
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) {
        final item = items[index];
        if (item is _ResultSection) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              item.title,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        }
        final book = item as CatalogBook;
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.sm),
            leading: SizedBox(
              width: 48,
              height: 70,
              child: OptimizedNetworkImage(
                url: book.coverUrl,
                width: 48,
                height: 70,
                fallback: const Icon(Icons.auto_stories_outlined),
              ),
            ),
            title: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${book.authorLabel}\n${book.inMyLibrary ? '${_statusLabel(book.status)} · ' : ''}${book.sourceLabel}',
            ),
            isThreeLine: true,
            trailing: _linkingId == book.id
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filledTonal(
                    tooltip: 'Añadir a la saga',
                    onPressed: () => _select(book),
                    icon: const Icon(Icons.add_rounded),
                  ),
          ),
        );
      },
    );
  }

  String _statusLabel(String status) => switch (status) {
    'FINALIZADO' => '✅ Terminado',
    'LEYENDO' => '📖 Leyendo',
    'PENDIENTE' => '🔖 Pendiente',
    _ => 'En tu biblioteca',
  };
}

class _ResultSection {
  const _ResultSection(this.title);
  final String title;
}
