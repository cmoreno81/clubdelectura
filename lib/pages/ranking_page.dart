import 'package:club_lectura_app/widgets/error_view.dart';
import 'package:flutter/material.dart';

import '../models/ranking.dart';
import '../models/ranking_item.dart';
import '../services/api_service.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  late Future<Ranking> rankingFuture;

  @override
  void initState() {
    super.initState();

    rankingFuture = ApiService().getRanking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🏆 Rankings'), centerTitle: true),

      body: FutureBuilder<Ranking>(
        future: rankingFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              onRetry: () {
                setState(() {
                  rankingFuture = ApiService().getRanking();
                });
              },
            );
          }

          final ranking = snapshot.data!;

          final reina = ranking.topLectoras.first;

          final libroClub = ranking.mejorValorados.first;

          final cementerio = ranking.masAbandonados.isNotEmpty
              ? ranking.masAbandonados.first
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),

            children: [
              Card(
                elevation: 4,

                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      const Text(
                        '👑 Reina del Club',

                        style: TextStyle(
                          fontSize: 22,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        reina.nombre,

                        style: const TextStyle(
                          fontSize: 28,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text('${reina.total} libros finalizados'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 4,

                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      const Text(
                        '⭐ Libro del Club',

                        style: TextStyle(
                          fontSize: 22,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        libroClub.nombre,

                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          fontSize: 24,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text('${libroClub.media.toStringAsFixed(2)} ⭐'),

                      Text('${libroClub.votos} valoraciones'),
                    ],
                  ),
                ),
              ),
              if (cementerio != null) ...[
                const SizedBox(height: 16),

                Card(
                  elevation: 4,

                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      children: [
                        const Text(
                          '😞 Cementerio Literario',

                          style: TextStyle(
                            fontSize: 22,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          cementerio.nombre,

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 24,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text('${cementerio.total} abandonos'),
                      ],
                    ),
                  ),
                ),
              ],
              _seccionTotales(
                titulo: '📚 Más deseados',
                items: ranking.masDeseados,
              ),

              const SizedBox(height: 16),

              _seccionTotales(
                titulo: '📖 Más leídos',
                items: ranking.masLeidos,
              ),

              const SizedBox(height: 16),

              _seccionValorados(
                titulo: '⭐ Mejor valorados',
                items: ranking.mejorValorados,
              ),

              const SizedBox(height: 16),

              _seccionTotales(
                titulo: '😞 Más abandonados',
                items: ranking.masAbandonados,
              ),

              const SizedBox(height: 16),

              _seccionTotales(
                titulo: '👑 Top lectoras',
                items: ranking.topLectoras,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _seccionTotales({
    required String titulo,

    required List<RankingItem> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              titulo,

              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...items.asMap().entries.map((entry) {
              final index = entry.key;

              final item = entry.value;

              return ListTile(
                leading: Text(
                  _medalla(index),

                  style: const TextStyle(fontSize: 24),
                ),

                title: Text(item.nombre),

                trailing: Text(
                  item.total.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _seccionValorados({
    required String titulo,

    required List<RankingItem> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              titulo,

              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...items.asMap().entries.map((entry) {
              final index = entry.key;

              final item = entry.value;

              return ListTile(
                leading: Text(
                  _medalla(index),

                  style: const TextStyle(fontSize: 24),
                ),

                title: Text(item.nombre),

                subtitle: Text('${item.votos} valoraciones'),

                trailing: Text(item.media.toStringAsFixed(2)),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _medalla(int posicion) {
    switch (posicion) {
      case 0:
        return '🥇';

      case 1:
        return '🥈';

      case 2:
        return '🥉';

      default:
        return '#${posicion + 1}';
    }
  }
}
