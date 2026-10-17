import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Portada de sustitución para un libro sin imagen: un «libro» de color con
/// lomo, marco fino y el título en serifa. El color sale del título, así cada
/// libro siempre tiene el mismo y una estantería sin portadas no es monótona.
class PortadaSinImagen extends StatelessWidget {
  const PortadaSinImagen({super.key, required this.title});

  final String title;

  /// Parejas (arriba, abajo) de la paleta de la app: tonos oscuros y cálidos
  /// con los que el texto crema se lee bien.
  static const _paleta = <(Color, Color)>[
    (Color(0xFF5C2B4A), Color(0xFF3A1830)), // ciruela
    (Color(0xFF2F4F4A), Color(0xFF1B302D)), // verde botella
    (Color(0xFF3B3F6B), Color(0xFF232648)), // azul noche
    (Color(0xFF8A3B3B), Color(0xFF5A2323)), // granate
    (Color(0xFF6B5A2E), Color(0xFF43381B)), // oliva dorado
    (Color(0xFF4A3B6B), Color(0xFF2E2346)), // violeta
    (Color(0xFF2E5560), Color(0xFF1A3640)), // petróleo
    (Color(0xFF7A4A2E), Color(0xFF4D2C18)), // cuero
  ];

  static const _crema = Color(0xFFFBEBDD);

  /// Índice estable (no depende de `hashCode`, que cambia entre ejecuciones).
  static int indiceDe(String texto) {
    var h = 0;
    for (final unidad in texto.trim().toLowerCase().codeUnits) {
      h = (h * 31 + unidad) & 0x7fffffff;
    }
    return h % _paleta.length;
  }

  @override
  Widget build(BuildContext context) {
    final (arriba, abajo) = _paleta[indiceDe(title)];
    return LayoutBuilder(
      builder: (context, c) {
        final ancho = c.hasBoundedWidth ? c.maxWidth : 96.0;
        final alto = c.hasBoundedHeight ? c.maxHeight : ancho * 1.5;
        final pequeno = ancho < 70;
        final lomo = (ancho * 0.07).clamp(3.0, 12.0);
        final margen = pequeno ? ancho * 0.1 : ancho * 0.12;
        final tamano = (ancho * (pequeno ? 0.15 : 0.115)).clamp(7.5, 20.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [arriba, abajo],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Lomo: una franja más oscura con un hilo claro, como un libro de verdad.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: lomo,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .22),
                    border: Border(
                      right: BorderSide(
                        color: _crema.withValues(alpha: .28),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              if (!pequeno)
                Positioned(
                  left: lomo + margen * .55,
                  right: margen * .55,
                  top: margen * .55,
                  bottom: margen * .55,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _crema.withValues(alpha: .32),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  lomo + margen,
                  margen,
                  margen,
                  margen,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!pequeno && alto > 110)
                        Padding(
                          padding: EdgeInsets.only(bottom: tamano * .6),
                          child: Text(
                            '✦',
                            style: TextStyle(
                              color: _crema.withValues(alpha: .7),
                              fontSize: tamano * .8,
                              height: 1,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: pequeno ? 4 : 5,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: _crema,
                            fontSize: tamano,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
