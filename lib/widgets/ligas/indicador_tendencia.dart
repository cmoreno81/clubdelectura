import 'package:flutter/material.dart';

import '../../models/liga.dart';
import '../../theme/app_colors.dart';

/// Flechita estilo parrilla de F1: sube/baja puestos desde el último ciclo
/// del cron (cada 1-3 h). Sin dato aún (recién unida) no muestra nada.
class IndicadorTendencia extends StatelessWidget {
  const IndicadorTendencia({super.key, required this.fila});
  final LigaFila fila;

  @override
  Widget build(BuildContext context) {
    final tendencia = fila.tendencia;
    if (tendencia == null || tendencia == LigaTendencia.igual) {
      return Icon(
        Icons.remove_rounded,
        size: 14,
        color: AppColors.textMuted.withValues(alpha: .5),
      );
    }
    final sube = tendencia == LigaTendencia.sube;
    final color = sube ? AppColors.success : AppColors.danger;
    final delta = (fila.delta ?? 0).abs();
    return Tooltip(
      message: sube ? 'Ha subido $delta puestos' : 'Ha bajado $delta puestos',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sube ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            size: 20,
            color: color,
          ),
        ],
      ),
    );
  }
}
