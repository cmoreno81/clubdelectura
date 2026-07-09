import 'package:flutter/material.dart';

import '../models/mood_club.dart';
import '../services/api_service.dart';

class MoodClubPage extends StatefulWidget {
  const MoodClubPage({super.key});

  @override
  State<MoodClubPage> createState() => _MoodClubPageState();
}

class _MoodClubPageState extends State<MoodClubPage> {
  late Future<MoodClub> future;

  @override
  void initState() {
    super.initState();
    future = ApiService().getMoodClub();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🧠 Mood del Club")),
      body: FutureBuilder<MoodClub>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final mood = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "📰 EL CLUB HOY",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        mood.titular,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "🎙️ El narrador",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(mood.narrador, style: const TextStyle(fontSize: 17)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: mood.estados
                        .map((e) => Chip(label: Text(e)))
                        .toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "📖 Crónicas del club",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...mood.actividad.map(
                (e) => Card(
                  child: ListTile(
                    leading: Text(
                      e.icono,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(e.texto),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
