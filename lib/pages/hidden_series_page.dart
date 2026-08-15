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
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

class HiddenSeriesSection extends StatefulWidget {
  const HiddenSeriesSection({
    super.key,
    this.loadHiddenSeries,
    this.restoreSeries,
    this.onSeriesRestored,
  });

  final Future<List<SagaOculta>> Function()? loadHiddenSeries;
  final Future<void> Function(String sagaId)? restoreSeries;
  final VoidCallback? onSeriesRestored;

  @override
  State<HiddenSeriesSection> createState() => _HiddenSeriesSectionState();
}

class _HiddenSeriesSectionState extends State<HiddenSeriesSection> {
  late Future<List<SagaOculta>> _future;
  final Set<String> _restoringIds = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<SagaOculta>> _load() =>
      widget.loadHiddenSeries?.call() ?? ApiService().getSagasOcultas();

  Future<void> _reload() async {
    final next = _load();
    if (!mounted) return;
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _restore(SagaOculta saga) async {
    if (_restoringIds.contains(saga.id)) return;
    setState(() => _restoringIds.add(saga.id));
    try {
      await (widget.restoreSeries?.call(saga.id) ??
          ApiService().mostrarSaga(sagaId: saga.id));
      if (!mounted) return;
      widget.onSeriesRestored?.call();
      if (widget.onSeriesRestored == null) {
        SeriesRefreshNotifier.instance.invalidate();
      }
      final current = await _future;
      if (!mounted) return;
      setState(() {
        _future = Future.value(
          current.where((item) => item.id != saga.id).toList(growable: false),
        );
      });
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
          return const SizedBox(height: 360, child: CardListSkeleton(count: 3));
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
                'Ocultar una saga no elimina sus libros ni tu progreso.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            for (final saga in sagas)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ClubCard(
                  elevated: false,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
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
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _restoringIds.contains(saga.id)
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : TextButton.icon(
                                  onPressed: () => _restore(saga),
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('Volver a mostrar'),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class HiddenSeriesPage extends StatelessWidget {
  const HiddenSeriesPage({
    super.key,
    this.loadHiddenSeries,
    this.restoreSeries,
    this.onSeriesRestored,
    this.contentBuilder,
  });

  final Future<List<SagaOculta>> Function()? loadHiddenSeries;
  final Future<void> Function(String sagaId)? restoreSeries;
  final VoidCallback? onSeriesRestored;
  final Widget Function()? contentBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sagas ocultas')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child:
              contentBuilder?.call() ??
              HiddenSeriesSection(
                loadHiddenSeries: loadHiddenSeries,
                restoreSeries: restoreSeries,
                onSeriesRestored: onSeriesRestored,
              ),
        ),
      ),
    );
  }
}
