import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Formatos de imagen para compartir un libro terminado.
/// El lienzo es de [ancho] × [alto] puntos lógicos y se exporta ×3, así que
/// la imagen final mide exactamente 1080 px de ancho.
enum FormatoCompartir {
  story('Story', '9:16', 360, 640),
  feed('Feed', '4:5', 360, 450);

  const FormatoCompartir(this.nombre, this.proporcion, this.ancho, this.alto);

  final String nombre;
  final String proporcion;
  final double ancho;
  final double alto;
}

/// Hoja para elegir formato (story o feed de Instagram) y compartir la imagen
/// del libro recién terminado.
Future<void> mostrarCompartirLibroTerminado(
  BuildContext context, {
  required String titulo,
  String coverUrl = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        CompartirLibroTerminadoSheet(titulo: titulo, coverUrl: coverUrl),
  );
}

class CompartirLibroTerminadoSheet extends StatefulWidget {
  const CompartirLibroTerminadoSheet({
    super.key,
    required this.titulo,
    required this.coverUrl,
  });

  final String titulo;
  final String coverUrl;

  @override
  State<CompartirLibroTerminadoSheet> createState() =>
      _CompartirLibroTerminadoSheetState();
}

class _CompartirLibroTerminadoSheetState
    extends State<CompartirLibroTerminadoSheet> {
  final GlobalKey _captureKey = GlobalKey();
  FormatoCompartir _formato = FormatoCompartir.story;
  bool _sharing = false;
  String? _error;

  Future<void> _compartir() async {
    if (_sharing) return;
    setState(() {
      _sharing = true;
      _error = null;
    });
    try {
      if (widget.coverUrl.trim().isNotEmpty) {
        // onError: precacheImage no lanza, y sin él Flutter lo reporta como fallo.
        await precacheImage(
          NetworkImage(widget.coverUrl),
          context,
          onError: (_, _) {},
        );
      }
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Vista no disponible');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('No se pudo crear la imagen');

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/clubreads_libro_${_formato.name}_'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: '¡He terminado de leer "${widget.titulo}"! 📚✨ #ClubReads',
          files: [XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo preparar la imagen. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Compartir libro terminado',
              style: AppTextStyles.title.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<FormatoCompartir>(
              key: const Key('compartir-formato'),
              showSelectedIcon: false,
              segments: [
                for (final f in FormatoCompartir.values)
                  ButtonSegment(
                    value: f,
                    label: Text(
                      f == FormatoCompartir.story
                          ? 'Story · ${f.proporcion}'
                          : 'Feed · ${f.proporcion}',
                    ),
                  ),
              ],
              selected: {_formato},
              onSelectionChanged: (s) => setState(() => _formato = s.first),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formato == FormatoCompartir.story
                  ? 'Pantalla completa para stories (1080 × 1920).'
                  : 'Para publicar en el feed de Instagram (1080 × 1350).',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _formato.ancho / _formato.alto,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RepaintBoundary(
                      key: _captureKey,
                      child: TarjetaLibroTerminado(
                        formato: _formato,
                        titulo: widget.titulo,
                        coverUrl: widget.coverUrl,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                key: const Key('compartir-error'),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.danger,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('compartir-boton'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _sharing ? null : _compartir,
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share_rounded, size: 20),
                label: Text(_sharing ? 'Preparando…' : 'Compartir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La imagen que se exporta. Tiene tamaño lógico fijo según el formato.
class TarjetaLibroTerminado extends StatelessWidget {
  const TarjetaLibroTerminado({
    super.key,
    required this.formato,
    required this.titulo,
    required this.coverUrl,
  });

  final FormatoCompartir formato;
  final String titulo;
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    final story = formato == FormatoCompartir.story;
    final anchoPortada = story ? 170.0 : 120.0;
    final altoPortada = anchoPortada * 1.45;

    return SizedBox(
      width: formato.ancho,
      height: formato.alto,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.background],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            28,
            story ? 48 : 28,
            28,
            story ? 40 : 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎉', style: TextStyle(fontSize: story ? 48 : 34)),
              SizedBox(height: story ? 10 : 4),
              Text(
                '¡Libro terminado!',
                style: AppTextStyles.title.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: story ? 28 : 24,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: story ? 28 : 16),
              Container(
                width: anchoPortada,
                height: altoPortada,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _sinPortada(),
                        )
                      : _sinPortada(),
                ),
              ),
              SizedBox(height: story ? 28 : 16),
              Text(
                titulo,
                style: AppTextStyles.title.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: story ? 22 : 18,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
                maxLines: story ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: story ? 24 : 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ClubReads',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.4,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sinPortada() => Container(
    color: AppColors.primaryLight,
    alignment: Alignment.center,
    child: const Icon(
      Icons.menu_book_rounded,
      color: AppColors.primary,
      size: 52,
    ),
  );
}
