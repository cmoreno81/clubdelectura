import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/colores_compra.dart';

/// Etiqueta «Publicidad» que acompaña a todo enlace de afiliado. Es
/// obligatoria (condiciones de Awin), así que vive en un único componente:
/// el texto y el aspecto no pueden desajustarse entre pantallas.
///
/// - [sobreFondoOscuro]: versión translúcida para las tarjetas con degradado.
/// - [conTexto]: añade «Enlace de afiliado» a su lado.
class EtiquetaPublicidad extends StatelessWidget {
  const EtiquetaPublicidad({
    super.key,
    this.sobreFondoOscuro = false,
    this.conTexto = false,
  });

  final bool sobreFondoOscuro;
  final bool conTexto;

  @override
  Widget build(BuildContext context) {
    final etiqueta = sobreFondoOscuro
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'PUBLICIDAD',
              style: AppTextStyles.caption.copyWith(
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ColoresCompra.verdeClaro,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Publicidad',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: ColoresCompra.verde,
              ),
            ),
          );
    if (!conTexto) return etiqueta;
    return Row(
      children: [
        etiqueta,
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Enlace de afiliado',
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
