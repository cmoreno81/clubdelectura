import 'package:flutter/material.dart';

import '../../models/general_dashboard.dart';
import '../../services/api_service.dart';
import '../../services/library_refresh_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'club_book_cover.dart';

/// Muestra un bottom sheet para editar las fechas de lectura directamente
/// desde el calendario mensual.
///
/// - Lectura en curso (library:xxx) → solo fecha de inicio.
/// - Lectura terminada (completion:xxx) → inicio y fin.
Future<bool> showCalendarEditFechasSheet(
  BuildContext context, {
  required MonthlyReadingSpan reading,
  required String usuario,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CalendarEditFechasSheet(reading: reading, usuario: usuario),
  );
  return result == true;
}

// ─────────────────────────────────────────────────────────────────────────────

class _CalendarEditFechasSheet extends StatefulWidget {
  final MonthlyReadingSpan reading;
  final String usuario;

  const _CalendarEditFechasSheet({
    required this.reading,
    required this.usuario,
  });

  @override
  State<_CalendarEditFechasSheet> createState() =>
      _CalendarEditFechasSheetState();
}

class _CalendarEditFechasSheetState extends State<_CalendarEditFechasSheet> {
  late DateTime? _fechaInicio;
  late DateTime? _fechaFin;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _fechaInicio = DateTime.tryParse(widget.reading.startedAt)?.toLocal();
    _fechaFin = widget.reading.isCompleted
        ? DateTime.tryParse(widget.reading.finishedAt)?.toLocal()
        : null;

    // Nunca fechas futuras
    final hoy = DateTime.now();
    if (_fechaInicio != null && _fechaInicio!.isAfter(hoy)) {
      _fechaInicio = hoy;
    }
    if (_fechaFin != null && _fechaFin!.isAfter(hoy)) {
      _fechaFin = hoy;
    }
  }

  String _formatoVisual(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return '$d/$m/${fecha.year}';
  }

  String _formatoApi(DateTime fecha) {
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$m-$d';
  }

  Future<void> _elegirInicio() async {
    final hoy = DateTime.now();
    final inicial = _fechaInicio ?? hoy;
    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial.isAfter(hoy) ? hoy : inicial,
      firstDate: DateTime(1950),
      lastDate: hoy,
      helpText: 'Fecha en que empezaste a leer',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _fechaInicio = elegida;
      if (_fechaFin != null && _fechaFin!.isBefore(elegida)) {
        _fechaFin = elegida;
      }
    });
  }

  Future<void> _elegirFin() async {
    final hoy = DateTime.now();
    final primeraPermitida = _fechaInicio ?? DateTime(1950);
    final inicial = _fechaFin ?? hoy;
    final elegida = await showDatePicker(
      context: context,
      initialDate:
          inicial.isBefore(primeraPermitida) ? primeraPermitida : inicial,
      firstDate: primeraPermitida,
      lastDate: hoy,
      helpText: 'Fecha en que terminaste el libro',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
    );
    if (elegida == null || !mounted) return;
    setState(() => _fechaFin = elegida);
  }

  Future<void> _guardar() async {
    final inicio = _fechaInicio;
    if (inicio == null) return;

    setState(() => _guardando = true);

    bool ok;

    try {
      if (widget.reading.isCompleted) {
        // Lectura terminada: actualiza startedAt + finishedAt en ReadingCompletion
        final resultado = await ApiService().actualizarFechasLectura(
          usuario: widget.usuario,
          libraryId: widget.reading.libraryId,
          completionId: widget.reading.completionId,
          fechaInicio: _formatoApi(inicio),
          fechaFin: _formatoApi(_fechaFin ?? inicio),
        );
        ok = resultado['ok'] == true;
      } else {
        // Lectura en curso: solo actualiza startedAt en Library
        ok = await ApiService().editarFechaInicioLectura(
          usuario: widget.usuario,
          libro: widget.reading.title,
          fechaInicio: inicio,
        );
      }
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      LibraryRefreshNotifier.instance.invalidate();
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se han podido actualizar las fechas.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.reading.isCompleted;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: 0,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ────────────────────────────────────────────────────────
          Row(
            children: [
              ClubBookCover(
                title: widget.reading.title,
                imageUrl: widget.reading.coverUrl,
                width: 48,
                showShadow: false,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reading.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.section.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted
                          ? 'Editar rango de lectura'
                          : 'Editar fecha de inicio',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // ── Fecha de inicio ─────────────────────────────────────────────────
          _DateTile(
            icon: Icons.play_circle_outline_rounded,
            label: 'Fecha de inicio',
            value: _formatoVisual(_fechaInicio),
            onTap: _elegirInicio,
          ),

          // ── Fecha de fin (solo para completions) ────────────────────────────
          if (isCompleted) ...[
            const SizedBox(height: AppSpacing.xs),
            _DateTile(
              icon: Icons.flag_outlined,
              label: 'Fecha de fin',
              value: _formatoVisual(_fechaFin),
              onTap: _elegirFin,
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Botón guardar ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_guardando ? 'Guardando…' : 'Guardar fechas'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(label, style: AppTextStyles.body),
      subtitle: Text(
        value,
        style: AppTextStyles.bodySecondary.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(
        Icons.calendar_month_outlined,
        color: AppColors.textMuted,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
