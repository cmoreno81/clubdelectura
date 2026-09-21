import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/club_wrapped.dart';
import '../services/api_exception.dart';
import '../services/club_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/error_view.dart';

/// Club Wrapped: el resumen anual del club entero, compartible como
/// imagen — el "wrapped" personal, pero del grupo. Algo que Mistbook no
/// puede ofrecer: ellos no tienen clubes, solo personas.
class ClubWrappedPage extends StatefulWidget {
  final String clubId;
  final int? year;

  const ClubWrappedPage({super.key, required this.clubId, this.year});

  @override
  State<ClubWrappedPage> createState() => _ClubWrappedPageState();
}

class _ClubWrappedPageState extends State<ClubWrappedPage> {
  late Future<ClubWrapped> _future;
  final GlobalKey _captureKey = GlobalKey();
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _future = ClubService().getClubWrapped(widget.clubId, year: widget.year);
  }

  Future<void> _compartir(ClubWrapped w) async {
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
        '${directory.path}/clubreads_wrapped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '${w.clubNombre} · ${w.year} en ClubReads',
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
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Club Wrapped')),
      body: FutureBuilder<ClubWrapped>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final e = snapshot.error;
            if (e is ApiException) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(e.message, textAlign: TextAlign.center),
                ),
              );
            }
            return ErrorView(
              onRetry: () => setState(() {
                _future = ClubService().getClubWrapped(
                  widget.clubId,
                  year: widget.year,
                );
              }),
            );
          }
          final w = snapshot.data!;
          if (w.totalLibros == 0 && w.totalComentarios == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Todavía no hay suficiente actividad en ${w.year} para generar el Wrapped del club.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary,
                ),
              ),
            );
          }
          return ListView(
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
                      child: _WrappedPoster(w: w),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _exportando ? null : () => _compartir(w),
                icon: _exportando
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(
                  _exportando ? 'Preparando imagen…' : 'Compartir Wrapped',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WrappedPoster extends StatelessWidget {
  final ClubWrapped w;

  const _WrappedPoster({required this.w});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.7),
            radius: 1.4,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
              Color(0xFF16091D),
            ],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: _Glow(color: AppColors.gold, size: 200, opacity: 0.28),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: _Glow(color: Colors.white, size: 210, opacity: 0.12),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'CLUB WRAPPED · ${w.year}',
                      style: TextStyle(
                        color: AppColors.gold.withValues(alpha: 0.95),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    w.clubNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${w.miembros} ${w.miembros == 1 ? 'lectora' : 'lectoras'}'
                    '${w.racha > 0 ? ' · 🔥 ${w.racha}' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatBlock(numero: '${w.totalLibros}', etiqueta: 'libros'),
                      _StatDivider(),
                      _StatBlock(
                        numero: '${w.totalComentarios}',
                        etiqueta: 'comentarios',
                      ),
                      if (w.generoMasLeido != null) ...[
                        _StatDivider(),
                        _StatBlock(
                          numero: w.generoMasLeido!,
                          etiqueta: 'género top',
                          esTexto: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (w.libroDelAnioTitulo != null) ...[
                    Text(
                      '👑 Libro del año',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: ClubBookCover(
                          title: w.libroDelAnioTitulo!,
                          imageUrl: w.libroDelAnioCoverUrl ?? '',
                          width: 84,
                          highResolution: true,
                          showShadow: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      w.libroDelAnioTitulo!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ] else if (w.favoritoTitulo != null) ...[
                    Text(
                      '❤️ Favorito del club',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: ClubBookCover(
                          title: w.favoritoTitulo!,
                          imageUrl: w.favoritoCoverUrl ?? '',
                          width: 84,
                          highResolution: true,
                          showShadow: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      w.favoritoTitulo!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ],
                  const Spacer(),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
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

class _StatBlock extends StatelessWidget {
  final String numero;
  final String etiqueta;
  final bool esTexto;

  const _StatBlock({
    required this.numero,
    required this.etiqueta,
    this.esTexto = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          numero,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: esTexto ? 15 : 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          etiqueta,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.white.withValues(alpha: 0.16),
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
