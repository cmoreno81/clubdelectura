import 'package:flutter/material.dart';

/// "¿Has comprado X?": se pregunta al volver de la tienda tras pulsar un botón
/// de compra. Devuelve true solo si la lectora confirma. Todo local: no se
/// envía nada a la tienda ni a la red de afiliación.
Future<bool> preguntarSiLoHasComprado(
  BuildContext context, {
  required String titulo,
  required String formato,
  String? tienda,
}) async {
  final comprado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.shopping_bag_outlined),
      title: Text('¿Has comprado "$titulo"?'),
      content: Text(
        'Si lo has comprado${tienda == null || tienda.isEmpty ? '' : ' en $tienda'} '
        '(${formato.toLowerCase()}), '
        'lo pasamos a tus comprados.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Todavía no'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Sí, ya lo compré'),
        ),
      ],
    ),
  );
  return comprado == true;
}
