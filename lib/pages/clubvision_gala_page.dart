import 'package:flutter/material.dart';

import '../models/dashboard.dart';
import '../services/api_service.dart';
import '../widgets/club/gala_card.dart';

class ClubvisionGalaPage extends StatefulWidget {
  const ClubvisionGalaPage({super.key});

  @override
  State<ClubvisionGalaPage> createState() => _ClubvisionGalaPageState();
}

class _ClubvisionGalaPageState extends State<ClubvisionGalaPage> {
  late Future<Dashboard> dashboardFuture;

  @override
  void initState() {
    super.initState();
    dashboardFuture = ApiService().getDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Dashboard>(
      future: dashboardFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final dashboard = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: const Text("🏆 Gala Clubvisión")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: GalaCard(dashboard: dashboard),
          ),
        );
      },
    );
  }
}
