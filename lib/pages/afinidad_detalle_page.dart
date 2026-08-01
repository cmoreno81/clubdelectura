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
import '../widgets/error_view.dart';

class AfinidadDetallePage extends StatefulWidget {
  const AfinidadDetallePage({
    super.key,
    required this.miembroId,
    required this.nombre,
    required this.avatarUrl,
    required this.librosComunes,
  });

  final String miembroId;
  final String nombre;
  final String avatarUrl;
  final int librosComunes;

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
              body: ErrorView(onRetry: () {
                setState(() => _future = ApiService().getAfinidadDetalle(widget.miembroId));
              }),
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
                              // Mi avatar (placeholder)
                              Positioned(
                                left: 0,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2.5),
                                    color: AppColors.primaryLight,
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                    size: 32,
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
                                        color: Colors.white, width: 2.5),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: widget.avatarUrl.isNotEmpty
                                      ? Image.network(widget.avatarUrl,
                                          fit: BoxFit.cover)
                                      : Container(
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
                                  child: const Icon(Icons.favorite_rounded,
                                      color: Colors.white, size: 14),
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
                    AppSpacing.md, AppSpacing.lg, AppSpacing.md, 100),
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
                            vertical: AppSpacing.sm),
                        child: Column(
                          children: [
                            for (var i = 0; i < libros.length; i++) ...[
                              _LibroRow(
                                libro: libros[i],
                                onTap: () => openBookDetail(
                                  context,
                                  title: libros[i]['titulo']?.toString() ?? '',
                                  bookId: libros[i]['id']?.toString() ?? '',
                                  coverUrl: libros[i]['coverUrl']?.toString() ?? '',
                                  genre: libros[i]['genero']?.toString() ?? '',
                                ),
                              ),
                              if (i < libros.length - 1)
                                const Divider(
                                    height: 1,
                                    indent: AppSpacing.md,
                                    endIndent: AppSpacing.md),
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
    // Máximo 8 portadas en la torre
    final books = libros.take(8).toList();
    final rng = Random(42);

    return SizedBox(
      height: 280,
      child: Center(
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < books.length; i++)
              _AnimatedBook(
                index: i,
                total: books.length,
                titulo: books[i]['titulo']?.toString() ?? '',
                coverUrl: books[i]['coverUrl']?.toString() ?? '',
                controller: controller,
                angle: (rng.nextDouble() * 24 - 12) * pi / 180,
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
  });

  final int index;
  final int total;
  final String titulo;
  final String coverUrl;
  final AnimationController controller;
  final double angle;

  @override
  Widget build(BuildContext context) {
    // Los libros se apilan: el primero cae primero, el último encima
    final delay = index / total;
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(delay * 0.6, delay * 0.6 + 0.4,
          curve: Curves.easeOutBack),
    );

    // Offset vertical: los libros más altos en el stack están más arriba
    final stackOffset = index * 6.0;

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..translate(0.0, (1 - anim.value) * -200)
          ..rotateZ(angle * anim.value),
        child: child,
      ),
      child: Positioned(
        bottom: stackOffset,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClubBookCover(
            title: titulo,
            imageUrl: coverUrl,
            width: 90,
            height: 130,
            borderRadius: BorderRadius.circular(AppRadius.md),
            showShadow: false,
          ),
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
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textMuted),
    );
  }
}
