import 'package:flutter/material.dart';

import '../../models/dashboard.dart';

class GalaCard extends StatelessWidget {
  final Dashboard dashboard;

  const GalaCard({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final club = dashboard.clubvision;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.emoji_events, size: 90, color: Colors.amber),

            const SizedBox(height: 20),

            const Text(
              "✨ Ya tenemos ganadora ✨",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            Text(
              club.ganador,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const Text(
              "Elegida por el Club",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),

            const SizedBox(height: 40),

            const Divider(),

            const SizedBox(height: 20),

            const Text(
              "⭐ Ya lo habían leído",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            if (club.lectoras.isEmpty)
              const Text("Será una lectura totalmente nueva para el club."),

            ...club.lectoras.map(
              (nombre) => ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.deepPurple),
                title: Text(nombre),
              ),
            ),

            const SizedBox(height: 30),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.auto_stories),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text("Comenzar lectura", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
