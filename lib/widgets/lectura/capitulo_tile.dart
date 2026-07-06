import 'package:flutter/material.dart';

import '../../models/capitulo_lectura.dart';
import 'fecha_relativa.dart';

class CapituloTile extends StatelessWidget {
  final CapituloLectura capitulo;
  final VoidCallback onTap;

  const CapituloTile({super.key, required this.capitulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade50,
          child: const Icon(Icons.forum_outlined, color: Colors.deepPurple),
        ),

        title: Text(
          capitulo.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: Colors.grey,
                  ),

                  const SizedBox(width: 4),

                  Text("${capitulo.comentarios}"),
                ],
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 16, color: Colors.red),

                  const SizedBox(width: 4),

                  Text("${capitulo.likes}"),
                ],
              ),

              if (capitulo.ultimaActividad.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),

                    const SizedBox(width: 4),

                    Text(FechaRelativa.formato(capitulo.ultimaActividad)),
                  ],
                ),
            ],
          ),
        ),

        trailing: const Icon(Icons.chevron_right),

        onTap: onTap,
      ),
    );
  }
}
