import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/historial_clubvision.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';

/// Tarjeta compartible con el resultado de una edición de Clubvisión:
/// libro ganador, puntos y podio (2º y 3er puesto).
class ClubvisionSharePage extends StatefulWidget {
  final HistorialClubvision historial;
  final String mes;
  final String? clubNombre;

  const ClubvisionSharePage({
    super.key,
    required this.historial,
    required this.mes,
    this.clubNombre,
  });

  @override
  State<ClubvisionSharePage> createState() => _ClubvisionSharePageState();
}

class _ClubvisionSharePageState extends State<ClubvisionSharePage> {
  final GlobalKey _captureKey = GlobalKey();
  bool _exportando = false;

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
      final file = File(
        '${directory.path}/clubreads_clubvision_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              'Clubvisión de ${widget.mes}: "${widget.historial.ganadora}" · ClubReads',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir resultado')),
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: RepaintBoundary(
                  key: _captureKey,
                  child: _ClubvisionPoster(
                    historial: widget.historial,
                    mes: widget.mes,
                    clubNombre: widget.clubNombre,
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
                : const Icon(Icons.ios_share_rounded),
            label: Text(
              _exportando ? 'Preparando imagen…' : 'Compartir resultado',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Formato vertical 4:5, listo para publicar.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _ClubvisionPoster extends StatelessWidget {
  final HistorialClubvision historial;
  final String mes;
  final String? clubNombre;

  const _ClubvisionPoster({
    required this.historial,
    required this.mes,
    this.clubNombre,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.3,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
              Color(0xFF16091D),
            ],
            stops: [0, 0.6, 1],
          ),
        ),
        child: Stack(
          children: [
            // Resplandores ambientales
            Positioned(
              top: -40,
              left: -40,
              child: _Glow(color: AppColors.gold, size: 180, opacity: 0.30),
            ),
            Positioned(
              bottom: -30,
              right: -30,
              child: _Glow(color: Colors.white, size: 200, opacity: 0.14),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'CLUBVISIÓN · GALA LITERARIA',
                      style: TextStyle(
                        color: AppColors.gold.withValues(alpha: 0.95),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clubNombre?.trim().isNotEmpty == true
                        ? '${clubNombre!} · $mes'
                        : mes,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📖 Libro ganador',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ClubBookCover(
                        title: historial.ganadora,
                        imageUrl: historial.ganadoraCoverUrl,
                        width: 92,
                        highResolution: true,
                        showShadow: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    historial.ganadora.trim().isEmpty
                        ? 'Sin datos'
                        : historial.ganadora,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${historial.puntos} puntos',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (historial.segunda.trim().isNotEmpty ||
                      historial.tercera.trim().isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (historial.segunda.trim().isNotEmpty)
                          _PodioMini(
                            posicion: '2º',
                            titulo: historial.segunda,
                            coverUrl: historial.segundaCoverUrl,
                          ),
                        if (historial.segunda.trim().isNotEmpty &&
                            historial.tercera.trim().isNotEmpty)
                          const SizedBox(width: 22),
                        if (historial.tercera.trim().isNotEmpty)
                          _PodioMini(
                            posicion: '3º',
                            titulo: historial.tercera,
                            coverUrl: historial.terceraCoverUrl,
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(
                          text: 'Club',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        TextSpan(
                          text: 'Reads',
                          style: TextStyle(
                            color: AppColors.gold.withValues(alpha: 0.92),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodioMini extends StatelessWidget {
  final String posicion;
  final String titulo;
  final String coverUrl;

  const _PodioMini({
    required this.posicion,
    required this.titulo,
    required this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: ClubBookCover(
            title: titulo,
            imageUrl: coverUrl,
            width: 46,
            highResolution: false,
            showShadow: false,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          posicion,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _Glow({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
