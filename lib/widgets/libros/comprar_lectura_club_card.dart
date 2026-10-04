import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_book_cover.dart';
import 'botones_compra.dart';

/// "Consigue el libro del club": en el dashboard del club, bajo la lectura
/// actual. Solo aparece si Casa del Libro tiene el libro localizado y la
/// lectora aún no lo ha empezado. Enlace de afiliado: lleva siempre la
/// etiqueta "Publicidad" antes de los botones.
class ComprarLecturaClubCard extends StatefulWidget {
  const ComprarLecturaClubCard({
    super.key,
    required this.bookId,
    required this.titulo,
    this.coverUrl = '',
  });

  final String bookId;
  final String titulo;
  final String coverUrl;

  @override
  State<ComprarLecturaClubCard> createState() => _ComprarLecturaClubCardState();
}

class _ComprarLecturaClubCardState extends State<ComprarLecturaClubCard> {
  EnlaceCompra? _enlace;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant ComprarLecturaClubCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId) {
      _enlace = null;
      _cargar();
    }
  }

  Future<void> _cargar() async {
    if (widget.bookId.isEmpty) return;
    final bookId = widget.bookId;
    try {
      final enlace = await ApiService().getEnlaceCompra(bookId);
      if (mounted && bookId == widget.bookId) setState(() => _enlace = enlace);
    } catch (_) {
      // Sin enlace simplemente no se muestra la tarjeta.
    }
  }

  @override
  Widget build(BuildContext context) {
    final enlace = _enlace;
    if (widget.bookId.isEmpty ||
        enlace == null ||
        !enlace.exacto ||
        enlace.yaEmpezado) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F2),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFCFE3D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClubBookCover(
            title: widget.titulo,
            imageUrl: widget.coverUrl,
            width: 56,
            height: 84,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consigue el libro del club',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDEEDF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Publicidad',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3F7A4D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Enlace de afiliado',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                BotonesCompra(enlace: enlace),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
