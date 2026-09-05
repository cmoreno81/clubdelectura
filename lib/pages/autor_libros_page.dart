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
import '../widgets/common/optimized_network_image.dart';
import '../widgets/libros/libro_acciones_rapidas.dart';
import '../widgets/error_view.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

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
  bool _openingBookActions = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = ApiService().getLibrosPorAutor(widget.autorId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // [silent]=true para la recarga oportunista al volver de ver una ficha
  // (openBookDetail no informa si algo cambió, así que refrescamos siempre
  // "por si acaso"): un fallo ahí no es un error del usuario, así que no
  // debe avisarle con un snackbar. [silent]=false se reserva para cuando sí
  // hubo una edición explícita (p. ej. desde las acciones rápidas).
  Future<void> _reloadBooks({bool silent = false}) async {
    try {
      final data = await ApiService().getLibrosPorAutor(widget.autorId);
      if (mounted) setState(() => _future = Future.value(data));
    } catch (_) {
      if (silent || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se han podido actualizar los libros.')),
      );
    }
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

  Future<void> _mostrarAcciones(Map<String, dynamic> data) async {
    if (_openingBookActions) return;
    _openingBookActions = true;
    final titulo = data['titulo']?.toString() ?? '';
    final bookId = data['id']?.toString() ?? '';
    final coverUrl = data['coverUrl']?.toString() ?? '';
    final genero = data['genero']?.toString() ?? '';
    try {
      final changed = await mostrarAccionesRapidasLibro(
        context,
        bookId: bookId,
        titulo: titulo,
        autor: widget.nombre,
        genero: genero,
        coverUrl: coverUrl,
        abrirFicha: (_) => openBookDetail(
          context,
          title: titulo,
          bookId: bookId,
          coverUrl: coverUrl,
          genre: genero,
        ),
      );
      if (changed && mounted) {
        await _reloadBooks();
      }
    } finally {
      _openingBookActions = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const CoverListSkeleton();
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
            key: const PageStorageKey('author-books-scroll'),
            controller: _scrollController,
            slivers: [
              // ── AppBar con foto del autor ──
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF4A2240),
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
                            colors: [Color(0xFF5C2B4A), Color(0xFF3A1830)],
                          ),
                        ),
                      ),
                      // Foto del autor
                      if (widget.photoUrl.isNotEmpty)
                        Positioned(
                          top: 52,
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
                              child: OptimizedNetworkImage(
                                url: widget.photoUrl,
                                width: 96,
                                height: 96,
                                fallback: Container(
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
                          top: 52,
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

                    // ── Libros agrupados por saga ──
                    _LibrosAgrupados(
                      libros: libros,
                      onTap: (libro) {
                        openBookDetail(
                          context,
                          title: libro['titulo']?.toString() ?? '',
                          bookId: libro['id']?.toString() ?? '',
                          coverUrl: libro['coverUrl']?.toString() ?? '',
                          genre: libro['genero']?.toString() ?? '',
                        ).then((_) {
                          // Recarga al volver: refresca portadas y estado biblioteca
                          if (mounted) _reloadBooks(silent: true);
                        });
                      },
                      onLongPress: _mostrarAcciones,
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

// ─── Libros agrupados por saga ────────────────────────────────────────────────

class _LibrosAgrupados extends StatelessWidget {
  const _LibrosAgrupados({
    required this.libros,
    required this.onTap,
    required this.onLongPress,
  });

  final List<Map<String, dynamic>> libros;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(Map<String, dynamic>) onLongPress;

  @override
  Widget build(BuildContext context) {
    // Separar libros con saga de libros sueltos
    final Map<String, List<Map<String, dynamic>>> porSaga = {};
    final List<Map<String, dynamic>> sueltos = [];

    for (final libro in libros) {
      final sagaNombre = libro['sagaNombre']?.toString();
      if (sagaNombre != null && sagaNombre.isNotEmpty) {
        porSaga.putIfAbsent(sagaNombre, () => []).add(libro);
      } else {
        sueltos.add(libro);
      }
    }

    // Ordenar sagas: primera saga por sagaOrden del primer libro
    int asInt(dynamic v) => v is num ? v.toInt() : 0;
    final sagasOrdenadas = porSaga.entries.toList()
      ..sort((a, b) {
        final aOrden = asInt(a.value.first['sagaOrden']);
        final bOrden = asInt(b.value.first['sagaOrden']);
        return aOrden.compareTo(bOrden);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Secciones por saga: timeline ──
        for (final entry in sagasOrdenadas) ...[
          _SagaTimeline(
            nombre: entry.key,
            libros: entry.value,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ── Libros sueltos: grid ──
        if (sueltos.isNotEmpty) ...[
          if (sagasOrdenadas.isNotEmpty) ...[
            _GridHeader(nombre: 'Independientes'),
            const SizedBox(height: AppSpacing.sm),
          ],
          _LibroGrid(
            libros: sueltos,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
const _kGold      = Color(0xFFA87C38);   // dorado — badges de número
const _kTerracota = Color(0xFF4A6741);   // verde musgo — título e icono de saga
const _kCoverW    = 58.0;   // ancho portada
const _kCoverH    = 84.0;   // alto portada (≈ 2:3)

// ── Widget principal de saga ─────────────────────────────────────────────────

class _SagaTimeline extends StatelessWidget {
  const _SagaTimeline({
    required this.nombre,
    required this.libros,
    required this.onTap,
    required this.onLongPress,
  });

  final String nombre;
  final List<Map<String, dynamic>> libros;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(Map<String, dynamic>) onLongPress;

  @override
  Widget build(BuildContext context) {
    if (libros.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.auto_stories_rounded, size: 18, color: _kTerracota),
          const SizedBox(width: 8),
          Expanded(child: Text(nombre,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppTextStyles.subtitle.copyWith(
              fontWeight: FontWeight.w800, color: _kTerracota, fontSize: 17))),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            for (int i = 0; i < libros.length; i++) _buildCard(i),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(int i) {
    final libro    = libros[i];
    final titulo   = libro['titulo']?.toString()  ?? '';
    final coverUrl = libro['coverUrl']?.toString() ?? '';

    return GestureDetector(
      onTap: () => onTap(libro),
      onLongPress: () => onLongPress(libro),
      child: SizedBox(
        width: _kCoverW,
        child: Stack(clipBehavior: Clip.none, children: [
          ClubBookCover(
            title: titulo,
            imageUrl: coverUrl,
            width: _kCoverW,
            height: _kCoverH,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            showShadow: true,
          ),
          Positioned(
            top: 3, left: 3,
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGold,
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: .3), blurRadius: 3)],
              ),
              alignment: Alignment.center,
              child: Text('${i + 1}', style: const TextStyle(
                color: Colors.white, fontSize: 9,
                fontWeight: FontWeight.w900, height: 1)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Cabecera para libros independientes ─────────────────────────────────────

class _GridHeader extends StatelessWidget {
  const _GridHeader({required this.nombre});
  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.book_outlined, size: 16, color: _kGold),
        const SizedBox(width: 8),
        Text(
          nombre,
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.w800,
            color: _kGold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

// ─── Grid de portadas (para libros sin saga) ──────────────────────────────────

class _LibroGrid extends StatelessWidget {
  const _LibroGrid({
    required this.libros,
    required this.onTap,
    required this.onLongPress,
  });

  final List<Map<String, dynamic>> libros;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(Map<String, dynamic>) onLongPress;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: .46,
      ),
      itemCount: libros.length,
      itemBuilder: (context, i) {
        final libro   = libros[i];
        final titulo  = libro['titulo']?.toString()  ?? '';
        final coverUrl = libro['coverUrl']?.toString() ?? '';
        final genero  = libro['genero']?.toString()  ?? '';

        return GestureDetector(
          onTap: () => onTap(libro),
          onLongPress: () => onLongPress(libro),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                hint: 'Mantén pulsado para abrir acciones rápidas',
                child: ClubBookCover(
                  title: titulo,
                  imageUrl: coverUrl,
                  width: double.infinity,
                  height: 140,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  showShadow: true,
                ),
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
    );
  }
}
