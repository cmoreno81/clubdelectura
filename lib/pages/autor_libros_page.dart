import 'package:flutter/material.dart';

import '../navigation/book_detail_navigation.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/genero_utils.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/error_view.dart';

class AutorLibrosPage extends StatefulWidget {
  const AutorLibrosPage({
    super.key,
    required this.autorId,
    required this.nombre,
    required this.photoUrl,
  });

  final String autorId;
  final String nombre;
  final String photoUrl;

  @override
  State<AutorLibrosPage> createState() => _AutorLibrosPageState();
}

class _AutorLibrosPageState extends State<AutorLibrosPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getLibrosPorAutor(widget.autorId);
  }

  String _initials(String nombre) {
    final palabras = nombre
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (palabras.length >= 2) {
      return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
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
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.nombre)),
              body: ErrorView(
                onRetry: () => setState(() {
                  _future = ApiService().getLibrosPorAutor(widget.autorId);
                }),
              ),
            );
          }

          final data = snapshot.data!;
          final biografia = data['biografia']?.toString() ?? '';
          final libros = (data['libros'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();

          return CustomScrollView(
            slivers: [
              // ── AppBar con foto del autor ──
              SliverAppBar(
                expandedHeight: 240,
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
                        color: Colors.black.withValues(alpha: .35),
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
                  title: Text(
                    widget.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Fondo degradado
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2D1B69), AppColors.primaryDark],
                          ),
                        ),
                      ),
                      // Foto del autor
                      if (widget.photoUrl.isNotEmpty)
                        Positioned(
                          top: 56,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .4),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .3),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                widget.photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white.withValues(alpha: .2),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _initials(widget.nombre),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          top: 56,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .4),
                                  width: 3,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _initials(widget.nombre),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Biografía ──
                    if (biografia.isNotEmpty) ...[
                      ClubCard(
                        elevated: false,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          biografia,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // ── Contador ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        '${libros.length} ${libros.length == 1 ? 'libro' : 'libros'} en la biblioteca',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // ── Grid de libros ──
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: .46,
                          ),
                      itemCount: libros.length,
                      itemBuilder: (context, i) {
                        final libro = libros[i];
                        final titulo = libro['titulo']?.toString() ?? '';
                        final coverUrl = libro['coverUrl']?.toString() ?? '';
                        final genero = libro['genero']?.toString() ?? '';
                        final bookId = libro['id']?.toString() ?? '';

                        return GestureDetector(
                          onTap: () => openBookDetail(
                            context,
                            title: titulo,
                            bookId: bookId,
                            coverUrl: coverUrl,
                            genre: genero,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClubBookCover(
                                title: titulo,
                                imageUrl: coverUrl,
                                width: double.infinity,
                                height: 140,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                showShadow: true,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                titulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (genero.isNotEmpty)
                                Text(
                                  '${iconoGenero(genero)} $genero',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
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
