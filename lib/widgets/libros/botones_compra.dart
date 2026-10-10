import 'package:club_lectura_app/theme/colores_compra.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../theme/app_text_styles.dart';
import '../ui/etiqueta_publicidad.dart';

/// "Comprar en <tienda>" + un botón por cada formato disponible
/// (Papel, Ebook, Audiolibro). Siempre se pinta igual, aunque solo haya un
/// formato, para que todos los libros se lean del mismo modo. El formato
/// principal (el que usa la lectora, o papel) va relleno.
class BotonesCompra extends StatelessWidget {
  const BotonesCompra({
    super.key,
    required this.enlace,
    this.reserva = false,
    this.formatoPrincipal,
    this.onAbierto,
  });

  final EnlaceCompra enlace;

  /// Libros que aún no han salido: "Reservar" en lugar de "Comprar".
  final bool reserva;

  /// Formato a destacar si la pantalla ya lo conoce (p. ej. el que la lectora
  /// eligió para un deseo); si el libro no lo tiene se usa el del enlace.
  final String? formatoPrincipal;

  /// Se llama cuando la tienda se ha abierto correctamente, con el formato
  /// elegido (la lista de deseos lo usa para preguntar al volver si se compró).
  final ValueChanged<EnlaceCompraFormato>? onAbierto;

  Future<void> _abrir(BuildContext context, EnlaceCompraFormato f) async {
    final uri = Uri.tryParse(f.url);
    final abierto =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (abierto) onAbierto?.call(f);
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido abrir la tienda.')),
      );
    }
  }

  Widget _boton(BuildContext context, EnlaceCompraFormato f, bool principal) {
    const estilo = TextStyle(fontWeight: FontWeight.w700, fontSize: 13);
    const padding = EdgeInsets.symmetric(horizontal: 10);
    final etiqueta = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(f.etiqueta, maxLines: 1),
    );
    return principal
        ? FilledButton(
            onPressed: () => _abrir(context, f),
            style: FilledButton.styleFrom(
              backgroundColor: ColoresCompra.verde,
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(0, 36),
              padding: padding,
              textStyle: estilo,
            ),
            child: etiqueta,
          )
        : OutlinedButton(
            onPressed: () => _abrir(context, f),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColoresCompra.verde,
              side: const BorderSide(color: ColoresCompra.borde),
              backgroundColor: ColoresCompra.fondo,
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(0, 36),
              padding: padding,
              textStyle: estilo,
            ),
            child: etiqueta,
          );
  }

  @override
  Widget build(BuildContext context) {
    // Sin lista de formatos (respuesta antigua): un único botón de papel.
    final formatos = enlace.formatos.isEmpty
        ? [
            EnlaceCompraFormato(
              formato: 'papel',
              etiqueta: 'Papel',
              url: enlace.url,
            ),
          ]
        : enlace.formatos;
    final principal = formatos.any((f) => f.formato == formatoPrincipal)
        ? formatoPrincipal
        : enlace.formato;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 16,
              color: ColoresCompra.verde,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                reserva
                    ? 'Reservar en ${enlace.tienda}'
                    : 'Comprar en ${enlace.tienda}',
                style: AppTextStyles.subtitle.copyWith(
                  color: ColoresCompra.verde,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Una sola fila: los botones se reparten el ancho y, si no caben,
        // el texto se encoge en vez de saltar a una segunda línea.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < formatos.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Flexible(
                child: _boton(
                  context,
                  formatos[i],
                  formatos[i].formato == principal,
                ),
              ),
            ],
          ],
        ),
        for (final otra in enlace.otras) _tambienEn(context, otra),
      ],
    );
  }

  /// Enlace discreto a otra tienda con el mismo libro; abre una hoja con sus
  /// formatos.
  Widget _tambienEn(BuildContext context, EnlaceCompra otra) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${reserva ? 'Reservar' : 'Comprar'} en ${otra.tienda}',
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const EtiquetaPublicidad(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < otra.formatos.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(sheet);
                              _abrir(context, otra.formatos[i]);
                            },
                            child: Text(otra.formatos[i].etiqueta),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(otra.avisoLegal, style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'También en ${otra.tienda} ›',
            style: AppTextStyles.caption.copyWith(
              color: ColoresCompra.verde,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
