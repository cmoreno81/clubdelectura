import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

// ── Colores del confeti en la paleta de ClubReaders ──────────────────────────

const _confettiColors = [
  AppColors.primary,       // morado
  AppColors.primaryDark,   // morado oscuro
  AppColors.gold,          // dorado
  AppColors.blush,         // rosa suave
  AppColors.success,       // verde salvia
  Color(0xFFF2C94C),       // amarillo cálido
];

// ── Partícula ─────────────────────────────────────────────────────────────────

class _Particle {
  _Particle({
    required this.color,
    required this.x,
    required this.speedX,
    required this.speedY,
    required this.angle,
    required this.angularVelocity,
    required this.size,
    required this.shape, // 0 rect, 1 circle, 2 ribbon
  });

  final Color color;
  final int shape;
  double x;
  double y = -0.05;
  final double speedX;
  final double speedY;
  double angle;
  final double angularVelocity;
  final double size;

  void update(double dt) {
    x += speedX * dt;
    y += speedY * dt;
    angle += angularVelocity * dt;
  }

  bool get isOffScreen => y > 1.1;
}

List<_Particle> _buildParticles(int count) {
  final rng = math.Random();
  return List.generate(count, (i) {
    final color = _confettiColors[rng.nextInt(_confettiColors.length)];
    return _Particle(
      color: color,
      x: rng.nextDouble(),
      speedX: (rng.nextDouble() - 0.5) * 0.15,
      speedY: 0.18 + rng.nextDouble() * 0.22,
      angle: rng.nextDouble() * math.pi * 2,
      angularVelocity: (rng.nextDouble() - 0.5) * 6,
      size: 6 + rng.nextDouble() * 9,
      shape: rng.nextInt(3),
    );
  });
}

// ── Painter ──────────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles);

  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final px = p.x * size.width;
      final py = p.y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.angle);

      paint.color = p.color.withValues(alpha: 0.88);

      switch (p.shape) {
        case 0: // rectángulo
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55,
            ),
            paint,
          );
        case 1: // círculo
          canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
        default: // ribbon
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size * 1.4,
                height: p.size * 0.3,
              ),
              const Radius.circular(2),
            ),
            paint,
          );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ── Widget principal ──────────────────────────────────────────────────────────

class LibroFinalizadoCelebration extends StatefulWidget {
  const LibroFinalizadoCelebration({
    super.key,
    required this.titulo,
    required this.coverUrl,
  });

  final String titulo;
  final String coverUrl;

  @override
  State<LibroFinalizadoCelebration> createState() =>
      _LibroFinalizadoCelebrationState();
}

class _LibroFinalizadoCelebrationState
    extends State<LibroFinalizadoCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _contentCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  final List<_Particle> _particles = _buildParticles(90);
  late final Ticker _ticker; // ignore: use_late_for_private_fields_and_variables
  double _lastT = 0;

  @override
  void initState() {
    super.initState();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..forward();

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(
      parent: _contentCtrl,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _contentCtrl,
      curve: Curves.easeIn,
    );

    _contentCtrl.forward();

    _ticker = createTicker((elapsed) {
      final t = elapsed.inMilliseconds / 1000.0;
      final dt = t - _lastT;
      _lastT = t;

      for (final p in _particles) {
        p.update(dt);
      }

      // Reciclar partículas que salen de pantalla (primeros 4 s)
      if (t < 4.0) {
        final rng = math.Random();
        for (int i = 0; i < _particles.length; i++) {
          if (_particles[i].isOffScreen) {
            final color = _confettiColors[rng.nextInt(_confettiColors.length)];
            _particles[i] = _Particle(
              color: color,
              x: rng.nextDouble(),
              speedX: (rng.nextDouble() - 0.5) * 0.15,
              speedY: 0.18 + rng.nextDouble() * 0.22,
              angle: rng.nextDouble() * math.pi * 2,
              angularVelocity: (rng.nextDouble() - 0.5) * 6,
              size: 6 + rng.nextDouble() * 9,
              shape: rng.nextInt(3),
            );
          }
        }
      }

      if (mounted) setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _confettiCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.97),
      child: Stack(
        children: [
          // ── Confeti ──
          Positioned.fill(
            child: CustomPaint(
              painter: _ConfettiPainter(_particles),
            ),
          ),

          // ── Contenido centrado ──
          SafeArea(
            child: Column(
              children: [
                // Botón cerrar
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.textPrimary.withValues(alpha: 0.08),
                      ),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),

                const Spacer(),

                // Emoji y título
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '¡Lo has conseguido!',
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.primaryDark,
                            fontSize: 26,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Has terminado de leer',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Portada del libro
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: _CoverCard(
                      titulo: widget.titulo,
                      coverUrl: widget.coverUrl,
                    ),
                  ),
                ),

                const Spacer(),

                // Botón continuar
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

// ── Tarjeta de portada ────────────────────────────────────────────────────────

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.titulo, required this.coverUrl});

  final String titulo;
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: coverUrl.isNotEmpty
            ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 180,
      height: 260,
      color: AppColors.primaryLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: AppColors.primary,
            size: 52,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              titulo,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Función de conveniencia ───────────────────────────────────────────────────

Future<void> mostrarCelebracionFinalizado(
  BuildContext context, {
  required String titulo,
  String coverUrl = '',
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => LibroFinalizadoCelebration(
        titulo: titulo,
        coverUrl: coverUrl,
      ),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
  );
}
