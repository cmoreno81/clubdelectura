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
import 'pregunta_compra.dart';

/// "Comprar en Casa del Libro" — enlace de afiliado (Awin). El código de
/// conducta de publicidad exige identificarlo como publicidad y de forma
/// visible, por eso la etiqueta "Publicidad" va siempre en la propia tarjeta.
class ComprarLibroCard extends StatefulWidget {
  const ComprarLibroCard({
    super.key,
    required this.bookId,
    this.titulo = '',
    this.espacioAntes = 0,
    this.espacioDespues = 0,
  });

  final String bookId;

  /// Título del libro, para preguntar «¿Has comprado …?» al volver de la tienda.
  final String titulo;

  /// Separación sobre y bajo la tarjeta. Se aplica solo cuando la tarjeta se
  /// ve: si el libro no está en la tienda, no deja huecos vacíos.
  final double espacioAntes;
  final double espacioDespues;

  @override
  State<ComprarLibroCard> createState() => _ComprarLibroCardState();
}

class _ComprarLibroCardState extends State<ComprarLibroCard>
    with WidgetsBindingObserver {
  bool _abriendo = false;
  EnlaceCompra? _enlace;

  /// Tienda y formato del último botón pulsado: al volver a la app se
  /// pregunta si se ha comprado. Todo local, no se envía nada a la tienda.
  ({String tienda, String formato})? _compraPendiente;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WishlistService.cambios.addListener(_alCambiar);
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WishlistService.cambios.removeListener(_alCambiar);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _preguntarCompra();
  }

  Future<void> _preguntarCompra() async {
    final pendiente = _compraPendiente;
    if (pendiente == null || !mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _compraPendiente = null;

    final comprado = await preguntarSiLoHasComprado(
      context,
      titulo: widget.titulo.isEmpty ? 'este libro' : widget.titulo,
      formato: pendiente.formato,
      tienda: pendiente.tienda,
    );
    if (comprado && mounted) await _marcarLoTengo(true);
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

  Future<void> _abrir([String? url, String? tienda, String? formato]) async {
    if (_abriendo || widget.bookId.isEmpty) return;
    setState(() => _abriendo = true);
    try {
      final destino = url ?? (_enlace ?? await _cargar())?.url;
      if (!mounted) return;
      final uri = destino == null ? null : Uri.tryParse(destino);
      final abierto =
          uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (abierto) {
        final enlace = _enlace;
        // Solo se pregunta si se puede marcar como «lo tengo»: el libro está
        // en la biblioteca y no se ha empezado ni marcado ya.
        final puedeMarcar =
            enlace != null &&
            enlace.enBiblioteca &&
            !enlace.yaEmpezado &&
            !enlace.loTengo;
        // Con la búsqueda genérica no se sabe qué libro acabará comprando.
        _compraPendiente = puedeMarcar && enlace.exacto
            ? (
                tienda: tienda ?? enlace.tienda,
                formato: formato ?? enlace.formato,
              )
            : null;
      }
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
    // Sin ficha exacta en la tienda se ofrece la búsqueda por título y autoría
    // (con nuestra campaña): nunca puede llevar a un libro equivocado. Mientras
    // carga no se muestra nada.
    final enlace = _enlace;
    if (widget.bookId.isEmpty || enlace == null) {
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
          _tarjeta(enlace),
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

  Widget _tarjeta(EnlaceCompra enlace) {
    return ClubSectionCard(
      onTap: () => _abrir(),
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
                        enlace.exacto
                            ? 'Comprar en ${enlace.tienda}'
                            : 'Buscar en ${enlace.tienda}',
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
                  !enlace.exacto
                      ? 'Buscamos el libro por título y autoría. Enlace de '
                            'afiliado: ClubReads puede recibir una comisión, '
                            'sin coste extra para ti.'
                      : enlace.otras.isEmpty &&
                            !enlace.avisoLegal.contains('Amazon')
                      ? 'Enlace de afiliado: ClubReads puede recibir una comisión, '
                            'sin coste extra para ti.'
                      : enlace.avisoLegal,
                  style: AppTextStyles.bodySecondary,
                ),
                for (final otra in enlace.otras) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'También en ${otra.tienda}',
                          style: AppTextStyles.caption.copyWith(
                            color: ColoresCompra.verde,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const EtiquetaPublicidad(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final f in otra.formatos)
                        ActionChip(
                          label: Text(f.etiqueta),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: ColoresCompra.borde),
                          onPressed: () =>
                              _abrir(f.url, otra.tienda, f.etiqueta),
                        ),
                    ],
                  ),
                ],
                if (enlace.exacto && (_enlace?.formatos.length ?? 0) > 1) ...[
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
                          onPressed: () =>
                              _abrir(f.url, enlace.tienda, f.etiqueta),
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
