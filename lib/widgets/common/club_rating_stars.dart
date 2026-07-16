import 'package:flutter/material.dart';

class ClubRatingStars extends StatelessWidget {
  final String valoracion;
  final double size;
  final Color color;
  final double spacing;

  const ClubRatingStars({
    super.key,
    required this.valoracion,
    this.size = 18,
    this.color = const Color(0xFFB48113),
    this.spacing = 1,
  });

  @override
  Widget build(BuildContext context) {
    final valor = parseValoracion(valoracion);

    if (valor <= 0) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Valoración: ${_formatearValor(valor)} de 5',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final valorDentroDeEstrella = valor - index;

          final IconData icono;

          if (valorDentroDeEstrella >= 1) {
            icono = Icons.star_rounded;
          } else if (valorDentroDeEstrella >= 0.5) {
            icono = Icons.star_half_rounded;
          } else {
            icono = Icons.star_border_rounded;
          }

          return Padding(
            padding: EdgeInsets.only(right: index < 4 ? spacing : 0),
            child: Icon(icono, size: size, color: color),
          );
        }),
      ),
    );
  }

  static double parseValoracion(String valoracion) {
    final texto = valoracion.trim().replaceAll('⭐️', '⭐').replaceAll(',', '.');

    if (texto.isEmpty || texto == '😞') {
      return 0;
    }

    final numeroDirecto = double.tryParse(texto);

    if (numeroDirecto != null) {
      return _redondearMedia(numeroDirecto.clamp(0, 5).toDouble());
    }

    final estrellasCompletas = RegExp('⭐').allMatches(texto).length;

    final tieneMedia =
        texto.contains('½') || texto.toLowerCase().contains('media');

    final resultado = estrellasCompletas + (tieneMedia ? 0.5 : 0);

    return _redondearMedia(resultado.clamp(0, 5).toDouble());
  }

  static double _redondearMedia(double valor) {
    return (valor * 2).round() / 2;
  }

  static String _formatearValor(double valor) {
    if (valor % 1 == 0) {
      return valor.toInt().toString();
    }

    return valor.toStringAsFixed(1).replaceAll('.', ',');
  }
}
