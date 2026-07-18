import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';

enum KitExportTipo { wallpaper, story }

class KitExportPage extends StatefulWidget {
  final KitExportTipo tipo;
  final String libro;
  final String coverUrl;
  final List<Color> colores;
  final String atmosferaTitulo;
  final String atmosferaIcono;

  const KitExportPage({
    super.key,
    required this.tipo,
    required this.libro,
    required this.coverUrl,
    required this.colores,
    required this.atmosferaTitulo,
    required this.atmosferaIcono,
  });

  @override
  State<KitExportPage> createState() => _KitExportPageState();
}

class _KitExportPageState extends State<KitExportPage> {
  final GlobalKey _captureKey = GlobalKey();
  bool _exportando = false;

  List<Color> get _colores {
    if (widget.colores.length >= 3) return widget.colores;
    return const [Color(0xFF6D4BC3), Color(0xFFB99CEB), Color(0xFFF5D9E8)];
  }

  Future<void> _compartir() async {
    if (_exportando) return;
    setState(() => _exportando = true);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Vista no disponible');

      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('No se pudo crear la imagen');

      final directory = await getTemporaryDirectory();
      final suffix = widget.tipo == KitExportTipo.story ? 'story' : 'wallpaper';
      final file = File(
        '${directory.path}/clubreads_${suffix}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: widget.tipo == KitExportTipo.story
              ? 'Mi próxima lectura: ${widget.libro} · ClubReads'
              : 'Mi fondo lector de ${widget.libro} · ClubReads',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo preparar la imagen.')),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.tipo == KitExportTipo.story;

    return Scaffold(
      appBar: AppBar(
        title: Text(story ? 'Story lectora' : 'Fondo de pantalla'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          40,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: RepaintBoundary(
                  key: _captureKey,
                  child: _KitPoster(
                    story: story,
                    libro: widget.libro,
                    coverUrl: widget.coverUrl,
                    colores: _colores,
                    atmosferaTitulo: widget.atmosferaTitulo,
                    atmosferaIcono: widget.atmosferaIcono,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _exportando ? null : _compartir,
            icon: _exportando
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    story ? Icons.ios_share_rounded : Icons.wallpaper_rounded,
                  ),
            label: Text(
              _exportando
                  ? 'Preparando imagen…'
                  : story
                  ? 'Compartir story'
                  : 'Guardar o compartir',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Formato vertical 9:16 listo para tu móvil.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _KitPoster extends StatelessWidget {
  final bool story;
  final String libro;
  final String coverUrl;
  final List<Color> colores;
  final String atmosferaTitulo;
  final String atmosferaIcono;

  const _KitPoster({
    required this.story,
    required this.libro,
    required this.coverUrl,
    required this.colores,
    required this.atmosferaTitulo,
    required this.atmosferaIcono,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(colores.first) == Brightness.dark
        ? Colors.white
        : const Color(0xFF201A29);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: story ? Alignment.topLeft : Alignment.topCenter,
            end: story ? Alignment.bottomRight : Alignment.bottomCenter,
            colors: story
                ? [colores.last, colores.first, colores[colores.length ~/ 2]]
                : [colores.first, colores[colores.length ~/ 2], colores.last],
          ),
        ),
        child: CustomPaint(
          painter: _PosterTexture(color: foreground, editorial: story),
          child: story
              ? _StoryComposition(
                  libro: libro,
                  coverUrl: coverUrl,
                  colores: colores,
                  foreground: foreground,
                  atmosferaTitulo: atmosferaTitulo,
                  atmosferaIcono: atmosferaIcono,
                )
              : _WallpaperComposition(
                  libro: libro,
                  coverUrl: coverUrl,
                  foreground: foreground,
                  atmosferaTitulo: atmosferaTitulo,
                  atmosferaIcono: atmosferaIcono,
                ),
        ),
      ),
    );
  }
}

class _WallpaperComposition extends StatelessWidget {
  final String libro;
  final String coverUrl;
  final Color foreground;
  final String atmosferaTitulo;
  final String atmosferaIcono;

  const _WallpaperComposition({
    required this.libro,
    required this.coverUrl,
    required this.foreground,
    required this.atmosferaTitulo,
    required this.atmosferaIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
      child: Column(
        children: [
          const SizedBox(height: 70),
          Text(
            atmosferaIcono.trim().isEmpty ? '✨' : atmosferaIcono,
            style: const TextStyle(fontSize: 30),
          ),
          const Spacer(),
          ClubBookCover(
            title: libro,
            imageUrl: coverUrl,
            width: 174,
            showShadow: true,
          ),
          const SizedBox(height: 24),
          Text(
            libro,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 27,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            atmosferaTitulo.trim().isEmpty
                ? 'Mi rincón de lectura'
                : atmosferaTitulo,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.76),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            'ClubReads',
            style: TextStyle(
              color: foreground.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryComposition extends StatelessWidget {
  final String libro;
  final String coverUrl;
  final List<Color> colores;
  final Color foreground;
  final String atmosferaTitulo;
  final String atmosferaIcono;

  const _StoryComposition({
    required this.libro,
    required this.coverUrl,
    required this.colores,
    required this.foreground,
    required this.atmosferaTitulo,
    required this.atmosferaIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        border: Border.all(color: foreground.withValues(alpha: 0.36)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CLUBREADS / 01',
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                atmosferaIcono.trim().isEmpty ? '✨' : atmosferaIcono,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            'MI PRÓXIMA\nLECTURA',
            style: TextStyle(
              color: foreground,
              fontSize: 31,
              height: 0.95,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Transform.rotate(
              angle: 0.035,
              child: ClubBookCover(
                title: libro,
                imageUrl: coverUrl,
                width: 146,
                showShadow: true,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            libro,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 24,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: colores.take(5).map((color) {
              return Container(
                width: 25,
                height: 7,
                margin: const EdgeInsets.only(right: 5),
                color: color,
              );
            }).toList(),
          ),
          const SizedBox(height: 15),
          Text(
            atmosferaTitulo.trim().isEmpty
                ? 'Una historia está a punto de comenzar'
                : atmosferaTitulo,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterTexture extends CustomPainter {
  final Color color;
  final bool editorial;

  const _PosterTexture({required this.color, required this.editorial});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var index = 0; index < (editorial ? 7 : 14); index++) {
      final inset = 18.0 + index * 24;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width, 0), radius: inset),
        0,
        3.14,
        false,
        paint,
      );
      canvas.drawCircle(
        Offset((index * 73) % size.width, (index * 137) % size.height),
        2 + (index % 3).toDouble(),
        Paint()..color = color.withValues(alpha: 0.09),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PosterTexture oldDelegate) =>
      oldDelegate.color != color || oldDelegate.editorial != editorial;
}
