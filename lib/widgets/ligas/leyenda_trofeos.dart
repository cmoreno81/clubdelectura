import 'package:flutter/material.dart';

import '../../models/liga.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Orden de las medallas de Liga en cualquier leyenda de trofeos — de más
/// fácil a más difícil de conseguir. Compartido entre la Sala de Trofeos y
/// "Cómo funciona la liga" para que cuenten exactamente lo mismo. Plata y
/// Bronce no llevan entrada propia: se explican junto al Oro.
const List<LigaMedallaTier> kOrdenLeyendaTrofeos = [
  LigaMedallaTier.ascenso,
  LigaMedallaTier.podioOro,
  LigaMedallaTier.remontada,
  LigaMedallaTier.rachaPerfecta,
  LigaMedallaTier.constancia,
  LigaMedallaTier.libroDelAnio,
  LigaMedallaTier.polifacetica,
  LigaMedallaTier.diamante,
  LigaMedallaTier.bicampeona,
  LigaMedallaTier.hattrick,
];

/// Contenido de la leyenda de trofeos: el Libro de Oro (premio anual único)
/// más las medallas de Liga en [kOrdenLeyendaTrofeos]. Sin envoltorio propio
/// (ni desplegable ni título) para poder incrustarlo en cualquier sitio —
/// hoy en la Sala de Trofeos y en "Cómo funciona la liga".
class LeyendaTrofeosContenido extends StatelessWidget {
  const LeyendaTrofeosContenido({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilaLeyendaTrofeo(
          icono: Text('🏆', style: TextStyle(fontSize: 15)),
          color: Color(0xFFD9A441),
          titulo: 'Libro de Oro',
          descripcion:
              'Premio anual único: ser 1ª del ranking Acumulado el 31 de '
              'diciembre.',
        ),
        for (final tier in kOrdenLeyendaTrofeos)
          FilaLeyendaTrofeo(
            icono: Text(tier.icono, style: const TextStyle(fontSize: 15)),
            color: tier.color,
            titulo: tier == LigaMedallaTier.podioOro
                ? '1ª / 2ª / 3ª de tu división'
                : tier.etiqueta,
            descripcion: tier == LigaMedallaTier.podioOro
                ? 'Podio de tu división al cerrar una temporada — pesa más '
                      'cuanto más alta sea la división.'
                : tier.descripcion,
          ),
      ],
    );
  }
}

class FilaLeyendaTrofeo extends StatelessWidget {
  const FilaLeyendaTrofeo({
    super.key,
    required this.icono,
    required this.color,
    required this.titulo,
    required this.descripcion,
  });

  final Widget icono;
  final Color color;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
            child: icono,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  descripcion,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
