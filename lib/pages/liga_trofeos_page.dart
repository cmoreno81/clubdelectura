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
///
/// Cuando ya se ha otorgado el "Libro de Oro" (1ª del Acumulado a 31 de
/// diciembre), su vitrina aparece destacada arriba del todo: es un premio
/// único, así que se ve sin tener que entrar en el perfil de nadie.
class LigaTrofeosPage extends StatefulWidget {
  const LigaTrofeosPage({super.key});

  @override
  State<LigaTrofeosPage> createState() => _LigaTrofeosPageState();
}

class _LigaTrofeosPageState extends State<LigaTrofeosPage> {
  late Future<_TrofeosData> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<_TrofeosData> _cargar() async {
    final results = await Future.wait([
      ApiService().getLigaSalaTrofeos(),
      ApiService().getLigaLibroDeOro(),
    ]);
    return _TrofeosData(
      sala: LigaSalaTrofeos.fromJson(results[0]),
      libroDeOro: LigaLibroDeOro.fromJson(results[1]),
    );
  }

  void _recargar() => setState(() => _future = _cargar());

  void _abrirMedallero({
    required String userId,
    required String nombre,
    String? avatarUrl,
  }) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => LigaMedalleroPage(
          userId: userId,
          nombre: nombre,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sala de Trofeos')),
      body: FutureBuilder<_TrofeosData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }
          final data = snapshot.data;
          final tabla = data?.sala?.tabla ?? const <LigaTrofeosFila>[];
          final libroDeOro = data?.libroDeOro;

          if (tabla.isEmpty && libroDeOro == null) {
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
                if (libroDeOro != null) ...[
                  _VitrinaLibroDeOro(
                    premio: libroDeOro,
                    onTap: () => _abrirMedallero(
                      userId: libroDeOro.userId,
                      nombre: libroDeOro.nombre,
                      avatarUrl: libroDeOro.avatarUrl,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _CabeceraSala(
                  totalParticipantes: data?.sala?.totalParticipantes ?? tabla.length,
                ),
                const SizedBox(height: AppSpacing.sm),
                const _LeyendaTrofeos(),
                const SizedBox(height: AppSpacing.lg),
                for (final fila in tabla)
                  _FilaTrofeos(
                    fila: fila,
                    onTap: () => _abrirMedallero(
                      userId: fila.userId,
                      nombre: fila.nombre,
                      avatarUrl: fila.avatarUrl,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrofeosData {
  const _TrofeosData({required this.sala, required this.libroDeOro});
  final LigaSalaTrofeos? sala;
  final LigaLibroDeOro? libroDeOro;
}

/// Vitrina del Libro de Oro — un premio único y permanente, con la misma
/// presencia de un trofeo físico grabado: nunca se entra en un perfil para
/// verlo, está aquí arriba a la vista de todo el mundo.
class _VitrinaLibroDeOro extends StatelessWidget {
  const _VitrinaLibroDeOro({required this.premio, required this.onTap});
  final LigaLibroDeOro premio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const RadialGradient(
              center: Alignment(0, -0.7),
              radius: 1.3,
              colors: [Color(0xFF3A2A5C), Color(0xFF221733), Color(0xFF170F22)],
              stops: [0, 0.55, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF140A23).withValues(alpha: .35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              // Cinta "PREMIO ANUAL · año"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF3D48A), Color(0xFFC9962F)],
                  ),
                ),
                child: Text(
                  '✦  PREMIO ANUAL · ${premio.year}  ✦',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: Color(0xFF3A2405),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Trofeo
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFCE7A8), Color(0xFFE7B84D), Color(0xFFA9721E)],
                ).createShader(bounds),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 84,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Libro de Oro',
                style: TextStyle(
                  color: Color(0xFFF6E9C9),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '1ª del Acumulado a 31 de diciembre',
                style: TextStyle(
                  color: const Color(0xFFF6E9C9).withValues(alpha: .7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              // Placa grabada con el nombre
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE7C877), Color(0xFFB4872C)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'GANADORA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: const Color(0xFF4A3308).withValues(alpha: .75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClubAvatar(
                          nombre: premio.nombre,
                          imageUrl: premio.avatarUrl,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            premio.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5,
                              color: Color(0xFF2E1F05),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${premio.puntos} pts acumulados',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A3308).withValues(alpha: .8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Único e irrepetible — queda grabado para siempre',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFF6E9C9).withValues(alpha: .55),
                ),
              ),
            ],
          ),
        ),
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

/// Leyenda plegable con todos los trofeos que se pueden conseguir: el Libro
/// de Oro (único, se explica aparte) más las medallas de Liga normales, con
/// icono y cómo se consiguen — para entender de un vistazo lo que se ve en
/// esta lista antes de entrar en el medallero de cada una.
class _LeyendaTrofeos extends StatefulWidget {
  const _LeyendaTrofeos();

  @override
  State<_LeyendaTrofeos> createState() => _LeyendaTrofeosState();
}

class _LeyendaTrofeosState extends State<_LeyendaTrofeos> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => setState(() => _abierta = !_abierta),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Qué trofeos se pueden ganar',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _abierta ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_abierta)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilaLeyenda(
                    icono: const Text('🏆', style: TextStyle(fontSize: 15)),
                    color: const Color(0xFFD9A441),
                    titulo: 'Libro de Oro',
                    descripcion:
                        'Premio anual único: ser 1ª del ranking Acumulado '
                        'el 31 de diciembre.',
                  ),
                  // De más fácil a más difícil de conseguir — Plata y
                  // Bronce se explican junto al Oro, así que no llevan fila
                  // propia.
                  for (final tier in const [
                    LigaMedallaTier.ascenso,
                    LigaMedallaTier.podioOro,
                    LigaMedallaTier.remontada,
                    LigaMedallaTier.rachaPerfecta,
                    LigaMedallaTier.constancia,
                    LigaMedallaTier.libroDelAnio,
                    LigaMedallaTier.polifacetica,
                    LigaMedallaTier.diamante,
                    LigaMedallaTier.bicampeona,
                    LigaMedallaTier.hattrick,
                  ])
                    _FilaLeyenda(
                      icono: Text(
                        tier.icono,
                        style: const TextStyle(fontSize: 15),
                      ),
                      color: tier.color,
                      titulo: tier == LigaMedallaTier.podioOro
                          ? '1ª / 2ª / 3ª de tu división'
                          : tier.etiqueta,
                      descripcion: tier == LigaMedallaTier.podioOro
                          ? 'Podio de tu división al cerrar una temporada — '
                                'pesa más cuanto más alta sea la división.'
                          : tier.descripcion,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaLeyenda extends StatelessWidget {
  const _FilaLeyenda({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.descripcion,
  });

  final Widget icono;
  final Color color;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
            child: icono,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  descripcion,
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
