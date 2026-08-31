import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/general_dashboard.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/reading_cover_calendar.dart';

class MonthlyReadingSharePage extends StatefulWidget {
  const MonthlyReadingSharePage({
    super.key,
    required this.calendar,
    required this.userName,
  });

  final ReadingCalendar calendar;
  final String userName;

  @override
  State<MonthlyReadingSharePage> createState() =>
      _MonthlyReadingSharePageState();
}

class _MonthlyReadingSharePageState extends State<MonthlyReadingSharePage> {
  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      for (final book in widget.calendar.finishedBooks) {
        if (book.coverUrl.trim().isNotEmpty) {
          try {
            await precacheImage(NetworkImage(book.coverUrl), context);
          } catch (_) {
            // El póster conserva un hueco editorial si una portada no responde.
          }
        }
      }
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Vista no disponible');

      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('No se pudo crear la imagen');

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/clubreads_mes_${widget.calendar.year}_${widget.calendar.month}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              'Mi mes lector en ClubReads: '
              '${widget.calendar.finishedBooks.length} '
              '${widget.calendar.finishedBooks.length == 1 ? 'libro' : 'libros'} 📚',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir mi mes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: RepaintBoundary(
                  key: _captureKey,
                  child: _MonthlyReadingPoster(
                    calendar: widget.calendar,
                    userName: widget.userName,
                  ),
                ),
              ),
            ),
          ),
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
              _sharing ? 'Preparando imagen…' : 'Compartir en Instagram',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Se abrirá el menú para elegir Instagram Stories u otra aplicación.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MonthlyReadingPoster extends StatelessWidget {
  const _MonthlyReadingPoster({required this.calendar, required this.userName});

  final ReadingCalendar calendar;
  final String userName;

  static const _months = [
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = calendar.finishedBooks.fold<int>(
      0,
      (total, book) => total + book.pages,
    );
    final booksWithPages =
        calendar.finishedBooks.where((book) => book.pages > 0).length;
    final hasAnyPageData =
        calendar.finishedBooks.isNotEmpty && booksWithPages > 0;
    final hasCompletePageData =
        hasAnyPageData &&
        booksWithPages == calendar.finishedBooks.length;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: ClipRect(
      child: CustomPaint(
        painter: const _PaperPainter(),
        child: Container(
          color: const Color(0xFFF7F0E4).withValues(alpha: .93),
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.primaryDark,
                    size: 25,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'CLUBREADS',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${_months[calendar.month - 1]} ${calendar.year}',
                style: const TextStyle(
                  color: AppColors.inkCoral,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mi mes\nlector',
                style: TextStyle(
                  color: Color(0xFF2C2430),
                  fontSize: 43,
                  height: .92,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.8,
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                flex: 7,
                child: calendar.readings.isEmpty
                    ? const _EmptyMonthlyPoster()
                    : Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .78),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryLight),
                        ),
                        child: Builder(
                          builder: (context) {
                            // Calcular semanas del mes para ajustar el aspecto
                            final firstDay = DateTime(
                              calendar.year,
                              calendar.month,
                              1,
                            );
                            final lastDay = DateTime(
                              calendar.year,
                              calendar.month + 1,
                              0,
                            );
                            final startOffset = (firstDay.weekday - 1) % 7;
                            final totalCells = startOffset + lastDay.day;
                            final weeks = (totalCells / 7).ceil();
                            // 5 semanas → .88, 6 semanas → .74
                            final ratio = weeks >= 6 ? .74 : .88;
                            return ReadingCoverCalendar(
                              calendar: calendar,
                              highResolution: true,
                              showMonthHeader: false,
                              cellAspectRatio: ratio,
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _PosterMetric(
                    value: '${calendar.finishedBooks.length}',
                    label: calendar.finishedBooks.length == 1
                        ? 'LIBRO'
                        : 'LIBROS',
                  ),
                  const SizedBox(width: 26),
                  _PosterMetric(
                    value: hasAnyPageData
                        ? (hasCompletePageData ? '$pages' : '$pages+')
                        : '—',
                    label: 'PÁGINAS',
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      userName,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ), // ClipRect
    ); // MediaQuery.withClampedTextScaling
  }
}

class _PosterMetric extends StatelessWidget {
  const _PosterMetric({required this.value, required this.label});

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
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _EmptyMonthlyPoster extends StatelessWidget {
  const _EmptyMonthlyPoster();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Las próximas historias de este mes aún están por escribir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 18,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFF7C5A43).withValues(alpha: .045)
      ..strokeWidth = .7;
    for (double y = 8; y < size.height; y += 17) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 5), line);
    }
    final fleck = Paint()
      ..color = AppColors.primary.withValues(alpha: .035)
      ..strokeWidth = 1.2;
    for (double x = 11; x < size.width; x += 31) {
      canvas.drawCircle(Offset(x, (x * 7) % size.height), .8, fleck);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
