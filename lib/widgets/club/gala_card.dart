import 'dart:math' show sin, pi;

import 'package:flutter/material.dart';

import '../../models/dashboard.dart';
import '../../navigation/book_detail_navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_avatar.dart';
import '../common/club_chip.dart';
import '../common/club_book_cover.dart';

class GalaCard extends StatefulWidget {
  final Dashboard dashboard;

  const GalaCard({super.key, required this.dashboard});

  @override
  State<GalaCard> createState() => _GalaCardState();
}

class _GalaCardState extends State<GalaCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, .06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scaleAnim = Tween<double>(
      begin: .92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.dashboard.clubvision;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero: portada grande con fondo degradado ──
            ScaleTransition(
              scale: _scaleAnim,
              child: _HeroCover(club: club),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Datos del libro ──
            _InfoCard(club: club),

            const SizedBox(height: AppSpacing.lg),

            // ── Lectoras previas ──
            if (club.lectoras.isNotEmpty || true) _LectorasPrevias(club: club),

            const SizedBox(height: AppSpacing.lg),

            // ── Mensaje + botón ficha ──
            _MensajeYAccion(club: club),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Hero con portada grande
// ─────────────────────────────────────────────

class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.club});
  final Clubvision club;

  @override
  Widget build(BuildContext context) {
    final hasCover = club.ganadorCoverUrl.isNotEmpty;

    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B69), Color(0xFF6B3FA0), Color(0xFFB4780A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D1B69).withValues(alpha: .35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Confeti / partículas decorativas
          const Positioned.fill(child: _Confetti()),

          // Portada centrada con sombra
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                if (hasCover)
                  ClubBookCover(
                    title: club.ganador,
                    imageUrl: club.ganadorCoverUrl,
                    width: 130,
                    height: 190,
                    borderRadius: BorderRadius.circular(12),
                    showShadow: true,
                  )
                else
                  Container(
                    width: 130,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: .55),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFD700),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ganadora de Clubvisión',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────
// Info card del libro
// ─────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.club});
  final Clubvision club;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF0), Color(0xFFFFF4D8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1E2B3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB48113).withValues(alpha: .10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            club.ganador,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 26, height: 1.15),
          ),
          if (club.mensaje.isNotEmpty &&
              !club.mensaje.contains(club.ganador)) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              club.mensaje,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(
                color: const Color(0xFFB48113),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Elegida por el club',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Lectoras previas
// ─────────────────────────────────────────────

class _LectorasPrevias extends StatelessWidget {
  const _LectorasPrevias({required this.club});
  final Clubvision club;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            club.lectoras.isEmpty
                ? '✨ Estreno para todo el club'
                : '👀 Ya lo habían leído',
            style: AppTextStyles.section.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            club.lectoras.isEmpty
                ? 'Será la primera vez que el club lee esta historia juntas.'
                : 'Estas lectoras podrán compartir su experiencia.',
            style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
          ),
          if (club.lectoras.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: club.lectoras
                  .map(
                    (nombre) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClubAvatar(nombre: nombre, size: 54),
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          width: 72,
                          child: Text(
                            nombre,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Mensaje final + botón ficha del libro
// ─────────────────────────────────────────────

class _MensajeYAccion extends StatelessWidget {
  const _MensajeYAccion({required this.club});
  final Clubvision club;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8F3FF), Color(0xFFF1E8FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Empieza una nueva aventura',
            textAlign: TextAlign.center,
            style: AppTextStyles.section,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'A partir de ahora, las conversaciones del club girarán alrededor de esta historia. Disfrútala con el resto de lectoras.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.xl),
          // Botón a la ficha del libro (no "Comenzar lectura")
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: () => openBookDetail(
              context,
              title: club.ganador,
              coverUrl: club.ganadorCoverUrl,
            ),
            icon: const Icon(Icons.menu_book_outlined, color: Colors.white),
            label: const Text(
              'Ver ficha del libro',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Confeti decorativo (partículas animadas)
// ─────────────────────────────────────────────

class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_ctrl.value)),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static final _pieces = List.generate(28, (i) {
    final rng = (i * 137.508) % 1.0;
    return (
      x: rng,
      speed: 0.12 + (i % 5) * 0.03,
      size: 4.0 + (i % 4) * 2.5,
      color: [
        const Color(0xFFFFD700),
        const Color(0xFFFF6B9D),
        const Color(0xFF7FDBFF),
        const Color(0xFFFFFFFF),
        const Color(0xFFB4FF9F),
      ][i % 5],
      phase: (i * 0.37) % 1.0,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pieces) {
      final y = ((t * p.speed + p.phase) % 1.0) * (size.height + 20) - 10;
      final x = p.x * size.width + sin((t + p.phase) * 2 * pi) * 18;
      final paint = Paint()
        ..color = p.color.withValues(alpha: .65)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
