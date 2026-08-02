import 'package:flutter/material.dart';

import '../models/dashboard.dart';
import '../services/api_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/error_view.dart';
import '../widgets/club/gala_card.dart';

class ClubvisionGalaPage extends StatefulWidget {
  const ClubvisionGalaPage({super.key});

  @override
  State<ClubvisionGalaPage> createState() => _ClubvisionGalaPageState();
}

class _ClubvisionGalaPageState extends State<ClubvisionGalaPage> {
  late Future<Dashboard> dashboardFuture;
  Map<String, String> _readerAvatarUrls = const {};

  @override
  void initState() {
    super.initState();
    dashboardFuture = _loadDashboard();
  }

  Future<Dashboard> _loadDashboard() async {
    final api = ApiService();
    final dashboard = await api.getDashboard();
    final entries = await Future.wait(
      dashboard.clubvision.lectoras.map((nombre) async {
        try {
          final perfil = await api.getPerfilUsuario(nombre);
          return MapEntry(nombre, perfil.avatarUrl);
        } catch (_) {
          return MapEntry(nombre, '');
        }
      }),
    );

    _readerAvatarUrls = Map.fromEntries(entries);
    return dashboard;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Dashboard>(
      future: dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Gala Clubvisión')),
            body: ErrorView(
              onRetry: () {
                setState(() {
                  dashboardFuture = _loadDashboard();
                });
              },
            ),
          );
        }

        final dashboard = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: const Text('Gala Clubvisión')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              48,
            ),
            child: GalaCard(
              dashboard: dashboard,
              readerAvatarUrls: _readerAvatarUrls,
            ),
          ),
        );
      },
    );
  }
}
