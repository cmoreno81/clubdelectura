import 'package:flutter/material.dart';

import '../models/estadisticas_personales.dart';
import '../models/general_dashboard.dart';
import '../services/api_service.dart';
import '../services/general_dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/floating_nav_bar.dart' show kFloatingNavClearance;
import '../widgets/common/mapa_calor_widget.dart';
import 'dashboard_page.dart' show AchievementsClubCard, LogrosClubCard;

/// "Mis estadísticas": todo lo que es dato puro sobre tu lectura — mapa de
/// calor, métricas del año, ritmo de lectura, géneros, reto lector y logros,
/// y los superlativos del año (libro más largo, lectura más rápida).
/// Disponible tanto en el espacio personal como en cuentas de club, porque
/// son datos tuyos como lectora, no del club.
class MiEstadisticasPage extends StatefulWidget {
  const MiEstadisticasPage({super.key});

  @override
  State<MiEstadisticasPage> createState() => _MiEstadisticasPageState();
}

class _MiEstadisticasPageState extends State<MiEstadisticasPage> {
  late Future<_PageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PageData> _load() async {
    final results = await Future.wait([
      GeneralDashboardService().load(),
      ApiService()
          .getEstadisticasPersonales()
          .then(EstadisticasPersonales.fromJson),
    ]);
    return _PageData(
      dashboard: results[0] as GeneralDashboard,
      estadisticas: results[1] as EstadisticasPersonales,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis estadísticas')),
      body: FutureBuilder<_PageData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _ErrorView(
              onRetry: () => setState(() {
                _future = _load();
              }),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() {
              _future = _load();
            }),
            child: _Content(data: snapshot.data!),
          );
        },
      ),
    );
  }
}

class _PageData {
  const _PageData({required this.dashboard, required this.estadisticas});
  final GeneralDashboard dashboard;
  final EstadisticasPersonales estadisticas;
}

class _Content extends StatelessWidget {
  const _Content({required this.data});
  final _PageData data;

  @override
  Widget build(BuildContext context) {
    final summary = data.dashboard.summary;
    final ritmo = data.estadisticas.ritmo;
    final generos = data.estadisticas.generos;
    final formatos = data.estadisticas.formatos;
    final valoraciones = data.estadisticas.valoraciones;
    final comparativaAnual = data.estadisticas.comparativaAnual;
    final libroMasLargo = data.estadisticas.libroMasLargo;
    final lecturaMasRapida = data.estadisticas.lecturaMasRapida;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        kFloatingNavClearance,
      ),
      children: [
        const _EstadisticasHeroBanner(),
        const SizedBox(height: AppSpacing.lg),

        // ── Cuadrícula de métricas ───────────────────────────────────────
        _StatsGrid(summary: summary),
        const SizedBox(height: AppSpacing.lg),

        // ── Mapa de calor ────────────────────────────────────────────────
        const ClubCard(child: MapaCalorWidget()),
        const SizedBox(height: AppSpacing.lg),

        // ── Ritmo de lectura ─────────────────────────────────────────────
        _RitmoLecturaCard(ritmo: ritmo),
        const SizedBox(height: AppSpacing.md),

        // ── Géneros del año ──────────────────────────────────────────────
        if (generos.isNotEmpty) ...[
          _GenerosCard(generos: generos),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Comparativa año a año ─────────────────────────────────────────
        if (comparativaAnual != null) ...[
          _ComparativaAnualCard(comparativa: comparativaAnual),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Formato de lectura ────────────────────────────────────────────
        if (formatos.isNotEmpty) ...[
          _FormatosCard(formatos: formatos),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Distribución de valoraciones ──────────────────────────────────
        if (valoraciones.any((v) => v.cantidad > 0)) ...[
          _ValoracionesCard(valoraciones: valoraciones),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Reto lector + logros ─────────────────────────────────────────
        const LogrosClubCard(esPersonal: true),
        const SizedBox(height: AppSpacing.sm),
        const AchievementsClubCard(esPersonal: true),
        const SizedBox(height: AppSpacing.md),

        // ── Superlativos del año ─────────────────────────────────────────
        if (libroMasLargo != null || lecturaMasRapida != null)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (libroMasLargo != null)
                  Expanded(
                    child: _SuperlativoCard(
                      eyebrow: 'Libro más largo',
                      titulo: libroMasLargo.titulo,
                      icon: Icons.menu_book_rounded,
                      colors: const [Color(0xFF1F4D5C), Color(0xFF3E7C8C)],
                      detalle: libroMasLargo.paginas != null
                          ? '${libroMasLargo.paginas} páginas'
                          : null,
                    ),
                  ),
                if (libroMasLargo != null && lecturaMasRapida != null)
                  const SizedBox(width: AppSpacing.sm),
                if (lecturaMasRapida != null)
                  Expanded(
                    child: _SuperlativoCard(
                      eyebrow: 'Lectura más rápida',
                      titulo: lecturaMasRapida.titulo,
                      icon: Icons.bolt_rounded,
                      colors: const [Color(0xFF2F5C3D), Color(0xFF4E8A63)],
                      detalle: lecturaMasRapida.dias == 0
                          ? 'Terminado en 1 día'
                          : 'Terminado en ${lecturaMasRapida.dias} días',
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _EstadisticasHeroBanner
// ────────────────────────────────────────────────────────────────────────────

class _EstadisticasHeroBanner extends StatelessWidget {
  const _EstadisticasHeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            Color(0xFF7B3F8F),
            AppColors.inkCoral,
          ],
          stops: [0, .55, 1],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: .10,
              child: Icon(
                Icons.query_stats_rounded,
                size: 130,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_graph_rounded, color: Colors.white, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'TU AÑO EN DATOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: .6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Así ha sido tu año lector',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Constancia, ritmo, géneros favoritos y los libros que más '
                'te han marcado este año.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .80),
                  fontSize: 13.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _StatsGrid
// ────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});
  final GeneralSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2,
      children: [
        _StatCard(
          value: '${summary.reading}',
          label: 'Leyendo ahora',
          icon: Icons.menu_book_rounded,
          color: AppColors.info,
        ),
        _StatCard(
          value: '${summary.finished}',
          label: 'Terminados',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
        _StatCard(
          value: '${summary.finishedThisMonth}',
          label: 'Este mes',
          icon: Icons.bolt_rounded,
          color: AppColors.warning,
        ),
        _StatCard(
          value: '${summary.pagesRead}',
          label: 'Páginas leídas',
          icon: Icons.bookmark_rounded,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: .14),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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

// ────────────────────────────────────────────────────────────────────────────
// _RitmoLecturaCard
// ────────────────────────────────────────────────────────────────────────────

class _RitmoLecturaCard extends StatefulWidget {
  const _RitmoLecturaCard({required this.ritmo});
  final RitmoLectura ritmo;

  @override
  State<_RitmoLecturaCard> createState() => _RitmoLecturaCardState();
}

const _mesesCortos = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String _diaMesCorto(DateTime d) => '${d.day} ${_mesesCortos[d.month - 1]}';

class _RitmoLecturaCardState extends State<_RitmoLecturaCard> {
  int? _seleccionada;

  @override
  Widget build(BuildContext context) {
    final ritmo = widget.ritmo;
    final maxVal = ritmo.serie.isEmpty
        ? 1
        : ritmo.serie.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    final variacion = ritmo.variacionPct;
    final seleccionada = _seleccionada;
    final tieneFechas = ritmo.semanaInicio.length == ritmo.serie.length;

    return ClubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu ritmo de lectura',
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (variacion != null)
                Text(
                  '${variacion >= 0 ? '▲' : '▼'} ${variacion.abs()}% vs. mes pasado',
                  style: AppTextStyles.caption.copyWith(
                    color: variacion >= 0 ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (tieneFechas)
            Text(
              'Últimas 12 semanas · del ${_diaMesCorto(ritmo.semanaInicio.first)} '
              'al ${_diaMesCorto(ritmo.semanaInicio.last.add(const Duration(days: 6)))}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          const SizedBox(height: AppSpacing.md),
          if (ritmo.serie.isNotEmpty) ...[
            SizedBox(
              height: 18,
              child: seleccionada == null
                  ? null
                  : Text(
                      tieneFechas
                          ? '${ritmo.serie[seleccionada]} pág. · semana del '
                                '${_diaMesCorto(ritmo.semanaInicio[seleccionada])}'
                          : '${ritmo.serie[seleccionada]} pág. esa semana',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < ritmo.serie.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(
                          () => _seleccionada = seleccionada == i ? null : i,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FractionallySizedBox(
                            heightFactor: ritmo.serie[i] / maxVal,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: i == seleccionada
                                    ? AppColors.inkCoral
                                    : i == ritmo.serie.length - 1
                                    ? AppColors.primary
                                    : AppColors.primaryLight,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (tieneFechas) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _diaMesCorto(ritmo.semanaInicio.first),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _diaMesCorto(ritmo.semanaInicio.last),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Media de ${ritmo.paginasPorDiaMes.toStringAsFixed(0)} páginas al día este mes',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _GenerosCard
// ────────────────────────────────────────────────────────────────────────────

class _GenerosCard extends StatelessWidget {
  const _GenerosCard({required this.generos});
  final List<GeneroLectura> generos;

  static const _colores = [AppColors.primary, AppColors.gold, AppColors.info];

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tus géneros de ${DateTime.now().year}',
            style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < generos.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      generos[i].nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: generos[i].porcentaje / 100,
                        minHeight: 8,
                        backgroundColor: AppColors.background,
                        color: _colores[i % _colores.length],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${generos[i].porcentaje}%',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
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

// ────────────────────────────────────────────────────────────────────────────
// _ComparativaAnualCard
// ────────────────────────────────────────────────────────────────────────────

class _ComparativaAnualCard extends StatelessWidget {
  const _ComparativaAnualCard({required this.comparativa});
  final ComparativaAnual comparativa;

  @override
  Widget build(BuildContext context) {
    final actual = comparativa.actual;
    final anterior = comparativa.anterior;
    final librosDelta = actual.libros - anterior.libros;
    final paginasDelta = actual.paginas - anterior.paginas;

    return ClubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${actual.anio} vs. ${anterior.anio}',
            style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ComparativaColumna(
                  eyebrow: 'Libros',
                  actual: actual.libros,
                  anterior: anterior.libros,
                  delta: librosDelta,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ComparativaColumna(
                  eyebrow: 'Páginas',
                  actual: actual.paginas,
                  anterior: anterior.paginas,
                  delta: paginasDelta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparativaColumna extends StatelessWidget {
  const _ComparativaColumna({
    required this.eyebrow,
    required this.actual,
    required this.anterior,
    required this.delta,
  });

  final String eyebrow;
  final int actual;
  final int anterior;
  final int delta;

  @override
  Widget build(BuildContext context) {
    final subiendo = delta > 0;
    final igual = delta == 0;
    final color = igual
        ? AppColors.textMuted
        : (subiendo ? AppColors.success : AppColors.danger);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$actual',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!igual)
              Icon(
                subiendo ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: color,
              ),
            Text(
              igual
                  ? 'Igual que en $anterior'
                  : '${delta.abs()} vs. $anterior',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _FormatosCard
// ────────────────────────────────────────────────────────────────────────────

class _FormatosCard extends StatelessWidget {
  const _FormatosCard({required this.formatos});
  final List<FormatoLectura> formatos;

  static const _iconos = {
    'Físico': Icons.menu_book_rounded,
    'Digital': Icons.tablet_mac_rounded,
    'Audiolibro': Icons.headphones_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final total = formatos.fold<int>(0, (sum, f) => sum + f.cantidad);

    return ClubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cómo lees',
            style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final formato in formatos)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    _iconos[formato.formato] ?? Icons.book_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 80,
                    child: Text(formato.formato, style: AppTextStyles.body),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? formato.cantidad / total : 0,
                        minHeight: 8,
                        backgroundColor: AppColors.background,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${formato.cantidad}',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
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

// ────────────────────────────────────────────────────────────────────────────
// _ValoracionesCard
// ────────────────────────────────────────────────────────────────────────────

class _ValoracionesCard extends StatelessWidget {
  const _ValoracionesCard({required this.valoraciones});
  final List<ValoracionLectura> valoraciones;

  @override
  Widget build(BuildContext context) {
    final maxCantidad = valoraciones.fold<int>(
      1,
      (max, v) => v.cantidad > max ? v.cantidad : max,
    );

    return ClubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tus valoraciones',
            style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final valoracion in valoraciones)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${valoracion.estrellas} ★',
                      style: AppTextStyles.body,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: valoracion.cantidad / maxCantidad,
                        minHeight: 8,
                        backgroundColor: AppColors.background,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${valoracion.cantidad}',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
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

// ────────────────────────────────────────────────────────────────────────────
// _SuperlativoCard
// ────────────────────────────────────────────────────────────────────────────

class _SuperlativoCard extends StatelessWidget {
  const _SuperlativoCard({
    required this.eyebrow,
    required this.titulo,
    required this.icon,
    required this.colors,
    this.detalle,
  });

  final String eyebrow;
  final String titulo;
  final String? detalle;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 2),
            Text(
              detalle!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _ErrorView
// ────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('No pudimos cargar tus estadísticas.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
