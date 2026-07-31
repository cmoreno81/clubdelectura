import 'package:flutter/material.dart';

import '../../models/libro.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/reading_status_copy.dart';
import '../common/club_avatar.dart';
import '../common/club_card.dart';
import '../common/club_chip.dart';
import 'libro_section.dart';
import 'pausar_lectura_dialog.dart';

/// Selector de opción estilo "pill" — siempre muestra label + valor,
/// nunca tapa el título con el valor seleccionado.
class _OptionSelector<T> extends StatelessWidget {
  const _OptionSelector({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color color;
  final T value;
  final List<({T value, String label, String? emoji})> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label siempre visible arriba
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        // Chips horizontales
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: options.map((opt) {
            final selected = opt.value == value;
            return GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? color : color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected ? color : color.withValues(alpha: .28),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: .25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (opt.emoji != null) ...[
                      Text(opt.emoji!, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : color,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class LibroInteresadasSection extends StatelessWidget {
  final List<Libro> registros;
  final Set<String> usuariosConFinalizacion;
  final String? usuarioActual;
  final Future<void> Function(
    Libro libro,
    String nuevoEstado, {
    String? valoracion,
    String? reflexion,
    String? motivoPausa,
    String? fechaInicio,
    String? fechaFin,
    String? formato,
  })
  onCambiarEstado;
  final Future<void> Function(Libro libro) onQuitarPendientes;
  final Future<void> Function(Libro libro, String prioridad, String formato)
  onActualizarPreferencias;
  final Future<Map<String, String>?> Function(Libro libro) onPedirValoracion;

  const LibroInteresadasSection({
    super.key,
    required this.registros,
    required this.usuariosConFinalizacion,
    required this.usuarioActual,
    required this.onCambiarEstado,
    required this.onQuitarPendientes,
    required this.onActualizarPreferencias,
    required this.onPedirValoracion,
  });

  @override
  Widget build(BuildContext context) {
    if (registros.isEmpty) {
      return const SizedBox.shrink();
    }

    return LibroSection(
      icon: Icons.people_outline_rounded,
      color: AppColors.info,
      title: 'Interesadas',
      subtitle:
          '${registros.length} lectoras tienen este libro en su biblioteca',
      child: Column(
        children: registros.map((registro) {
          final usuarioNormalizado = registro.usuario.trim().toLowerCase();
          final esUsuarioActual =
              usuarioActual != null &&
              usuarioNormalizado == usuarioActual!.trim().toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _LectoraCard(
              registro: registro,
              esUsuarioActual: esUsuarioActual,
              tieneFinalizaciones: usuariosConFinalizacion.contains(
                usuarioNormalizado,
              ),
              onCambiarEstado: onCambiarEstado,
              onQuitarPendientes: onQuitarPendientes,
              onActualizarPreferencias: onActualizarPreferencias,
              onPedirValoracion: onPedirValoracion,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LectoraCard extends StatelessWidget {
  final Libro registro;
  final bool esUsuarioActual;
  final bool tieneFinalizaciones;
  final Future<void> Function(
    Libro libro,
    String nuevoEstado, {
    String? valoracion,
    String? reflexion,
    String? motivoPausa,
    String? fechaInicio,
    String? fechaFin,
    String? formato,
  })
  onCambiarEstado;
  final Future<void> Function(Libro libro) onQuitarPendientes;
  final Future<void> Function(Libro libro, String prioridad, String formato)
  onActualizarPreferencias;
  final Future<Map<String, String>?> Function(Libro libro) onPedirValoracion;

  const _LectoraCard({
    required this.registro,
    required this.esUsuarioActual,
    required this.tieneFinalizaciones,
    required this.onCambiarEstado,
    required this.onQuitarPendientes,
    required this.onActualizarPreferencias,
    required this.onPedirValoracion,
  });

  /// Opciones de estado como datos planos para el _EstadoSelector
  List<({String value, String label, String? emoji})> get _opcionesEstadoData {
    if (registro.estado == 'FINALIZADO') {
      return [
        (
          value: 'FINALIZADO',
          label: ReadingStatusCopy.label('FINALIZADO'),
          emoji: '✅',
        ),
        (
          value: 'PENDIENTE',
          label: ReadingStatusCopy.label('PENDIENTE'),
          emoji: '📚',
        ),
        (
          value: 'RELECTURA',
          label: ReadingStatusCopy.label('RELECTURA'),
          emoji: '🔁',
        ),
      ];
    }
    return [
      (
        value: 'PENDIENTE',
        label: ReadingStatusCopy.label('PENDIENTE'),
        emoji: '📚',
      ),
      if (!tieneFinalizaciones || registro.estado == 'LEYENDO')
        (
          value: 'LEYENDO',
          label: ReadingStatusCopy.label('LEYENDO'),
          emoji: '📖',
        ),
      (
        value: 'PAUSADO',
        label: ReadingStatusCopy.label('PAUSADO'),
        emoji: '😮‍💨',
      ),
      (
        value: 'RELECTURA',
        label: ReadingStatusCopy.label('RELECTURA'),
        emoji: '🔁',
      ),
      (
        value: 'ABANDONADO',
        label: ReadingStatusCopy.label('ABANDONADO'),
        emoji: '💔',
      ),
      (
        value: 'FINALIZADO',
        label: ReadingStatusCopy.label('FINALIZADO'),
        emoji: '✅',
      ),
    ];
  }

  Future<bool> _confirmarCorreccionFinalizacion(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corregir finalización'),
        content: const Text(
          'El libro volverá a Pendiente y se eliminará del historial la '
          'última finalización marcada por error.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Corregir'),
          ),
        ],
      ),
    );

    return confirmado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: esUsuarioActual
          ? AppColors.surfaceSoft
          : AppColors.surface,
      borderColor: esUsuarioActual ? AppColors.primaryLight : AppColors.divider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClubAvatar(
                nombre: registro.usuario,
                imageUrl: registro.avatarUrl,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            registro.usuario,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (esUsuarioActual) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const ClubChip(
                            label: 'Tú',
                            icon: Icons.person_rounded,
                            variant: ClubChipVariant.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: ClubChip(
                        label: _labelEstado(registro.estado),
                        icon: _iconoEstado(registro.estado),
                        variant: _varianteEstado(registro.estado),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (esUsuarioActual) ...[
            const SizedBox(height: AppSpacing.md),

            _OptionSelector<String>(
              label: 'Prioridad personal',
              icon: Icons.flag_rounded,
              color: AppColors.warning,
              value: registro.prioridad.isEmpty ? 'MEDIA' : registro.prioridad,
              options: const [
                (value: 'ALTA', label: 'Alta', emoji: '🔴'),
                (value: 'MEDIA', label: 'Media', emoji: '🟡'),
                (value: 'BAJA', label: 'Baja', emoji: '🟢'),
              ],
              onChanged: (value) =>
                  onActualizarPreferencias(registro, value, registro.formato),
            ),

            const SizedBox(height: AppSpacing.md),

            _OptionSelector<String>(
              label: 'Mi formato',
              icon: Icons.library_books_rounded,
              color: AppColors.info,
              value: registro.formato.isEmpty ? '' : registro.formato,
              options: const [
                (value: 'FISICO', label: 'Físico', emoji: '📖'),
                (value: 'DIGITAL', label: 'Digital', emoji: '📱'),
                (value: 'AUDIOLIBRO', label: 'Audio', emoji: '🎧'),
              ],
              onChanged: (value) => onActualizarPreferencias(
                registro,
                registro.prioridad.isEmpty ? 'MEDIA' : registro.prioridad,
                value,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            _EstadoSelector(
              estado: registro.estado,
              opciones: _opcionesEstadoData,
              onChanged: (value) async {
                if (value == null || value == registro.estado) {
                  return;
                }

                if (registro.estado == 'FINALIZADO' && value == 'PENDIENTE') {
                  final confirmado = await _confirmarCorreccionFinalizacion(
                    context,
                  );
                  if (!confirmado) return;
                }

                Map<String, String>? datosValoracion;
                String? motivoPausa;

                if (value == 'FINALIZADO') {
                  datosValoracion = await onPedirValoracion(registro);

                  if (datosValoracion == null) {
                    return;
                  }
                }

                if (value == 'PAUSADO') {
                  if (!context.mounted) return;

                  motivoPausa = await showDialog<String>(
                    context: context,
                    builder: (_) => const PausarLecturaDialog(),
                  );

                  if (motivoPausa == null) {
                    return;
                  }
                }

                await onCambiarEstado(
                  registro,
                  value,
                  valoracion: datosValoracion?['valoracion'],
                  reflexion: datosValoracion?['reflexion'],
                  fechaInicio: datosValoracion?['fechaInicio'],
                  fechaFin: datosValoracion?['fechaFin'],
                  formato: datosValoracion?['formato'],
                  motivoPausa: motivoPausa,
                );
              },
            ),
          ],
          if (registro.estado == 'PAUSADO') ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF4E0B0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pause_circle_outline_rounded,
                        color: Color(0xFF9A6B10),
                        size: 20,
                      ),

                      const SizedBox(width: AppSpacing.xs),

                      Expanded(
                        child: Text(
                          _textoFechaPausa(registro.pausedAt),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: const Color(0xFF7D5C17),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (registro.pauseReason.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: Color(0xFF9A6B10),
                          size: 20,
                        ),

                        const SizedBox(width: AppSpacing.xs),

                        Expanded(
                          child: Text(
                            registro.pauseReason.trim(),
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (registro.valoracion.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 19),

                const SizedBox(width: AppSpacing.xs),

                Text(
                  registro.valoracion,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],

          if (esUsuarioActual && registro.estado == 'PENDIENTE') ...[
            const SizedBox(height: AppSpacing.sm),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  onQuitarPendientes(registro);
                },
                icon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: AppColors.danger,
                ),
                label: const Text(
                  'Quitar de mi lista',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _textoFechaPausa(DateTime? fecha) {
    if (fecha == null) {
      return 'Lectura en pausa';
    }

    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays <= 0) {
      return 'Pausada hoy';
    }

    if (diferencia.inDays == 1) {
      return 'Pausada ayer';
    }

    if (diferencia.inDays < 7) {
      return 'En pausa desde hace ${diferencia.inDays} días';
    }

    if (diferencia.inDays < 30) {
      final semanas = (diferencia.inDays / 7).floor();

      return semanas == 1
          ? 'En pausa desde hace 1 semana'
          : 'En pausa desde hace $semanas semanas';
    }

    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return 'En pausa desde el '
        '${fecha.day} ${meses[fecha.month - 1]}';
  }

  static String _labelEstado(String estado) {
    return ReadingStatusCopy.label(estado);
  }

  static IconData _iconoEstado(String estado) {
    return ReadingStatusCopy.icon(estado);
  }

  static ClubChipVariant _varianteEstado(String estado) {
    switch (estado) {
      case 'LEYENDO':
        return ClubChipVariant.info;
      case 'PAUSADO':
        return ClubChipVariant.warning;
      case 'RELECTURA':
        return ClubChipVariant.primary;
      case 'FINALIZADO':
        return ClubChipVariant.success;
      case 'ABANDONADO':
      case 'ABANDONED':
        return ClubChipVariant.danger;
      default:
        return ClubChipVariant.warning;
    }
  }
}

/// Selector de estado de lectura — versión async-aware que envuelve _OptionSelector.
/// Muestra el label "Estado de lectura" siempre visible sobre los chips.
class _EstadoSelector extends StatelessWidget {
  const _EstadoSelector({
    required this.estado,
    required this.opciones,
    required this.onChanged,
  });

  final String estado;
  final List<({String value, String label, String? emoji})> opciones;
  final Future<void> Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return _OptionSelector<String>(
      label: 'Estado de lectura',
      icon: Icons.swap_horiz_rounded,
      color: AppColors.primary,
      value: estado,
      options: opciones,
      onChanged: onChanged,
    );
  }
}
