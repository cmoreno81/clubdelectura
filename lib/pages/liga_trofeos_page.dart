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
import 'perfil_usuario_page.dart';

/// Sala de Trofeos: ranking global de toda la comunidad por medallas de Liga
/// acumuladas (podios de temporada, ascensos, Diamante, constancia). Pensada
/// como una vitrina vistosa — el podio arriba, el resto en una lista — desde
/// la que se entra al perfil de cualquiera para curiosear su medallero
/// completo.
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

  void _abrirPerfil(LigaTrofeosFila fila) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => PerfilUsuarioPage(
          usuario: fila.nombre,
          profileUserId: fila.userId,
          initialTab: 'LOGROS',
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

          final podio = tabla.take(3).toList();
          final resto = tabla.skip(3).toList();

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
                if (podio.isNotEmpty) ...[
                  _Podio(filas: podio, onTap: _abrirPerfil),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (resto.isNotEmpty) ...[
                  Text(
                    'Clasificación general',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final fila in resto)
                    _FilaTrofeos(fila: fila, onTap: () => _abrirPerfil(fila)),
                ],
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

/// Podio con los 3 palmareses más vistosos — el 1º más alto y en el centro,
/// como un pódium físico.
class _Podio extends StatelessWidget {
  const _Podio({required this.filas, required this.onTap});
  final List<LigaTrofeosFila> filas;
  final void Function(LigaTrofeosFila) onTap;

  LigaTrofeosFila? _en(int puesto) =>
      filas.where((f) => f.puesto == puesto).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final primero = _en(1);
    final segundo = _en(2);
    final tercero = _en(3);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (segundo != null)
          Expanded(
            child: _PodioColumna(
              fila: segundo,
              alto: 96,
              color: const Color(0xFF9AA4B2),
              medalla: '🥈',
              onTap: () => onTap(segundo),
            ),
          ),
        const SizedBox(width: AppSpacing.sm),
        if (primero != null)
          Expanded(
            child: _PodioColumna(
              fila: primero,
              alto: 124,
              color: const Color(0xFFD5A94E),
              medalla: '🥇',
              onTap: () => onTap(primero),
              destacado: true,
            ),
          ),
        const SizedBox(width: AppSpacing.sm),
        if (tercero != null)
          Expanded(
            child: _PodioColumna(
              fila: tercero,
              alto: 80,
              color: const Color(0xFFA9714B),
              medalla: '🥉',
              onTap: () => onTap(tercero),
            ),
          ),
      ],
    );
  }
}

class _PodioColumna extends StatelessWidget {
  const _PodioColumna({
    required this.fila,
    required this.alto,
    required this.color,
    required this.medalla,
    required this.onTap,
    this.destacado = false,
  });

  final LigaTrofeosFila fila;
  final double alto;
  final Color color;
  final String medalla;
  final VoidCallback onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Column(
          children: [
            Text(medalla, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            ClubAvatar(
              nombre: fila.nombre,
              imageUrl: fila.avatarUrl,
              size: destacado ? 56 : 46,
            ),
            const SizedBox(height: 6),
            Text(
              fila.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              fila.total == 1 ? '1 trofeo' : '${fila.total} trofeos',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              height: alto,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .18),
                border: Border.all(color: color.withValues(alpha: .45)),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaTrofeos extends StatelessWidget {
  const _FilaTrofeos({required this.fila, required this.onTap});
  final LigaTrofeosFila fila;
  final VoidCallback onTap;

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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${fila.puesto}',
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
