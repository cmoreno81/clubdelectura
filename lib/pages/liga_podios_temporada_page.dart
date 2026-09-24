import 'package:flutter/material.dart';

import '../models/liga.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/error_view.dart';

/// Podio (top 3) de CADA división en una temporada ya cerrada de las Ligas
/// de ClubReads — como ver de un vistazo quién ganó en 1ª, 2ª, 3ª división...
/// de una liga de fútbol, en vez de solo la tabla de tu propia división.
class LigaPodiosTemporadaPage extends StatefulWidget {
  const LigaPodiosTemporadaPage({super.key, required this.temporada});

  /// Nº de la temporada a mostrar (ver `numero`/`temporada` en el backend).
  final int temporada;

  @override
  State<LigaPodiosTemporadaPage> createState() =>
      _LigaPodiosTemporadaPageState();
}

class _LigaPodiosTemporadaPageState extends State<LigaPodiosTemporadaPage> {
  late Future<LigaPodiosTemporada> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<LigaPodiosTemporada> _cargar() async {
    final data = await ApiService().getLigaPodiosTemporada(widget.temporada);
    return LigaPodiosTemporada.fromJson(data);
  }

  void _recargar() {
    setState(() => _future = _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Podios · Temporada ${widget.temporada + 1}')),
      body: FutureBuilder<LigaPodiosTemporada>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (snapshot.hasError || data == null || !data.ok) {
            return ErrorView(
              mensaje: data?.mensaje,
              onRetry: _recargar,
            );
          }
          if (data.divisiones.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No hay datos de podio para esta temporada.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                Text(
                  'Campeonas de cada división, de arriba abajo — como en '
                  'una liga de fútbol, cada división tiene su propio podio.',
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final d in data.divisiones.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _PodioDivisionCard(podioDivision: d),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PodioDivisionCard extends StatelessWidget {
  const _PodioDivisionCard({required this.podioDivision});
  final LigaPodioDivision podioDivision;

  @override
  Widget build(BuildContext context) {
    final division = podioDivision.division;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: division.color.withValues(alpha: .12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Text(division.icono, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    division.etiqueta,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: division.color,
                    ),
                  ),
                ),
                Text(
                  '${podioDivision.totalParticipantes} participantes',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                for (final fila in podioDivision.podio)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _FilaPodio(fila: fila),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaPodio extends StatelessWidget {
  const _FilaPodio({required this.fila});
  final LigaFila fila;

  String get _medalla => switch (fila.puesto) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '${fila.puesto}',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: fila.puesto == 1
            ? AppColors.primary.withValues(alpha: .06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(_medalla, style: const TextStyle(fontSize: 16)),
          ),
          ClubAvatar(nombre: fila.nombre, imageUrl: fila.avatarUrl, size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              fila.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontWeight: fila.puesto == 1 ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${fila.puntos}',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          Text(
            ' pts',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
