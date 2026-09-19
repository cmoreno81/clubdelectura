import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/common/club_reads_mark.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Degradado radial en vez de morado plano: da algo de profundidad
          // y hace que el icono destaque más en el centro.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.15),
                radius: 1.1,
                colors: [
                  AppColors.primaryLight,
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          // Marca de agua: el propio icono, gigante y muy tenue, de fondo —
          // rompe el morado liso con algo que es la propia marca, no ruido.
          Center(
            child: Opacity(
              opacity: 0.06,
              child: Transform.rotate(
                angle: -0.14,
                child: const ClubReadsMark(size: 580, animate: false),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ClubReadsMark(size: 140),
                const SizedBox(height: 26),
                const _SplashFadeIn(
                  delay: Duration(milliseconds: 550),
                  child: _SplashTitulo(),
                ),
                const SizedBox(height: 12),
                _SplashFadeIn(
                  delay: const Duration(milliseconds: 700),
                  child: Text(
                    'LEE · COMENTA · COMPARTE',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      letterSpacing: 2,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primaryLight,
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

class _SplashTitulo extends StatelessWidget {
  const _SplashTitulo();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Club',
            style: GoogleFonts.dmSans(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: AppColors.surface,
              letterSpacing: -0.3,
            ),
          ),
          TextSpan(
            text: 'Reads',
            style: GoogleFonts.playfairDisplay(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aparece con un pequeño desvanecido + subida, tras un retraso — para que
/// el nombre y el lema entren justo cuando el icono termina de "abrirse".
class _SplashFadeIn extends StatefulWidget {
  const _SplashFadeIn({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_SplashFadeIn> createState() => _SplashFadeInState();
}

class _SplashFadeInState extends State<_SplashFadeIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
