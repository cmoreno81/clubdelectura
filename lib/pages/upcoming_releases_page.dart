import 'package:flutter/material.dart';

import '../models/catalog_book.dart';
import '../models/upcoming_release.dart';
import '../services/api_service.dart';
import '../services/upcoming_releases_service.dart';
import '../services/wishlist_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/libros/add_book_sheet.dart';

enum _ReleaseRange { week, month, soon }

enum ReleaseCatalogMode { upcoming, newReleases }

class UpcomingReleasesPage extends StatefulWidget {
  const UpcomingReleasesPage({
    super.key,
    this.mode = ReleaseCatalogMode.upcoming,
  });

  final ReleaseCatalogMode mode;

  @override
  State<UpcomingReleasesPage> createState() => _UpcomingReleasesPageState();
}

class _UpcomingReleasesPageState extends State<UpcomingReleasesPage> {
  final _service = UpcomingReleasesService();
  final _wishlist = WishlistService();
  _ReleaseRange _range = _ReleaseRange.soon;
  late Future<List<UpcomingRelease>> _future = _load();
  final Set<String> _busy = {};
  String? _selectedCliche;
  String? _selectedGenre;

  Future<List<UpcomingRelease>> _load() {
    if (widget.mode == ReleaseCatalogMode.newReleases) {
      return _service.loadNew();
    }
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = switch (_range) {
      _ReleaseRange.week => from.add(const Duration(days: 7)),
      _ReleaseRange.month => DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      _ReleaseRange.soon => from.add(const Duration(days: 180)),
    };
    return _service.load(from: from, to: to);
  }

  void _select(_ReleaseRange value) {
    setState(() {
      _range = value;
      _future = _load();
    });
  }

  Future<void> _toggleWishlist(UpcomingRelease book) async {
    if (_busy.contains(book.id)) return;
    setState(() => _busy.add(book.id));
    try {
      if (book.isInWishlist && book.wishlistItemId != null) {
        await _wishlist.deleteItem(book.wishlistItemId!);
      } else {
        await _wishlist.addItem(
          bookId: book.id,
          title: book.title,
          author: book.author,
          coverUrl: book.coverUrl,
          isbn: book.isbn,
          releaseDate: book.publicationDate,
        );
      }
      if (mounted) setState(() => _future = _load());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se ha podido actualizar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(book.id));
    }
  }

  Future<void> _addToLibrary(UpcomingRelease book) async {
    if (book.isInLibrary || _busy.contains(book.id)) return;
    final preferences = await showAddBookSheet(
      context,
      title: book.title,
      author: book.author ?? '',
      coverUrl: book.coverUrl ?? '',
    );
    if (preferences == null || !mounted) return;
    setState(() => _busy.add(book.id));
    try {
      await ApiService().importarLibroCatalogo(
        book: CatalogBook(
          id: book.id,
          source: 'CLUBREADS',
          title: book.title,
          authors: book.author == null ? const [] : [book.author!],
          coverUrl: book.coverUrl ?? '',
          genre: book.genre,
          isbn: book.isbn ?? '',
          inMyLibrary: false,
          status: '',
          publicationYear: book.publicationDate.year,
          publisher: book.publisher ?? '',
          publicationDate: book.publicationDate.toIso8601String(),
        ),
        prioridad: preferences.priority,
        formato: preferences.format,
      );
      if (mounted) {
        setState(() => _future = _load());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${book.title} está en tu biblioteca')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se ha podido añadir: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(book.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.mode == ReleaseCatalogMode.newReleases
            ? 'Novedades disponibles'
            : 'Próximos lanzamientos',
      ),
    ),
    body: Column(
      children: [
        if (widget.mode == ReleaseCatalogMode.upcoming)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SegmentedButton<_ReleaseRange>(
              segments: const [
                ButtonSegment(value: _ReleaseRange.week, label: Text('Semana')),
                ButtonSegment(value: _ReleaseRange.month, label: Text('Mes')),
                ButtonSegment(value: _ReleaseRange.soon, label: Text('Pronto')),
              ],
              selected: {_range},
              onSelectionChanged: (value) => _select(value.first),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<UpcomingRelease>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _message(
                  Icons.cloud_off_outlined,
                  widget.mode == ReleaseCatalogMode.newReleases
                      ? 'No hemos podido cargar las novedades'
                      : 'No hemos podido cargar los lanzamientos',
                  button: 'Reintentar',
                  onPressed: () => setState(() => _future = _load()),
                );
              }
              final allBooks = snapshot.data ?? const [];
              if (allBooks.isEmpty) {
                return _message(
                  Icons.event_available_outlined,
                  widget.mode == ReleaseCatalogMode.newReleases
                      ? 'Todavía no hay novedades disponibles'
                      : 'No hay lanzamientos en este periodo',
                );
              }
              final cliches =
                  allBooks.expand((book) => book.cliches).toSet().toList()
                    ..sort();
              final genres =
                  allBooks
                      .map((book) => book.genre.trim())
                      .where((genre) => genre.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
              final selected = cliches.contains(_selectedCliche)
                  ? _selectedCliche
                  : null;
              final selectedGenre = genres.contains(_selectedGenre)
                  ? _selectedGenre
                  : null;
              final books = allBooks
                  .where(
                    (book) =>
                        (selectedGenre == null ||
                            book.genre.trim() == selectedGenre) &&
                        (selected == null || book.cliches.contains(selected)),
                  )
                  .toList(growable: false);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: DropdownButtonFormField<String?>(
                      initialValue: selectedGenre,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined),
                        labelText: 'Filtrar por género',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos los géneros'),
                        ),
                        ...genres.map(
                          (genre) => DropdownMenuItem<String?>(
                            value: genre,
                            child: Text(genre),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedGenre = value),
                    ),
                  ),
                  if (widget.mode == ReleaseCatalogMode.upcoming)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: DropdownButtonFormField<String?>(
                        initialValue: selected,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.auto_awesome_outlined),
                          labelText: 'Filtrar por cliché',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos los clichés'),
                          ),
                          ...cliches.map(
                            (cliche) => DropdownMenuItem<String?>(
                              value: cliche,
                              child: Text(cliche),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedCliche = value),
                      ),
                    ),
                  Expanded(
                    child: books.isEmpty
                        ? _message(
                            Icons.filter_alt_off_outlined,
                            'No hay títulos con estos filtros en esta selección',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.xxl,
                            ),
                            itemCount: books.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (_, index) =>
                                _releaseCard(books[index]),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _releaseCard(UpcomingRelease book) {
    final busy = _busy.contains(book.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClubBookCover(
              title: book.title,
              imageUrl: book.coverUrl ?? '',
              width: 76,
              height: 114,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if ((book.author ?? '').isNotEmpty) Text(book.author!),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDate(book.publicationDate),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    [
                      book.genre,
                      book.publisher,
                    ].where((value) => value?.isNotEmpty == true).join(' · '),
                  ),
                  if (book.cliches.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: book.cliches
                          .map(
                            (cliche) => Chip(
                              avatar: const Icon(Icons.auto_awesome, size: 15),
                              label: Text(cliche),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (book.isInWishlist)
                        FilledButton.tonalIcon(
                          onPressed: busy ? null : () => _toggleWishlist(book),
                          icon: const Icon(Icons.favorite),
                          label: const Text('En mi wishlist'),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => _toggleWishlist(book),
                          icon: const Icon(Icons.favorite_border),
                          label: const Text('Añadir a mi wishlist'),
                        ),
                      FilledButton.tonalIcon(
                        onPressed: busy || book.isInLibrary
                            ? null
                            : () => _addToLibrary(book),
                        icon: Icon(book.isInLibrary ? Icons.check : Icons.add),
                        label: Text(
                          book.isInLibrary
                              ? 'En mi biblioteca'
                              : 'Añadir a mi biblioteca',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(
    IconData icon,
    String text, {
    String? button,
    VoidCallback? onPressed,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(text, textAlign: TextAlign.center),
          if (button != null)
            TextButton(onPressed: onPressed, child: Text(button)),
        ],
      ),
    ),
  );

  String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}
