import 'package:flutter/material.dart';

/// Reparte [children] en dos columnas cuando hay ancho (tablet) y los apila
/// en una sola columna en móvil. Cada fila alinea sus tarjetas por arriba,
/// así que pueden tener alturas distintas.
class DosColumnas extends StatelessWidget {
  const DosColumnas({
    super.key,
    required this.children,
    this.espacio = 16,
    this.anchoMinimo = 720,
  });

  final List<Widget> children;
  final double espacio;
  final double anchoMinimo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < anchoMinimo || children.length < 2) {
          return Column(children: children);
        }
        // Dos columnas independientes (pares / impares): si una tarjeta se
        // despliega, no deja huecos en la otra columna.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i += 2) children[i],
                ],
              ),
            ),
            SizedBox(width: espacio),
            Expanded(
              child: Column(
                children: [
                  for (var i = 1; i < children.length; i += 2) children[i],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
