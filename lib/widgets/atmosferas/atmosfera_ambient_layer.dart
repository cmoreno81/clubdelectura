import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/atmosferas/atmosfera_tipo.dart';

class AtmosferaAmbientLayer extends StatefulWidget {
  final Widget child;
  final AtmosferaLectura atmosfera;
  final Color color;
  final Color accentColor;
  final Color backgroundColor;
  final bool enabled;

  const AtmosferaAmbientLayer({
    super.key,
    required this.child,
    required this.atmosfera,
    required this.color,
    required this.accentColor,
    required this.backgroundColor,
    this.enabled = true,
  });

  @override
  State<AtmosferaAmbientLayer> createState() => _AtmosferaAmbientLayerState();
}

class _AtmosferaAmbientLayerState extends State<AtmosferaAmbientLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _actualizarAnimacion();
  }

  @override
  void didUpdateWidget(covariant AtmosferaAmbientLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled != widget.enabled) {
      _actualizarAnimacion();
    }

    if (oldWidget.atmosfera != widget.atmosfera ||
        oldWidget.color != widget.color ||
        oldWidget.accentColor != widget.accentColor ||
        oldWidget.backgroundColor != widget.backgroundColor) {
      setState(() {});
    }
  }

  void _actualizarAnimacion() {
    if (widget.enabled) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneAtmosfera = widget.atmosfera != AtmosferaLectura.neutra;

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: widget.backgroundColor)),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _EditorialPaperPainter()),
          ),
        ),

        if (tieneAtmosfera)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withValues(alpha: 0.20),
                      widget.backgroundColor.withValues(alpha: 0.42),
                      widget.accentColor.withValues(alpha: 0.18),
                    ],
                    stops: const [0, 0.52, 1],
                  ),
                ),
              ),
            ),
          ),

        if (widget.enabled)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _AtmosferaPainter(
                        progreso: _controller.value,
                        atmosfera: widget.atmosfera,
                        color: widget.color,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        widget.child,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _EditorialPaperPainter extends CustomPainter {
  const _EditorialPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paperRect = Offset.zero & size;
    canvas.drawRect(
      paperRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.18, -0.22),
          radius: 1.22,
          colors: [
            const Color(0xFFFFFBF2).withValues(alpha: .16),
            const Color(0xFF8D654A).withValues(alpha: .13),
          ],
          stops: const [.48, 1],
        ).createShader(paperRect),
    );

    final warmClouds = [
      (const Offset(.12, .18), 116.0, .065),
      (const Offset(.86, .36), 148.0, .05),
      (const Offset(.28, .78), 176.0, .046),
      (const Offset(.92, .9), 105.0, .055),
    ];
    for (final cloud in warmClouds) {
      final center = Offset(
        size.width * cloud.$1.dx,
        size.height * cloud.$1.dy,
      );
      final rect = Rect.fromCircle(center: center, radius: cloud.$2);
      canvas.drawCircle(
        center,
        cloud.$2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFB98762).withValues(alpha: cloud.$3),
              Colors.transparent,
            ],
          ).createShader(rect),
      );
    }

    final fiber = Paint()
      ..color = const Color(0xFF705D4E).withValues(alpha: .1)
      ..strokeWidth = .72;
    for (var y = 13.0; y < size.height; y += 23) {
      final shift = ((y ~/ 23) % 5) * 9.0;
      canvas.drawLine(
        Offset(14 + shift, y),
        Offset(math.min(size.width - 12, 88 + shift), y + .8),
        fiber,
      );
      if (size.width > 220) {
        canvas.drawLine(
          Offset(size.width - 112 - shift, y + 9),
          Offset(size.width - 22 - shift, y + 8.2),
          fiber,
        );
      }
    }

    final ruledLine = Paint()
      ..color = const Color(0xFF7C6B88).withValues(alpha: .072)
      ..strokeWidth = .78;
    for (var y = 31.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(26, y), Offset(size.width, y), ruledLine);
    }

    final longFiber = Paint()
      ..color = const Color(0xFF9A7256).withValues(alpha: .065)
      ..strokeWidth = .52;
    for (var index = 0; index < 18; index++) {
      final y = ((index * 83.0) + 41) % math.max(size.height, 1.0);
      final x = ((index * 47.0) + 19) % math.max(size.width, 1.0);
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(size.width, x + 104 + (index % 4) * 18), y + 1.4),
        longFiber,
      );
    }

    final speck = Paint()
      ..color = const Color(0xFF6E513E).withValues(alpha: .12);
    final speckCount = math.min(210, (size.width * size.height / 3200).round());
    for (var index = 0; index < speckCount; index++) {
      final x =
          ((index * 73.37 + math.sin(index * 1.7) * 31).abs()) %
          math.max(size.width, 1.0);
      final y =
          ((index * 127.19 + math.cos(index * 2.1) * 47).abs()) %
          math.max(size.height, 1.0);
      final radius = .3 + (index % 4) * .14;
      canvas.drawCircle(Offset(x, y), radius, speck);
    }

    final margin = Paint()
      ..color = const Color(0xFFC75D4D).withValues(alpha: .34)
      ..strokeWidth = 1.25;
    canvas.drawLine(const Offset(11, 0), Offset(11, size.height), margin);
    canvas.drawLine(
      const Offset(14, 0),
      Offset(14, size.height),
      Paint()
        ..color = const Color(0xFF603B73).withValues(alpha: .1)
        ..strokeWidth = .9,
    );

    final edgePaint = Paint()
      ..color = const Color(0xFF74523E).withValues(alpha: .075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawRect(
      Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AtmosferaPainter extends CustomPainter {
  final double progreso;
  final AtmosferaLectura atmosfera;
  final Color color;

  const _AtmosferaPainter({
    required this.progreso,
    required this.atmosfera,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (atmosfera) {
      case AtmosferaLectura.romantica:
        _pintarPetalos(canvas, size);
        _pintarDestellos(canvas, size);

      case AtmosferaLectura.magica:
        _pintarDestellos(canvas, size);
        _pintarConstelacion(canvas, size);

      case AtmosferaLectura.marina:
        _pintarVientoMarino(canvas, size);
        _pintarGaviotas(canvas, size);
        _pintarMareaViva(canvas, size);
        _pintarBrillosAgua(canvas, size);

      case AtmosferaLectura.bosque:
        // Sin rayos de luz: las bandas diagonales parecían rayas heredadas de
        // la atmósfera anterior (épica dibujaba las mismas).
        _pintarHojas(canvas, size);

      case AtmosferaLectura.oscura:
        // Noche en calma: niebla, luna y estrellas. Sin lluvia ni brasas, que
        // no casaban con una lectura «silenciosa».
        _pintarEstrellasTenues(canvas, size);
        _pintarLunaTenue(canvas, size);
        _pintarBruma(canvas, size);

      case AtmosferaLectura.gotica:
        _pintarBruma(canvas, size);
        _pintarCenizaAscendente(canvas, size);

      case AtmosferaLectura.misteriosa:
        _pintarBruma(canvas, size);
        _pintarLuciernagas(canvas, size);

      case AtmosferaLectura.futurista:
        _pintarParticulasNeon(canvas, size);
        _pintarDestelloDiagonal(canvas, size);

      case AtmosferaLectura.epica:
        _pintarResplandorFogata(canvas, size);
        _pintarEstandartes(canvas, size);
        _pintarChispas(canvas, size);

      case AtmosferaLectura.acogedora:
        _pintarVaporTaza(canvas, size);
        _pintarPolvoCalido(canvas, size);

      case AtmosferaLectura.historica:
        // Solo los papeles: el polvo cálido de puntos pasaba demasiado
        // rápido y restaba calma a la atmósfera.
        _pintarPapelesFlotantes(canvas, size);

      case AtmosferaLectura.neutra:
        break;
    }
  }

  void _pintarPetalos(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.22);

    for (var i = 0; i < 25; i++) {
      final velocidad = 0.45 + (i % 4) * 0.11;
      final fase = (progreso * velocidad + i * 0.113) % 1;

      final xBase = _fraccion(i * 53.17) * size.width;
      final oscilacion = math.sin((progreso * math.pi * 2) + i) * 24;
      final x = xBase + oscilacion;
      final y = -30 + fase * (size.height + 60);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progreso * math.pi * 2 + i);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 8 + (i % 3) * 2,
          height: 15 + (i % 4) * 2,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  void _pintarDestellos(Canvas canvas, Size size) {
    for (var i = 0; i < 38; i++) {
      final x = _fraccion(i * 81.41) * size.width;
      final y = _fraccion(i * 39.73) * size.height;

      final pulso = (math.sin((progreso * math.pi * 2) + i * 0.8) + 1) / 2;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.07 + pulso * 0.20);

      canvas.drawCircle(Offset(x, y), 1.5 + pulso * 3.2, paint);

      if (i % 4 == 0) {
        final linePaint = Paint()
          ..color = color.withValues(alpha: 0.06 + pulso * 0.15)
          ..strokeWidth = 1;

        canvas.drawLine(Offset(x - 6, y), Offset(x + 6, y), linePaint);

        canvas.drawLine(Offset(x, y - 6), Offset(x, y + 6), linePaint);
      }
    }
  }

  void _pintarHojas(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.20);

    for (var i = 0; i < 24; i++) {
      final fase = (progreso * (0.35 + (i % 3) * 0.1) + i * 0.16) % 1;

      final xBase = _fraccion(i * 67.27) * size.width;
      final x = xBase + math.sin(progreso * math.pi * 2 + i) * 30;
      final y = -25 + fase * (size.height + 50);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i + progreso * 2);

      final path = Path()
        ..moveTo(0, -8)
        ..quadraticBezierTo(7, -3, 0, 9)
        ..quadraticBezierTo(-7, -3, 0, -8);

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _pintarBruma(Canvas canvas, Size size) {
    for (var i = 0; i < 7; i++) {
      final desplazamiento = ((progreso * (0.1 + i * 0.012)) + i * 0.19) % 1;

      final x = -size.width * 0.4 + desplazamiento * size.width * 1.8;
      final y = size.height * (0.12 + i * 0.13);

      final paint = Paint()
        ..color = color.withValues(alpha: 0.10 + (i % 3) * 0.025)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: size.width * 0.65,
          height: 90,
        ),
        paint,
      );
    }
  }

  void _pintarChispas(Canvas canvas, Size size) {
    final fase2pi = progreso * math.pi * 2;
    for (var i = 0; i < 26; i++) {
      // Cada ascua vive un ciclo: nace abajo, sube despacio balanceándose y
      // se apaga antes de reiniciar (así el bucle de 10 s no da saltos).
      final vida = (progreso + i * 0.0731) % 1;
      final aparicion = math.sin(vida * math.pi);
      final xBase = _fraccion(i * 45.73) * size.width;
      final x = xBase + math.sin(fase2pi + i * 1.7) * 14;
      final yInicio = size.height * (0.62 + _fraccion(i * 19.31) * 0.40);
      final y = yInicio - vida * size.height * 0.34;
      final parpadeo = (math.sin(fase2pi * 3 + i * 2.1) + 1) / 2;
      final alfa = aparicion * (0.18 + parpadeo * 0.34);

      canvas.drawCircle(
        Offset(x, y),
        3.5 + (i % 3),
        Paint()
          ..color = color.withValues(alpha: alfa * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        Offset(x, y),
        1.3 + (i % 3) * 0.6,
        Paint()..color = color.withValues(alpha: alfa),
      );
    }
  }

  /// Ceniza de vela que flota y se desvanece — sustituye los arcos fijos de
  /// Gótica por algo que de verdad se mueve por la escena.
  void _pintarCenizaAscendente(Canvas canvas, Size size) {
    for (var i = 0; i < 26; i++) {
      final velocidad = 0.16 + (i % 4) * 0.05;
      final fase = (progreso * velocidad + i * 0.091) % 1;
      final xBase = _fraccion(i * 58.3) * size.width;
      final deriva = math.sin(progreso * math.pi * 1.2 + i) * 26;
      final x = xBase + deriva;
      final y = size.height + 15 - fase * (size.height + 40);
      final parpadeo = (math.sin(progreso * math.pi * 4 + i * 1.1) + 1) / 2;

      canvas.drawCircle(
        Offset(x, y),
        0.9 + parpadeo * 1.5,
        Paint()..color = color.withValues(alpha: 0.06 + parpadeo * 0.17),
      );
    }
  }

  /// Luciérnagas que serpentean en la niebla — reemplaza la constelación fija
  /// de Misteriosa, que no aportaba sensación de movimiento.
  void _pintarLuciernagas(Canvas canvas, Size size) {
    for (var i = 0; i < 14; i++) {
      final cx = _fraccion(i * 83.7) * size.width;
      final cy = _fraccion(i * 51.3) * size.height;
      final radioX = 24.0 + (i % 3) * 14;
      final radioY = 16.0 + (i % 4) * 10;
      final angulo = progreso * math.pi * 2 * (0.4 + (i % 3) * 0.15) + i;
      final x = cx + math.cos(angulo) * radioX;
      final y = cy + math.sin(angulo * 1.3) * radioY;
      final pulso = (math.sin(progreso * math.pi * 4 + i * 0.9) + 1) / 2;

      canvas.drawCircle(
        Offset(x, y),
        5 + pulso * 3,
        Paint()
          ..color = color.withValues(alpha: 0.05 + pulso * 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(x, y),
        1.2 + pulso * 1.1,
        Paint()..color = color.withValues(alpha: 0.18 + pulso * 0.3),
      );
    }
  }

  /// Partículas neón que ascienden con brillo — sustituye las líneas y
  /// puntos estáticos de Futurista por algo con sensación de ingravidez.
  void _pintarParticulasNeon(Canvas canvas, Size size) {
    for (var i = 0; i < 28; i++) {
      final velocidad = 0.22 + (i % 5) * 0.07;
      final fase = (progreso * velocidad + i * 0.081) % 1;
      final xBase = _fraccion(i * 69.5) * size.width;
      final x = xBase + math.sin(progreso * math.pi * 2 + i * 0.7) * 14;
      final y = size.height + 20 - fase * (size.height + 60);
      final pulso = (math.sin(progreso * math.pi * 6 + i) + 1) / 2;

      canvas.drawCircle(
        Offset(x, y),
        3 + pulso * 2.4,
        Paint()
          ..color = color.withValues(alpha: 0.08 + pulso * 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        Offset(x, y),
        1 + pulso * 0.8,
        Paint()..color = color.withValues(alpha: 0.3 + pulso * 0.4),
      );
    }
  }

  /// Un par de destellos cruzan la pantalla en diagonal de vez en cuando,
  /// como un rastro de datos o una estrella fugaz digital.
  void _pintarDestelloDiagonal(Canvas canvas, Size size) {
    for (var i = 0; i < 2; i++) {
      final t = (progreso + i * 0.5) % 1.0;
      if (t > 0.4) continue;
      final avance = t / 0.4;

      final startX = -size.width * 0.15 + i * size.width * 0.3;
      final startY = size.height * (0.08 + i * 0.18);
      final endX = startX + size.width * 0.95;
      final endY = startY + size.height * 0.5;

      final headX = startX + (endX - startX) * avance;
      final headY = startY + (endY - startY) * avance;
      final tailFrac = math.max(0.0, avance - 0.16);
      final tailX = startX + (endX - startX) * tailFrac;
      final tailY = startY + (endY - startY) * tailFrac;
      final opacidad = (1 - avance) * 0.45;

      canvas.drawLine(
        Offset(tailX, tailY),
        Offset(headX, headY),
        Paint()
          ..color = color.withValues(alpha: opacidad)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(headX, headY),
        2.2,
        Paint()..color = color.withValues(alpha: (opacidad + 0.25).clamp(0, 1)),
      );
    }
  }

  /// Volutas de vapor subiendo en zigzag, como de una taza caliente —
  /// sustituye el polvo flotante como protagonista de Acogedora.
  void _pintarVaporTaza(Canvas canvas, Size size) {
    for (var i = 0; i < 5; i++) {
      final xBase = size.width * (0.22 + i * 0.16);
      final velocidad = 0.3 + (i % 3) * 0.05;
      final fase = (progreso * velocidad + i * 0.17) % 1;
      final alturaRecorrido = size.height * 0.62;
      final yInicio = size.height * 0.92;
      final y = yInicio - fase * alturaRecorrido;
      final desvanecimiento = (1 - fase).clamp(0.0, 1.0);

      final path = Path()..moveTo(xBase, y);
      for (var paso = 1; paso <= 5; paso++) {
        final progresoPaso = paso / 5;
        final yPaso = y - progresoPaso * 46;
        final xPaso =
            xBase +
            math.sin((progreso * math.pi * 2.8) + i + progresoPaso * 3) * 9;
        path.lineTo(xPaso, yPaso);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.16 * desvanecimiento)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Trocitos de papel que caen girando en diagonal — sustituye las líneas
  /// de manuscrito fijas de Histórica por algo con sensación de caída real.
  void _pintarPapelesFlotantes(Canvas canvas, Size size) {
    for (var i = 0; i < 14; i++) {
      final velocidad = 0.16 + (i % 4) * 0.04;
      final fase = (progreso * velocidad + i * 0.141) % 1;
      final xBase = _fraccion(i * 59.9) * size.width;
      final deriva = math.sin(progreso * math.pi * 1.1 + i) * 34;
      final x = xBase + deriva + fase * 40;
      final y = -20 + fase * (size.height + 40);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progreso * math.pi * 2 * (0.6 + (i % 3) * 0.2) + i);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 9, height: 12),
        Paint()..color = color.withValues(alpha: 0.14),
      );
      canvas.restore();
    }
  }

  void _pintarPolvoCalido(Canvas canvas, Size size) {
    for (var i = 0; i < 36; i++) {
      final x = _fraccion(i * 71.17) * size.width;
      final y = _fraccion(i * 37.91 + progreso * 20) * size.height;

      final pulso = (math.sin(progreso * math.pi * 2 + i * 0.6) + 1) / 2;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.08 + pulso * 0.18);
      canvas.drawCircle(Offset(x, y), 1.3 + pulso * 2.8, paint);
    }
  }

  void _pintarConstelacion(Canvas canvas, Size size) {
    final points = <Offset>[];
    for (var i = 0; i < 12; i++) {
      points.add(
        Offset(
          _fraccion(i * 43.71) * size.width,
          _fraccion(i * 77.13) * size.height,
        ),
      );
    }
    final pulse = 0.15 + (math.sin(progreso * math.pi * 2) + 1) * 0.06;
    final line = Paint()
      ..color = color.withValues(alpha: pulse)
      ..strokeWidth = 0.9;
    final dot = Paint()..color = color.withValues(alpha: pulse + 0.06);
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 1.8 + (i % 3), dot);
      if (i > 0 && i % 3 != 0) canvas.drawLine(points[i - 1], points[i], line);
    }
  }

  // ── Marina ────────────────────────────────────────────────────────────

  /// Rayas de viento que cruzan la parte alta de lado a lado.
  void _pintarVientoMarino(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.08 + _fraccion(i * 37.3) * 0.34);
      final largo = size.width * (0.16 + _fraccion(i * 13.7) * 0.22);
      // Multiplicador entero: el bucle de 10 s encaja sin saltos.
      final x =
          ((progreso * (1 + i % 3) + i * 0.17) % 1) * (size.width + largo * 2) -
          largo;
      canvas.drawLine(Offset(x, y), Offset(x + largo, y), paint);
    }
  }

  /// Gaviotas que planean de un lado a otro moviendo las alas.
  void _pintarGaviotas(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    for (var g = 0; g < 2; g++) {
      final t = (progreso + g * 0.5) % 1;
      final x = -40 + t * (size.width + 80);
      final y = size.height * (0.17 + g * 0.10) + math.sin(t * math.pi * 4) * 9;
      final ala = 8 + math.sin(t * math.pi * 12) * 2.6;
      final path = Path()
        ..moveTo(x - ala * 2, y + ala * 0.3)
        ..quadraticBezierTo(x - ala, y - ala * 0.9, x, y)
        ..quadraticBezierTo(x + ala, y - ala * 0.9, x + ala * 2, y + ala * 0.3);
      canvas.drawPath(path, paint);
    }
  }

  /// Cuatro capas de olas rellenas que suben y bajan a distinto ritmo, con
  /// espuma en la cresta de la más cercana.
  void _pintarMareaViva(Canvas canvas, Size size) {
    final fase = progreso * math.pi * 2;
    for (var capa = 0; capa < 4; capa++) {
      final dir = capa.isEven ? 1 : -1;
      final vel = 1 + capa % 2;
      // Vaivén vertical de toda la capa, como respirando.
      final base =
          size.height * (0.62 + capa * 0.085) + math.sin(fase + capa * 1.3) * 6;
      final amp = 9.0 + capa * 3;
      final longitud = 58.0 + capa * 17;

      final relleno = Path()..moveTo(-10, size.height + 10);
      final cresta = Path();
      final crestas = <Offset>[];
      for (double x = -10; x <= size.width + 10; x += 6) {
        final y =
            base +
            math.sin(x / longitud + fase * vel * dir) * amp +
            math.sin(x / 23 - fase * 2) * 2.4;
        relleno.lineTo(x, y);
        if (x == -10) {
          cresta.moveTo(x, y);
        } else {
          cresta.lineTo(x, y);
        }
        if (capa == 3 && (x + 10) % 36 == 0) crestas.add(Offset(x, y));
      }
      relleno
        ..lineTo(size.width + 10, size.height + 10)
        ..close();

      canvas.drawPath(
        relleno,
        Paint()..color = color.withValues(alpha: 0.09 + capa * 0.035),
      );
      canvas.drawPath(
        cresta,
        Paint()
          ..color = color.withValues(alpha: 0.18 + capa * 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      for (var i = 0; i < crestas.length; i++) {
        final espuma = (math.sin(fase * 2 + i) + 1) / 2;
        canvas.drawCircle(
          crestas[i].translate(0, -2),
          1.2 + espuma * 1.8,
          Paint()..color = Colors.white.withValues(alpha: 0.10 + espuma * 0.22),
        );
      }
    }
  }

  /// Destellos del sol sobre el agua: rayitas horizontales que titilan.
  void _pintarBrillosAgua(Canvas canvas, Size size) {
    final fase = progreso * math.pi * 2;
    for (var i = 0; i < 24; i++) {
      final x = _fraccion(i * 81.41) * size.width;
      final y = size.height * (0.64 + _fraccion(i * 39.73) * 0.32);
      final pulso = (math.sin(fase * (1 + i % 2) + i * 0.9) + 1) / 2;
      canvas.drawLine(
        Offset(x - 5 - pulso * 5, y),
        Offset(x + 5 + pulso * 5, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06 + pulso * 0.24)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── Oscura ────────────────────────────────────────────────────────────

  /// Luna con un halo que respira muy despacio, arriba a la derecha.
  void _pintarLunaTenue(Canvas canvas, Size size) {
    final centro = Offset(size.width * 0.80, size.height * 0.13);
    final respiro = (math.sin(progreso * math.pi * 2) + 1) / 2;
    canvas.drawCircle(
      centro,
      120,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.20 + respiro * 0.08),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: 120)),
    );
    canvas.drawCircle(
      centro,
      24,
      Paint()..color = color.withValues(alpha: 0.30 + respiro * 0.06),
    );
  }

  /// Pocas estrellas que titilan en la parte alta.
  void _pintarEstrellasTenues(Canvas canvas, Size size) {
    for (var i = 0; i < 16; i++) {
      final x = _fraccion(i * 71.37) * size.width;
      final y = _fraccion(i * 29.11) * size.height * 0.45;
      final titileo = (math.sin(progreso * math.pi * 2 * (1 + i % 2) + i) + 1) / 2;
      canvas.drawCircle(
        Offset(x, y),
        0.9 + titileo * 1.0,
        Paint()..color = color.withValues(alpha: 0.10 + titileo * 0.30),
      );
    }
  }

  // ── Épica ─────────────────────────────────────────────────────────────

  /// Luz de hoguera que parpadea desde el borde de abajo.
  void _pintarResplandorFogata(Canvas canvas, Size size) {
    final fase = progreso * math.pi * 2;
    final parpadeo =
        0.5 + math.sin(fase * 3) * 0.25 + math.sin(fase * 7 + 1.3) * 0.15;
    final centro = Offset(size.width * 0.5, size.height * 1.02);
    final radio = size.height * 0.55;
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.18 + parpadeo * 0.12),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: radio)),
    );
  }

  /// Dos estandartes ondeando en los bordes, como un campamento antes de la
  /// batalla.
  void _pintarEstandartes(Canvas canvas, Size size) {
    final fase = progreso * math.pi * 2;
    for (var lado = 0; lado < 2; lado++) {
      final dir = lado == 0 ? 1.0 : -1.0;
      final xAsta = lado == 0 ? size.width * 0.07 : size.width * 0.93;
      final yTop = size.height * (0.08 + lado * 0.05);
      final largo = size.width * 0.30;
      final alto = 58.0;

      canvas.drawLine(
        Offset(xAsta, yTop - 10),
        Offset(xAsta, yTop + alto + size.height * 0.30),
        Paint()
          ..color = color.withValues(alpha: 0.30)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );

      const pasos = 14;
      final arriba = <Offset>[];
      final abajo = <Offset>[];
      for (var k = 0; k <= pasos; k++) {
        final u = k / pasos;
        final x = xAsta + dir * largo * u;
        final ondulacion = math.sin(fase * 2 - u * 4 + lado) * 7 * u;
        final mitad = alto / 2 * (1 - u);
        final centroY = yTop + alto / 2 + ondulacion;
        arriba.add(Offset(x, centroY - mitad));
        abajo.add(Offset(x, centroY + mitad));
      }
      final bandera = Path()..moveTo(arriba.first.dx, arriba.first.dy);
      for (final punto in arriba.skip(1)) {
        bandera.lineTo(punto.dx, punto.dy);
      }
      for (final punto in abajo.reversed) {
        bandera.lineTo(punto.dx, punto.dy);
      }
      bandera.close();

      canvas.drawPath(bandera, Paint()..color = color.withValues(alpha: 0.20));
      canvas.drawPath(
        bandera,
        Paint()
          ..color = color.withValues(alpha: 0.34)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }


  double _fraccion(double valor) {
    return valor - valor.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _AtmosferaPainter oldDelegate) {
    return oldDelegate.progreso != progreso ||
        oldDelegate.atmosfera != atmosfera ||
        oldDelegate.color != color;
  }
}
