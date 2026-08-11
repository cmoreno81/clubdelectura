import 'package:club_lectura_app/services/library_refresh_notifier.dart';
import 'package:flutter/material.dart';

import '../models/catalog_book.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';

class CatalogBookDetailPage extends StatefulWidget {
  const CatalogBookDetailPage({
    super.key,
    required this.bookId,
    required this.title,
    required this.coverUrl,
    required this.genre,
  });

  final String bookId;
  final String title;
  final String coverUrl;
  final String genre;

  @override
  State<CatalogBookDetailPage> createState() => _CatalogBookDetailPageState();
}

class _CatalogBookDetailPageState extends State<CatalogBookDetailPage> {
  CatalogBook? _book;
  bool _loading = true;
  bool _adding = false;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final books = await ApiService().getCatalogoGeneral(query: widget.title);
      final match = books
          .where(
            (b) =>
                b.id == widget.bookId ||
                b.title.trim().toLowerCase() ==
                    widget.title.trim().toLowerCase(),
          )
          .firstOrNull;
      if (mounted) {
        setState(() {
          _book = match;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToLibrary() async {
    final result = await showModalBottomSheet<_LibraryPrefs>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddToLibrarySheet(title: widget.title),
    );
    if (result == null || !mounted) return;

    setState(() => _adding = true);
    try {
      await ApiService().importarLibroCatalogo(
        book: _book,
        bookId: _book == null ? widget.bookId : null,
        prioridad: result.priority,
        formato: result.format,
        estado: result.status,
        fechaInicio: result.startDate,
        fechaFin: result.endDate,
        valoracion: result.rating,
      );
      if (mounted) {
        LibraryRefreshNotifier.instance.invalidate();

        setState(() {
          _added = true;
          _adding = false;
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
          // ── Portada + info básica ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClubBookCover(
                title: widget.title,
                imageUrl: widget.coverUrl,
                width: 110,
                highResolution: true,
                height: 160,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.title.copyWith(fontSize: 18),
                    ),
                    if (widget.genre.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(widget.genre, style: AppTextStyles.bodySecondary),
                    ],
                    if (_loading) ...[
                      const SizedBox(height: AppSpacing.md),
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ] else if (_book != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _book!.authorLabel,
                        style: AppTextStyles.bodySecondary,
                      ),
                      if (_book!.pages != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${_book!.pages} páginas',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Botón añadir ──
          if (_added)
            ClubCard(
              elevated: false,
              borderColor: AppColors.success.withValues(alpha: .3),
              child: Row(
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

          // ── Info de que el libro existe en ClubReads ──
          if (!_loading)
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
                      'Al añadirlo podrás ver quién más lo está leyendo '
                      'y participar en las lecturas del club.',
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
