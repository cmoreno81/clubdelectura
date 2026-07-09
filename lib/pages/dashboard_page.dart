import 'package:club_lectura_app/pages/mood_club_page.dart';
import 'package:club_lectura_app/pages/ranking_page.dart';
import 'package:club_lectura_app/widgets/club/club_card.dart';
import 'package:club_lectura_app/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'tendencias_club_page.dart';
import 'perfil_usuario_page.dart';
import '../dev/dev_settings.dart';
import '../models/dashboard_view_data.dart';
import '../services/api_service.dart';
import '../services/club_narrador.dart';
import '../services/usuario_service.dart';
import '../widgets/info_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardViewData> dashboardFuture;
  String? usuarioActual;

  @override
  void initState() {
    super.initState();
    dashboardFuture = _cargarDashboard();
    _cargarUsuarioActual();
  }

  Future<DashboardViewData> _cargarDashboard() async {
    final dashboardFuture = ApiService().getDashboard();
    final clubvisionFuture = ApiService().getClubvision();

    final dashboard = await dashboardFuture;
    final clubvision = await clubvisionFuture;

    return DashboardViewData(
      dashboard: dashboard,
      haVotado: clubvision.haVotado,
    );
  }

  Future<void> _cargarUsuarioActual() async {
    final usuario = await UsuarioService().obtenerUsuario();

    if (!mounted) return;

    setState(() {
      usuarioActual = usuario;
    });
  }

  String _iniciales(String nombre) {
    final limpio = nombre.trim();

    if (limpio.isEmpty) return "?";

    final partes = limpio.split(RegExp(r'\s+'));

    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }

    return "${partes.first[0]}${partes.last[0]}".toUpperCase();
  }

  void _abrirPerfil(String usuario) {
    final limpio = usuario.trim();

    if (limpio.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PerfilUsuarioPage(usuario: limpio)),
    );
  }

  void _abrirRanking({int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RankingPage(initialTab: initialTab)),
    );
  }

  Widget _tapCard({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: child,
    );
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
          '📚 ClubReads',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => _abrirPerfil(usuarioActual ?? ''),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.deepPurple.shade100,
                child: Text(
                  _iniciales(usuarioActual ?? ''),
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: FutureBuilder<DashboardViewData>(
        future: dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              onRetry: () {
                setState(() {
                  dashboardFuture = _cargarDashboard();
                });
              },
            );
          }

          final viewData = snapshot.data!;
          final data = viewData.dashboard;

          final estadoClub = ClubNarrador().narrar(
            estado: DevSettings.estadoForzado ?? data.clubvision.estado,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _tapCard(
                  onTap: () => _abrirPerfil(data.resumen.usuarioMes),
                  child: InfoCard(
                    title: 'Usuario del mes',
                    value:
                        '${data.resumen.usuarioMes}\n${data.resumen.librosUsuarioMes} libros',
                    icon: Icons.emoji_events,
                    backgroundColor: const Color(0xFFF4ECFF),
                    iconColor: Colors.deepPurple,
                  ),
                ),

                const SizedBox(height: 16),

                ClubCard(
                  dashboard: data,
                  estadoClub: estadoClub,
                  haVotado: viewData.haVotado,
                  onActualizar: () async {
                    setState(() {
                      dashboardFuture = _cargarDashboard();
                    });
                  },
                ),

                const SizedBox(height: 16),

                _tapCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoodClubPage()),
                    );
                  },
                  child: InfoCard(
                    title: 'Mood del club',
                    value: data.mood,
                    icon: Icons.psychology,
                    backgroundColor: const Color(0xFFFFF3F7),
                    iconColor: Colors.pink,
                  ),
                ),

                const SizedBox(height: 16),

                _tapCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TendenciasClubPage(),
                      ),
                    );
                  },
                  child: InfoCard(
                    title: 'Tendencia',
                    value: data.tendencia,
                    icon: Icons.trending_up,
                    backgroundColor: const Color(0xFFF2FFF5),
                    iconColor: Colors.green,
                  ),
                ),

                const SizedBox(height: 16),

                if (data.libroMes.isNotEmpty) ...[
                  InfoCard(
                    title: 'Libro del mes',
                    value:
                        '${data.libroMes.first.libro}\n${data.libroMes.first.puntos} puntos',
                    icon: Icons.menu_book,
                    backgroundColor: const Color(0xFFF2F6FF),
                    iconColor: Colors.indigo,
                  ),
                  const SizedBox(height: 16),
                ],

                _tapCard(
                  onTap: () => _abrirRanking(initialTab: 1),
                  child: InfoCard(
                    title: 'Actividad del mes',
                    value: '${data.resumen.actividadMes} libros',
                    icon: Icons.local_fire_department,
                    backgroundColor: const Color(0xFFFFF7EC),
                    iconColor: Colors.orange,
                  ),
                ),

                const SizedBox(height: 16),

                _tapCard(
                  onTap: () => _abrirRanking(initialTab: 2),
                  child: InfoCard(
                    title: 'Valoración media',
                    value: data.resumen.valoracionMedia,
                    icon: Icons.star,
                    backgroundColor: const Color(0xFFFFFBEA),
                    iconColor: Colors.amber,
                  ),
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
                      onTap: () => _abrirPerfil(usuario.usuario),
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
