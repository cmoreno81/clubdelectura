import 'package:flutter/material.dart';

import '../../models/comentario_lectura.dart';
import 'avatar_usuario.dart';
import 'fecha_relativa.dart';

class ComentarioCard extends StatelessWidget {
  final ComentarioLectura comentario;

  const ComentarioCard({super.key, required this.comentario});

  @override
  Widget build(BuildContext context) {
    if (comentario.eliminado) {
      return Card(
        child: ListTile(
          title: Text(
            "Este comentario fue eliminado.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarUsuario(nombre: comentario.usuario),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comentario.usuario,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    FechaRelativa.formato(comentario.fecha),
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    comentario.comentario,
                    style: const TextStyle(fontSize: 16),
                  ),

                  if (comentario.editado)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "(editado)",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 4),

                      Text("${comentario.likes}"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
