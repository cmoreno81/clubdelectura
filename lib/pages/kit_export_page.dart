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
  final List<Color> subrayadores;
  final String atmosferaTitulo;
  final String atmosferaIcono;
  /// Etiqueta superior en la story (por defecto «ESTOY LEYENDO»).
  /// Pasa «YA LO HE LEÍDO» cuando la story se genera al finalizar.
  final String etiquetaStory;
  /// Valoración en estrellas (1–5, admite medias). Si es null no se muestran.
  final double? valoracion;

  const KitExportPage({
    super.key,
    required this.tipo,
    required this.libro,
    required this.coverUrl,
    required this.colores,
    this.subrayadores = const [],
    required this.atmosferaTitulo,
    required this.atmosferaIcono,
    this.etiquetaStory = 'ESTOY LEYENDO',
    this.valoracion,
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
        title: Text(story ? 'Story de lectura' : 'Fondo de pantalla'),
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
                    etiquetaStory: widget.etiquetaStory,
                    valoracion: widget.valoracion,
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
  final String etiquetaStory;
  final double? valoracion;

  const _KitPoster({
    required this.story,
    required this.libro,
    required this.coverUrl,
    required this.colores,
    required this.subrayadores,
    required this.atmosferaTitulo,
    required this.atmosferaIcono,
    this.etiquetaStory = 'ESTOY LEYENDO',
    this.valoracion,
  });

  @override
  Widget build(BuildContext context) {
    // Para el story: fondo claro y aireado mezclando los colores de la paleta
    // con blanco — estética editorial de ClubReads, no oscura.
    // Para el wallpaper: gradiente de paleta como antes.
    final storyTop = colores.isNotEmpty
        ? Color.lerp(const Color(0xFFFCF9FF), colores.first, 0.22)!
        : const Color(0xFFF2EEFF);
    final storyBottom = colores.isNotEmpty
        ? Color.lerp(const Color(0xFFF4EFFE), colores.last, 0.30)!
        : const Color(0xFFE6DBFF);

    final foreground = story
        ? const Color(0xFF1A0F33) // morado muy oscuro sobre fondos claros
        : ThemeData.estimateBrightnessForColor(colores.first) == Brightness.dark
            ? Colors.white
            : const Color(0xFF201A29);

    final decoration = story
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [storyTop, storyBottom],
            ),
          )
        : BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colores.first,
                colores[colores.length ~/ 2],
                colores.last,
              ],
            ),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: decoration,
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
                  etiquetaStory: etiquetaStory,
                  valoracion: valoracion,
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
  final String etiquetaStory;
  final double? valoracion;

  const _StoryComposition({
    required this.libro,
    required this.coverUrl,
    required this.colores,
    required this.subrayadores,
    required this.foreground,
    required this.atmosferaTitulo,
    required this.atmosferaIcono,
    this.etiquetaStory = 'ESTOY LEYENDO',
    this.valoracion,
  });

  // Leyenda de colores (tabbing style BookTok)
  static const List<(String, String)> _labels = [
    ('✦', 'favoritos'),
    ('💬', 'citas'),
    ('🔮', 'teorías'),
    ('👤', 'personajes'),
    ('💥', 'impacto'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final tonos = colores.take(5).toList(growable: false);

        // ── Portada: ocupa la parte izquierda-central ─────────────────
        final coverW = w * 0.62;
        final coverH = coverW * 1.50;
        final coverX = w * 0.03;
        final coverY = h * 0.09;

        // ── Tabs: emergen del borde derecho de la portada ─────────────
        // La parte izquierda queda oculta bajo la portada (efecto "metida en páginas")
        const tabOverlap = 16.0;
        final tabVisibleW = w * 0.21; // más cortas, aspecto real de banderita
        final tabTotalW = tabVisibleW + tabOverlap;
        const tabH = 21.0;
        final tabX = coverX + coverW - tabOverlap;

        // Distribución vertical + pequeños offsets X para aspecto irregular
        final tabAreaTop = coverY + coverH * 0.10;
        final tabAreaH = coverH * 0.80;
        final tabStep = tabAreaH / 4;

        // Ángulo distinto para cada tab: sensación de colocadas a mano
        const tabAngles = [0.08, -0.07, 0.11, -0.05, 0.09];
        // Pequeño offset X para que no queden todas alineadas al píxel
        final tabOffsets = [0.0, w * 0.012, -w * 0.008, w * 0.015, 0.0];

        // Color del acento para branding y detalles
        final accentColor = tonos.isNotEmpty ? tonos.first : const Color(0xFF6D4BC3);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // ── Orb decorativo arriba-derecha ──────────────────────────
            Positioned(
              right: -w * 0.22,
              top: h * 0.03,
              child: Container(
                width: w * 0.62,
                height: w * 0.62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (tonos.length > 1 ? tonos[1] : accentColor)
                          .withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Orb decorativo abajo-izquierda ─────────────────────────
            Positioned(
              left: -w * 0.25,
              bottom: h * 0.05,
              child: Container(
                width: w * 0.70,
                height: w * 0.70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (tonos.isNotEmpty ? tonos.last : const Color(0xFFD4B8FF))
                          .withValues(alpha: 0.32),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── TABS — detrás de la portada para efecto de página ──────
            for (var i = 0; i < 5; i++)
              Positioned(
                left: tabX + tabOffsets[i],
                top: tabAreaTop + i * tabStep - tabH / 2,
                child: Transform.rotate(
                  angle: tabAngles[i],
                  alignment: Alignment.centerLeft,
                  child: _PageTab(
                    color: tonos.length > i
                        ? tonos[i]
                        : const Color(0xFF8B5CF6),
                    emoji: _labels[i].$1,
                    label: _labels[i].$2,
                    totalWidth: tabTotalW,
                    height: tabH,
                    overlap: tabOverlap,
                  ),
                ),
              ),

            // ── PORTADA encima de los tabs ─────────────────────────────
            Positioned(
              left: coverX,
              top: coverY,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(4, 10),
                    ),
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.28),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: ClubBookCover(
                    title: libro,
                    imageUrl: coverUrl,
                    width: coverW,
                    highResolution: true,
                    showShadow: false,
                  ),
                ),
              ),
            ),

            // ── Tarjeta de título (frosted, abajo) ─────────────────────
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.18),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 2,
                          margin: const EdgeInsets.only(right: 7),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        Text(
                          etiquetaStory,
                          style: TextStyle(
                            color: foreground.withValues(alpha: 0.52),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      libro,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 18,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (atmosferaTitulo.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${atmosferaIcono.trim().isEmpty ? '✨' : atmosferaIcono}  $atmosferaTitulo',
                        style: TextStyle(
                          color: foreground.withValues(alpha: 0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Estrellas flotantes bajo la portada ────────────────────
            if (valoracion != null && valoracion! > 0)
              Positioned(
                left: coverX,
                width: coverW,
                top: coverY + coverH + 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = valoracion! >= i + 1;
                    final half = !filled && valoracion! >= i + 0.5;
                    return Icon(
                      filled
                          ? Icons.star_rounded
                          : half
                              ? Icons.star_half_rounded
                              : Icons.star_outline_rounded,
                      size: 22,
                      color: (filled || half)
                          ? accentColor
                          : foreground.withValues(alpha: 0.20),
                    );
                  }),
                ),
              ),

            // ── Branding top-left + dots top-right ─────────────────────
            Positioned(
              left: 18,
              right: 18,
              top: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.30),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'CLUBREADS',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: tonos
                        .map(
                          (c) => Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(left: 5),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.45),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Pestaña de página estilo BookTok tabbing ──────────────────────────────
//
// Simula una banderita/pestaña adhesiva pegada al borde de las páginas.
// La parte izquierda (`overlap` px) queda oculta bajo la portada del libro;
// la parte derecha es la "lengüeta" visible con color y leyenda.
class _PageTab extends StatelessWidget {
  final Color color;
  final String emoji;
  final String label;
  final double totalWidth;  // ancho total incluyendo la parte oculta
  final double height;
  final double overlap;     // cuántos px quedan bajo la portada

  const _PageTab({
    required this.color,
    required this.emoji,
    required this.label,
    required this.totalWidth,
    required this.height,
    required this.overlap,
  });

  @override
  Widget build(BuildContext context) {
    // Color de la pestaña: ligeramente más claro que el tono base
    final tabColor = Color.lerp(color, Colors.white, 0.28)!;

    // Color de texto: blanco si el tab es oscuro, casi negro si es claro
    final textColor =
        ThemeData.estimateBrightnessForColor(tabColor) == Brightness.dark
        ? Colors.white
        : const Color(0xFF1A1228);

    // Línea inferior (sombra entre hojas)
    final shadowColor = Color.lerp(color, Colors.black, 0.28)!;

    return SizedBox(
      width: totalWidth,
      height: height + 2, // +2 para el borde inferior (efecto hoja)
      child: Stack(
        children: [
          // ── Sombra / borde inferior (simula grosor de hoja) ──────────
          Positioned(
            left: overlap,
            right: 0,
            bottom: 0,
            height: height + 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: shadowColor.withValues(alpha: 0.45),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
            ),
          ),

          // ── Cuerpo principal de la pestaña ────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tabColor,
                // Solo el lado derecho tiene bordes redondeados
                // (izq queda enrasado al borde de las páginas del libro)
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.50),
                    blurRadius: 10,
                    offset: const Offset(4, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 5,
                    offset: const Offset(3, 2),
                  ),
                ],
              ),
            ),
          ),

          // ── Brillo sutil en la mitad superior ────────────────────────
          Positioned(
            left: overlap,
            right: 0,
            top: 0,
            height: height * 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(5),
                ),
              ),
            ),
          ),

          // ── Emoji + texto de leyenda ──────────────────────────────────
          Positioned(
            left: overlap + 8,  // empezar después de la zona oculta
            right: 6,
            top: 0,
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: height * 0.46,
                    height: 1.0,
                  ),
                ),
                SizedBox(width: height * 0.22),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: height * 0.42,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
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
