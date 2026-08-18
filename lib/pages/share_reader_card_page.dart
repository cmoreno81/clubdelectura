import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';

/// Datos que alimentan la tarjeta compartible.
/// Tanto mi_espacio_page como perfil_usuario_page construyen este objeto
/// desde sus respectivos modelos.
class ReaderCardData {
  const ReaderCardData({
    required this.userName,
    required this.booksFinished,
    this.avatarUrl = '',
    this.booksReading = 0,
    this.topGenre = '',
    this.monthStreak = 0,
    this.pagesRead = 0,
    this.coverUrls = const [],
  });

  final String userName;
  final String avatarUrl;
  final int booksFinished;
  final int booksReading;
  final String topGenre;
  final int monthStreak;
  final int pagesRead;
  final List<String> coverUrls;
}

// ─────────────────────────────────────────────────────────────────────────────

class ShareReaderCardPage extends StatefulWidget {
  const ShareReaderCardPage({super.key, required this.data});

  final ReaderCardData data;

  @override
  State<ShareReaderCardPage> createState() => _ShareReaderCardPageState();
}

class _ShareReaderCardPageState extends State<ShareReaderCardPage> {
  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      // Precachear portadas de red antes de capturar
      for (final url in widget.data.coverUrls) {
        if (url.trim().isNotEmpty) {
          try {
            await precacheImage(NetworkImage(url), context);
          } catch (_) {}
        }
      }
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Vista no disponible');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('No se pudo crear la imagen');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/clubreads_perfil_lector.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              '${widget.data.booksFinished} libros leídos en ${DateTime.now().year} 📚 '
              '¡Únete a ClubReads!',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo compartir la tarjeta')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tarjeta lectora'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // ── Vista previa centrada ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: RepaintBoundary(
                key: _captureKey,
                child: _ReaderCard(data: widget.data),
              ),
            ),
            const Spacer(),
            // ── Botón de compartir ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sharing ? null : _share,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.ios_share_rounded),
                  label: Text(
                    _sharing ? 'Generando imagen…' : 'Compartir tarjeta',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReaderCard — el diseño visual que se captura y comparte
// ─────────────────────────────────────────────────────────────────────────────

class _ReaderCard extends StatelessWidget {
  const _ReaderCard({required this.data});

  final ReaderCardData data;

  @override
  Widget build(BuildContext context) {
    final firstName = data.userName.split(' ').first;
    final validCovers =
        data.coverUrls.where((u) => u.trim().isNotEmpty).take(4).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B1F4D), // púrpura oscuro
            Color(0xFF603B73), // AppColors.primary
            Color(0xFFAD3B30), // coral oscuro
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Stack(
        children: [
          // Círculos decorativos de fondo
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .05),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .04),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .035),
              ),
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Branding ──────────────────────────────────────────────
                Row(
                  children: [
                    const Text('📚', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'ClubReads',
                      style: AppTextStyles.subtitle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${DateTime.now().year}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .55),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Avatar + nombre ───────────────────────────────────────
                Row(
                  children: [
                    _Avatar(name: data.userName, avatarUrl: data.avatarUrl),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.4,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Lectora · ClubReads',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .65),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Stat principal ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .18),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${data.booksFinished}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.booksFinished == 1 ? 'libro leído' : 'libros leídos'} en ${DateTime.now().year}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .80),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Stats secundarios ─────────────────────────────────────
                Row(
                  children: [
                    if (data.booksReading > 0)
                      _MiniStat(
                        emoji: '📖',
                        value: '${data.booksReading}',
                        label: 'leyendo',
                      ),
                    if (data.monthStreak > 0) ...[
                      if (data.booksReading > 0)
                        const SizedBox(width: AppSpacing.sm),
                      _MiniStat(
                        emoji: '🔥',
                        value: '${data.monthStreak}',
                        label:
                            data.monthStreak == 1 ? 'mes seguido' : 'meses',
                      ),
                    ],
                    if (data.topGenre.isNotEmpty) ...[
                      if (data.booksReading > 0 || data.monthStreak > 0)
                        const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MiniStat(
                          emoji: '💕',
                          value: data.topGenre,
                          label: 'favorito',
                        ),
                      ),
                    ],
                  ],
                ),

                // ── Portadas ──────────────────────────────────────────────
                if (validCovers.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: validCovers.asMap().entries.map((e) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: e.key < validCovers.length - 1
                              ? AppSpacing.xs
                              : 0,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: ClubBookCover(
                            title: '',
                            imageUrl: e.value,
                            width: 60,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // ── Footer ────────────────────────────────────────────────
                Center(
                  child: Text(
                    '¡Únete en ClubReads! 📚',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .3,
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

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.avatarUrl});

  final String name;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').take(2).map((p) => p[0].toUpperCase()).join();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .18),
        border: Border.all(color: Colors.white.withValues(alpha: .30), width: 2),
        image: avatarUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: avatarUrl.isEmpty
          ? Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : null,
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withValues(alpha: .15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$value $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
