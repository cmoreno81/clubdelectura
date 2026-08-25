import 'package:flutter/material.dart';

import '../../models/kit_lectura_seleccion.dart';
import '../../services/kit_lectura_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_card.dart';

class KitLecturaCard extends StatefulWidget {
  final String bookId;
  final VoidCallback onTap;

  const KitLecturaCard({
    super.key,
    required this.bookId,
    required this.onTap,
  });

  @override
  State<KitLecturaCard> createState() => _KitLecturaCardState();
}

class _KitLecturaCardState extends State<KitLecturaCard> {
  final KitLecturaService _kitService = KitLecturaService();
  KitLecturaSeleccion? _seleccion;

  static const int _totalSecciones = 6;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (widget.bookId.isEmpty) return;
    final s = await _kitService.obtener(widget.bookId);
    if (!mounted) return;
    setState(() => _seleccion = s);
  }

  int get _preparadas {
    final s = _seleccion;
    if (s == null) return 0;
    return [
      s.tienePaleta,
      s.tieneSubrayadores,
      s.tieneAtmosfera,
      s.tienePlaylist,
      s.wallpaperGenerado,
      s.storyGenerada,
    ].where((v) => v).length;
  }

  Color _colorDesdeHex(String hex) {
    final limpio = hex.replaceAll('#', '').replaceAll('0x', '').trim();
    final valor = limpio.length == 6 ? 'FF$limpio' : limpio.padLeft(8, 'F');
    return Color(int.parse(valor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final seleccion = _seleccion;
    final preparadas = _preparadas;
    final tieneKit = preparadas > 0;

    return ClubCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.primary.withValues(alpha: tieneKit ? 0.35 : 0.22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: tieneKit
            ? const [Color(0xFFF5EFFF), Color(0xFFECDFFF)]
            : const [Color(0xFFF8F3FF), Color(0xFFF0E5FF)],
      ),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera ────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 29,
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kit de lectura',
                        style: AppTextStyles.section.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      Text(
                        tieneKit
                            ? '$preparadas de $_totalSecciones preparadas'
                            : 'Prepara una experiencia inspirada en este libro.',
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: tieneKit
                              ? AppColors.primary.withValues(alpha: 0.8)
                              : null,
                          fontWeight:
                              tieneKit ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Barra de progreso (solo si hay kit) ─────────────────────────
            if (tieneKit) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: preparadas / _totalSecciones,
                  minHeight: 5,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Preview de lo preparado / chips estáticos ───────────────────
            if (tieneKit && seleccion != null)
              _KitProgresoPreview(seleccion: seleccion, colorDesdeHex: _colorDesdeHex)
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: const [
                  _KitPreviewChip(
                    icon: Icons.palette_outlined,
                    label: 'Paleta',
                  ),
                  _KitPreviewChip(
                    icon: Icons.nights_stay_outlined,
                    label: 'Atmósfera',
                  ),
                  _KitPreviewChip(
                    icon: Icons.music_note_rounded,
                    label: 'Playlist',
                  ),
                  _KitPreviewChip(
                    icon: Icons.ios_share_rounded,
                    label: 'Story',
                  ),
                ],
              ),

            const SizedBox(height: AppSpacing.lg),

            // ── CTA ─────────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),

                const SizedBox(width: AppSpacing.xs),

                Expanded(
                  child: Text(
                    tieneKit
                        ? preparadas == _totalSecciones
                              ? 'Ver mi kit completo'
                              : 'Continúa preparando tu kit'
                        : 'Preparar mi lectura',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra qué secciones están preparadas con previews concretos.
class _KitProgresoPreview extends StatelessWidget {
  final KitLecturaSeleccion seleccion;
  final Color Function(String) colorDesdeHex;

  const _KitProgresoPreview({
    required this.seleccion,
    required this.colorDesdeHex,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (seleccion.tienePaleta)
          _ColorPaletteChip(
            colores: seleccion.paleta.map(colorDesdeHex).toList(),
          )
        else
          const _KitPreviewChip(
            icon: Icons.palette_outlined,
            label: 'Paleta',
            pending: true,
          ),

        if (seleccion.tieneAtmosfera)
          _TextChip(
            emoji: seleccion.atmosferaIcono.isEmpty ? '🌙' : seleccion.atmosferaIcono,
            label: seleccion.atmosferaTitulo.isEmpty ? 'Atmósfera' : seleccion.atmosferaTitulo,
          )
        else
          const _KitPreviewChip(
            icon: Icons.nights_stay_outlined,
            label: 'Atmósfera',
            pending: true,
          ),

        if (seleccion.tienePlaylist)
          _TextChip(emoji: '🎵', label: seleccion.playlistTitulo.isEmpty ? 'Playlist' : seleccion.playlistTitulo)
        else
          const _KitPreviewChip(
            icon: Icons.music_note_rounded,
            label: 'Playlist',
            pending: true,
          ),

        if (seleccion.storyGenerada)
          const _TextChip(emoji: '✨', label: 'Story lista')
        else
          const _KitPreviewChip(
            icon: Icons.ios_share_rounded,
            label: 'Story',
            pending: true,
          ),
      ],
    );
  }
}

class _ColorPaletteChip extends StatelessWidget {
  final List<Color> colores;

  const _ColorPaletteChip({required this.colores});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...colores.take(5).map(
            (c) => Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Paleta',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextChip extends StatelessWidget {
  final String emoji;
  final String label;

  const _TextChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KitPreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool pending;

  const _KitPreviewChip({
    required this.icon,
    required this.label,
    this.pending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: pending ? 0.45 : 0.7),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: pending ? 0.08 : 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: AppColors.primary.withValues(alpha: pending ? 0.4 : 1),
          ),

          const SizedBox(width: 6),

          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary.withValues(alpha: pending ? 0.4 : 1),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
