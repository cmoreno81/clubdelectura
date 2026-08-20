import 'package:flutter/material.dart';

import '../../models/libro_agrupado.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_book_cover.dart';

/// Acciones rápidas disponibles desde la tarjeta de libro.
enum LibroAccion {
  anadir,
  empezar, // PENDIENTE → iniciarLectura
  reanudar, // PAUSADO → actualizarEstado(LEYENDO)
  pausar,
  finalizar,
  releer,
  quitar,
  verFicha,
  editarFechaInicio, // LEYENDO/RELECTURA/PAUSADO → editar startedAt
}

/// Muestra el bottom sheet de acciones y devuelve la acción elegida (o null).
Future<LibroAccion?> mostrarLibroAccionesSheet(
  BuildContext context,
  LibroAgrupado libro,
) {
  return showModalBottomSheet<LibroAccion>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _LibroAccionesSheet(libro: libro),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _LibroAccionesSheet extends StatelessWidget {
  const _LibroAccionesSheet({required this.libro});

  final LibroAgrupado libro;

  @override
  Widget build(BuildContext context) {
    final propioEstado =
        libro.registros
            .where((r) => r.yaLoTengo)
            .map((r) => r.estado.toUpperCase())
            .firstOrNull ??
        '';

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cabecera con portada y título ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                ClubBookCover(
                  title: libro.libro,
                  imageUrl: libro.coverUrl,
                  width: 52,
                  showShadow: false,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        libro.libro,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.section.copyWith(fontSize: 16),
                      ),
                      if (libro.genero.isNotEmpty)
                        Text(
                          libro.genero,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Acciones contextuales ──────────────────────────────────────────
          ..._acciones(context, propioEstado),

          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  List<Widget> _acciones(BuildContext context, String propioEstado) {
    final tiles = <Widget>[];

    if (!libro.leidoPorMi && !libro.yaLoTengo) {
      // Libro que no está en la lista
      tiles.add(
        _tile(
          context,
          icon: Icons.add_circle_outline_rounded,
          label: 'Añadir a mi lista',
          color: AppColors.primary,
          accion: LibroAccion.anadir,
        ),
      );
    } else if (propioEstado == 'PENDIENTE') {
      tiles.add(
        _tile(
          context,
          icon: Icons.play_circle_outline_rounded,
          label: 'Empezar a leer',
          color: AppColors.success,
          accion: LibroAccion.empezar,
        ),
      );
      tiles.add(
        _tile(
          context,
          icon: Icons.remove_circle_outline_rounded,
          label: 'Quitar de pendientes',
          color: AppColors.danger,
          accion: LibroAccion.quitar,
        ),
      );
    } else if (propioEstado == 'LEYENDO' || propioEstado == 'RELECTURA') {
      tiles.add(
        _tile(
          context,
          icon: Icons.nights_stay_outlined,
          label: 'Pausar lectura',
          color: const Color(0xFFE8A020),
          accion: LibroAccion.pausar,
        ),
      );
      tiles.add(
        _tile(
          context,
          icon: Icons.check_circle_outline_rounded,
          label: 'Marcar como finalizado',
          color: AppColors.success,
          accion: LibroAccion.finalizar,
        ),
      );
      tiles.add(
        _tile(
          context,
          icon: Icons.edit_calendar_outlined,
          label: 'Editar fecha de inicio',
          color: AppColors.primary,
          accion: LibroAccion.editarFechaInicio,
        ),
      );
    } else if (propioEstado == 'PAUSADO') {
      tiles.add(
        _tile(
          context,
          icon: Icons.play_circle_outline_rounded,
          label: 'Reanudar lectura',
          color: AppColors.success,
          accion: LibroAccion.reanudar,
        ),
      );
      tiles.add(
        _tile(
          context,
          icon: Icons.check_circle_outline_rounded,
          label: 'Marcar como finalizado',
          color: AppColors.success,
          accion: LibroAccion.finalizar,
        ),
      );
      tiles.add(
        _tile(
          context,
          icon: Icons.edit_calendar_outlined,
          label: 'Editar fecha de inicio',
          color: AppColors.primary,
          accion: LibroAccion.editarFechaInicio,
        ),
      );
    } else if (libro.leidoPorMi) {
      // FINALIZADO, ABANDONADO, etc.
      tiles.add(
        _tile(
          context,
          icon: Icons.replay_rounded,
          label: 'Volver a leer',
          color: AppColors.primary,
          accion: LibroAccion.releer,
        ),
      );
    }

    // Siempre: ver ficha
    tiles.add(
      _tile(
        context,
        icon: Icons.info_outline_rounded,
        label: 'Ver ficha completa',
        color: AppColors.textSecondary,
        accion: LibroAccion.verFicha,
      ),
    );

    return tiles;
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required LibroAccion accion,
  }) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 20,
      ),
      onTap: () => Navigator.pop(context, accion),
    );
  }
}
