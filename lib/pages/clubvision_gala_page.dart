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
                  dashboardFuture = ApiService().getDashboard();
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
            child: GalaCard(dashboard: dashboard),
          ),
        );
      },
    );
  }
}
