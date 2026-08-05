import 'dart:math';
import 'package:club_lectura_app/pages/clubvision_gala_page.dart';
import 'package:club_lectura_app/pages/clubvision_menu_page.dart';
import 'package:flutter/material.dart';

import '../../navigation/app_page_route.dart';
import '../../models/dashboard.dart';
import '../../models/estado_club.dart';
import '../../pages/clubvision_votacion_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_button.dart';
import '../common/club_card.dart';
import '../common/club_chip.dart';
import 'director_escenas.dart';

class ClubvisionCard extends StatelessWidget {
  final Dashboard dashboard;
  final EstadoClub estadoClub;
  final bool haVotado;
  final Future<void> Function() onActualizar;

  const ClubvisionCard({
    super.key,
    required this.dashboard,
    required this.estadoClub,
    required this.haVotado,
    required this.onActualizar,
  });

  bool get _mostrarFlecha {
    final estado = dashboard.clubvision.estado.toUpperCase();

    return estado == 'VOTACION' || estado == 'RESULTADOS';
  }

  bool get _esInteractiva {
    final estado = dashboard.clubvision.estado.toUpperCase();
    return estado == 'VOTACION' ||
        estado == 'RESULTADOS' ||
        estado == 'LECTURA' ||
        estado == 'ULTIMAS_HORAS';
  }

  Future<void> _abrirClubvision(BuildContext context) async {
    final esGala = dashboard.clubvision.estado == 'RESULTADOS';
    await Navigator.push(
      context,
      AppPageRoute(
        builder: (_) =>
            esGala ? const ClubvisionGalaPage() : const ClubvisionMenuPage(),
      ),
    );
    await onActualizar();
  }

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      padding: EdgeInsets.zero,
      borderColor: estadoClub.iconColor.withValues(alpha: 0.18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          estadoClub.color,
          Color.lerp(estadoClub.color, AppColors.surface, 0.55) ??
              estadoClub.color,
        ],
      ),
      onTap: _esInteractiva ? () => _abrirClubvision(context) : null,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _cabecera(),

                const SizedBox(height: AppSpacing.lg),

                DirectorEscenas().construir(
                  estado: estadoClub,
                  dashboard: dashboard,
                ),

                if (estadoClub.permiteVotar) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _bloqueVotacion(context),
                ],

                if (estadoClub.mostrarGanador) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _bloqueGanador(),
                ],
              ],
            ),
          ),

          if (_mostrarFlecha)
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cabecera() {
    if (estadoClub.estado == EstadoClubTipo.lectura) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LECTURA OFICIAL',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  estadoClub.titulo,
                  style: AppTextStyles.section.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  estadoClub.mensaje,
                  style: AppTextStyles.bodySecondary.copyWith(height: 1.3),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Icon(estadoClub.icono, size: 34, color: estadoClub.iconColor),
        ),

        const SizedBox(height: AppSpacing.md),

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _mostrarFlecha ? AppSpacing.xl : 0,
          ),
          child: Text(
            estadoClub.titulo,
            textAlign: TextAlign.center,
            style: AppTextStyles.section.copyWith(fontWeight: FontWeight.w700),
          ),
        ),

        if (estadoClub.mensaje.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),

          Text(
            estadoClub.mensaje,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ],
    );
  }

  Widget _bloqueVotacion(BuildContext context) {
    final total = dashboard.clubvision.totalUsuarios;
    final recibidos = dashboard.clubvision.votosRecibidos;

    final progreso = total == 0 ? 0.0 : recibidos / total;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progreso.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.7),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ClubChip(
              label: '$recibidos votos',
              icon: Icons.how_to_vote_outlined,
              variant: ClubChipVariant.primary,
            ),
            ClubChip(
              label: '${dashboard.clubvision.votosPendientes} pendientes',
              icon: Icons.schedule_rounded,
              variant: ClubChipVariant.warning,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        if (!haVotado)
          ClubButton(
            label: 'Votar ahora',
            icon: Icons.how_to_vote_rounded,
            onPressed: () async {
              final actualizado = await Navigator.push<bool>(
                context,
                AppPageRoute(
                  builder: (_) => ClubvisionVotacionPage(
                    idVotacion: dashboard.clubvision.idVotacion,
                  ),
                ),
              );

              if (actualizado == true) {
                await onActualizar();
              }
            },
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 34,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Tu voto ya forma parte de esta historia',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Ahora solo queda esperar al desenlace.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _bloqueGanador() {
    final esResultados = dashboard.clubvision.estado == 'RESULTADOS';

    if (esResultados) return const _GalaResultadosCard();

    // ── Estado LECTURA: muestra actividad del club ──
    return Column(
      children: [
        if (dashboard.clubvision.estado == 'LECTURA' &&
            dashboard.clubvision.comentarios > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ClubChip(
                      label: '${dashboard.clubvision.comentarios} comentarios',
                      icon: Icons.chat_bubble_outline_rounded,
                      variant: ClubChipVariant.primary,
                    ),
                    ClubChip(
                      label: '${dashboard.clubvision.likes}',
                      icon: Icons.favorite_border_rounded,
                      variant: ClubChipVariant.danger,
                    ),
                  ],
                ),

                if (dashboard.clubvision.ultimaActividad.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    dashboard.clubvision.ultimaActividad,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),
        ],

        ClubChip(
          label: dashboard.clubvision.lectoras.isEmpty
              ? 'Estreno para todo el club'
              : 'Ya leído por ${dashboard.clubvision.lectoras.length}',
          icon: dashboard.clubvision.lectoras.isEmpty
              ? Icons.auto_awesome_rounded
              : Icons.star_outline_rounded,
          variant: ClubChipVariant.warning,
        ),

        if (dashboard.clubvision.lectoras.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),

          Text(
            dashboard.clubvision.lectoras.join(' · '),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Card animada para el estado RESULTADOS (Gala)
// ─────────────────────────────────────────────

class _GalaResultadosCard extends StatefulWidget {
  const _GalaResultadosCard();

  @override
  State<_GalaResultadosCard> createState() => _GalaResultadosCardState();
}

class _GalaResultadosCardState extends State<_GalaResultadosCard>
    with TickerProviderStateMixin {
  // Fade + slide de entrada del contenido
  late final AnimationController _entrada;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Pulso continuo del botón
  late final AnimationController _pulso;
  late final Animation<double> _escala;

  // Estrellas parpadeantes
  late final AnimationController _estrellas;

  @override
  void initState() {
    super.initState();

    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fade = CurvedAnimation(parent: _entrada, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, .12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrada, curve: Curves.easeOutCubic));

    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _escala = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulso, curve: Curves.easeInOut));

    _estrellas = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _entrada.dispose();
    _pulso.dispose();
    _estrellas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D2800), Color(0xFF7A5A00), Color(0xFFB48113)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB48113).withValues(alpha: .35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              children: [
                // Partículas de fondo
                Positioned.fill(child: _StarField(controller: _estrellas)),

                // Contenido
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Trofeo
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFFFFD700),
                          size: 34,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      const Text(
                        'Ya tenemos ganadora',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Entra a la Gala para descubrir el libro\nelegido y ver cómo votó cada lectora.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .82),
                          fontSize: 13,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Botón pulsante
                      ScaleTransition(
                        scale: _escala,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFD700,
                                ).withValues(alpha: .5),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF3D2800),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ver la ganadora →',
                                style: TextStyle(
                                  color: Color(0xFF3D2800),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Pequeñas estrellas/destellos animados en el fondo
class _StarField extends StatelessWidget {
  const _StarField({required this.controller});
  final AnimationController controller;

  static final _stars = List.generate(18, (i) {
    final rng = Random(i * 7 + 3);
    return (
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 1.5 + rng.nextDouble() * 2.5,
      phase: rng.nextDouble(),
    );
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) =>
          CustomPaint(painter: _StarPainter(controller.value, _stars)),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.t, this.stars);
  final double t;
  final List<({double x, double y, double size, double phase})> stars;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      // cada estrella parpadea con su propio desfase
      final brightness = (sin((t + s.phase) * 2 * pi) * .5 + .5);
      final paint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: brightness * .6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}
