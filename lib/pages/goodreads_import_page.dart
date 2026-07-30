import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/goodreads_import.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/goodreads_csv_parser.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_section_title.dart';

class GoodreadsImportPage extends StatefulWidget {
  const GoodreadsImportPage({super.key});

  @override
  State<GoodreadsImportPage> createState() => _GoodreadsImportPageState();
}

class _GoodreadsImportPageState extends State<GoodreadsImportPage> {
  final _api = ApiService();
  final _parser = const GoodreadsCsvParser();

  List<GoodreadsImportRow> _rows = const [];
  GoodreadsImportPreview? _preview;
  GoodreadsImportSummary? _result;
  String _fileName = '';
  String _error = '';
  bool _loading = false;

  Future<void> _selectFile() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
      _preview = null;
      _result = null;
    });
    try {
      const typeGroup = XTypeGroup(
        label: 'Archivos CSV',
        uniformTypeIdentifiers: ['public.comma-separated-values-text'],
      );
      final file = await openFile(acceptedTypeGroups: const [typeGroup]);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _fileName = file.name);

      final rows = _parser.parse(bytes);
      if (rows.isEmpty) {
        throw const FormatException('El archivo no contiene ningún libro.');
      }
      final preview = await _api.previsualizarImportacionGoodreads(rows);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _preview = preview;
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
    if (_loading || preview == null || preview.summary.imported == 0) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final result = await _api.confirmarImportacionGoodreads(_rows);
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

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Importar desde Goodreads')),
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
          _ProtectionCard(fileName: _fileName),
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
            const SizedBox(height: AppSpacing.lg),
            const ClubSectionTitle(
              title: 'Revisión previa',
              subtitle: 'Nada se guardará hasta que confirmes',
              icon: Icons.fact_check_outlined,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...preview.books
                .take(60)
                .map(
                  (book) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _PreviewBookTile(book: book),
                  ),
                ),
            if (preview.books.length > 60)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  'Y ${preview.books.length - 60} libros más.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
          ] else
            _Instructions(onSelect: _selectFile),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.md),
        child: result != null
            ? FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Volver a mi perfil'),
              )
            : preview != null
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : _selectFile,
                      child: const Text('Elegir otro'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loading || preview.summary.imported == 0
                          ? null
                          : _confirm,
                      icon: const Icon(Icons.download_done_rounded),
                      label: Text('Importar ${preview.summary.imported}'),
                    ),
                  ),
                ],
              )
            : FilledButton.icon(
                onPressed: _loading ? null : _selectFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Seleccionar CSV de Goodreads'),
              ),
      ),
    );
  }
}

class _ProtectionCard extends StatelessWidget {
  const _ProtectionCard({required this.fileName});

  final String fileName;

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
  const _Instructions({required this.onSelect});

  final VoidCallback onSelect;

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
          const _Step(
            number: '1',
            text: 'Exporta tu biblioteca desde Goodreads.',
          ),
          const _Step(
            number: '2',
            text: 'Selecciona aquí el archivo CSV descargado.',
          ),
          const _Step(
            number: '3',
            text: 'Revisa qué libros son nuevos y cuáles ya están protegidos.',
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
              label: '${summary.skipped} omitidos',
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

class _PreviewBookTile extends StatelessWidget {
  const _PreviewBookTile({required this.book});

  final GoodreadsImportPreviewBook book;

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
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
                  book.message,
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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
            'Buscaremos automáticamente las portadas que falten. '
            'Pueden aparecer poco a poco en tu biblioteca.',
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
        ],
      ),
    );
  }
}
