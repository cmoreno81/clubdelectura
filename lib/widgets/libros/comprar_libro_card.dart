import 'package:club_lectura_app/theme/colores_compra.dart';
import 'package:club_lectura_app/widgets/ui/etiqueta_publicidad.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../ui/club_section_card.dart';

/// "Comprar en Casa del Libro" — enlace de afiliado (Awin). El código de
/// conducta de publicidad exige identificarlo como publicidad y de forma
/// visible, por eso la etiqueta "Publicidad" va siempre en la propia tarjeta.
class ComprarLibroCard extends StatefulWidget {
  const ComprarLibroCard({
    super.key,
    required this.bookId,
    this.espacioAntes = 0,
    this.espacioDespues = 0,
  });

  final String bookId;

  /// Separación sobre y bajo la tarjeta. Se aplica solo cuando la tarjeta se
  /// ve: si el libro no está en la tienda, no deja huecos vacíos.
  final double espacioAntes;
  final double espacioDespues;

  @override
  State<ComprarLibroCard> createState() => _ComprarLibroCardState();
}

class _ComprarLibroCardState extends State<ComprarLibroCard> {
  bool _abriendo = false;
  EnlaceCompra? _enlace;

  @override
  void initState() {
    super.initState();
    WishlistService.cambios.addListener(_alCambiar);
    _cargar();
  }

  @override
  void dispose() {
    WishlistService.cambios.removeListener(_alCambiar);
    super.dispose();
  }

  void _alCambiar() => _cargar();

  @override
  void didUpdateWidget(covariant ComprarLibroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId) {
      _enlace = null;
      _cargar();
    }
  }

  Future<EnlaceCompra?> _cargar() async {
    if (widget.bookId.isEmpty) return null;
    final bookId = widget.bookId;
    try {
      final enlace = await ApiService().getEnlaceCompra(bookId);
      if (mounted && bookId == widget.bookId) {
        setState(() => _enlace = enlace);
      }
      return enlace;
    } catch (_) {
      return null;
    }
  }

  Future<void> _abrir([String? url]) async {
    if (_abriendo || widget.bookId.isEmpty) return;
    setState(() => _abriendo = true);
    try {
      final destino = url ?? (_enlace ?? await _cargar())?.url;
      if (!mounted) return;
      final uri = destino == null ? null : Uri.tryParse(destino);
      final abierto =
          uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abierto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se ha podido abrir la tienda.')),
        );
      }
    } finally {
      if (mounted) setState(() => _abriendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solo se ofrece comprar si la tienda tiene el libro localizado: sin ficha
    // exacta (p. ej. un autopublicado) no se muestra nada, ni mientras carga.
    final enlace = _enlace;
    if (widget.bookId.isEmpty || enlace == null || !enlace.exacto) {
      return const SizedBox.shrink();
    }
    // Ya lo tiene: en lugar de ofrecer la compra, una línea discreta para
    // deshacerlo si fue un error.
    if (enlace.loTengo) {
      return Padding(
        padding: EdgeInsets.only(
          top: widget.espacioAntes,
          bottom: widget.espacioDespues,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: ColoresCompra.verde,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text('Ya lo tienes', style: AppTextStyles.bodySecondary),
            ),
            TextButton(
              onPressed: () => _marcarLoTengo(false),
              child: const Text('Deshacer'),
            ),
          ],
        ),
      );
    }
    final puedeMarcar = enlace.enBiblioteca && !enlace.yaEmpezado;
    return Padding(
      padding: EdgeInsets.only(
        top: widget.espacioAntes,
        bottom: widget.espacioDespues,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tarjeta(),
          if (puedeMarcar)
            TextButton.icon(
              onPressed: () => _marcarLoTengo(true),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Ya lo tengo'),
              style: TextButton.styleFrom(
                foregroundColor: ColoresCompra.verde,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _marcarLoTengo(bool valor) async {
    final messenger = ScaffoldMessenger.of(context);
    final guardado = await ApiService().setLoTengo(widget.bookId, valor);
    if (guardado) WishlistService.avisarCambio();
    if (!mounted) return;
    if (!guardado) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se ha podido guardar. Inténtalo de nuevo.'),
        ),
      );
      return;
    }
    await _cargar();
  }

  Widget _tarjeta() {
    return ClubSectionCard(
      onTap: _abrir,
      backgroundColor: ColoresCompra.fondo,
      borderColor: ColoresCompra.borde,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ColoresCompra.verdeClaro,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _abriendo
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    color: ColoresCompra.verde,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Comprar en Casa del Libro',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const EtiquetaPublicidad(),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enlace de afiliado: ClubReads puede recibir una comisión, '
                  'sin coste extra para ti.',
                  style: AppTextStyles.bodySecondary,
                ),
                if ((_enlace?.formatos.length ?? 0) > 1) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final f in _enlace!.formatos)
                        ActionChip(
                          label: Text(f.etiqueta),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: f.formato == _enlace!.formato
                              ? ColoresCompra.verdeClaro
                              : Colors.white,
                          side: const BorderSide(color: ColoresCompra.borde),
                          onPressed: () => _abrir(f.url),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right_rounded, color: ColoresCompra.verde),
        ],
      ),
    );
  }
}
