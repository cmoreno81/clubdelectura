import 'package:flutter/material.dart';

import '../../models/conversacion_libro.dart';
import '../../pages/lectura_page.dart';
import '../../services/api_service.dart';

class ConversacionesLibroCard extends StatelessWidget {
  final String libro;

  const ConversacionesLibroCard({super.key, required this.libro});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConversacionLibro>>(
      future: ApiService().getConversacionesLibro(libro: libro),

      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final conversaciones = snapshot.data!;

        if (conversaciones.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "💬 Conversaciones",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...conversaciones.map(
              (c) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.tipo == "OFICIAL"
                        ? Colors.deepPurple
                        : Colors.blue,

                    child: Icon(
                      c.tipo == "OFICIAL" ? Icons.emoji_events : Icons.people,
                      color: Colors.white,
                    ),
                  ),

                  title: Text(
                    c.tipo == "OFICIAL"
                        ? "🏆 Lectura oficial"
                        : "👥 Lectura compartida",
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const SizedBox(height: 4),

                      Text("💬 ${c.comentarios} comentarios · ❤️ ${c.likes}"),

                      if (c.ultimaActividad.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),

                          child: Text(c.ultimaActividad),
                        ),

                      const SizedBox(height: 4),

                      Text(
                        c.estado,
                        style: TextStyle(
                          color: c.estado == "ACTIVA"
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LecturaPage(libro: libro),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
