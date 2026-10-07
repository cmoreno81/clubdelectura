import 'package:club_lectura_app/theme/colores_compra.dart';
import 'package:club_lectura_app/widgets/ui/etiqueta_publicidad.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
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
    // "Ya lo tengo" se marca en otras pantallas: al avisar el cambio se
    // vuelve a pedir el enlace.
    WishlistService.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    WishlistService.cambios.removeListener(_cargar);
    super.dispose();
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
        enlace.yaEmpezado ||
        enlace.loTengo) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: ColoresCompra.fondo,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: ColoresCompra.borde),
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
                const EtiquetaPublicidad(conTexto: true),
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
