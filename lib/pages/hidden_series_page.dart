import 'package:flutter/material.dart';

import '../models/saga_oculta.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/series_refresh_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_empty_state.dart';
import '../widgets/error_view.dart';

class HiddenSeriesSection extends StatefulWidget {
  const HiddenSeriesSection({super.key});

  @override
  State<HiddenSeriesSection> createState() => _HiddenSeriesSectionState();
}

class _HiddenSeriesSectionState extends State<HiddenSeriesSection> {
  late Future<List<SagaOculta>> _future;
  final Set<String> _restoringIds = {};

  @override
  void initState() {
    super.initState();
    _future = ApiService().getSagasOcultas();
  }

  Future<void> _reload() async {
    final next = ApiService().getSagasOcultas();
    if (!mounted) return;
    setState(() => _future = next);
    await next;
  }

  Future<void> _restore(SagaOculta saga) async {
    if (_restoringIds.contains(saga.id)) return;
    setState(() => _restoringIds.add(saga.id));
    try {
      await ApiService().mostrarSaga(sagaId: saga.id);
      if (!mounted) return;
      SeriesRefreshNotifier.instance.invalidate();
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${saga.nombre} vuelve a estar visible.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _restoringIds.remove(saga.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SagaOculta>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) return ErrorView(onRetry: _reload);

        final sagas = snapshot.data ?? const [];
        if (sagas.isEmpty) {
          return const ClubEmptyState(
            icon: Icons.visibility_outlined,
            title: 'No tienes sagas ocultas',
            message:
                'Las sagas que ocultes aparecerán aquí para que puedas recuperarlas.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'Puedes volver a mostrar una saga cuando quieras. Tus libros nunca se eliminan al ocultarla.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            for (final saga in sagas)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ClubCard(
                  elevated: false,
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.visibility_off_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      saga.nombre.isEmpty ? 'Saga sin nombre' : saga.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text('Oculta en tu perfil'),
                    trailing: _restoringIds.contains(saga.id)
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton.icon(
                            onPressed: () => _restore(saga),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Mostrar'),
                          ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
