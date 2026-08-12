import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';

// ────────────────────────────────────────────────────────────────────────────
// ClubShimmer — efecto de brillo deslizante sin dependencias externas.
// ────────────────────────────────────────────────────────────────────────────

/// Bloque rectangular con efecto shimmer animado.
class ClubShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ClubShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ClubShimmer> createState() => _ClubShimmerState();
}

class _ClubShimmerState extends State<ClubShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final highlight =
        isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(AppRadius.md),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: [base, highlight, base],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Helpers de conveniencia
// ────────────────────────────────────────────────────────────────────────────

/// Línea de texto shimmer.
class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLine({super.key, required this.width, this.height = 14});

  @override
  Widget build(BuildContext context) => ClubShimmer(
    width: width,
    height: height,
    borderRadius: BorderRadius.circular(height / 2),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Skeleton: lista de libros (biblioteca)
// ────────────────────────────────────────────────────────────────────────────

/// Imita la forma visual de un _libroCard mientras carga.
class BookListItemSkeleton extends StatelessWidget {
  const BookListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClubShimmer(
            width: 92,
            height: 138,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLine(width: double.infinity, height: 18),
                const SizedBox(height: 6),
                const ShimmerLine(width: 160, height: 18),
                const SizedBox(height: 12),
                const ShimmerLine(width: 100, height: 13),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ClubShimmer(
                      width: 70,
                      height: 24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(width: 8),
                    ClubShimmer(
                      width: 55,
                      height: 24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const ShimmerLine(width: 130, height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Página completa de esqueletos de libro (carga inicial de la biblioteca).
class BookListSkeleton extends StatelessWidget {
  final int count;

  const BookListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, _) => const BookListItemSkeleton(),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Skeleton: lista genérica de tarjetas (la mayoría de páginas)
// ────────────────────────────────────────────────────────────────────────────

/// Una tarjeta esqueleto con N líneas de texto.
class _CardSkeleton extends StatelessWidget {
  final int lines;

  const _CardSkeleton({this.lines = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < lines; i++) ...[
            ShimmerLine(
              width: i == 0
                  ? double.infinity
                  : (i == lines - 1 ? 120.0 : 200.0),
              height: i == 0 ? 16 : 13,
            ),
            if (i < lines - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Lista genérica de tarjetas shimmer. Sirve para la mayoría de páginas
/// (ranking, lecturas, notificaciones, logros, tendencias, etc.).
class CardListSkeleton extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry? padding;

  const CardListSkeleton({
    super.key,
    this.count = 6,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 110),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) => _CardSkeleton(
        lines: index % 3 == 0 ? 2 : 3,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Skeleton: lista con portada a la izquierda (ranking, autor, catálogo…)
// ────────────────────────────────────────────────────────────────────────────

class _CoverRowSkeleton extends StatelessWidget {
  const _CoverRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClubShimmer(
            width: 60,
            height: 90,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerLine(width: double.infinity, height: 16),
                SizedBox(height: 8),
                ShimmerLine(width: 140, height: 13),
                SizedBox(height: 8),
                ShimmerLine(width: 100, height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de filas con portada pequeña a la izquierda (ranking, autor, catálogo).
class CoverListSkeleton extends StatelessWidget {
  final int count;

  const CoverListSkeleton({super.key, this.count = 7});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, _) => const _CoverRowSkeleton(),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Skeleton: dashboard (tarjetas de estadísticas + gráfica)
// ────────────────────────────────────────────────────────────────────────────

/// Skeleton para páginas tipo dashboard con tiles de estadísticas.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta hero grande
          ClubShimmer(
            width: double.infinity,
            height: 160,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          const SizedBox(height: 14),
          // Fila de tiles de estadísticas
          Row(
            children: List.generate(3, (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(left: i > 0 ? 10 : 0),
                child: ClubShimmer(
                  width: double.infinity,
                  height: 80,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            )),
          ),
          const SizedBox(height: 14),
          // Tarjeta mediana
          ClubShimmer(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          const SizedBox(height: 14),
          // Fila de 2 tiles
          Row(
            children: [
              Expanded(
                child: ClubShimmer(
                  width: double.infinity,
                  height: 100,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClubShimmer(
                  width: double.infinity,
                  height: 100,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Lista de tarjetas
          for (int i = 0; i < 3; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerLine(width: double.infinity, height: 16),
                  SizedBox(height: 8),
                  ShimmerLine(width: 200, height: 13),
                  SizedBox(height: 8),
                  ShimmerLine(width: 140, height: 13),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Skeleton: perfil de usuario
// ────────────────────────────────────────────────────────────────────────────

/// Skeleton para páginas de perfil (avatar + stats + contenido).
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          const ClubShimmer(
            width: 88,
            height: 88,
            borderRadius: BorderRadius.all(Radius.circular(44)),
          ),
          const SizedBox(height: 14),
          // Nombre
          const ShimmerLine(width: 160, height: 20),
          const SizedBox(height: 8),
          const ShimmerLine(width: 110, height: 14),
          const SizedBox(height: 20),
          // Fila de stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(left: i > 0 ? 10 : 0),
                child: ClubShimmer(
                  width: double.infinity,
                  height: 72,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            )),
          ),
          const SizedBox(height: 16),
          // Tabs placeholder
          ClubShimmer(
            width: double.infinity,
            height: 44,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          const SizedBox(height: 16),
          // Tarjetas de contenido
          for (int i = 0; i < 4; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerLine(width: double.infinity, height: 15),
                  SizedBox(height: 8),
                  ShimmerLine(width: 200, height: 13),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
