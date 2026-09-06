import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../utils/idioma_utils.dart';
import '../common/club_book_cover.dart';

class AddBookPreferences {
  const AddBookPreferences({
    required this.priority,
    required this.format,
    this.idioma = '',
    this.status = 'PENDIENTE',
  });

  final String priority;
  final String format;

  /// Código de idioma elegido a mano ('' = sin especificar, se deja lo que
  /// haya detectado el catálogo automáticamente).
  final String idioma;

  /// Estado de lectura inicial elegido al añadir: 'PENDIENTE' (por defecto),
  /// 'LEYENDO' o 'FINALIZADO'. Solo se pregunta cuando [showAddBookSheet] se
  /// llama con `showStatusPicker: true` (biblioteca); en la wishlist no aplica.
  final String status;
}

Future<AddBookPreferences?> showAddBookSheet(
  BuildContext context, {
  required String title,
  String author = '',
  String coverUrl = '',
  bool showStatusPicker = false,
}) => showModalBottomSheet<AddBookPreferences>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => AddBookSheet(
    title: title,
    author: author,
    coverUrl: coverUrl,
    showStatusPicker: showStatusPicker,
  ),
);

class AddBookSheet extends StatefulWidget {
  const AddBookSheet({
    super.key,
    required this.title,
    this.author = '',
    this.coverUrl = '',
    this.showStatusPicker = false,
  });

  final String title;
  final String author;
  final String coverUrl;
  final bool showStatusPicker;

  @override
  State<AddBookSheet> createState() => _AddBookSheetState();
}

// Idiomas más frecuentes para no saturar la hoja rápida con las ~20 opciones
// que sí admite la corrección desde la tarjeta del libro.
const _idiomasRapidos = ['es', 'en', 'fr', 'de', 'it', 'pt'];

class _AddBookSheetState extends State<AddBookSheet> {
  String _status = 'PENDIENTE';
  String _priority = 'MEDIA';
  String _format = '';
  String _idioma = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              // ── Contenido con scroll ──────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Añadir a mi biblioteca',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.coverUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.md,
                              ),
                              child: ClubBookCover(
                                title: widget.title,
                                imageUrl: widget.coverUrl,
                                width: 58,
                                height: 86,
                                showShadow: false,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: colors.onSurface,
                                      ),
                                ),
                                if (widget.author.trim().isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    widget.author.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.showStatusPicker) ...[
                        _sectionDivider(context),
                        _optionTitle(context, 'Estado', Icons.timelapse_rounded),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children:
                              const {
                                'PENDIENTE': 'Quiero leerlo',
                                'LEYENDO': 'Lo estoy leyendo',
                                'FINALIZADO': 'Ya lo he leído',
                              }.entries.map((entry) {
                                return _choice(
                                  context,
                                  key: ValueKey(
                                    'add-book-status-${entry.key}',
                                  ),
                                  label: entry.value,
                                  selected: _status == entry.key,
                                  onSelected: () =>
                                      setState(() => _status = entry.key),
                                );
                              }).toList(),
                        ),
                      ],
                      if (!widget.showStatusPicker || _status == 'PENDIENTE') ...[
                        _sectionDivider(context),
                        _optionTitle(context, 'Prioridad', Icons.flag_outlined),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children:
                              const {
                                'BAJA': 'Baja',
                                'MEDIA': 'Media',
                                'ALTA': 'Alta',
                              }.entries.map((entry) {
                                return _choice(
                                  context,
                                  key: ValueKey(
                                    'add-book-priority-${entry.key}',
                                  ),
                                  label: entry.value,
                                  selected: _priority == entry.key,
                                  onSelected: () =>
                                      setState(() => _priority = entry.key),
                                );
                              }).toList(),
                        ),
                      ],
                      _sectionDivider(context),
                      _optionTitle(
                        context,
                        'Formato',
                        Icons.auto_stories_outlined,
                      ),
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
                            }.entries.map((entry) {
                              return _choice(
                                context,
                                key: ValueKey('add-book-format-${entry.key}'),
                                label: entry.value,
                                selected: _format == entry.key,
                                onSelected: () =>
                                    setState(() => _format = entry.key),
                              );
                            }).toList(),
                      ),
                      _sectionDivider(context),
                      _optionTitle(context, 'Idioma', Icons.language_rounded),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _choice(
                            context,
                            key: const ValueKey('add-book-idioma-'),
                            label: 'Sin especificar',
                            selected: _idioma.isEmpty,
                            onSelected: () => setState(() => _idioma = ''),
                          ),
                          for (final codigo in _idiomasRapidos)
                            _choice(
                              context,
                              key: ValueKey('add-book-idioma-$codigo'),
                              label:
                                  '${banderaIdioma(codigo)} ${nombreIdioma(codigo)}',
                              selected: _idioma == codigo,
                              onSelected: () =>
                                  setState(() => _idioma = codigo),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // ── Pie fijo: siempre visible, sin necesidad de hacer scroll ──
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                    top: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.sm + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('confirm-add-book'),
                          onPressed: () => Navigator.pop(
                            context,
                            AddBookPreferences(
                              priority: _priority,
                              format: _format,
                              idioma: _idioma,
                              status: widget.showStatusPicker
                                  ? _status
                                  : 'PENDIENTE',
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            _status == 'FINALIZADO' ? 'Siguiente' : 'Añadir',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionDivider(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    ),
  );

  Widget _optionTitle(BuildContext context, String label, IconData icon) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _choice(
    BuildContext context, {
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final colors = Theme.of(context).colorScheme;
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: selected,
      selectedColor: colors.primary,
      backgroundColor: colors.surfaceContainerHighest,
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
      ),
      checkmarkColor: colors.onPrimary,
      labelStyle: TextStyle(
        color: selected ? colors.onPrimary : colors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
