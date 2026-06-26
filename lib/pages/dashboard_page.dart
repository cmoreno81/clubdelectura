import 'package:flutter/material.dart';

import '../models/dashboard.dart';
import '../services/api_service.dart';
import '../widgets/info_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Dashboard> dashboardFuture;

  @override
  void initState() {
    super.initState();

    dashboardFuture = ApiService().getDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          '📚 Club de Lectura',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: FutureBuilder<Dashboard>(
        future: dashboardFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [
                // Usuario del mes
                InfoCard(
                  title: 'Usuario del mes',
                  value:
                      '${data.resumen.usuarioMes}\n${data.resumen.librosUsuarioMes} libros',
                  icon: Icons.emoji_events,
                ),

                const SizedBox(height: 16),

                // Clubvisión
                Card(
                  elevation: 4,

                  color: Colors.blue.shade50,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(24),

                    child: Column(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          size: 52,
                          color: Colors.amber,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          data.clubvision.titulo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          data.clubvision.mensaje,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          data.clubvision.lectoras.isEmpty
                              ? '🌟 Estreno para todo el club'
                              : '⭐ Ya leído por:\n${data.clubvision.lectoras.join(", ")}',

                          textAlign: TextAlign.center,

                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Mood
                InfoCard(
                  title: 'Mood del club',
                  value: data.mood,
                  icon: Icons.psychology,
                ),

                const SizedBox(height: 16),

                // Tendencia
                InfoCard(
                  title: 'Tendencia',
                  value: data.tendencia,
                  icon: Icons.trending_up,
                ),

                const SizedBox(height: 16),

                // Libro del mes
                if (data.libroMes.isNotEmpty)
                  InfoCard(
                    title: 'Libro del mes',
                    value:
                        '${data.libroMes.first.libro}\n${data.libroMes.first.puntos} puntos',
                    icon: Icons.menu_book,
                  ),

                const SizedBox(height: 16),

                // Actividad
                InfoCard(
                  title: 'Actividad del mes',
                  value: '${data.resumen.actividadMes} libros',
                  icon: Icons.menu_book,
                ),

                const SizedBox(height: 16),

                // Valoración
                InfoCard(
                  title: 'Valoración media',
                  value: data.resumen.valoracionMedia,
                  icon: Icons.star,
                ),

                const SizedBox(height: 24),

                const Align(
                  alignment: Alignment.centerLeft,

                  child: Text(
                    '📖 Leyendo ahora',

                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 12),

                ...data.leyendoAhora.map(
                  (usuario) => Card(
                    elevation: 2,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: ListTile(
                      title: Text(
                        usuario.usuario,

                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      subtitle: Text(
                        usuario.libros.isEmpty
                            ? 'Nada ahora'
                            : usuario.libros.join('\n'),
                      ),

                      trailing: CircleAvatar(
                        child: Text(usuario.total.toString()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
