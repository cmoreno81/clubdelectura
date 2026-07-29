import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/general_dashboard.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/club_book_cover.dart';

class YearReadingSharePage extends StatefulWidget {
  const YearReadingSharePage({
    super.key,
    required this.year,
    required this.books,
    required this.userName,
  });

  final int year;
  final List<YearShelfBook> books;
  final String userName;

  @override
  State<YearReadingSharePage> createState() => _YearReadingSharePageState();
}

class _YearReadingSharePageState extends State<YearReadingSharePage> {
  late final List<GlobalKey> _captureKeys;
  bool _sharing = false;

  List<YearShelfBook> get _orderedBooks =>
      [...widget.books]
        ..sort((left, right) => left.finishedAt.compareTo(right.finishedAt));

  List<List<YearShelfBook>> get _bookPages {
    final ordered = _orderedBooks;
    if (ordered.isEmpty) return [const []];
    return [
      for (var start = 0; start < ordered.length; start += 30)
        ordered.sublist(
          start,
          start + 30 < ordered.length ? start + 30 : ordered.length,
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    final pageCount = widget.books.isEmpty
        ? 1
        : (widget.books.length / 30).ceil();
    _captureKeys = List.generate(pageCount, (_) => GlobalKey());
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      for (final book in widget.books) {
        if (book.coverUrl.trim().isEmpty) continue;
        try {
          await precacheImage(NetworkImage(book.coverUrl), context);
        } catch (_) {
          // El diseño conserva el lomo editorial si una portada no responde.
        }
      }
      await WidgetsBinding.instance.endOfFrame;

      final directory = await getTemporaryDirectory();
      final files = <XFile>[];
      for (var index = 0; index < _captureKeys.length; index++) {
        final boundary =
            _captureKeys[index].currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary == null) throw StateError('Vista no disponible');

        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) throw StateError('No se pudo crear la imagen');

        final file = File(
          '${directory.path}/clubreads_ano_${widget.year}_${index + 1}.png',
        );
        await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
        files.add(XFile(file.path));
      }

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text:
              'Mi año lector ${widget.year} en ClubReads: '
              '${widget.books.length} '
              '${widget.books.length == 1 ? 'libro' : 'libros'} 📚',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo preparar la imagen.')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _bookPages;
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir mi año')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          child: Column(
            children: [
              for (var index = 0; index < pages.length; index++) ...[
                if (pages.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Lámina ${index + 1} de ${pages.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: RepaintBoundary(
                        key: _captureKeys[index],
                        child: _YearReadingPoster(
                          year: widget.year,
                          books: pages[index],
                          allBooks: widget.books,
                          userName: widget.userName,
                          page: index + 1,
                          pageCount: pages.length,
                        ),
                      ),
                    ),
                  ),
                ),
                if (index < pages.length - 1)
                  const SizedBox(height: AppSpacing.xl),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _sharing ? null : _share,
                icon: _sharing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(
                  _sharing ? 'Preparando imagen…' : 'Compartir mi año lector',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                pages.length == 1
                    ? 'Se abrirá el menú para elegir Instagram Stories u otra aplicación.'
                    : 'Se compartirán ${pages.length} láminas en orden para publicar toda la estantería.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearReadingPoster extends StatelessWidget {
  const _YearReadingPoster({
    required this.year,
    required this.books,
    required this.allBooks,
    required this.userName,
    required this.page,
    required this.pageCount,
  });

  final int year;
  final List<YearShelfBook> books;
  final List<YearShelfBook> allBooks;
  final String userName;
  final int page;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final ordered = [...books]
      ..sort((left, right) => left.finishedAt.compareTo(right.finishedAt));
    final shelfCount = ((ordered.length / 5).ceil()).clamp(4, 6);
    final activeMonths = allBooks
        .map((book) => DateTime.tryParse(book.finishedAt)?.month)
        .whereType<int>()
        .toSet()
        .length;

    return ClipRect(
      child: CustomPaint(
        painter: const _YearPaperPainter(),
        child: Container(
          color: const Color(0xFFF5EBDD).withValues(alpha: .94),
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.primaryDark,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'CLUBREADS',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '$year',
                style: const TextStyle(
                  color: AppColors.inkCoral,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                page == 1 ? 'Mi año\nentre libros' : 'Mi estantería\ncontinúa',
                style: const TextStyle(
                  color: Color(0xFF2C2430),
                  fontSize: 39,
                  height: .94,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8D4B7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD0AF84)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ordered.isEmpty
                      ? const Center(
                          child: Text(
                            'Tu próxima historia\nempieza aquí',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (var shelf = 0; shelf < shelfCount; shelf++)
                              Expanded(
                                child: _PosterShelf(
                                  shelfIndex: shelf,
                                  books: _booksForShelf(ordered, shelf),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _YearMetric(value: '${allBooks.length}', label: 'LIBROS'),
                  const SizedBox(width: 24),
                  _YearMetric(value: '$activeMonths', label: 'MESES LEYENDO'),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (pageCount > 1)
                        Text(
                          '$page / $pageCount',
                          style: const TextStyle(
                            color: AppColors.inkCoral,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 82),
                        child: Text(
                          userName,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<YearShelfBook> _booksForShelf(List<YearShelfBook> visible, int shelf) {
    final start = shelf * 5;
    if (start >= visible.length) return const [];
    final end = start + 5 < visible.length ? start + 5 : visible.length;
    return visible.sublist(start, end);
  }
}

class _PosterShelf extends StatelessWidget {
  const _PosterShelf({required this.shelfIndex, required this.books});

  final int shelfIndex;
  final List<YearShelfBook> books;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: const _PosterWoodGrain())),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 10,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFB9834F),
                  Color(0xFF8A5937),
                  Color(0xFF68422E),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          bottom: 9,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < books.length; index++) ...[
                  if (index > 0) const SizedBox(width: 3),
                  Expanded(
                    child: Transform.rotate(
                      angle:
                          ((books[index].id.hashCode.abs() + index) % 5 - 2) *
                          .012,
                      alignment: Alignment.bottomCenter,
                      child: LayoutBuilder(
                        builder: (context, constraints) => ClubBookCover(
                          title: books[index].title,
                          imageUrl: books[index].coverUrl,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          borderRadius: BorderRadius.circular(3),
                          showShadow: false,
                        ),
                      ),
                    ),
                  ),
                ],
                if (books.length < 5) ...[
                  const Spacer(),
                  Icon(
                    shelfIndex.isEven
                        ? Icons.local_florist_rounded
                        : Icons.light_rounded,
                    size: 24,
                    color: shelfIndex.isEven
                        ? const Color(0xFF5D7954)
                        : const Color(0xFFD49A3A),
                  ),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _YearMetric extends StatelessWidget {
  const _YearMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2C2430),
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _YearPaperPainter extends CustomPainter {
  const _YearPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFF9D775E).withValues(alpha: .06)
      ..strokeWidth = .7;
    for (double y = 16; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 1.5), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PosterWoodGrain extends CustomPainter {
  const _PosterWoodGrain();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7F5839).withValues(alpha: .07)
      ..strokeWidth = .6;
    for (double y = 8; y < size.height; y += 13) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
