import 'package:flutter/material.dart';

class ClubRatingSelector extends StatelessWidget {
  final double valoracion;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final double starSize;
  final double itemWidth;

  const ClubRatingSelector({
    super.key,
    required this.valoracion,
    required this.onChanged,
    this.enabled = true,
    this.starSize = 36,
    this.itemWidth = 42,
  });

  @override
  Widget build(BuildContext context) {
    const colorActiva = Color(0xFFB48113);
    final colorInactiva = Theme.of(context).colorScheme.outlineVariant;

    return Semantics(
      label: 'Valoración: $valoracion de 5',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final numeroEstrella = index + 1;
          final valorCompleto = numeroEstrella.toDouble();
          final valorMedio = numeroEstrella - 0.5;

          IconData icono;

          if (valoracion >= valorCompleto) {
            icono = Icons.star_rounded;
          } else if (valoracion >= valorMedio) {
            icono = Icons.star_half_rounded;
          } else {
            icono = Icons.star_border_rounded;
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled
                ? (details) {
                    final pulsaMitadIzquierda =
                        details.localPosition.dx <= itemWidth / 2;

                    onChanged(pulsaMitadIzquierda ? valorMedio : valorCompleto);
                  }
                : null,
            child: SizedBox(
              width: itemWidth,
              height: 46,
              child: Icon(
                icono,
                size: starSize,
                color: enabled ? colorActiva : colorInactiva,
              ),
            ),
          );
        }),
      ),
    );
  }
}
