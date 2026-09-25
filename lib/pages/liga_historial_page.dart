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
import 'liga_temporada_page.dart';

/// Histórico de las Ligas de ClubReads, en dos pestañas: "Por temporadas"
/// (cada temporada cerrada, con su división y puesto) y "Acumulado" (el
/// ranking de todo el mundo sumando los puntos de todas sus temporadas).
class LigaHistorialPage extends StatefulWidget {
  const LigaHistorialPage({super.key});

  @override
  State<LigaHistorialPage> createState() => _LigaHistorialPageState();
}

class _LigaHistorialPageState extends State<LigaHistorialPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de ligas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Por temporadas'),
            Tab(text: 'Acumulado'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_TemporadasTab(), _AcumuladoTab()],
      ),
    );
  }
}

class _TemporadasTab extends StatefulWidget {
  const _TemporadasTab();

  @override
  State<_TemporadasTab> createState() => _TemporadasTabState();
}

class _TemporadasTabState extends State<_TemporadasTab> {
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
    return FutureBuilder<LigaHistorial>(
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
    );
  }
}

class _AcumuladoTab extends StatefulWidget {
  const _AcumuladoTab();

  @override
  State<_AcumuladoTab> createState() => _AcumuladoTabState();
}

class _AcumuladoTabState extends State<_AcumuladoTab> {
  late Future<LigaAcumulado> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<LigaAcumulado> _cargar() async {
    final data = await ApiService().getLigaAcumulado();
    return LigaAcumulado.fromJson(data);
  }

  void _recargar() {
    setState(() => _future = _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LigaAcumulado>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorView(onRetry: _recargar);
        }
        final tabla = snapshot.data!.tabla;
        if (tabla.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const SizedBox(height: AppSpacing.xl),
                const Center(child: Text('🏆', style: TextStyle(fontSize: 48))),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Todavía no hay ninguna temporada cerrada.\nEn cuanto '
                  'cierre la primera, aquí verás el acumulado de todo el mundo.',
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
            itemCount: tabla.length,
            itemBuilder: (context, index) => _FilaAcumulado(fila: tabla[index]),
          ),
        );
      },
    );
  }
}

class _FilaAcumulado extends StatelessWidget {
  const _FilaAcumulado({required this.fila});
  final LigaFila fila;

  String get _medalla => switch (fila.puesto) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final temporadas = fila.temporadasJugadas ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: fila.esTu
            ? AppColors.primary.withValues(alpha: .10)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: fila.esTu ? AppColors.primary : AppColors.border,
          width: fila.esTu ? 1.4 : 1,
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
                    fontWeight: fila.esTu ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                Text(
                  temporadas == 1
                      ? '1 temporada'
                      : '$temporadas temporadas',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
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
