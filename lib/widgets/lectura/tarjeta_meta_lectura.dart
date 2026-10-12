import 'package:flutter/material.dart';

import '../../models/configuracion_lectura.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'editor_metas.dart';

/// Resume la próxima meta de la lectura conjunta. Tono siempre positivo: no
/// hay avisos de retraso, solo el siguiente tramo y su día.
class TarjetaMetaLectura extends StatelessWidget {
  const TarjetaMetaLectura({super.key, required this.config, DateTime? hoy})
    : _hoy = hoy;

  final ConfiguracionLectura config;
  final DateTime? _hoy;

  @override
  Widget build(BuildContext context) {
    final proxima = config.proximaMeta(_hoy ?? DateTime.now());
    if (config.metas.isEmpty) return const SizedBox.shrink();

    final String titulo;
    final String detalle;
    if (proxima == null) {
      titulo = '🎉 ¡Habéis llegado a todas las metas!';
      detalle = 'Gracias por leer en compañía.';
    } else {
      final meta = proxima.meta;
      final rango = proxima.desde >= meta.capitulo
          ? 'el capítulo ${meta.capitulo}'
          : 'los capítulos ${proxima.desde} a ${meta.capitulo}';
      final hoy = _hoy ?? DateTime.now();
      final dia = meta.dia;
      final esHoy =
          dia != null &&
          dia.year == hoy.year &&
          dia.month == hoy.month &&
          dia.day == hoy.day;
      titulo = esHoy ? '💬 Hoy comentamos $rango' : '📖 Próxima meta: $rango';
      detalle = esHoy
          ? '¡Cuéntanos qué te ha parecido!'
          : 'Lo comentamos el ${fechaLegible(meta.fecha)}.';
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: const Color(0xFFE49A24).withValues(alpha: .35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: Color(0xFFE49A24)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detalle, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
