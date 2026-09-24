import 'package:flutter/material.dart';

import '../models/liga.dart';
import '../navigation/app_page_route.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/error_view.dart';
import 'liga_temporada_page.dart';

/// Histórico completo de temporadas cerradas de las Ligas de ClubReads, más
/// reciente primero. Cada temporada se puede abrir para ver su detalle.
class LigaHistorialPage extends StatefulWidget {
  const LigaHistorialPage({super.key});

  @override
  State<LigaHistorialPage> createState() => _LigaHistorialPageState();
}

class _LigaHistorialPageState extends State<LigaHistorialPage> {
  late Future<LigaHistorial> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<LigaHistorial> _cargar() async {
    final data = await ApiService().getLigaHistorial();
    return LigaHistorial.fromJson(data);
  }

  void _recargar() {
    setState(() => _future = _cargar());
  }

  void _abrirTemporada(int temporada) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => LigaTemporadaPage(temporada: temporada),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de temporadas')),
      body: FutureBuilder<LigaHistorial>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }
          final temporadas = snapshot.data!.temporadas;
          if (temporadas.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _recargar(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const Center(child: Text('📅', style: TextStyle(fontSize: 48))),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Aún no has completado ninguna temporada.\nCuando '
                    'cierre la primera, aparecerá aquí.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + MediaQuery.of(context).padding.bottom,
              ),
              itemCount: temporadas.length,
              itemBuilder: (context, index) => _TarjetaTemporada(
                temporada: temporadas[index],
                onTap: () => _abrirTemporada(temporadas[index].temporada),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaTemporada extends StatelessWidget {
  const _TarjetaTemporada({required this.temporada, required this.onTap});
  final LigaHistorialTemporada temporada;
  final VoidCallback onTap;

  String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: temporada.division.color.withValues(alpha: .16),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  temporada.division.icono,
                  style: const TextStyle(fontSize: 19),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Temporada ${temporada.temporada + 1}',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: temporada.division.color.withValues(
                              alpha: .16,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            temporada.division.etiqueta,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: temporada.division.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fecha(temporada.inicio)} – ${_fecha(temporada.fin)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${temporada.puesto} de ${temporada.totalParticipantes} '
                      '· ${temporada.puntos} pts',
                      style: AppTextStyles.bodySecondary,
                    ),
                    if (temporada.medallas.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          for (final m in temporada.medallas)
                            Tooltip(
                              message: m.tier.etiqueta,
                              child: Text(
                                m.tier.icono,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
