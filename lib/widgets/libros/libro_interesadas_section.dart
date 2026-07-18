import 'package:flutter/material.dart';

import '../../models/libro.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_avatar.dart';
import '../common/club_card.dart';
import '../common/club_chip.dart';
import 'libro_section.dart';
import 'pausar_lectura_dialog.dart';

class LibroInteresadasSection extends StatelessWidget {
  final List<Libro> registros;
  final String? usuarioActual;
  final Future<void> Function(
    Libro libro,
    String nuevoEstado, {
    String? valoracion,
    String? reflexion,
    String? motivoPausa,
    String? fechaInicio,
  })
  onCambiarEstado;
  final Future<void> Function(Libro libro) onQuitarPendientes;
  final Future<Map<String, String>?> Function(Libro libro) onPedirValoracion;

  const LibroInteresadasSection({
    super.key,
    required this.registros,
    required this.usuarioActual,
    required this.onCambiarEstado,
    required this.onQuitarPendientes,
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
          final esUsuarioActual =
              usuarioActual != null &&
              registro.usuario.trim().toLowerCase() ==
                  usuarioActual!.trim().toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _LectoraCard(
              registro: registro,
              esUsuarioActual: esUsuarioActual,
              onCambiarEstado: onCambiarEstado,
              onQuitarPendientes: onQuitarPendientes,
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
  final Future<void> Function(
    Libro libro,
    String nuevoEstado, {
    String? valoracion,
    String? reflexion,
    String? motivoPausa,
    String? fechaInicio,
  })
  onCambiarEstado;
  final Future<void> Function(Libro libro) onQuitarPendientes;
  final Future<Map<String, String>?> Function(Libro libro) onPedirValoracion;

  const _LectoraCard({
    required this.registro,
    required this.esUsuarioActual,
    required this.onCambiarEstado,
    required this.onQuitarPendientes,
    required this.onPedirValoracion,
  });

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
                    Text(
                      registro.usuario,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    ClubChip(
                      label: _labelEstado(registro.estado),
                      icon: _iconoEstado(registro.estado),
                      variant: _varianteEstado(registro.estado),
                    ),
                  ],
                ),
              ),

              if (esUsuarioActual)
                const ClubChip(
                  label: 'Tú',
                  icon: Icons.person_rounded,
                  variant: ClubChipVariant.primary,
                ),
            ],
          ),

          if (esUsuarioActual) ...[
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<String>(
              initialValue: registro.estado,
              decoration: const InputDecoration(
                labelText: 'Estado de lectura',
                prefixIcon: Icon(Icons.swap_horiz_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'PENDIENTE', child: Text('Pendiente')),
                DropdownMenuItem(value: 'LEYENDO', child: Text('Leyendo')),
                DropdownMenuItem(value: 'PAUSADO', child: Text('En pausa')),
                DropdownMenuItem(value: 'RELECTURA', child: Text('Relectura')),
                DropdownMenuItem(
                  value: 'ABANDONADO',
                  child: Text('Abandonado'),
                ),
                DropdownMenuItem(
                  value: 'FINALIZADO',
                  child: Text('Finalizado'),
                ),
              ],
              onChanged: (value) async {
                if (value == null || value == registro.estado) {
                  return;
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

                      Text(
                        _textoFechaPausa(registro.pausedAt),
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: const Color(0xFF7D5C17),
                          fontWeight: FontWeight.w700,
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
    switch (estado) {
      case 'LEYENDO':
        return 'Leyendo';
      case 'PAUSADO':
        return 'En pausa';
      case 'RELECTURA':
        return 'Relectura';
      case 'FINALIZADO':
        return 'Finalizado';
      case 'ABANDONADO':
      case 'ABANDONED':
        return 'Abandonado';
      default:
        return 'Pendiente';
    }
  }

  static IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'LEYENDO':
        return Icons.menu_book_rounded;
      case 'PAUSADO':
        return Icons.pause_circle_outline_rounded;
      case 'RELECTURA':
        return Icons.refresh_rounded;
      case 'FINALIZADO':
        return Icons.check_circle_outline_rounded;
      case 'ABANDONADO':
      case 'ABANDONED':
        return Icons.heart_broken_rounded;
      default:
        return Icons.schedule_rounded;
    }
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
