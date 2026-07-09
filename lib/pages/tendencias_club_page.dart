// lib/pages/tendencias_club_page.dart

import 'package:club_lectura_app/services/api_service.dart';
import 'package:flutter/material.dart';

import '../models/tendencias_club.dart';
import 'perfil_usuario_page.dart';

class TendenciasClubPage extends StatefulWidget {
  const TendenciasClubPage({super.key});

  @override
  State<TendenciasClubPage> createState() => _TendenciasClubPageState();
}

class _TendenciasClubPageState extends State<TendenciasClubPage> {
  late Future<TendenciasClub> future;

  @override
  void initState() {
    super.initState();
    future = ApiService().getTendenciasClub();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📈 Tendencias")),
      body: FutureBuilder<TendenciasClub>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final maxGenero = _max(data.generos);
          final maxLibro = _max(data.libros);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: const Color(0xFFF2FFF5),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      const Text(
                        "💚 LO QUE ESTÁ PASANDO",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        data.titular,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        data.narrador,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17),
                      ),
                      const SizedBox(height: 18),
                      Chip(
                        label: Text("📚 ${data.totalLeyendo} lecturas activas"),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 26),

              const Text(
                "🏷️ Géneros en tendencia",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...data.generos.map(
                (g) => _barraItem(
                  nombre: g.nombre,
                  total: g.total,
                  max: maxGenero,
                  icono: "🏷️",
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                "🔥 Libros calientes",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...data.libros.map(
                (l) =>
                    _libroCard(nombre: l.nombre, total: l.total, max: maxLibro),
              ),

              const SizedBox(height: 28),

              const Text(
                "👑 Quién marca tendencia",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...data.lectoras.asMap().entries.map((entry) {
                final index = entry.key;
                final lectora = entry.value;

                return Card(
                  child: ListTile(
                    leading: Text(
                      _medalla(index),
                      style: const TextStyle(fontSize: 26),
                    ),
                    title: Text(
                      lectora.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${lectora.total} lecturas activas"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PerfilUsuarioPage(usuario: lectora.nombre),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _barraItem({
    required String nombre,
    required int total,
    required int max,
    required String icono,
  }) {
    final value = max == 0 ? 0.0 : total / max;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$icono $nombre",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: value,
              minHeight: 9,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 8),
            Text("$total ${total == 1 ? 'lectora' : 'lectoras'}"),
          ],
        ),
      ),
    );
  }

  Widget _libroCard({
    required String nombre,
    required int total,
    required int max,
  }) {
    return Card(
      child: ListTile(
        leading: const Text("🔥", style: TextStyle(fontSize: 26)),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(
            value: max == 0 ? 0 : total / max,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        trailing: Text(
          total.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  int _max(List<TendenciaItem> items) {
    if (items.isEmpty) return 0;

    return items.map((e) => e.total).reduce((a, b) => a > b ? a : b);
  }

  String _medalla(int index) {
    switch (index) {
      case 0:
        return "🥇";
      case 1:
        return "🥈";
      case 2:
        return "🥉";
      default:
        return "#${index + 1}";
    }
  }
}
