import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/kit/rotulador_preview.dart';

enum KitExportTipo { wallpaper, story }

class KitExportPage extends StatefulWidget {
  final KitExportTipo tipo;
  final String libro;
  final String coverUrl;
  final List<Color> colores;
  final List<Color> subrayadores;
  final String atmosferaTitulo;
  final String atmosferaIcono;

  const KitExportPage({
    super.key,
    required this.tipo,
    required this.libro,
    required this.coverUrl,
    required this.colores,
    this.subrayadores = const [],
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
                    subrayadores: widget.subrayadores.isEmpty
                        ? _colores
                        : widget.subrayadores,
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
  final List<Color> subrayadores;
  final String atmosferaTitulo;
  final String atmosferaIcono;

  const _KitPoster({
    required this.story,
    required this.libro,
    required this.coverUrl,
    required this.colores,
    required this.subrayadores,
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
                  subrayadores: subrayadores,
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
            highResolution: true,
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
  final List<Color> subrayadores;
  final Color foreground;
  final String atmosferaTitulo;
  final String atmosferaIcono;

  const _StoryComposition({
    required this.libro,
    required this.coverUrl,
    required this.colores,
    required this.subrayadores,
    required this.foreground,
    required this.atmosferaTitulo,
    required this.atmosferaIcono,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final tonos = colores.take(5).toList(growable: false);
        final rotuladores = subrayadores.take(5).toList(growable: false);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 22,
              right: 22,
              top: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CLUBREADS',
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
            ),
            Positioned(
              left: 24,
              top: 62,
              child: Text(
                'MI PUNTO\nDE LECTURA',
                style: TextStyle(
                  color: foreground,
                  fontSize: 27,
                  height: 0.98,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            for (var index = 0; index < tonos.length; index++)
              Positioned(
                right: 40.0 + (index % 2) * 20,
                top: height * 0.22 + index * 39,
                child: Transform.rotate(
                  angle: index.isEven ? 0.08 : -0.06,
                  child: _PostItMarcador(
                    color: tonos[index],
                    label: const [
                      'citas',
                      'teorías',
                      'favoritos',
                      'personajes',
                      'impacto',
                    ][index],
                  ),
                ),
              ),
            Positioned(
              left: width * 0.22,
              top: height * 0.22,
              child: Transform.rotate(
                angle: -0.045,
                child: ClubBookCover(
                  title: libro,
                  imageUrl: coverUrl,
                  width: width * 0.5,
                  highResolution: true,
                  showShadow: true,
                ),
              ),
            ),
            Positioned(
              left: 26,
              right: 92,
              bottom: height * 0.17,
              child: Transform.rotate(
                angle: -0.035,
                child: _NotaLectura(
                  libro: libro,
                  atmosferaTitulo: atmosferaTitulo,
                  color: tonos.length > 1 ? tonos[1] : tonos.first,
                  foreground: foreground,
                ),
              ),
            ),
            for (var index = 0; index < rotuladores.length; index++)
              Positioned(
                left: 20.0 + index * 22,
                bottom: 28.0 + (index.isEven ? 0 : 8),
                child: Transform.rotate(
                  angle: -0.16 + index * 0.075,
                  child: RotuladorPreview(
                    color: rotuladores[index],
                    vertical: false,
                    length: width * 0.46,
                    thickness: 20,
                  ),
                ),
              ),
            Positioned(
              right: 22,
              bottom: 18,
              child: Text(
                'mi kit lector',
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PostItMarcador extends StatelessWidget {
  final Color color;
  final String label;

  const _PostItMarcador({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 31,
      padding: const EdgeInsets.only(left: 29, right: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.white, 0.16),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: const TextStyle(
          color: Color(0xFF342C39),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotaLectura extends StatelessWidget {
  final String libro;
  final String atmosferaTitulo;
  final Color color;
  final Color foreground;

  const _NotaLectura({
    required this.libro,
    required this.atmosferaTitulo,
    required this.color,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 14, 14),
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.white, 0.28),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            libro,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF2B2330),
              fontSize: 18,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            atmosferaTitulo.trim().isEmpty
                ? 'una nueva historia empieza aquí'
                : atmosferaTitulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.72),
              fontSize: 10,
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
