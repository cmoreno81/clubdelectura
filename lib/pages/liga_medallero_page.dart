import 'package:flutter/material.dart';

import '../models/liga.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_empty_state.dart';
import '../widgets/error_view.dart';

/// Medallero de Liga de una participante: exclusivamente sus trofeos de Liga
/// (podios de temporada, ascensos, Diamante, constancia), sin mezclarlos con
/// los logros generales de la app. Se abre desde la Sala de Trofeos.
class LigaMedalleroPage extends StatefulWidget {
  const LigaMedalleroPage({
    super.key,
    required this.userId,
    required this.nombre,
    this.avatarUrl,
  });

  final String userId;
  final String nombre;
  final String? avatarUrl;

  @override
  State<LigaMedalleroPage> createState() => _LigaMedalleroPageState();
}

class _LigaMedalleroPageState extends State<LigaMedalleroPage> {
  late Future<LigaMedallero?> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<LigaMedallero?> _cargar() async {
    final data = await ApiService().getLigaMedallas(widget.userId);
    return LigaMedallero.fromJson(data);
  }

  void _recargar() => setState(() => _future = _cargar());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trofeos de ${widget.nombre.split(' ').first}')),
      body: FutureBuilder<LigaMedallero?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }
          final medallero = snapshot.data;
          final medallas = medallero?.medallas ?? const <LigaMedalla>[];

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
                Row(
                  children: [
                    ClubAvatar(
                      nombre: widget.nombre,
                      imageUrl: widget.avatarUrl,
                      size: 48,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nombre,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            medallas.isEmpty
                                ? 'Sin trofeos de Liga todavía'
                                : medallas.length == 1
                                ? '1 trofeo de Liga'
                                : '${medallas.length} trofeos de Liga',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (medallas.isEmpty)
                  const ClubEmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'Todavía sin trofeos',
                    message:
                        'Los trofeos de Liga aparecerán aquí al cerrar '
                        'temporadas y subir de división.',
                  )
                else ...[
                  if (medallero != null && medallero.resumen.isNotEmpty) ...[
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final tier in LigaMedallaTier.values)
                          if ((medallero.resumen[tier] ?? 0) > 0)
                            _ResumenTierChip(
                              tier: tier,
                              cantidad: medallero.resumen[tier]!,
                            ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  for (final medalla in medallas)
                    _MedallaTile(medalla: medalla),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ResumenTierChip extends StatelessWidget {
  const _ResumenTierChip({required this.tier, required this.cantidad});
  final LigaMedallaTier tier;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tier.etiqueta,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: tier.color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: tier.color.withValues(alpha: .3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tier.icono, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '×$cantidad',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: tier.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedallaTile extends StatelessWidget {
  const _MedallaTile({required this.medalla});
  final LigaMedalla medalla;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(medalla.tier.icono, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medalla.tier.etiqueta,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  medalla.streak != null
                      ? 'Racha de ${medalla.streak} temporadas seguidas'
                      : 'Temporada ${medalla.seasonNumber + 1} · '
                            '${medalla.division.icono} ${medalla.division.etiqueta}'
                            '${medalla.rank != null ? ' · #${medalla.rank}' : ''}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
