import 'package:flutter/material.dart';

/// Diálogo de confirmación para deshacer un "terminado" marcado por error:
/// vuelve el libro a Pendiente y borra del historial la última
/// finalización (no todo el historial de lectura). Compartido entre
/// [MiFichaLecturaCard] y la tarjeta de lectora en la ficha del libro para
/// que el texto no diverja entre los dos sitios donde se puede corregir.
Future<bool> confirmarCorreccionFinalizacion(BuildContext context) async {
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
