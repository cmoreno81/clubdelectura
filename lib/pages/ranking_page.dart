import 'package:club_lectura_app/widgets/error_view.dart';
import 'package:flutter/material.dart';

import '../models/ranking.dart';
import '../models/ranking_item.dart';
import '../services/api_service.dart';

class RankingPage extends StatefulWidget {
  final int initialTab;

  const RankingPage({super.key, this.initialTab = 0});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  late Future<Ranking> rankingFuture;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _topLectorasKey = GlobalKey();
  final GlobalKey _mejorValoradosKey = GlobalKey();
  final GlobalKey _masLeidosKey = GlobalKey();

  bool _yaHizoScrollInicial = false;

  @override
  void initState() {
    super.initState();
    rankingFuture = ApiService().getRanking();
  }

  void _scrollInicial() {
    if (_yaHizoScrollInicial) return;

    _yaHizoScrollInicial = true;

    GlobalKey? targetKey;

    switch (widget.initialTab) {
      case 1:
        targetKey = _topLectorasKey;
        break;
      case 2:
        targetKey = _mejorValoradosKey;
        break;
      case 3:
        targetKey = _masLeidosKey;
        break;
      default:
        targetKey = null;
    }

    if (targetKey?.currentContext == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Scrollable.ensureVisible(
        targetKey!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    });
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
                  _yaHizoScrollInicial = false;
                  rankingFuture = ApiService().getRanking();
                });
              },
            );
          }

          final ranking = snapshot.data!;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollInicial();
          });

          final reina = ranking.topLectoras.isNotEmpty
              ? ranking.topLectoras.first
              : null;

          final libroClub = ranking.mejorValorados.isNotEmpty
              ? ranking.mejorValorados.first
              : null;

          final cementerio = ranking.masAbandonados.isNotEmpty
              ? ranking.masAbandonados.first
              : null;

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              if (reina != null)
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

              if (libroClub != null) ...[
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
              ],

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

              KeyedSubtree(
                key: _masLeidosKey,
                child: _seccionTotales(
                  titulo: '📖 Más leídos',
                  items: ranking.masLeidos,
                ),
              ),

              const SizedBox(height: 16),

              KeyedSubtree(
                key: _mejorValoradosKey,
                child: _seccionValorados(
                  titulo: '⭐ Mejor valorados',
                  items: ranking.mejorValorados,
                ),
              ),

              const SizedBox(height: 16),

              _seccionTotales(
                titulo: '😞 Más abandonados',
                items: ranking.masAbandonados,
              ),

              const SizedBox(height: 16),

              KeyedSubtree(
                key: _topLectorasKey,
                child: _seccionTotales(
                  titulo: '👑 Top lectoras',
                  items: ranking.topLectoras,
                ),
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
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Todavía no hay datos.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
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
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Todavía no hay datos.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
