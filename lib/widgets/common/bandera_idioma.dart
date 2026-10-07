import 'package:flutter/material.dart';

import '../../utils/idioma_utils.dart';

/// Bandera de un idioma. Para casi todos usa el emoji de la bandera del país;
/// catalán, euskera y gallego no tienen emoji propio, así que se dibujan con
/// la bandera de su territorio (senyera, ikurriña y bandera de Galicia).
class BanderaIdioma extends StatelessWidget {
  const BanderaIdioma(this.codigo, {super.key, this.tamano = 18});

  /// Código del idioma (`es`, `ca`, `eu`…). Vacío = globo genérico.
  final String codigo;

  /// Tamaño equivalente al `fontSize` que tendría el emoji.
  final double tamano;

  /// Idiomas cuya bandera se dibuja en vez de usar un emoji.
  static const dibujadas = {'ca', 'eu', 'gl'};

  @override
  Widget build(BuildContext context) {
    final c = codigo.trim().toLowerCase();
    if (!dibujadas.contains(c)) {
      return Text(
        c.isEmpty ? '🌐' : banderaIdioma(c),
        style: TextStyle(fontSize: tamano),
      );
    }
    final alto = tamano * 0.82;
    return Semantics(
      label: 'Bandera: ${nombreIdioma(c)}',
      child: Container(
        width: alto * 1.5,
        height: alto,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(alto * 0.12),
          border: Border.all(color: Colors.black.withValues(alpha: .18), width: .6),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(painter: _PintorBandera(c)),
      ),
    );
  }
}

class _PintorBandera extends CustomPainter {
  _PintorBandera(this.codigo);

  final String codigo;

  @override
  void paint(Canvas canvas, Size size) {
    switch (codigo) {
      case 'ca':
        _senyera(canvas, size);
      case 'eu':
        _ikurrina(canvas, size);
      case 'gl':
        _galicia(canvas, size);
    }
  }

  /// Senyera: nueve franjas, cinco amarillas y cuatro rojas.
  void _senyera(Canvas canvas, Size size) {
    const amarillo = Color(0xFFFCDD09);
    const rojo = Color(0xFFDA121A);
    final franja = size.height / 9;
    for (var i = 0; i < 9; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * franja, size.width, franja + .5),
        Paint()..color = i.isEven ? amarillo : rojo,
      );
    }
  }

  /// Ikurriña: fondo rojo, aspa verde y cruz blanca encima.
  void _ikurrina(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFD52B1E),
    );
    final aspa = Paint()
      ..color = const Color(0xFF009B48)
      ..strokeWidth = size.height * .2;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), aspa);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), aspa);
    final cruz = Paint()..color = Colors.white;
    final grosor = size.height * .2;
    canvas.drawRect(
      Rect.fromLTWH(0, (size.height - grosor) / 2, size.width, grosor),
      cruz,
    );
    canvas.drawRect(
      Rect.fromLTWH((size.width - grosor) / 2, 0, grosor, size.height),
      cruz,
    );
  }

  /// Galicia: fondo blanco con una banda azul en diagonal.
  void _galicia(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, size.height),
      Paint()
        ..color = const Color(0xFF0B6FB8)
        ..strokeWidth = size.height * .34,
    );
  }

  @override
  bool shouldRepaint(covariant _PintorBandera old) => old.codigo != codigo;
}
