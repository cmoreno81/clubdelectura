import 'package:flutter/material.dart';

import '../../models/catalog_book.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class SeriesVolumeDetailsDialog extends StatefulWidget {
  const SeriesVolumeDetailsDialog({
    super.key,
    required this.book,
    required this.preservePersonalData,
    required this.initialOrder,
    required this.initialStatus,
    required this.initialFormat,
    required this.initialRating,
    required this.initialStartDate,
    required this.initialEndDate,
  });

  final CatalogBook book;
  final bool preservePersonalData;
  final String initialOrder;
  final String initialStatus;
  final String initialFormat;
  final String initialRating;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  @override
  State<SeriesVolumeDetailsDialog> createState() =>
      _SeriesVolumeDetailsDialogState();
}

class _SeriesVolumeDetailsDialogState extends State<SeriesVolumeDetailsDialog> {
  late final TextEditingController _orderController;
  late String _status;
  late String _format;
  late String _rating;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _orderController = TextEditingController(text: widget.initialOrder);
    _status = widget.initialStatus;
    _format = widget.initialFormat;
    _rating = widget.initialRating;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  void dispose() {
    _orderController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? current) => showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  void _submit() {
    final cleanOrder = _orderController.text.trim();
    if (cleanOrder.isEmpty) {
      setState(() => _error = 'Indica el número del volumen.');
      return;
    }
    // Valoración obligatoria solo si marca FINALIZADO manualmente (no si ya lo tenía)
    if (_status == 'FINALIZADO' &&
        _rating.isEmpty &&
        !widget.preservePersonalData) {
      setState(() => _error = 'Selecciona una valoración.');
      return;
    }
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      setState(
        () => _error = 'La fecha de fin no puede ser anterior al inicio.',
      );
      return;
    }
    Navigator.pop(
      context,
      SeriesVolumeSelection(
        order: cleanOrder,
        status: _status,
        format: _format,
        rating: _rating,
        startDate: _formatDate(_startDate),
        endDate: _formatDate(_endDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preservePersonalData = widget.preservePersonalData;

    return AlertDialog(
      title: const Text('Añadir a la saga'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Banner contextual ──
            if (preservePersonalData)
              _InfoBanner(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                text:
                    'Ya tienes este libro terminado con su valoración y fechas. '
                    'Solo necesitamos el número de volumen para vincularlo.',
              )
            else if (widget.book.inMyLibrary)
              _InfoBanner(
                icon: Icons.info_outline_rounded,
                color: AppColors.info,
                text:
                    'Este libro ya está en tu biblioteca. '
                    'Se vinculará a la saga respetando tu estado actual.',
              )
            else
              Text(
                'Vincula este libro a la saga y añade tus datos de lectura.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),

            const SizedBox(height: AppSpacing.md),

            // ── Número de volumen — siempre visible ──
            TextFormField(
              controller: _orderController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Número en la saga',
                hintText: '1, 2, 2.5…',
              ),
            ),

            // ── Estado — solo si NO está ya finalizado ──
            if (!preservePersonalData) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Estado (opcional)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final option in const [
                    ('', 'Sin indicar'),
                    ('PENDIENTE', 'Pendiente'),
                    ('LEYENDO', 'Leyendo'),
                    ('FINALIZADO', 'Terminado'),
                  ])
                    _OptionChip(
                      label: option.$2,
                      selected: _status == option.$1,
                      onSelected: () => setState(() {
                        _status = option.$1;
                        _error = null;
                      }),
                    ),
                ],
              ),
            ],

            // ── Formato — solo si no está ya en biblioteca ──
            if (!widget.book.inMyLibrary) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Formato (opcional)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final option in const [
                    ('', 'Sin indicar'),
                    ('FISICO', 'Físico'),
                    ('DIGITAL', 'Digital'),
                    ('AUDIOLIBRO', 'Audio'),
                  ])
                    _OptionChip(
                      label: option.$2,
                      selected: _format == option.$1,
                      onSelected: () => setState(() => _format = option.$1),
                    ),
                ],
              ),
            ],

            // ── Fecha inicio — si no está finalizado y hay estado activo ──
            if (!preservePersonalData &&
                _status != 'PENDIENTE' &&
                _status != '') ...[
              const SizedBox(height: AppSpacing.md),
              _DateSelector(
                label: 'Fecha de inicio (opcional)',
                value: _startDate,
                onTap: () async {
                  final selected = await _pickDate(_startDate);
                  if (selected != null) {
                    setState(() => _startDate = selected);
                  }
                },
              ),
            ],

            // ── Fecha fin + valoración — solo si marca FINALIZADO manualmente ──
            if (!preservePersonalData && _status == 'FINALIZADO') ...[
              const SizedBox(height: AppSpacing.md),
              _DateSelector(
                label: 'Fecha de fin (opcional)',
                value: _endDate,
                onTap: () async {
                  final selected = await _pickDate(_endDate);
                  if (selected != null) {
                    setState(() => _endDate = selected);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Valoración',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final value in const ['1', '2', '3', '4', '5'])
                    _OptionChip(
                      label: '$value ★',
                      selected: _rating == value,
                      onSelected: () => setState(() {
                        _rating = value;
                        _error = null;
                      }),
                    ),
                ],
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Añadir a la saga')),
      ],
    );
  }
}

// ─── Modelos de retorno ──────────────────────────────────────────

class SeriesVolumeSelection {
  const SeriesVolumeSelection({
    required this.order,
    required this.status,
    required this.format,
    required this.rating,
    required this.startDate,
    required this.endDate,
  });

  final String order;
  final String status;
  final String format;
  final String rating;
  final String startDate;
  final String endDate;
}

// ─── Widgets internos ────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: .85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        date == null ? 'Sin fecha' : '${date.day}/${date.month}/${date.year}',
      ),
      trailing: const Icon(Icons.calendar_month_rounded),
      onTap: onTap,
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceSoft,
      checkmarkColor: Colors.white,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
