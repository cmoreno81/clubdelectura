import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../common/club_book_cover.dart';

class AddBookPreferences {
  const AddBookPreferences({
    required this.priority,
    required this.format,
    this.status = 'PENDIENTE',
  });

  final String priority;
  final String format;

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

class _AddBookSheetState extends State<AddBookSheet> {
  String _status = 'PENDIENTE';
  String _priority = 'MEDIA';
  String _format = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
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
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Text(
                'Añadir a mi biblioteca',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      padding: const EdgeInsets.only(right: AppSpacing.md),
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
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.showStatusPicker) ...[
                const SizedBox(height: AppSpacing.lg),
                _optionTitle(context, 'Estado'),
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
                          key: ValueKey('add-book-status-${entry.key}'),
                          label: entry.value,
                          selected: _status == entry.key,
                          onSelected: () => setState(() => _status = entry.key),
                        );
                      }).toList(),
                ),
              ],
              if (!widget.showStatusPicker || _status == 'PENDIENTE') ...[
                const SizedBox(height: AppSpacing.lg),
                _optionTitle(context, 'Prioridad'),
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
                          key: ValueKey('add-book-priority-${entry.key}'),
                          label: entry.value,
                          selected: _priority == entry.key,
                          onSelected: () =>
                              setState(() => _priority = entry.key),
                        );
                      }).toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _optionTitle(context, 'Formato'),
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
                        onSelected: () => setState(() => _format = entry.key),
                      );
                    }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTitle(BuildContext context, String label) => Text(
    label,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w800,
    ),
  );

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
