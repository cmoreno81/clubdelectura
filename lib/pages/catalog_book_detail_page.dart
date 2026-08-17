import 'package:club_lectura_app/services/library_refresh_notifier.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/catalog_book.dart';
import '../models/libro_agrupado.dart';
import '../navigation/app_page_route.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/libros/add_book_sheet.dart';
import 'detalle_libro_page.dart';

class CatalogBookDetailPage extends StatefulWidget {
  const CatalogBookDetailPage({
    super.key,
    required this.bookId,
    required this.title,
    required this.coverUrl,
    required this.genre,
    this.loadBook,
    this.addBook,
    this.onLibraryChanged,
  });

  final String bookId;
  final String title;
  final String coverUrl;
  final String genre;
  final Future<CatalogBook?> Function(String bookId, String title)? loadBook;
  final Future<String> Function(
    CatalogBook? book,
    AddBookPreferences preferences,
  )?
  addBook;
  final VoidCallback? onLibraryChanged;

  @override
  State<CatalogBookDetailPage> createState() => _CatalogBookDetailPageState();
}

class _CatalogBookDetailPageState extends State<CatalogBookDetailPage> {
  CatalogBook? _book;
  bool _loading = true;
  bool _adding = false;
  bool _added = false;
  bool _navigating = false;
  bool _sheetOpen = false;

  /// bookId devuelto por el servidor al añadir (puede diferir del widget.bookId
  /// si el servidor redirige a un libro canónico).
  String _addedBookId = '';

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final supplied = widget.loadBook;
      final CatalogBook? match;
      if (supplied != null) {
        match = await supplied(widget.bookId, widget.title);
      } else {
        final books = await ApiService().getCatalogoGeneral(
          query: widget.title,
        );
        match = widget.bookId.isNotEmpty
            ? books.where((book) => book.id == widget.bookId).firstOrNull
            : books
                  .where(
                    (book) =>
                        book.title.trim().toLowerCase() ==
                        widget.title.trim().toLowerCase(),
                  )
                  .firstOrNull;
      }
      if (mounted) {
        setState(() {
          _book = match;
          _added = match?.inMyLibrary == true;
          if (_added) _addedBookId = match!.id;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToLibrary() async {
    if (_adding || _added || _sheetOpen) return;
    _sheetOpen = true;
    final AddBookPreferences? result;
    try {
      result = await showAddBookSheet(
        context,
        title: _book?.title ?? widget.title,
        author: _book?.authorLabel ?? '',
        coverUrl: _book?.coverUrl.isNotEmpty == true
            ? _book!.coverUrl
            : widget.coverUrl,
      );
    } finally {
      _sheetOpen = false;
    }
    if (result == null || !mounted) return;

    setState(() => _adding = true);
    try {
      final addedId = widget.addBook != null
          ? await widget.addBook!(_book, result)
          : await ApiService().importarLibroCatalogo(
              book: _book,
              bookId: _book == null ? widget.bookId : null,
              titulo: _book == null ? widget.title : null,
              prioridad: result.priority,
              formato: result.format,
              estado: 'PENDIENTE',
            );
      if (mounted) {
        LibraryRefreshNotifier.instance.invalidate();
        widget.onLibraryChanged?.call();

        setState(() {
          _added = true;
          _adding = false;
          _addedBookId = addedId.isNotEmpty ? addedId : widget.bookId;
          _book = _book?.copyWith(inMyLibrary: true, status: 'PENDIENTE');
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.title} añadido a tu biblioteca')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _adding = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _verEnBiblioteca() async {
    if (_navigating) return;
    setState(() => _navigating = true);

    try {
      final effectiveBookId = _addedBookId.isNotEmpty
          ? _addedBookId
          : widget.bookId;

      // Cargamos los datos reales de la biblioteca (la caché ya fue invalidada
      // por LibraryRefreshNotifier al añadir el libro).
      final data = await ApiService().getLibrosData();

      if (!mounted) return;

      // Buscamos el libro por bookId entre todos los registros de la biblioteca.
      final Map<String, LibroAgrupado> agrupados = {};
      for (final libro in data.libros) {
        final clave = libro.libro.trim().toLowerCase();
        agrupados.putIfAbsent(
          clave,
          () => LibroAgrupado(
            libro: libro.libro,
            genero: libro.genero,
            registros: [],
            finalizados: [],
            yaLoTengo: libro.yaLoTengo,
            coverUrl: libro.coverUrl,
          ),
        );
        agrupados[clave]!.registros.add(libro);
        if (agrupados[clave]!.coverUrl.isEmpty && libro.coverUrl.isNotEmpty) {
          agrupados[clave]!.coverUrl = libro.coverUrl;
        }
      }
      for (final fin in data.finalizados) {
        final clave = fin.libro.trim().toLowerCase();
        agrupados.putIfAbsent(
          clave,
          () => LibroAgrupado(
            libro: fin.libro,
            genero: fin.genero,
            registros: [],
            finalizados: [],
            yaLoTengo: false,
            coverUrl: fin.coverUrl,
          ),
        );
        agrupados[clave]!.finalizados.add(fin);
      }

      // Primero buscamos por bookId exacto, después por título.
      LibroAgrupado? agrupado = agrupados.values
          .where((a) => a.bookId == effectiveBookId)
          .firstOrNull;
      agrupado ??= agrupados[widget.title.trim().toLowerCase()];

      if (agrupado == null || !mounted) return;

      await Navigator.push<void>(
        context,
        AppPageRoute(builder: (_) => DetalleLibroPage(libro: agrupado!)),
      );
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  Future<void> _abrirGoodreads() async {
    var value = _book?.goodreadsUrl.trim() ?? '';
    if (value.isEmpty) return;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          100,
        ),
        children: [
          ClubCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surfaceSoft, Color(0xFFF0E5FF)],
            ),
            borderColor: AppColors.primaryLight,
            child: Column(
              children: [
                ClubBookCover(
                  title: _book?.title ?? widget.title,
                  imageUrl: _book?.coverUrl.isNotEmpty == true
                      ? _book!.coverUrl
                      : widget.coverUrl,
                  width: 164,
                  highResolution: true,
                  showShadow: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _book?.title ?? widget.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 26,
                    height: 1.15,
                  ),
                ),
                if (_book?.authors.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _book!.authorLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if ((_book?.genre ?? widget.genre).trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    (_book?.genre ?? widget.genre).trim(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (_loading) ...[
                  const SizedBox(height: AppSpacing.md),
                  const CircularProgressIndicator(strokeWidth: 2),
                ] else if (_book != null &&
                    (_book!.pages != null || _book!.series.isNotEmpty)) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    alignment: WrapAlignment.center,
                    children: [
                      if (_book!.pages != null)
                        Chip(label: Text('${_book!.pages} páginas')),
                      if (_book!.series.isNotEmpty)
                        Chip(
                          label: Text(
                            _book!.seriesPosition.isEmpty
                                ? _book!.series
                                : '${_book!.series} · Libro ${_book!.seriesPosition}',
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Botón añadir ──
          if (_added)
            ClubCard(
              elevated: false,
              borderColor: AppColors.success.withValues(alpha: .3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '¡Añadido a tu biblioteca!',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _navigating ? null : _verEnBiblioteca,
                      icon: _navigating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.menu_book_outlined, size: 18),
                      label: const Text('Ver en mi biblioteca'),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _adding ? null : _addToLibrary,
                icon: _adding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(_adding ? 'Añadiendo…' : 'Añadir a mi biblioteca'),
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          if (_book?.description.trim().isNotEmpty == true) ...[
            ClubCard(
              elevated: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sinopsis', style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _book!.description.trim(),
                    style: AppTextStyles.body.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          if (_book != null &&
              (_book!.publisher.isNotEmpty ||
                  _book!.isbn.isNotEmpty ||
                  _book!.language.isNotEmpty ||
                  _book!.publicationDate.isNotEmpty ||
                  _book!.publicationYear != null)) ...[
            ClubCard(
              elevated: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos editoriales', style: AppTextStyles.subtitle),
                  if (_book!.publisher.isNotEmpty)
                    _MetadataRow(label: 'Editorial', value: _book!.publisher),
                  if (_book!.publicationDate.isNotEmpty)
                    _MetadataRow(
                      label: 'Publicación',
                      value: _book!.publicationDate,
                    )
                  else if (_book!.publicationYear != null)
                    _MetadataRow(
                      label: 'Publicación',
                      value: '${_book!.publicationYear}',
                    ),
                  if (_book!.language.isNotEmpty)
                    _MetadataRow(label: 'Idioma', value: _book!.language),
                  if (_book!.isbn.isNotEmpty)
                    _MetadataRow(label: 'ISBN', value: _book!.isbn),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          if (_book?.goodreadsUrl.trim().isNotEmpty == true) ...[
            ClubCard(
              elevated: false,
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.open_in_new_rounded),
                  title: const Text('Ver ficha en Goodreads'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _abrirGoodreads,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Info de que el libro existe en ClubReads ──
          if (!_loading && !_added)
            ClubCard(
              elevated: false,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Este libro está en el catálogo de ClubReads. '
                      'Al añadirlo podrás organizarlo en tu biblioteca y '
                      'gestionar tu estado de lectura.',
                      style: AppTextStyles.caption.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 96, child: Text(label, style: AppTextStyles.caption)),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySecondary.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Sheet de añadir ─────────────────────────────────────────────

class _LibraryPrefs {
  const _LibraryPrefs({
    required this.priority,
    required this.format,
    required this.status,
    this.startDate,
    this.endDate,
    this.rating,
  });
  final String priority;
  final String format;
  final String status;
  final String? startDate;
  final String? endDate;
  final String? rating;
}

class _AddToLibrarySheet extends StatefulWidget {
  const _AddToLibrarySheet({required this.title});
  final String title;

  @override
  State<_AddToLibrarySheet> createState() => _AddToLibrarySheetState();
}

class _AddToLibrarySheetState extends State<_AddToLibrarySheet> {
  String _priority = 'MEDIA';
  String _format = '';
  String _status = 'PENDIENTE';
  String _rating = '';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<DateTime?> _pickDate(DateTime? current) => showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Añadir a mi biblioteca',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Estado
            const Text('Estado'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final opt in const [
                  ('PENDIENTE', 'Pendiente'),
                  ('LEYENDO', 'Leyendo'),
                  ('FINALIZADO', 'Terminado'),
                ])
                  ChoiceChip(
                    label: Text(opt.$2),
                    selected: _status == opt.$1,
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _status == opt.$1
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() {
                      _status = opt.$1;
                      if (_status != 'FINALIZADO') {
                        _rating = '';
                        _endDate = null;
                      }
                      if (_status == 'PENDIENTE') _startDate = null;
                    }),
                  ),
              ],
            ),

            if (_status == 'LEYENDO' || _status == 'FINALIZADO') ...[
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de inicio (opcional)'),
                subtitle: Text(
                  _startDate == null
                      ? 'Sin fecha'
                      : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                ),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final d = await _pickDate(_startDate);
                  if (d != null) setState(() => _startDate = d);
                },
              ),
            ],

            if (_status == 'FINALIZADO') ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de fin (opcional)'),
                subtitle: Text(
                  _endDate == null
                      ? 'Sin fecha'
                      : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                ),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final d = await _pickDate(_endDate);
                  if (d != null) setState(() => _endDate = d);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text('Valoración'),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final v in const ['1', '2', '3', '4', '5'])
                    ChoiceChip(
                      label: Text('$v ★'),
                      selected: _rating == v,
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _rating == v
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setState(() => _rating = v),
                    ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            const Text('Prioridad'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: ['ALTA', 'MEDIA', 'BAJA']
                  .map(
                    (v) => ChoiceChip(
                      label: Text(v[0] + v.substring(1).toLowerCase()),
                      selected: _priority == v,
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _priority == v
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setState(() => _priority = v),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: AppSpacing.md),
            const Text('Formato (opcional)'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children:
                  const {
                        '': 'Sin decidir',
                        'FISICO': 'Físico',
                        'DIGITAL': 'Digital',
                        'AUDIOLIBRO': 'Audiolibro',
                      }.entries
                      .map(
                        (e) => ChoiceChip(
                          label: Text(e.value),
                          selected: _format == e.key,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _format == e.key
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) => setState(() => _format = e.key),
                        ),
                      )
                      .toList(),
            ),

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  _LibraryPrefs(
                    priority: _priority,
                    format: _format,
                    status: _status,
                    startDate: _fmt(_startDate),
                    endDate: _fmt(_endDate),
                    rating: _rating.isEmpty ? null : _rating,
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
