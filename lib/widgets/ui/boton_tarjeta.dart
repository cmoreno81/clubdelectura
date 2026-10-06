import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';

/// Píldora blanca con flecha de las tarjetas de acceso del inicio ("Ver mis
/// libros", "Ver lista completa"). Es solo la forma: el toque lo recoge la
/// tarjeta entera. [color] es el tono oscuro de la tarjeta donde se coloca.
class BotonTarjeta extends StatelessWidget {
  const BotonTarjeta({super.key, required this.etiqueta, required this.color});

  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 16, color: color),
        ],
      ),
    );
  }
}
