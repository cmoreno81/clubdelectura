import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Pantalla Wrapped anual — resumen lector estilo Spotify.
class WrappedPage extends StatefulWidget {
  const WrappedPage({super.key, this.anio});

  final int? anio;

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
      final data = await ApiService().getWrappedAnual(anio: _year);
      if (mounted) setState(() { _data = data; _loading = false; });
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
          ? _ErrorView(onRetry: () { setState(() => _loading = true); _cargar(); })
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
      _pc.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prev() {
    if (_page > 0) {
      HapticFeedback.selectionClick();
      _pc.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
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
    final byMonth = (d['byMonth'] as List<dynamic>?)
        ?.map((e) => (e as num).toInt())
        .toList() ?? List.filled(12, 0);
    final rawBooks = (d['books'] as List<dynamic>?) ?? [];
    final allBooks = rawBooks
        .cast<Map<String, dynamic>>()
        .map((b) => _WrappedBook(
              title: b['title'] as String? ?? '',
              coverUrl: b['coverUrl'] as String? ?? '',
            ))
        .toList(growable: false);

    return [
      _SlideIntro(year: widget.year),
      // Estantería visual — justo después de la intro si hay libros con portada
      if (allBooks.any((b) => b.coverUrl.isNotEmpty))
        _SlideEstanteria(books: allBooks, year: widget.year),
      _SlideLibros(total: totalBooks, paginas: totalPages),
      _SlideDias(dias: totalActiveDays, streak: streak),
      if (topGenre != null) _SlideGenero(genero: topGenre['name'] as String? ?? ''),
      if (topAuthor != null) _SlideAutor(autor: topAuthor['name'] as String? ?? ''),
      if (bestMonth != null) _SlideMes(mes: bestMonth['name'] as String? ?? '', libros: bestMonth['count'] as int? ?? 0),
      _SlideGrafico(byMonth: byMonth),
      if (avgRating != null) _SlideRating(rating: avgRating.toDouble()),
      if (longestBook != null) _SlideLongest(
        titulo: longestBook['title'] as String? ?? '',
        paginas: longestBook['pages'] as int?,
        coverUrl: longestBook['coverUrl'] as String?,
      ),
      if (firstBook != null) _SlidePrimero(
        titulo: firstBook['title'] as String? ?? '',
        coverUrl: firstBook['coverUrl'] as String?,
      ),
      _SlideComparativa(totalBooks: totalBooks, prevYear: prevYearBooks, diff: diffVsPrevYear, year: widget.year),
      _SlideFinal(totalBooks: totalBooks, year: widget.year),
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
          PageView.builder(
            controller: _pc,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => pages[i],
          ),
          // Indicador de progreso arriba
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
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
          // Botón cerrar
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
  const _BookCover({
    required this.coverUrl,
    this.height = 180,
  });

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
                errorBuilder: (_, __, ___) => _PlaceholderCover(width: width, height: height),
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
      child: const Center(
        child: Text('📖', style: TextStyle(fontSize: 36)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo interno
// ─────────────────────────────────────────────────────────────────────────────

class _WrappedBook {
  const _WrappedBook({required this.title, required this.coverUrl});
  final String title;
  final String coverUrl;
}

// ─────────────────────────────────────────────────────────────────────────────
// Slides
// ─────────────────────────────────────────────────────────────────────────────

class _BaseSlide extends StatelessWidget {
  const _BaseSlide({
    required this.color,
    required this.child,
    this.emoji,
  });
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
    // Filtramos los que tienen portada; el resto se muestran como placeholder
    final booksConPortada = books.where((b) => b.coverUrl.isNotEmpty).toList();
    final total = books.length;

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
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Cuadrícula de portadas — desplazable si hay muchos libros
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
                  itemCount: booksConPortada.length,
                  itemBuilder: (_, i) {
                    final book = booksConPortada[i];
                    return Tooltip(
                      message: book.title,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          book.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white12,
                            child: const Center(
                              child: Text('📖', style: TextStyle(fontSize: 20)),
                            ),
                          ),
                        ),
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
          _Sub('Este es tu Wrapped $year.\nToca para descubrir tu historia lectora.'),
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
          _Sub('Y en total estuviste activo $dias ${dias == 1 ? 'día' : 'días'} este año.'),
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
          _Sub('Terminaste $libros ${libros == 1 ? 'libro' : 'libros'} ese mes.'),
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
              const monthAbbr = ['E','F','M','A','M','J','J','A','S','O','N','D'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (val > 0)
                        Text(
                          '$val',
                          style: const TextStyle(color: Colors.white54, fontSize: 9),
                        ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        height: 80 * pct + (val > 0 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: val > 0
                              ? Colors.white.withValues(alpha: 0.2 + 0.8 * pct)
                              : Colors.white12,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthAbbr[i],
                        style: const TextStyle(color: Colors.white38, fontSize: 9),
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
            Center(
              child: _BookCover(coverUrl: coverUrl!, height: 200),
            )
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
          _Headline(mejor ? 'Mejor que\nel año pasado' : 'El año pasado\nleíste más'),
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
          _Sub('$totalBooks ${totalBooks == 1 ? 'libro' : 'libros'} en $year.\nQue ${ year + 1} traiga muchos más.'),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  color: Color(0xFF0D0D1A),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
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
            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver', style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }
}
