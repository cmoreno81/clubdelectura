import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/api_service.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Pantalla Wrapped anual — resumen lector estilo Spotify.
class WrappedPage extends StatefulWidget {
  const WrappedPage({super.key, this.anio, this.loadData});

  final int? anio;
  final Future<Map<String, dynamic>> Function(int year)? loadData;

  @override
  State<WrappedPage> createState() => _WrappedPageState();
}

class _WrappedPageState extends State<WrappedPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  int get _year => widget.anio ?? DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data =
          await (widget.loadData?.call(_year) ??
              ApiService().getWrappedAnual(anio: _year));
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _data == null
          ? _ErrorView(
              onRetry: () {
                setState(() => _loading = true);
                _cargar();
              },
            )
          : _WrappedContent(data: _data!, year: _year),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WrappedContent extends StatefulWidget {
  const _WrappedContent({required this.data, required this.year});
  final Map<String, dynamic> data;
  final int year;

  @override
  State<_WrappedContent> createState() => _WrappedContentState();
}

class _WrappedContentState extends State<_WrappedContent> {
  final PageController _pc = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      HapticFeedback.selectionClick();
      _pc.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    if (_page > 0) {
      HapticFeedback.selectionClick();
      _pc.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  List<Widget> get _pages {
    final d = widget.data;
    final totalBooks = (d['totalBooks'] as num?)?.toInt() ?? 0;
    final totalPages = (d['totalPages'] as num?)?.toInt() ?? 0;
    final totalActiveDays = (d['totalActiveDays'] as num?)?.toInt() ?? 0;
    final streak = (d['streak'] as num?)?.toInt() ?? 0;
    final topGenre = d['topGenre'] as Map<String, dynamic>?;
    final topAuthor = d['topAuthor'] as Map<String, dynamic>?;
    final bestMonth = d['bestMonth'] as Map<String, dynamic>?;
    final avgRating = d['avgRating'];
    final longestBook = d['longestBook'] as Map<String, dynamic>?;
    final firstBook = d['firstBook'] as Map<String, dynamic>?;
    final diffVsPrevYear = (d['diffVsPrevYear'] as num?)?.toInt() ?? 0;
    final prevYearBooks = (d['prevYearBooks'] as num?)?.toInt() ?? 0;
    final byMonth =
        (d['byMonth'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        List.filled(12, 0);
    final rawBooks = (d['books'] as List<dynamic>?) ?? [];
    final allBooks = rawBooks
        .cast<Map<String, dynamic>>()
        .map(
          (b) => _WrappedBook(
            title: b['title'] as String? ?? '',
            coverUrl: b['coverUrl'] as String? ?? '',
          ),
        )
        .toList(growable: false);
    final favoriteBooks = ((d['favoriteBooks'] as List<dynamic>?) ?? const [])
        .whereType<Map>()
        .map((book) => _WrappedBook.fromMap(book))
        .take(5)
        .toList(growable: false);
    final rawBookOfYear = d['bookOfYear'];
    final bookOfYear = rawBookOfYear is Map
        ? _WrappedBookOfYear.fromMap(rawBookOfYear)
        : null;

    return [
      _SlideIntro(year: widget.year),
      // Estantería visual — justo después de la intro si hay libros con portada
      if (allBooks.any((b) => b.coverUrl.isNotEmpty))
        _SlideEstanteria(books: allBooks, year: widget.year),
      _SlideLibros(total: totalBooks, paginas: totalPages),
      _SlideDias(dias: totalActiveDays, streak: streak),
      if (topGenre != null)
        _SlideGenero(genero: topGenre['name'] as String? ?? ''),
      if (topAuthor != null)
        _SlideAutor(autor: topAuthor['name'] as String? ?? ''),
      if (favoriteBooks.isNotEmpty) _SlideFavoritos(books: favoriteBooks),
      if (bestMonth != null)
        _SlideMes(
          mes: bestMonth['name'] as String? ?? '',
          libros: bestMonth['count'] as int? ?? 0,
        ),
      _SlideGrafico(byMonth: byMonth),
      if (avgRating != null) _SlideRating(rating: avgRating.toDouble()),
      if (longestBook != null)
        _SlideLongest(
          titulo: longestBook['title'] as String? ?? '',
          paginas: longestBook['pages'] as int?,
          coverUrl: longestBook['coverUrl'] as String?,
        ),
      if (firstBook != null)
        _SlidePrimero(
          titulo: firstBook['title'] as String? ?? '',
          coverUrl: firstBook['coverUrl'] as String?,
        ),
      _SlideComparativa(
        totalBooks: totalBooks,
        prevYear: prevYearBooks,
        diff: diffVsPrevYear,
        year: widget.year,
      ),
      if (bookOfYear != null && bookOfYear.started)
        _SlideBookOfYear(data: bookOfYear, year: widget.year),
      _SlideFinal(totalBooks: totalBooks, year: widget.year),
      _SlideResumenCompartir(
        year: widget.year,
        totalBooks: totalBooks,
        totalPages: totalPages,
        totalActiveDays: totalActiveDays,
        streak: streak,
        topGenre: topGenre?['name'] as String?,
        topAuthor: topAuthor?['name'] as String?,
        avgRating: avgRating?.toDouble(),
        bestMonth: bestMonth?['name'] as String?,
        favoriteBooks: favoriteBooks,
        bookOfYearWinner: bookOfYear?.winner,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return GestureDetector(
      onTapDown: (details) {
        final half = MediaQuery.of(context).size.width / 2;
        if (details.localPosition.dx > half) {
          _next();
        } else {
          _prev();
        }
      },
      child: Stack(
        children: [
          // ── Slides ────────────────────────────────────────────────────────
          PageView.builder(
            controller: _pc,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => pages[i],
          ),

          // ── Indicador de progreso arriba ─────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: List.generate(pages.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: i <= _page ? Colors.white : Colors.white30,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── Botón cerrar ─────────────────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget portada de libro
// ─────────────────────────────────────────────────────────────────────────────

class _BookCover extends StatelessWidget {
  const _BookCover({required this.coverUrl, this.height = 180});

  final String coverUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ratio = 2 / 3; // proporción estándar libro
    final width = height * ratio;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .45),
            blurRadius: 20,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: coverUrl.isNotEmpty
            ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _PlaceholderCover(width: width, height: height),
              )
            : _PlaceholderCover(width: width, height: height),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.white12,
      child: const Center(child: Text('📖', style: TextStyle(fontSize: 36))),
    );
  }
}

/// Placeholder compacto para la cuadrícula de la estantería (sin portada)
class _GridPlaceholder extends StatelessWidget {
  const _GridPlaceholder({required this.title});
  final String title;

  // Paleta de colores variados según inicial del título
  static const _colors = [
    Color(0xFF3D1A5C),
    Color(0xFF1A3D5C),
    Color(0xFF5C3D1A),
    Color(0xFF1A5C3D),
    Color(0xFF5C1A3D),
    Color(0xFF3D5C1A),
    Color(0xFF2A1A5C),
    Color(0xFF5C2A1A),
  ];

  @override
  Widget build(BuildContext context) {
    final colorIdx = title.isEmpty ? 0 : title.codeUnitAt(0) % _colors.length;
    final initial = title.isEmpty ? '?' : title[0].toUpperCase();
    return Container(
      color: _colors[colorIdx],
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo interno
// ─────────────────────────────────────────────────────────────────────────────

class _WrappedBook {
  const _WrappedBook({
    required this.title,
    required this.coverUrl,
    this.id = '',
    this.authorName = '',
  });
  factory _WrappedBook.fromMap(Map<dynamic, dynamic> map) => _WrappedBook(
    id: map['id']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    coverUrl: map['coverUrl']?.toString() ?? '',
    authorName: map['authorName']?.toString() ?? '',
  );
  final String id;
  final String title;
  final String coverUrl;
  final String authorName;
}

class _WrappedBookOfYear {
  const _WrappedBookOfYear({
    required this.status,
    required this.completedMonths,
    required this.finalists,
    this.winner,
  });
  factory _WrappedBookOfYear.fromMap(Map<dynamic, dynamic> map) =>
      _WrappedBookOfYear(
        status: map['status']?.toString() ?? 'NOT_STARTED',
        completedMonths: (map['completedMonths'] as num?)?.toInt() ?? 0,
        finalists: ((map['finalists'] as List<dynamic>?) ?? const [])
            .whereType<Map>()
            .map(_WrappedBook.fromMap)
            .toList(growable: false),
        winner: map['winner'] is Map
            ? _WrappedBook.fromMap(map['winner'] as Map)
            : null,
      );
  final String status;
  final int completedMonths;
  final List<_WrappedBook> finalists;
  final _WrappedBook? winner;
  bool get started =>
      status != 'NOT_STARTED' ||
      completedMonths > 0 ||
      finalists.isNotEmpty ||
      winner != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Slides
// ─────────────────────────────────────────────────────────────────────────────

class _BaseSlide extends StatelessWidget {
  const _BaseSlide({required this.color, required this.child, this.emoji});
  final Color color;
  final Widget child;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.1,
          colors: [color.withValues(alpha: .6), const Color(0xFF0D0D1A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (emoji != null)
                      Text(emoji!, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: AppSpacing.lg),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 38,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _Sub extends StatelessWidget {
  const _Sub(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white60, fontSize: 18, height: 1.4),
    );
  }
}

class _Accent extends StatelessWidget {
  const _Accent(this.text, {this.size = 56});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
      ),
    );
  }
}

// ── Slides concretos ──────────────────────────────────────────────────────────

/// Slide de estantería — muestra todas las portadas del año en una cuadrícula.
class _SlideEstanteria extends StatelessWidget {
  const _SlideEstanteria({required this.books, required this.year});
  final List<_WrappedBook> books;
  final int year;

  @override
  Widget build(BuildContext context) {
    final total = books.length;
    // Todos los libros aparecen en la cuadrícula; los sin portada muestran placeholder
    final conPortada = books.where((b) => b.coverUrl.isNotEmpty).length;
    final sinPortada = total - conPortada;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A2E), Color(0xFF0D0D1A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📚', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tu estantería\nde $year',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$total ${total == 1 ? 'libro terminado' : 'libros terminados'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                  if (sinPortada > 0)
                    Text(
                      '$sinPortada sin portada disponible',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Cuadrícula — todos los libros, desplazable si hay muchos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 90,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2 / 3,
                  ),
                  itemCount: total,
                  itemBuilder: (_, i) {
                    final book = books[i];
                    return Tooltip(
                      message: book.title,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: book.coverUrl.isNotEmpty
                            ? Image.network(
                                book.coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _GridPlaceholder(title: book.title),
                              )
                            : _GridPlaceholder(title: book.title),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _SlideIntro extends StatelessWidget {
  const _SlideIntro({required this.year});
  final int year;

  @override
  Widget build(BuildContext context) {
    return _BaseSlide(
      color: const Color(0xFF6C3FF5),
      emoji: '📚',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Headline('Tu año\nen libros'),
          const SizedBox(height: AppSpacing.md),
          _Sub(
            'Este es tu Wrapped $year.\nToca para descubrir tu historia lectora.',
          ),
        ],
      ),
    );
  }
}

class _SlideLibros extends StatelessWidget {
  const _SlideLibros({required this.total, required this.paginas});
  final int total;
  final int paginas;

  @override
  Widget build(BuildContext context) {
    return _BaseSlide(
      color: const Color(0xFF1DB954),
      emoji: '🎉',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Headline('Este año\nterminaste'),
          const SizedBox(height: AppSpacing.sm),
          _Accent('$total ${total == 1 ? 'libro' : 'libros'}'),
          if (paginas > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _Sub('Eso son $paginas páginas.\n¡Impresionante!'),
          ],
        ],
      ),
    );
  }
}

class _SlideDias extends StatelessWidget {
  const _SlideDias({required this.dias, required this.streak});
  final int dias;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return _BaseSlide(
      color: const Color(0xFFFF6B35),
      emoji: '🔥',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Headline('Tu racha\nlectora'),
          const SizedBox(height: AppSpacing.sm),
          _Accent('$streak días'),
          const SizedBox(height: AppSpacing.md),
          _Sub(
            'Y en total estuviste activo $dias ${dias == 1 ? 'día' : 'días'} este año.',
          ),
        ],
      ),
    );
  }
}

class _SlideGenero extends StatelessWidget {
  const _SlideGenero({required this.genero});
  final String genero;

  @override
  Widget build(BuildContext context) {
    return _BaseSlide(
      color: const Color(0xFFE91E8C),
      emoji: '🎭',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Headline('Tu género\nfavorito fue'),
          const SizedBox(height: AppSpacing.sm),
          _Accent(genero, size: 40),
        ],
      ),
    );
  }
}

class _SlideAutor extends StatelessWidget {
  const _SlideAutor({required this.autor});
  final String autor;

  @override
  Widget build(BuildContext context) {
    return _BaseSlide(
      color: const Color(0xFF00BCD4),
      emoji: '✍️',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Headline('Tu autor\nfavorito'),
          const SizedBox(height: AppSpacing.sm),
          _Accent(autor, size: 36),
          const SizedBox(height: AppSpacing.md),
          const _Sub('Volviste a su mundo una y otra vez.'),
        ],
      ),
    );
  }
}

class _SlideMes extends StatelessWidget {
  const _SlideMes({required this.mes, required this.libros});
  final String mes;
  final int libros;

  @override
  Widget build(BuildContext context) {
    return _BaseSlide(
      color: const Color(0xFFFFC107),
      emoji: '📅',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Headline('Tu mejor\nmes fue'),
          const SizedBox(height: AppSpacing.sm),
          _Accent(mes.toUpperCase(), size: 44),
          const SizedBox(height: AppSpacing.md),
          _Sub(
            'Terminaste $libros ${libros == 1 ? 'libro' : 'libros'} ese mes.',
          ),
        ],
      ),
    );
  }
}

class _SlideGrafico extends StatelessWidget {
  const _SlideGrafico({required this.byMonth});
  final List<int> byMonth;

  @override
  Widget build(BuildContext context) {
    final maxVal = byMonth.reduce(math.max);
    return _BaseSlide(
      color: const Color(0xFF3F51B5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊', style: TextStyle(fontSize: 52)),
          const SizedBox(height: AppSpacing.lg),
          const _Headline('Tu año\nen gráfico'),
          const SizedBox(height: AppSpacing.xl),
          // Barras por mes
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(12, (i) {
              final val = byMonth[i];
              final pct = maxVal > 0 ? val / maxVal : 0.0;
              const monthAbbr = [
                'E',
                'F',
                'M',
                'A',
                'M',
                'J',
                'J',
                'A',
                'S',
                'O',
                'N',
                'D',
              ];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (val > 0)
                        Text(
                          '$val',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                          ),
                        ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        height: 80 * pct + (val > 0 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: val > 0
                              ? Colors.white.withValues(alpha: 0.2 + 0.8 * pct)
                              : Colors.white12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthAbbr[i],
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SlideRating extends StatelessWidget {
  const _SlideRating({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final stars = '⭐' * rating.round().clamp(0, 5);
    return _BaseSlide(
      color: const Color(0xFFFF9800),
      emoji: '⭐',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Headline('Tu valoración\nmedia fue'),
          const SizedBox(height: AppSpacing.sm),
          _Accent('$rating / 5'),
          const SizedBox(height: AppSpacing.sm),
          Text(stars, style: const TextStyle(fontSize: 32)),
        ],
      ),
    );
  }
}

class _SlideLongest extends StatelessWidget {
  const _SlideLongest({required this.titulo, this.paginas, this.coverUrl});
  final String titulo;
  final int? paginas;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;
    return _BaseSlide(
      color: const Color(0xFF4CAF50),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Texto a la izquierda
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 52)),
                const SizedBox(height: AppSpacing.lg),
                const _Headline('El libro más\nlargo que\nterminaste'),
                const SizedBox(height: AppSpacing.md),
                _Accent(titulo, size: hasCover ? 20 : 26),
                if (paginas != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _Sub('$paginas páginas.\n¡Toda una hazaña!'),
                ],
              ],
            ),
          ),
          // Portada a la derecha
          if (hasCover) ...[
            const SizedBox(width: AppSpacing.lg),
            _BookCover(coverUrl: coverUrl!, height: 160),
          ],
        ],
      ),
    );
  }
}

class _SlidePrimero extends StatelessWidget {
  const _SlidePrimero({required this.titulo, this.coverUrl});
  final String titulo;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;
    return _BaseSlide(
      color: const Color(0xFF9C27B0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 52)),
          const SizedBox(height: AppSpacing.lg),
          const _Headline('Empezaste\nel año con'),
          const SizedBox(height: AppSpacing.xl),
          if (hasCover)
            // Portada horizontal centrada en la parte inferior
            Center(child: _BookCover(coverUrl: coverUrl!, height: 200))
          else
            _Accent(titulo, size: 28),
          if (hasCover) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _SlideFavoritos extends StatelessWidget {
  const _SlideFavoritos({required this.books});
  final List<_WrappedBook> books;

  @override
  Widget build(BuildContext context) => _BaseSlide(
    color: const Color(0xFF7A4F86),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Headline('Los favoritos\nque te acompañan'),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: 250,
          child: ListView.separated(
            key: const ValueKey('wrapped-favorites'),
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, index) {
              final book = books[index];
              return SizedBox(
                width: 112,
                child: Column(
                  children: [
                    _BookCover(coverUrl: book.coverUrl, height: 150),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (book.authorName.isNotEmpty)
                      Text(
                        book.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _SlideBookOfYear extends StatelessWidget {
  const _SlideBookOfYear({required this.data, required this.year});
  final _WrappedBookOfYear data;
  final int year;

  @override
  Widget build(BuildContext context) {
    final winner = data.winner;
    if (winner != null) {
      return _BaseSlide(
        color: const Color(0xFF8A6832),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('👑', style: TextStyle(fontSize: 58)),
            const _Headline('Tu Libro del año'),
            _Sub('$year'),
            const SizedBox(height: AppSpacing.xl),
            Center(child: _BookCover(coverUrl: winner.coverUrl, height: 230)),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                winner.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (winner.authorName.isNotEmpty)
              Center(
                child: Text(
                  winner.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 15),
                ),
              ),
          ],
        ),
      );
    }
    if (data.finalists.isNotEmpty) {
      return _BaseSlide(
        color: const Color(0xFF65518A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Headline('Tu cuadro todavía\nbusca un ganador'),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final book in data.finalists.take(3))
                  _BookCover(coverUrl: book.coverUrl, height: 145),
              ],
            ),
          ],
        ),
      );
    }
    return _BaseSlide(
      color: const Color(0xFF5F477A),
      emoji: '🏆',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Headline('Tu cuadro está\nen marcha'),
          const SizedBox(height: AppSpacing.lg),
          _Accent('${data.completedMonths} de 12', size: 46),
          const _Sub('meses elegidos'),
          const SizedBox(height: AppSpacing.xl),
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.white30)),
              Icon(Icons.chevron_right_rounded, color: Colors.white54),
              Expanded(child: Divider(color: Colors.white30)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlideComparativa extends StatelessWidget {
  const _SlideComparativa({
    required this.totalBooks,
    required this.prevYear,
    required this.diff,
    required this.year,
  });
  final int totalBooks;
  final int prevYear;
  final int diff;
  final int year;

  @override
  Widget build(BuildContext context) {
    final mejor = diff >= 0;
    return _BaseSlide(
      color: mejor ? const Color(0xFF1DB954) : const Color(0xFFFF5722),
      emoji: mejor ? '📈' : '📉',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Headline(
            mejor ? 'Mejor que\nel año pasado' : 'El año pasado\nleíste más',
          ),
          const SizedBox(height: AppSpacing.md),
          if (diff != 0)
            _Accent(
              '${mejor ? '+' : ''}$diff ${diff.abs() == 1 ? 'libro' : 'libros'}',
              size: 44,
            ),
          const SizedBox(height: AppSpacing.md),
          _Sub('$year: $totalBooks libros — ${year - 1}: $prevYear libros'),
        ],
      ),
    );
  }
}

class _SlideFinal extends StatelessWidget {
  const _SlideFinal({required this.totalBooks, required this.year});
  final int totalBooks;
  final int year;

  @override
  Widget build(BuildContext context) {
    return _BaseSlide(
      color: const Color(0xFF6C3FF5),
      emoji: '✨',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Headline('Eso es todo,\nlector.'),
          const SizedBox(height: AppSpacing.md),
          _Sub(
            '$totalBooks ${totalBooks == 1 ? 'libro' : 'libros'} en $year.\nQue ${year + 1} traiga muchos más.',
          ),
          const SizedBox(height: 40),
          // Sin botón Cerrar aquí: el siguiente slide es el resumen compartible
          Text(
            'Desliza para ver tu resumen →',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide resumen + compartir (pantalla final)
// ─────────────────────────────────────────────────────────────────────────────

class _SlideResumenCompartir extends StatefulWidget {
  const _SlideResumenCompartir({
    required this.year,
    required this.totalBooks,
    required this.totalPages,
    required this.totalActiveDays,
    required this.streak,
    this.topGenre,
    this.topAuthor,
    this.avgRating,
    this.bestMonth,
    this.favoriteBooks = const [],
    this.bookOfYearWinner,
  });

  final int year;
  final int totalBooks;
  final int totalPages;
  final int totalActiveDays;
  final int streak;
  final String? topGenre;
  final String? topAuthor;
  final double? avgRating;
  final String? bestMonth;
  final List<_WrappedBook> favoriteBooks;
  final _WrappedBook? bookOfYearWinner;

  @override
  State<_SlideResumenCompartir> createState() => _SlideResumenCompartirState();
}

class _SlideResumenCompartirState extends State<_SlideResumenCompartir> {
  final _repaintKey = GlobalKey();
  bool _sharing = false;

  Future<void> _compartir() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final coverUrls = [
        if (widget.bookOfYearWinner?.coverUrl.isNotEmpty == true)
          widget.bookOfYearWinner!.coverUrl,
        ...widget.favoriteBooks
            .where((book) => book.coverUrl.isNotEmpty)
            .take(3)
            .map((book) => book.coverUrl),
      ];
      await Future.wait(
        coverUrls.map(
          (url) => precacheImage(NetworkImage(url), context).catchError((_) {}),
        ),
      );
      if (!mounted) return;
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/wrapped_${widget.year}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Mi Wrapped ${widget.year} en ClubReaders 📚✨',
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stars = widget.avgRating != null
        ? '⭐ ${widget.avgRating!.toStringAsFixed(1)}'
        : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D1A), Color(0xFF1A0D2E), Color(0xFF0D1A12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              // ── Tarjeta capturada ──────────────────────────────────────
              Expanded(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.1,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A0A3D), Color(0xFF0D2218)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Encabezado
                          const Text('✨', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          Text(
                            'Wrapped ${widget.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ClubReaders',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // ── Grid de estadísticas ──────────────────────────
                          _StatGrid(
                            children: [
                              _StatCell(
                                emoji: '📚',
                                value: '${widget.totalBooks}',
                                label: widget.totalBooks == 1
                                    ? 'libro'
                                    : 'libros',
                                accent: const Color(0xFF6C3FF5),
                              ),
                              _StatCell(
                                emoji: '📄',
                                value: '${widget.totalPages}',
                                label: 'páginas',
                                accent: const Color(0xFF1DB954),
                              ),
                              _StatCell(
                                emoji: '📅',
                                value: '${widget.totalActiveDays}',
                                label: 'días activa',
                                accent: const Color(0xFFFF6B9D),
                              ),
                              _StatCell(
                                emoji: '🔥',
                                value: '${widget.streak}',
                                label: 'racha',
                                accent: const Color(0xFFFFB347),
                              ),
                              if (widget.topGenre != null)
                                _StatCell(
                                  emoji: '🎭',
                                  value: widget.topGenre!,
                                  label: 'género fav.',
                                  accent: const Color(0xFF64B5F6),
                                  isText: true,
                                ),
                              if (widget.topAuthor != null)
                                _StatCell(
                                  emoji: '✍️',
                                  value: widget.topAuthor!,
                                  label: 'autor fav.',
                                  accent: const Color(0xFFFFD700),
                                  isText: true,
                                ),
                              if (stars != null)
                                _StatCell(
                                  emoji: '⭐',
                                  value: widget.avgRating!.toStringAsFixed(1),
                                  label: 'media de lectura',
                                  accent: const Color(0xFFFFD700),
                                ),
                              if (widget.bestMonth != null)
                                _StatCell(
                                  emoji: '🏆',
                                  value: widget.bestMonth!,
                                  label: 'mejor mes',
                                  accent: const Color(0xFFFF8A65),
                                  isText: true,
                                ),
                            ],
                          ),
                          if (widget.bookOfYearWinner != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '👑',
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    widget.bookOfYearWinner!.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (widget.favoriteBooks.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final book in widget.favoriteBooks.take(3))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: _BookCover(
                                      coverUrl: book.coverUrl,
                                      height: 42,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Botón compartir grande ────────────────────────────────
              GestureDetector(
                onTap: _compartir,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _sharing
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF6C3FF5), Color(0xFF1DB954)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: _sharing
                        ? Colors.white.withValues(alpha: 0.15)
                        : null,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_sharing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.ios_share_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _sharing
                              ? 'Preparando imagen...'
                              : 'Compartir mi Wrapped',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Botón cerrar secundario
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cerrar',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers visuales del resumen ─────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.0,
      children: children,
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.emoji,
    required this.value,
    required this.label,
    required this.accent,
    this.isText = false,
  });

  final String emoji;
  final String value;
  final String label;
  final Color accent;
  final bool isText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isText ? 11 : 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No se pudo cargar tu Wrapped',
            style: AppTextStyles.subtitle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Volver',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }
}
