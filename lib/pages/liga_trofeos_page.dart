import 'package:flutter/material.dart';

import '../models/liga.dart';
import '../navigation/app_page_route.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/error_view.dart';
import 'liga_medallero_page.dart';

/// Sala de Trofeos: ranking global de toda la comunidad por medallas de Liga
/// acumuladas (podios de temporada, ascensos, Diamante, constancia). Un
/// listado simple, ordenado por palmarés — al tocar cualquiera se entra en
/// su medallero de Liga, sin mezclarlo con los logros generales.
class LigaTrofeosPage extends StatefulWidget {
  const LigaTrofeosPage({super.key});

  @override
  State<LigaTrofeosPage> createState() => _LigaTrofeosPageState();
}

class _LigaTrofeosPageState extends State<LigaTrofeosPage> {
  late Future<LigaSalaTrofeos?> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<LigaSalaTrofeos?> _cargar() async {
    final data = await ApiService().getLigaSalaTrofeos();
    return LigaSalaTrofeos.fromJson(data);
  }

  void _recargar() => setState(() => _future = _cargar());

  void _abrirMedallero(LigaTrofeosFila fila) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => LigaMedalleroPage(
          userId: fila.userId,
          nombre: fila.nombre,
          avatarUrl: fila.avatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sala de Trofeos')),
      body: FutureBuilder<LigaSalaTrofeos?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }
          final sala = snapshot.data;
          final tabla = sala?.tabla ?? const <LigaTrofeosFila>[];
          if (tabla.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _recargar(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 48)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Todavía no hay medallas en juego.\nEn cuanto cierre la '
                    'primera temporada, aquí brillará el palmarés de todo el '
                    'mundo.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
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
                _CabeceraSala(totalParticipantes: sala?.totalParticipantes ?? tabla.length),
                const SizedBox(height: AppSpacing.lg),
                for (final fila in tabla)
                  _FilaTrofeos(fila: fila, onTap: () => _abrirMedallero(fila)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CabeceraSala extends StatelessWidget {
  const _CabeceraSala({required this.totalParticipantes});
  final int totalParticipantes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A2E7A), Color(0xFF7C5CBF), Color(0xFFD9A441)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sala de Trofeos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalParticipantes == 1
                      ? '1 lectora con medallas de Liga'
                      : '$totalParticipantes lectoras con medallas de Liga',
                  style: TextStyle(color: Colors.white.withValues(alpha: .85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaTrofeos extends StatelessWidget {
  const _FilaTrofeos({required this.fila, required this.onTap});
  final LigaTrofeosFila fila;
  final VoidCallback onTap;

  String get _medalla => switch (fila.puesto) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final tiersOrdenados = LigaMedallaTier.values
        .where((tier) => (fila.resumen[tier] ?? 0) > 0)
        .toList();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: fila.puesto <= 3
                ? const Color(0xFFD9A441).withValues(alpha: .08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: fila.puesto <= 3
                  ? const Color(0xFFD9A441).withValues(alpha: .35)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  _medalla.isNotEmpty ? _medalla : '${fila.puesto}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ClubAvatar(nombre: fila.nombre, imageUrl: fila.avatarUrl, size: 34),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fila.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (tiersOrdenados.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: [
                          for (final tier in tiersOrdenados)
                            Text(
                              '${tier.icono}×${fila.resumen[tier]}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${fila.total}',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
