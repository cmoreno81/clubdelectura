import 'package:flutter/material.dart';

import '../models/como_votaron.dart';
import '../services/api_service.dart';

class ClubvisionComoVotaronPage extends StatefulWidget {
  const ClubvisionComoVotaronPage({super.key});

  @override
  State<ClubvisionComoVotaronPage> createState() =>
      _ClubvisionComoVotaronPageState();
}

class _ClubvisionComoVotaronPageState extends State<ClubvisionComoVotaronPage> {
  late Future<List<ComoVotaron>> future;

  @override
  void initState() {
    super.initState();
    future = ApiService().getComoVotaron();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🗳️ Cómo votaron")),

      body: FutureBuilder<List<ComoVotaron>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final lista = snapshot.data!;

          if (lista.isEmpty) {
            return const Center(
              child: Text(
                "Todavía no hay votaciones.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final persona = lista[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 18),
                elevation: 3,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),

                          const SizedBox(width: 12),

                          Text(
                            persona.usuaria,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      ...persona.votos.map(
                        (voto) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),

                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text(
                                  _emoji(voto.puntos),
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),

                              Expanded(
                                child: Text(
                                  voto.libro,
                                  style: const TextStyle(fontSize: 17),
                                ),
                              ),

                              Text(
                                "${voto.puntos}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _emoji(int puntos) {
    switch (puntos) {
      case 12:
        return "🥇";

      case 10:
        return "🥈";

      case 8:
        return "🥉";

      case 7:
        return "4️⃣";

      case 6:
        return "5️⃣";

      default:
        return "•";
    }
  }
}
