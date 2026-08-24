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
    _range = value;
    final refreshed = _load();
    setState(() {
      _future = refreshed;
    });
  }

  void _reload() {
    final refreshed = _load();
    setState(() {
      _future = refreshed;
    });
  }

  Future<void> _toggleWishlist(UpcomingRelease book) async {
    if (_busy.contains(book.id)) return;
    setState(() {
      _busy.add(book.id);
    });
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
      if (mounted) {
        final refreshed = _load();
        setState(() {
          _future = refreshed;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se ha podido actualizar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy.remove(book.id);
        });
      }
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
    setState(() {
      _busy.add(book.id);
    });
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
        final refreshed = _load();
        setState(() {
          _future = refreshed;
        });
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
      if (mounted) {
        setState(() {
          _busy.remove(book.id);
        });
      }
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
    body: FutureBuilder<List<UpcomingRelease>>(
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
            onPressed: _reload,
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
        final cliches = allBooks.expand((book) => book.cliches).toSet().toList()
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
        return RefreshIndicator(
          onRefresh: () async {
            final refreshed = _load();
            setState(() {
              _future = refreshed;
            });
            await refreshed;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            itemCount: (books.isEmpty ? 1 : books.length) + 2,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? AppSpacing.md : AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _catalogHeader(allBooks.length);
              }
              if (index == 1) {
                return _filters(
                  genres: genres,
                  selectedGenre: selectedGenre,
                  cliches: cliches,
                  selectedCliche: selected,
                  resultCount: books.length,
                );
              }
              if (books.isEmpty) {
                return _message(
                  Icons.filter_alt_off_outlined,
                  'No hay títulos con estos filtros en esta selección',
                );
              }
              return _releaseCard(books[index - 2]);
            },
          ),
        );
      },
    ),
  );

  Widget _catalogHeader(int total) {
    final upcoming = widget.mode == ReleaseCatalogMode.upcoming;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: upcoming
              ? const [AppColors.primaryDark, AppColors.primary]
              : const [Color(0xFF9B493F), AppColors.inkCoral],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: (upcoming ? AppColors.primary : AppColors.inkCoral)
                .withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  upcoming
                      ? Icons.auto_awesome_outlined
                      : Icons.local_library_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upcoming ? 'RADAR EDITORIAL' : 'RECIÉN LLEGADOS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      upcoming
                          ? 'Historias que están por llegar'
                          : 'Nuevas historias en librerías',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            upcoming
                ? '$total lanzamientos para descubrir, guardar y reservar.'
                : '$total novedades disponibles para tu próxima lectura.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .84),
              height: 1.35,
            ),
          ),
          if (upcoming) ...[
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<_ReleaseRange>(
              segments: const [
                ButtonSegment(value: _ReleaseRange.week, label: Text('Semana')),
                ButtonSegment(value: _ReleaseRange.month, label: Text('Mes')),
                ButtonSegment(value: _ReleaseRange.soon, label: Text('Pronto')),
              ],
              selected: {_range},
              onSelectionChanged: (value) => _select(value.first),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primaryDark
                      : Colors.white,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white.withValues(alpha: .08),
                ),
                side: WidgetStatePropertyAll(
                  BorderSide(color: Colors.white.withValues(alpha: .26)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filters({
    required List<String> genres,
    required String? selectedGenre,
    required List<String> cliches,
    required String? selectedCliche,
    required int resultCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft.withValues(alpha: .82),
        border: Border.all(color: AppColors.border),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(
                child: Text(
                  'Encuentra tu próxima historia',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$resultCount títulos',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _filterField(
            label: 'Género',
            icon: Icons.category_outlined,
            value: selectedGenre,
            emptyLabel: 'Todos los géneros',
            options: genres,
            onChanged: (value) {
              setState(() {
                _selectedGenre = value;
              });
            },
          ),
          if (widget.mode == ReleaseCatalogMode.upcoming) ...[
            const SizedBox(height: AppSpacing.sm),
            _filterField(
              label: 'Cliché',
              icon: Icons.auto_awesome_outlined,
              value: selectedCliche,
              emptyLabel: 'Todos los clichés',
              options: cliches,
              onChanged: (value) {
                setState(() {
                  _selectedCliche = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterField({
    required String label,
    required IconData icon,
    required String? value,
    required String emptyLabel,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 6),
        child: Text(
          'Filtrar por $label',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      DropdownButtonFormField<String?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
        ),
        items: [
          DropdownMenuItem<String?>(value: null, child: Text(emptyLabel)),
          ...options.map(
            (option) => DropdownMenuItem<String?>(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    ],
  );

  Widget _releaseCard(UpcomingRelease book) {
    final busy = _busy.contains(book.id);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border.withValues(alpha: .8)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                ClubBookCover(
                  title: book.title,
                  imageUrl: book.coverUrl ?? '',
                  width: 82,
                  height: 123,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${book.publicationDate.day} ${_shortMonth(book.publicationDate)}',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      height: 1.15,
                    ),
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

  String _shortMonth(DateTime date) => const [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC',
  ][date.month - 1];
}
