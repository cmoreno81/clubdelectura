import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/goodreads_import.dart';
import '../services/bookmory_xlsx_parser.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/goodreads_csv_parser.dart';
import '../services/library_refresh_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_section_title.dart';
import '../widgets/common/optimized_network_image.dart';

enum ReadingImportSource { goodreads, bookmory }

class GoodreadsImportPage extends StatefulWidget {
  const GoodreadsImportPage({
    super.key,
    this.source = ReadingImportSource.goodreads,
  });

  final ReadingImportSource source;

  @override
  State<GoodreadsImportPage> createState() => _GoodreadsImportPageState();
}

class _GoodreadsImportPageState extends State<GoodreadsImportPage> {
  final _api = ApiService();

  List<GoodreadsImportRow> _rows = const [];
  GoodreadsImportPreview? _preview;
  GoodreadsImportSummary? _result;
  String _fileName = '';
  String _error = '';
  bool _loading = false;
  bool _showAll = false;
  Set<int> _selectedRows = <int>{};
  Map<int, String> _resolutions = <int, String>{};

  bool get _isBookmory => widget.source == ReadingImportSource.bookmory;

  String get _sourceName => _isBookmory ? 'Bookmory' : 'Goodreads';

  Future<void> _selectFile() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
      _preview = null;
      _result = null;
      _selectedRows = <int>{};
      _resolutions = <int, String>{};
      _showAll = false;
    });
    try {
      final typeGroup = XTypeGroup(
        label: _isBookmory ? 'Archivos Excel' : 'Archivos CSV',
        extensions: [_isBookmory ? 'xlsx' : 'csv'],
        uniformTypeIdentifiers: [
          _isBookmory
              ? 'org.openxmlformats.spreadsheetml.sheet'
              : 'public.comma-separated-values-text',
        ],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _fileName = file.name);

      final rows = _isBookmory
          ? const BookmoryXlsxParser().parse(bytes)
          : const GoodreadsCsvParser().parse(bytes);
      if (rows.isEmpty) {
        throw const FormatException('El archivo no contiene ningún libro.');
      }
      final preview = await _api.previsualizarImportacionGoodreads(
        rows,
        source: _isBookmory ? 'BOOKMORY' : 'GOODREADS',
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _preview = preview;
        _selectedRows = preview.books
            .where((book) => book.canImport)
            .map((book) => book.index)
            .toSet();
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => _error =
              'El selector de archivos todavía no se ha cargado. '
              'Detén la aplicación y vuelve a iniciarla por completo.',
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _error =
              error.message ??
              'iOS no ha podido abrir el selector de archivos.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se ha podido revisar este archivo.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final preview = _preview;
    if (_loading || preview == null || _selectedRows.isEmpty) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final selectedEntries = _rows
          .asMap()
          .entries
          .where((entry) => _selectedRows.contains(entry.key))
          .toList(growable: false);
      final selectedRows = selectedEntries
          .map((entry) => entry.value)
          .toList(growable: false);
      final resolutions = <int, String>{};
      for (var position = 0; position < selectedEntries.length; position++) {
        final bookId = _resolutions[selectedEntries[position].key];
        if (bookId != null) resolutions[position] = bookId;
      }
      final result = await _api.confirmarImportacionGoodreads(
        selectedRows,
        resolutions: resolutions,
        source: _isBookmory ? 'BOOKMORY' : 'GOODREADS',
      );
      if (!mounted) return;
      setState(() => _result = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se ha podido terminar la importación.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolveBook(GoodreadsImportPreviewBook book) async {
    final candidate = await showModalBottomSheet<GoodreadsImportCandidate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CandidatePicker(book: book),
    );
    if (candidate == null || !mounted) return;
    setState(() {
      _resolutions[book.index] = candidate.bookId;
      _selectedRows.add(book.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text('Importar desde $_sourceName')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          110,
        ),
        children: [
          const ClubSectionTitle(
            title: 'Trae tu historia lectora',
            subtitle: 'Sin perder nada de lo que ya tienes en ClubReads',
            icon: Icons.import_export_rounded,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          _ProtectionCard(fileName: _fileName, sourceName: _sourceName),
          const SizedBox(height: AppSpacing.md),
          if (_error.isNotEmpty) ...[
            ClubCard(
              elevated: false,
              backgroundColor: AppColors.danger.withValues(alpha: .08),
              borderColor: AppColors.danger.withValues(alpha: .35),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(_error)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (result != null)
            _ImportFinished(summary: result)
          else if (preview != null) ...[
            _PreviewSummary(summary: preview.summary),
            const SizedBox(height: AppSpacing.sm),
            _ImportCategoryGuide(summary: preview.summary),
            const SizedBox(height: AppSpacing.lg),
            ClubSectionTitle(
              title: 'Revisión previa',
              subtitle:
                  '${_selectedRows.length} seleccionados · Nada se guardará hasta que confirmes',
              icon: Icons.fact_check_outlined,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SelectionControls(
              selected: _selectedRows.length,
              total:
                  preview.books.where((book) => book.canImport).length +
                  _resolutions.length,
              onSelectAll: () {
                setState(() {
                  _selectedRows = preview.books
                      .where(
                        (book) =>
                            book.canImport ||
                            _resolutions.containsKey(book.index),
                      )
                      .map((book) => book.index)
                      .toSet();
                });
              },
              onClear: () => setState(_selectedRows.clear),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...preview.books
                .take(_showAll ? preview.books.length : 60)
                .map(
                  (book) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _PreviewBookTile(
                      book: book,
                      selected: _selectedRows.contains(book.index),
                      selectedCandidateId: _resolutions[book.index],
                      onResolve:
                          book.action == 'REVISAR' && book.candidates.isNotEmpty
                          ? () => _resolveBook(book)
                          : null,
                      onChanged:
                          book.canImport || _resolutions.containsKey(book.index)
                          ? (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedRows.add(book.index);
                                } else {
                                  _selectedRows.remove(book.index);
                                }
                              });
                            }
                          : null,
                    ),
                  ),
                ),
            if (preview.books.length > 60)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  icon: Icon(
                    _showAll
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(
                    _showAll
                        ? 'Mostrar menos'
                        : 'Revisar los ${preview.books.length} libros',
                  ),
                ),
              ),
          ] else
            _Instructions(
              onSelect: _selectFile,
              sourceName: _sourceName,
              isBookmory: _isBookmory,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.md),
        child: result != null
            ? FilledButton(
                onPressed: () {
                  LibraryRefreshNotifier.instance.invalidate();
                  Navigator.pop(context, true);
                },
                child: const Text('Volver a mi perfil'),
              )
            : preview != null
            ? Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _selectFile,
                      child: const Text('Elegir otro'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: _loading || _selectedRows.isEmpty
                          ? null
                          : _confirm,
                      icon: const Icon(Icons.download_done_rounded),
                      label: Text(
                        'Importar ${_selectedRows.length} seleccionados',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              )
            : FilledButton.icon(
                onPressed: _loading ? null : _selectFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(
                  _isBookmory
                      ? 'Seleccionar Excel de Bookmory'
                      : 'Seleccionar CSV de Goodreads',
                ),
              ),
      ),
    );
  }
}

class _ProtectionCard extends StatelessWidget {
  const _ProtectionCard({required this.fileName, required this.sourceName});

  final String fileName;
  final String sourceName;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: .96),
          AppColors.primaryDark,
        ],
      ),
      borderColor: AppColors.primaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Tus datos de ClubReads tienen prioridad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Nunca sustituiremos estados, fechas, valoraciones, reseñas, '
            'prioridades, formatos, sagas ni historial que ya hayas guardado.',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'De $sourceName solo importaremos libros finalizados y valorados. '
            'Los pendientes '
            'y los que estás leyendo se quedarán fuera.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (fileName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .78),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions({
    required this.onSelect,
    required this.sourceName,
    required this.isBookmory,
  });

  final VoidCallback onSelect;
  final String sourceName;
  final bool isBookmory;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cómo hacerlo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          _Step(number: '1', text: 'Exporta tu biblioteca desde $sourceName.'),
          _Step(
            number: '2',
            text:
                'Selecciona aquí el archivo ${isBookmory ? 'Excel' : 'CSV'} descargado.',
          ),
          const _Step(
            number: '3',
            text:
                'Revisa tus libros finalizados y valorados; los pendientes no aparecerán.',
          ),
          const _Step(number: '4', text: 'Confirma la importación.'),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: onSelect,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Ya tengo el archivo'),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({required this.summary});

  final GoodreadsImportSummary summary;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _SummaryChip(
            icon: Icons.add_circle_outline_rounded,
            label: '${summary.newBooks} nuevos',
            color: AppColors.success,
          ),
          _SummaryChip(
            icon: Icons.library_add_outlined,
            label: '${summary.toAdd} para añadir',
            color: AppColors.info,
          ),
          _SummaryChip(
            icon: Icons.shield_outlined,
            label: '${summary.protected} protegidos',
            color: AppColors.primary,
          ),
          if (summary.toReview > 0)
            _SummaryChip(
              icon: Icons.help_outline_rounded,
              label: '${summary.toReview} para revisar',
              color: AppColors.warning,
            ),
          if (summary.skipped > 0)
            _SummaryChip(
              icon: Icons.remove_circle_outline_rounded,
              label: '${summary.skipped} pendientes o sin valorar',
              color: AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ImportCategoryGuide extends StatelessWidget {
  const _ImportCategoryGuide({required this.summary});

  final GoodreadsImportSummary summary;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.sm),
      backgroundColor: AppColors.surfaceSoft.withValues(alpha: .62),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Text(
              '¿Qué ocurrirá con cada grupo?',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (summary.newBooks > 0)
            const _CategoryExplanation(
              icon: Icons.add_circle_outline_rounded,
              color: AppColors.success,
              title: 'Nuevos',
              text: 'Se crearán y se añadirán a tu biblioteca.',
            ),
          if (summary.toAdd > 0)
            const _CategoryExplanation(
              icon: Icons.library_add_outlined,
              color: AppColors.info,
              title: 'Para añadir',
              text: 'Ya existen; añadiremos la ficha correcta a tu biblioteca.',
            ),
          if (summary.protected > 0)
            const _CategoryExplanation(
              icon: Icons.shield_outlined,
              color: AppColors.primary,
              title: 'Protegidos',
              text: 'Ya los tienes. No cambiaremos ninguno de tus datos.',
            ),
          if (summary.toReview > 0)
            const _CategoryExplanation(
              icon: Icons.help_outline_rounded,
              color: AppColors.warning,
              title: 'Para revisar',
              text:
                  'Hay varias coincidencias. No se importarán hasta elegir la correcta.',
            ),
          if (summary.skipped > 0)
            const _CategoryExplanation(
              icon: Icons.remove_circle_outline_rounded,
              color: AppColors.textMuted,
              title: 'Omitidos',
              text:
                  'Pendientes, sin valorar o filas repetidas; se quedarán fuera.',
            ),
        ],
      ),
    );
  }
}

class _CategoryExplanation extends StatelessWidget {
  const _CategoryExplanation({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: text,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionControls extends StatelessWidget {
  const _SelectionControls({
    required this.selected,
    required this.total,
    required this.onSelectAll,
    required this.onClear,
  });

  final int selected;
  final int total;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      backgroundColor: AppColors.primaryLight.withValues(alpha: .42),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$selected de $total para importar',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: selected == total ? null : onSelectAll,
            child: const Text('Todos'),
          ),
          TextButton(
            onPressed: selected == 0 ? null : onClear,
            child: const Text('Ninguno'),
          ),
        ],
      ),
    );
  }
}

class _PreviewBookTile extends StatelessWidget {
  const _PreviewBookTile({
    required this.book,
    required this.selected,
    required this.onChanged,
    required this.selectedCandidateId,
    required this.onResolve,
  });

  final GoodreadsImportPreviewBook book;
  final bool selected;
  final ValueChanged<bool>? onChanged;
  final String? selectedCandidateId;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    GoodreadsImportCandidate? selectedCandidate;
    for (final candidate in book.candidates) {
      if (candidate.bookId == selectedCandidateId) {
        selectedCandidate = candidate;
        break;
      }
    }
    final (icon, color) = switch (book.action) {
      'NUEVO' => (Icons.add_circle_outline_rounded, AppColors.success),
      'ANADIR' => (Icons.library_add_outlined, AppColors.info),
      'PROTEGIDO' => (Icons.shield_outlined, AppColors.primary),
      'REVISAR' => (Icons.help_outline_rounded, AppColors.warning),
      _ => (Icons.remove_circle_outline_rounded, AppColors.textMuted),
    };
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.sm),
      backgroundColor: onChanged != null && !selected
          ? AppColors.surfaceSoft.withValues(alpha: .62)
          : null,
      onTap: onChanged == null ? null : () => onChanged!(!selected),
      child: Row(
        children: [
          if (onChanged != null)
            Checkbox(
              value: selected,
              onChanged: (value) => onChanged!(value ?? false),
              activeColor: AppColors.primary,
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color),
            ),
          const SizedBox(width: AppSpacing.sm),
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
                if (book.author.isNotEmpty)
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                Text(
                  onChanged != null && !selected
                      ? 'No se importará'
                      : selectedCandidate != null
                      ? 'Usaremos: ${selectedCandidate.title}'
                      : book.message,
                  style: TextStyle(
                    color: onChanged != null && !selected
                        ? AppColors.textMuted
                        : color,
                    fontSize: 12,
                  ),
                ),
                if (onResolve != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: onResolve,
                    icon: Icon(
                      selectedCandidateId == null
                          ? Icons.manage_search_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                    label: Text(
                      selectedCandidateId == null
                          ? 'Elegir coincidencia'
                          : 'Cambiar coincidencia',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidatePicker extends StatelessWidget {
  const _CandidatePicker({required this.book});

  final GoodreadsImportPreviewBook book;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: .78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Elige la ficha correcta',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Archivo: ${book.title} · ${book.author}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: book.candidates.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final candidate = book.candidates[index];
                    return ClubCard(
                      elevated: false,
                      onTap: () => Navigator.pop(context, candidate),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 54,
                            height: 78,
                            child: OptimizedNetworkImage(
                              url: candidate.coverUrl,
                              width: 54,
                              height: 78,
                              fallback: const Icon(Icons.auto_stories_outlined),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  candidate.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (candidate.author.isNotEmpty)
                                  Text(
                                    candidate.author,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                if (candidate.isbn.isNotEmpty)
                                  Text(
                                    'ISBN ${candidate.isbn}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_outline_rounded),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportFinished extends StatelessWidget {
  const _ImportFinished({required this.summary});

  final GoodreadsImportSummary summary;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      gradient: LinearGradient(
        colors: [AppColors.success.withValues(alpha: .22), AppColors.surface],
      ),
      borderColor: AppColors.success.withValues(alpha: .45),
      child: Column(
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            size: 54,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Tu biblioteca ya está al día',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${summary.imported} libros añadidos · '
            '${summary.protected} libros de ClubReads protegidos',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Los pendientes de Goodreads no se han importado. Buscaremos '
            'automáticamente las portadas que falten en el historial añadido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (summary.toReview > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${summary.toReview} coincidencias dudosas no se importaron.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.warning),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: .25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🖊️', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Si algún libro viene sin portada o sin género, puedes completarlo tú misma: '
                    'abre el libro en tu biblioteca y pulsa "Editar".',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
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
