import 'dart:math';

import 'package:flutter/material.dart';

import '../navigation/book_detail_navigation.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/optimized_network_image.dart';
import '../widgets/error_view.dart';

class AfinidadDetallePage extends StatefulWidget {
  const AfinidadDetallePage({
    super.key,
    required this.miembroId,
    required this.nombre,
    required this.avatarUrl,
    required this.librosComunes,
    this.miAvatarUrl = '',
  });

  final String miembroId;
  final String nombre;
  final String avatarUrl;
  final int librosComunes;
  final String miAvatarUrl;

  @override
  State<AfinidadDetallePage> createState() => _AfinidadDetallePageState();
}

class _AfinidadDetallePageState extends State<AfinidadDetallePage>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _future;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getAfinidadDetalle(widget.miembroId);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.nombre)),
              body: ErrorView(
                onRetry: () {
                  setState(
                    () => _future = ApiService().getAfinidadDetalle(
                      widget.miembroId,
                    ),
                  );
                },
              ),
            );
          }

          final data = snapshot.data!;
          final libros = (data['librosComunes'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();

          return CustomScrollView(
            slivers: [
              // ── AppBar con degradado ──
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2D1B69), AppColors.primaryDark],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Avatares superpuestos
                        SizedBox(
                          height: 72,
                          width: 120,
                          child: Stack(
                            children: [
                              // Mi avatar
                              Positioned(
                                left: 0,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: OptimizedNetworkImage(
                                    url: widget.miAvatarUrl,
                                    width: 64,
                                    height: 64,
                                    fallback: Container(
                                      color: AppColors.primaryLight,
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: AppColors.primary,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Avatar de la compañera
                              Positioned(
                                left: 44,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: OptimizedNetworkImage(
                                    url: widget.avatarUrl,
                                    width: 64,
                                    height: 64,
                                    fallback: Container(
                                      color: AppColors.primaryLight,
                                      alignment: Alignment.center,
                                      child: Text(
                                        widget.nombre.isNotEmpty
                                            ? widget.nombre[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Corazón central
                              Positioned(
                                left: 36,
                                bottom: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE91E8C),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tú y ${widget.nombre.split(' ').first}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${widget.librosComunes} ${widget.librosComunes == 1 ? 'libro' : 'libros'} en común este año',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  100,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (libros.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Text('Sin libros en común este año'),
                        ),
                      )
                    else ...[
                      // Torre de portadas animada
                      _BookTower(libros: libros, controller: _ctrl),

                      const SizedBox(height: AppSpacing.xl),

                      // Lista detallada
                      ClubCard(
                        elevated: false,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < libros.length; i++) ...[
                              _LibroRow(
                                libro: libros[i],
                                onTap: () => openBookDetail(
                                  context,
                                  title: libros[i]['titulo']?.toString() ?? '',
                                  bookId: libros[i]['id']?.toString() ?? '',
                                  coverUrl:
                                      libros[i]['coverUrl']?.toString() ?? '',
                                  genre: libros[i]['genero']?.toString() ?? '',
                                ),
                              ),
                              if (i < libros.length - 1)
                                const Divider(
                                  height: 1,
                                  indent: AppSpacing.md,
                                  endIndent: AppSpacing.md,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Torre de portadas animada
// ─────────────────────────────────────────────

class _BookTower extends StatelessWidget {
  const _BookTower({required this.libros, required this.controller});

  final List<Map<String, dynamic>> libros;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final books = libros.take(7).toList();
    final n = books.length;

    // Ángulos distribuidos en abanico: de -40° a +40°
    // El libro central (índice medio) queda vertical, los extremos inclinados
    List<double> angles = [];
    List<double> offsets = []; // desplazamiento X
    for (var i = 0; i < n; i++) {
      final t = n == 1 ? 0.0 : (i / (n - 1)) * 2 - 1; // -1..1
      angles.add(t * 38 * pi / 180);
      offsets.add(t * 55); // spread horizontal
    }

    return SizedBox(
      height: 260,
      child: Center(
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < n; i++)
              _AnimatedBook(
                index: i,
                total: n,
                titulo: books[i]['titulo']?.toString() ?? '',
                coverUrl: books[i]['coverUrl']?.toString() ?? '',
                controller: controller,
                angle: angles[i],
                offsetX: offsets[i],
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBook extends StatelessWidget {
  const _AnimatedBook({
    required this.index,
    required this.total,
    required this.titulo,
    required this.coverUrl,
    required this.controller,
    required this.angle,
    required this.offsetX,
  });

  final int index;
  final int total;
  final String titulo;
  final String coverUrl;
  final AnimationController controller;
  final double angle;
  final double offsetX;

  @override
  Widget build(BuildContext context) {
    // Escalonado: los extremos caen un poco después
    final delay = (index / total) * 0.5;
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, delay + 0.5, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..translateByDouble(
            offsetX * anim.value,
            (1 - anim.value) * -180,
            0,
            1,
          )
          ..rotateZ(angle * anim.value),
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .22),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClubBookCover(
          title: titulo,
          imageUrl: coverUrl,
          width: 88,
          height: 128,
          borderRadius: BorderRadius.circular(AppRadius.md),
          showShadow: false,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Fila de libro en la lista
// ─────────────────────────────────────────────

class _LibroRow extends StatelessWidget {
  const _LibroRow({required this.libro, required this.onTap});

  final Map<String, dynamic> libro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClubBookCover(
        title: libro['titulo']?.toString() ?? '',
        imageUrl: libro['coverUrl']?.toString() ?? '',
        width: 40,
        height: 56,
        borderRadius: BorderRadius.circular(6),
        showShadow: false,
      ),
      title: Text(
        libro['titulo']?.toString() ?? '',
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        libro['genero']?.toString() ?? '',
        style: AppTextStyles.caption,
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
    );
  }
}
