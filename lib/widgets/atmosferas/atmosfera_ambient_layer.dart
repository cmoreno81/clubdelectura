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
                        acento: widget.accentColor,
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
  final Color acento;

  const _AtmosferaPainter({
    required this.progreso,
    required this.atmosfera,
    required this.color,
    required this.acento,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (atmosfera) {
      case AtmosferaLectura.romantica:
        _pintarAtardecerRosa(canvas, size);
        _pintarPetalos(canvas, size);
        _pintarCorazones(canvas, size);
        _pintarDestellos(canvas, size);

      case AtmosferaLectura.magica:
        _pintarCieloEstrellado(canvas, size);
        _pintarConstelacion(canvas, size);
        _pintarOrbesMagicos(canvas, size);
        _pintarEstrellaFugaz(canvas, size);

      case AtmosferaLectura.marina:
        _pintarVientoMarino(canvas, size);
        _pintarGaviotas(canvas, size);
        _pintarMareaViva(canvas, size);
        _pintarBrillosAgua(canvas, size);

      case AtmosferaLectura.bosque:
        _pintarMotasDeLuz(canvas, size);
        _pintarPinos(canvas, size);
        _pintarHojas(canvas, size);

      case AtmosferaLectura.oscura:
        // Noche cerrada: sombras que se cierran por los bordes, niebla
        // oscura, luna con halo, estrellas y cuervos.
        _pintarEstrellasTenues(canvas, size);
        _pintarLunaGrande(canvas, size);
        _pintarBruma(canvas, size, intensidad: 2.0);
        _pintarSombrasBordes(canvas, size);
        _pintarCuervos(canvas, size);

      case AtmosferaLectura.gotica:
        _pintarBruma(canvas, size, intensidad: 1.2);
        _pintarMurcielagos(canvas, size);
        _pintarVelas(canvas, size);

      case AtmosferaLectura.misteriosa:
        _pintarBruma(canvas, size, intensidad: 2.2);
        _pintarFocoLinterna(canvas, size);
        _pintarLuciernagas(canvas, size);

      case AtmosferaLectura.futurista:
        _pintarNocheNeon(canvas, size);
        _pintarEstelasNeon(canvas, size);
        _pintarPuntosNeon(canvas, size);

      case AtmosferaLectura.epica:
        _pintarResplandorFogata(canvas, size);
        _pintarEstandartes(canvas, size);
        _pintarChispas(canvas, size);

      case AtmosferaLectura.acogedora:
        _pintarLamparaCalida(canvas, size);
        _pintarLluviaSuave(canvas, size);
        _pintarGotasVentana(canvas, size);
        _pintarLibrosYManta(canvas, size);
        _pintarVaporTaza(canvas, size);

      case AtmosferaLectura.historica:
        _pintarCartasVolando(canvas, size);

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

  void _pintarBruma(Canvas canvas, Size size, {double intensidad = 1.0}) {
    for (var i = 0; i < 7; i++) {
      final desplazamiento = ((progreso * (0.1 + i * 0.012)) + i * 0.19) % 1;

      final x = -size.width * 0.4 + desplazamiento * size.width * 1.8;
      final y = size.height * (0.12 + i * 0.13);

      final paint = Paint()
        ..color = color.withValues(
          alpha: ((0.10 + (i % 3) * 0.025) * intensidad).clamp(0.0, 1.0),
        )
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

  /// Línea del suelo del rincón de lectura: libros y manta se apoyan aquí.
  double _lineaManta(Size size) => size.height * 0.91;

  /// Posición de la taza, apoyada sobre la manta.
  Offset _posicionTaza(Size size) =>
      Offset(size.width * 0.76, _lineaManta(size) - 4);

  /// Rincón de lectura abajo: una hilera de libros en el estante, una manta
  /// de cuadros por delante y una taza humeante encima.
  void _pintarLibrosYManta(Canvas canvas, Size size) {
    final suelo = _lineaManta(size);
    final fase = progreso * math.pi * 2;

    // Libros de pie, de distinto alto y grosor, alguno ladeado.
    var x = -6.0;
    var i = 0;
    while (x < size.width + 20) {
      final ancho = 14.0 + _fraccion(i * 13.37) * 14;
      final alto = size.height * (0.075 + _fraccion(i * 7.91) * 0.085);
      final inclinado = i % 7 == 3;
      canvas.save();
      if (inclinado) {
        canvas.translate(x + ancho, suelo);
        canvas.rotate(-0.16);
        canvas.translate(-(x + ancho), -suelo);
      }
      final lomo = Rect.fromLTWH(x, suelo - alto, ancho, alto + 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(lomo, const Radius.circular(2)),
        Paint()..color = (i % 3 == 0 ? acento : color).withValues(alpha: 0.20),
      );
      final banda = Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(x + 2, suelo - alto + 8),
        Offset(x + ancho - 2, suelo - alto + 8),
        banda,
      );
      canvas.drawLine(
        Offset(x + 2, suelo - alto + 13),
        Offset(x + ancho - 2, suelo - alto + 13),
        banda,
      );
      canvas.restore();
      x += ancho + 1.5;
      i++;
    }

    // Manta: borde ondulado que se mece apenas, con trama de cuadros.
    final manta = Path()..moveTo(-10, size.height + 10);
    for (double px = -10; px <= size.width + 10; px += 6) {
      final y =
          suelo +
          math.sin(px / 62 + fase) * 5 +
          math.sin(px / 27 - fase * 2) * 2 +
          (px > size.width * 0.55 ? -6 : 0);
      manta.lineTo(px, y);
    }
    manta
      ..lineTo(size.width + 10, size.height + 10)
      ..close();
    canvas.drawPath(manta, Paint()..color = acento.withValues(alpha: 0.30));
    canvas.save();
    canvas.clipPath(manta);
    final trama = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 3;
    for (double px = 0; px < size.width; px += 26) {
      canvas.drawLine(Offset(px, suelo - 12), Offset(px, size.height), trama);
    }
    for (double py = suelo; py < size.height; py += 26) {
      canvas.drawLine(Offset(0, py), Offset(size.width, py), trama);
    }
    final fina = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    for (double px = 13; px < size.width; px += 26) {
      canvas.drawLine(Offset(px, suelo - 12), Offset(px, size.height), fina);
    }
    canvas.restore();
    canvas.drawPath(
      manta,
      Paint()
        ..color = color.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Taza sobre la manta.
    final taza = _posicionTaza(size);
    final cuerpo = RRect.fromRectAndRadius(
      Rect.fromLTWH(taza.dx - 17, taza.dy - 30, 34, 30),
      const Radius.circular(6),
    );
    canvas.drawRRect(cuerpo, Paint()..color = color.withValues(alpha: 0.42));
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(taza.dx + 20, taza.dy - 16),
        width: 16,
        height: 18,
      ),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );
    canvas.drawLine(
      Offset(taza.dx - 12, taza.dy - 24),
      Offset(taza.dx + 12, taza.dy - 24),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.5,
    );
  }

  /// Vapor que sube de la taza en volutas que se difuminan.
  void _pintarVaporTaza(Canvas canvas, Size size) {
    final taza = _posicionTaza(size);
    final fase = progreso * math.pi * 2;
    for (var i = 0; i < 4; i++) {
      final vida = _vida(i, 0.25);
      final env = _envolvente(vida);
      final inicio = Offset(taza.dx - 9 + i * 6.0, taza.dy - 34);
      final path = Path()..moveTo(inicio.dx, inicio.dy);
      for (var paso = 1; paso <= 9; paso++) {
        path.lineTo(
          inicio.dx +
              math.sin(fase * 2 + paso * 0.7 + i * 1.3) * (4 + paso * 1.2),
          inicio.dy - vida * 18 - paso * 9.0,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.30 * env)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
    }
  }

  /// Dos constelaciones reconocibles (el Carro y Casiopea) cuyas estrellas
  /// laten con un ritmo ligeramente distinto.
  void _pintarConstelacion(Canvas canvas, Size size) {
    const carro = [
      Offset(0.08, 0.09), Offset(0.20, 0.12), Offset(0.31, 0.16),
      Offset(0.40, 0.23), Offset(0.38, 0.32), Offset(0.53, 0.30),
      Offset(0.51, 0.20), //
    ];
    const casiopea = [
      Offset(0.55, 0.64), Offset(0.64, 0.72), Offset(0.74, 0.64),
      Offset(0.83, 0.74), Offset(0.93, 0.66), //
    ];
    void dibujar(List<Offset> puntos, List<List<int>> uniones, int semilla) {
      final reales = [
        for (final p in puntos) Offset(p.dx * size.width, p.dy * size.height),
      ];
      final linea = Paint()
        ..color = color.withValues(alpha: 0.30)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (final u in uniones) {
        canvas.drawLine(reales[u[0]], reales[u[1]], linea);
      }
      for (var i = 0; i < reales.length; i++) {
        final pulso =
            (math.sin(
                  progreso * math.pi * 2 * (1 + (i + semilla) % 2) + i * 1.7,
                ) +
                1) /
            2;
        canvas.drawCircle(
          reales[i],
          9 + pulso * 4,
          Paint()
            ..color = acento.withValues(alpha: 0.18 + pulso * 0.14)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(
          reales[i],
          2.4 + pulso * 1.2,
          Paint()..color = color.withValues(alpha: 0.62 + pulso * 0.3),
        );
      }
    }

    dibujar(carro, const [
      [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 3], //
    ], 0);
    dibujar(casiopea, const [
      [0, 1], [1, 2], [2, 3], [3, 4], //
    ], 1);
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

  /// Luna grande con un halo que respira muy despacio, arriba a la derecha.
  void _pintarLunaGrande(Canvas canvas, Size size) {
    final centro = Offset(size.width * 0.78, size.height * 0.13);
    final respiro = (math.sin(progreso * math.pi * 2) + 1) / 2;
    final halo = size.width * 0.50;
    canvas.drawCircle(
      centro,
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF4C9).withValues(alpha: 0.42 + respiro * 0.12),
            const Color(0xFFFFF4C9).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: halo)),
    );
    canvas.drawCircle(
      centro,
      34,
      Paint()..color = const Color(0xFFFFF8E0).withValues(alpha: 0.95),
    );
    for (final c in const [Offset(-9, -6), Offset(8, 7), Offset(-2, 12)]) {
      canvas.drawCircle(
        centro + c,
        6,
        Paint()..color = color.withValues(alpha: 0.13),
      );
    }
  }

  /// Estrellas que titilan en la parte alta, más vivas hacia los bordes.
  void _pintarEstrellasTenues(Canvas canvas, Size size) {
    for (var i = 0; i < 22; i++) {
      final x = _fraccion(i * 71.37) * size.width;
      final y = _fraccion(i * 29.11) * size.height * 0.5;
      final titileo =
          (math.sin(progreso * math.pi * 2 * (1 + i % 2) + i) + 1) / 2;
      canvas.drawCircle(
        Offset(x, y),
        1.1 + titileo * 1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.25 + titileo * 0.55),
      );
    }
  }

  /// Las sombras se cierran desde los bordes y laten muy despacio.
  void _pintarSombrasBordes(Canvas canvas, Size size) {
    final latido = (math.sin(progreso * math.pi * 2) + 1) / 2;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.15, -0.25),
          radius: 1.05,
          colors: [
            Colors.transparent,
            const Color(0xFF120D26).withValues(alpha: 0.38 + latido * 0.10),
          ],
          stops: const [0.38, 1.0],
        ).createShader(rect),
    );
  }

  /// Dos cuervos que cruzan despacio por delante de la luna.
  void _pintarCuervos(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF140E22).withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    for (var c = 0; c < 2; c++) {
      final t = (progreso + c * 0.5) % 1;
      final x = size.width * 1.1 - t * (size.width * 1.25);
      final y =
          size.height * (0.16 + c * 0.13) + math.sin(t * math.pi * 4) * 10;
      final ala = 11 + math.sin(t * math.pi * 14) * 3.2;
      _dibujarAve(canvas, x, y, ala, paint);
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

  // ── Utilidades ────────────────────────────────────────────────────────

  /// Ciclo de vida de una partícula: 0 → 1 cada 10 s, desfasado por [paso].
  double _vida(int i, double paso) => (progreso + i * paso) % 1;

  /// Aparición y desvanecimiento suaves (0 en los extremos del ciclo), para
  /// que el bucle de 10 s no deje saltos.
  double _envolvente(double vida) => math.sin(vida * math.pi);

  /// Ave de perfil (gaviota, cuervo): dos curvas que forman las alas.
  void _dibujarAve(Canvas canvas, double x, double y, double ala, Paint paint) {
    final path = Path()
      ..moveTo(x - ala * 2, y + ala * 0.3)
      ..quadraticBezierTo(x - ala, y - ala * 0.9, x, y)
      ..quadraticBezierTo(x + ala, y - ala * 0.9, x + ala * 2, y + ala * 0.3);
    canvas.drawPath(path, paint);
  }

  Path _corazon(double s) {
    return Path()
      ..moveTo(0, s * 0.35)
      ..cubicTo(-s * 0.95, -s * 0.15, -s * 0.45, -s * 0.85, 0, -s * 0.3)
      ..cubicTo(s * 0.45, -s * 0.85, s * 0.95, -s * 0.15, 0, s * 0.35)
      ..close();
  }

  // ── Romántica ─────────────────────────────────────────────────────────

  /// Luz rosada de atardecer que respira desde abajo.
  void _pintarAtardecerRosa(Canvas canvas, Size size) {
    final latido = (math.sin(progreso * math.pi * 2) + 1) / 2;
    final centro = Offset(size.width * 0.5, size.height * 1.05);
    final radio = size.height * 0.62;
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF8FA3).withValues(alpha: 0.26 + latido * 0.08),
            const Color(0xFFFF8FA3).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: radio)),
    );
  }

  /// Corazoncitos que suben meciéndose y se desvanecen.
  void _pintarCorazones(Canvas canvas, Size size) {
    for (var i = 0; i < 11; i++) {
      final vida = _vida(i, 0.0909);
      final env = _envolvente(vida);
      final x =
          _fraccion(i * 47.31) * size.width +
          math.sin(progreso * math.pi * 2 + i * 1.9) * 16;
      final y = size.height * (0.98 - vida * 0.50) - _fraccion(i * 13.7) * 90;
      final tam = 9.0 + (i % 4) * 3;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.sin(progreso * math.pi * 2 + i) * 0.35);
      canvas.drawPath(
        _corazon(tam),
        Paint()..color = color.withValues(alpha: 0.34 * env),
      );
      canvas.restore();
    }
  }

  // ── Mágica ────────────────────────────────────────────────────────────

  /// Cielo de estrellas de cuatro puntas que titilan con distinto ritmo.
  void _pintarCieloEstrellado(Canvas canvas, Size size) {
    for (var i = 0; i < 30; i++) {
      final x = _fraccion(i * 91.13) * size.width;
      final y = _fraccion(i * 47.71) * size.height;
      final titileo =
          (math.sin(progreso * math.pi * 2 * (1 + i % 3) + i * 1.3) + 1) / 2;
      final r = 2.0 + titileo * 3.4 + (i % 4 == 0 ? 2 : 0);
      final paint = Paint()
        ..color = (i % 3 == 0 ? acento : color).withValues(
          alpha: 0.12 + titileo * 0.50,
        )
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x - r, y), Offset(x + r, y), paint);
      canvas.drawLine(Offset(x, y - r), Offset(x, y + r), paint);
      canvas.drawCircle(
        Offset(x, y),
        r * 0.35,
        Paint()..color = paint.color.withValues(alpha: paint.color.a * 0.9),
      );
    }
  }

  /// Orbes de luz que suben flotando, con halo, como hechizos sueltos.
  void _pintarOrbesMagicos(Canvas canvas, Size size) {
    for (var i = 0; i < 9; i++) {
      final vida = _vida(i, 0.111);
      final env = _envolvente(vida);
      final x =
          _fraccion(i * 53.9) * size.width +
          math.sin(progreso * math.pi * 2 * (1 + i % 2) + i) * 20;
      final y = size.height * (1.0 - vida * 0.75);
      canvas.drawCircle(
        Offset(x, y),
        12 + (i % 3) * 3,
        Paint()
          ..color = acento.withValues(alpha: 0.30 * env)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
      canvas.drawCircle(
        Offset(x, y),
        2.6,
        Paint()..color = Colors.white.withValues(alpha: 0.75 * env),
      );
    }
  }

  /// Estrella fugaz que cruza el cielo una vez por ciclo.
  void _pintarEstrellaFugaz(Canvas canvas, Size size) {
    final t = (progreso + 0.25) % 1;
    if (t > 0.30) return;
    final avance = t / 0.30;
    final inicio = Offset(size.width * 1.05, size.height * 0.06);
    final fin = Offset(size.width * 0.20, size.height * 0.42);
    final cabeza = Offset.lerp(inicio, fin, avance)!;
    final cola = Offset.lerp(inicio, fin, math.max(0, avance - 0.22))!;
    final alfa = math.sin(avance * math.pi);
    canvas.drawLine(
      cola,
      cabeza,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFFD36B).withValues(alpha: 0),
            const Color(0xFFFFD36B).withValues(alpha: 0.85 * alfa),
          ],
        ).createShader(Rect.fromPoints(cola, cabeza))
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      cabeza,
      3.4,
      Paint()..color = Colors.white.withValues(alpha: 0.9 * alfa),
    );
  }

  // ── Bosque ────────────────────────────────────────────────────────────

  /// Tres capas de pinos que se mecen con el viento, cada vez más cerca.
  void _pintarPinos(Canvas canvas, Size size) {
    final fase = progreso * math.pi * 2;
    for (var capa = 0; capa < 3; capa++) {
      final separacion = 46.0 + capa * 14;
      final base = size.height + 4;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.12 + capa * 0.08);
      for (var i = -1; i * separacion < size.width + separacion; i++) {
        final x = i * separacion + (capa.isEven ? 0 : separacion * 0.5);
        final altura =
            size.height *
            (0.15 + capa * 0.045) *
            (0.78 + _fraccion(i * 7.31 + capa * 3.1) * 0.45);
        final ancho = altura * 0.46;
        final balanceo = math.sin(fase + i * 0.7 + capa) * (2.0 + capa);
        for (var piso = 0; piso < 3; piso++) {
          final yArriba = base - altura + piso * altura * 0.26;
          final yAbajo = yArriba + altura * 0.42;
          final mitad = ancho * (0.42 + piso * 0.30) / 2 * 1.4;
          canvas.drawPath(
            Path()
              ..moveTo(x + balanceo * (1 - piso * 0.3), yArriba)
              ..lineTo(x - mitad, yAbajo)
              ..lineTo(x + mitad, yAbajo)
              ..close(),
            paint,
          );
        }
        canvas.drawRect(
          Rect.fromLTWH(x - 2.5, base - altura * 0.16, 5, altura * 0.16 + 4),
          paint,
        );
      }
    }
  }

  /// Motas de luz dorada que se cuelan entre las ramas y suben despacio.
  void _pintarMotasDeLuz(Canvas canvas, Size size) {
    for (var i = 0; i < 16; i++) {
      final vida = _vida(i, 0.0625);
      final env = _envolvente(vida);
      final x =
          _fraccion(i * 61.7) * size.width +
          math.sin(progreso * math.pi * 2 + i * 1.1) * 12;
      final y = size.height * (0.78 - vida * 0.42) + _fraccion(i * 9.3) * 70;
      canvas.drawCircle(
        Offset(x, y),
        6 + (i % 3) * 2,
        Paint()
          ..color = const Color(0xFFFFE08A).withValues(alpha: 0.38 * env)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(x, y),
        1.6,
        Paint()..color = const Color(0xFFFFF1BF).withValues(alpha: 0.8 * env),
      );
    }
  }

  // ── Gótica ────────────────────────────────────────────────────────────

  /// Tres velas cuya llama parpadea y de las que sube un hilo de humo.
  void _pintarVelas(Canvas canvas, Size size) {
    final fase = progreso * math.pi * 2;
    for (var v = 0; v < 3; v++) {
      final x = size.width * (0.20 + v * 0.30);
      final yBase = size.height * 0.97;
      final altura = 38.0 + (v % 2) * 14;
      final parpadeo =
          0.55 +
          math.sin(fase * (3 + v) + v * 2) * 0.25 +
          math.sin(fase * 7 + v) * 0.15;

      // Resplandor de la llama sobre el entorno.
      final yLlama = yBase - altura - 12;
      canvas.drawCircle(
        Offset(x, yLlama),
        60 + parpadeo * 24,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  const Color(0xFFFFB84D).withValues(alpha: 0.30 * parpadeo),
                  const Color(0xFFFFB84D).withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: Offset(x, yLlama), radius: 84),
              ),
      );
      // Cuerpo de la vela.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 6, yBase - altura, 12, altura),
          const Radius.circular(2),
        ),
        Paint()..color = color.withValues(alpha: 0.30),
      );
      // Llama.
      final llama = Path()
        ..moveTo(x, yLlama - 9 - parpadeo * 4)
        ..quadraticBezierTo(x + 6, yLlama - 1, x, yLlama + 5)
        ..quadraticBezierTo(x - 6, yLlama - 1, x, yLlama - 9 - parpadeo * 4)
        ..close();
      canvas.drawPath(
        llama,
        Paint()..color = const Color(0xFFFFC857).withValues(alpha: 0.85),
      );
      // Humo.
      final humo = Path()..moveTo(x, yLlama - 12);
      for (var k = 1; k <= 8; k++) {
        humo.lineTo(
          x + math.sin(fase * 2 + k * 0.8 + v) * (3 + k * 1.4),
          yLlama - 12 - k * 11.0,
        );
      }
      canvas.drawPath(
        humo,
        Paint()
          ..color = color.withValues(alpha: 0.13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Dos murciélagos que cruzan la noche batiendo las alas.
  void _pintarMurcielagos(Canvas canvas, Size size) {
    for (var b = 0; b < 2; b++) {
      final t = (progreso + b * 0.5) % 1;
      final x = size.width * 1.1 - t * (size.width * 1.2);
      final y =
          size.height * (0.22 + b * 0.18) + math.sin(t * math.pi * 6) * 12;
      final aleteo = math.sin(t * math.pi * 40);
      final ala = 11.0;
      final cuerpo = Paint()
        ..color = const Color(0xFF2A1E33).withValues(alpha: 0.55);
      final alas = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x - ala,
          y - ala * (0.8 + aleteo * 0.5),
          x - ala * 2.0,
          y - ala * (0.2 + aleteo * 0.6),
        )
        ..quadraticBezierTo(
          x - ala * 1.4,
          y + ala * 0.3,
          x - ala * 1.0,
          y + ala * 0.1,
        )
        ..quadraticBezierTo(x - ala * 0.5, y + ala * 0.5, x, y + ala * 0.35)
        ..quadraticBezierTo(
          x + ala * 0.5,
          y + ala * 0.5,
          x + ala * 1.0,
          y + ala * 0.1,
        )
        ..quadraticBezierTo(
          x + ala * 1.4,
          y + ala * 0.3,
          x + ala * 2.0,
          y - ala * (0.2 + aleteo * 0.6),
        )
        ..quadraticBezierTo(x + ala, y - ala * (0.8 + aleteo * 0.5), x, y)
        ..close();
      canvas.drawPath(alas, cuerpo);
    }
  }

  // ── Misteriosa ────────────────────────────────────────────────────────

  /// Haz de linterna que barre la niebla de un lado a otro.
  void _pintarFocoLinterna(Canvas canvas, Size size) {
    final origen = Offset(size.width * 0.14, size.height * 1.04);
    final angulo =
        -math.pi / 2 + 0.30 + math.sin(progreso * math.pi * 2) * 0.42;
    final largo = size.height * 1.05;
    final abertura = 0.17;
    final p1 =
        origen +
        Offset(math.cos(angulo - abertura), math.sin(angulo - abertura)) *
            largo;
    final p2 =
        origen +
        Offset(math.cos(angulo + abertura), math.sin(angulo + abertura)) *
            largo;
    final centro = origen + Offset(math.cos(angulo), math.sin(angulo)) * largo;
    canvas.drawPath(
      Path()
        ..moveTo(origen.dx, origen.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFFE6A8).withValues(alpha: 0.80),
            const Color(0xFFFFE6A8).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromPoints(origen, centro))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  // ── Futurista ─────────────────────────────────────────────────────────

  // ── Futurista ─────────────────────────────────────────────────────────

  /// Colores de neón de verdad: cian, magenta, violeta, lima y naranja.
  static const _neones = [
    Color(0xFF00E5FF),
    Color(0xFFFF2BD6),
    Color(0xFF9D4DFF),
    Color(0xFFB6FF00),
    Color(0xFFFF7A1A),
  ];

  /// Velo de noche de ciudad para que el neón destaque sobre el fondo claro.
  void _pintarNocheNeon(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x59190B3D), Color(0x26FF2BD6), Color(0x4D0A2A5C)],
        ).createShader(rect),
    );
  }

  /// Puntos de luz de neón con halo que suben meciéndose y se apagan.
  void _pintarPuntosNeon(Canvas canvas, Size size) {
    final fase = progreso * math.pi * 2;
    for (var i = 0; i < 38; i++) {
      final neon = _neones[i % _neones.length];
      final vida = _vida(i, 0.0263);
      final env = _envolvente(vida);
      // 0,618…: reparte los puntos de forma pareja por todo el ancho.
      final x =
          _fraccion(i * 0.61803 + 0.17) * size.width +
          math.sin(fase * (1 + i % 2) + i * 0.8) * 16;
      final y =
          size.height * (1.02 - vida * 0.55) -
          _fraccion(i * 23.1) * size.height * 0.30;
      final pulso = (math.sin(fase * 3 + i) + 1) / 2;
      canvas.drawCircle(
        Offset(x, y),
        8 + pulso * 6 + (i % 3) * 2,
        Paint()
          ..color = neon.withValues(alpha: 0.55 * env)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawCircle(
        Offset(x, y),
        2.2 + pulso * 1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.95 * env),
      );
    }
  }

  /// Estelas de luz que cruzan la pantalla, como láseres o coches lejanos.
  void _pintarEstelasNeon(Canvas canvas, Size size) {
    for (var i = 0; i < 6; i++) {
      final neon = _neones[(i * 2) % _neones.length];
      final t = ((progreso * (1 + i % 2) + i * 0.17) % 1);
      final dir = i.isEven ? 1.0 : -1.0;
      final largo = size.width * (0.30 + (i % 3) * 0.08);
      final y = size.height * (0.12 + _fraccion(i * 37.7) * 0.76);
      final cabeza = dir > 0
          ? -largo + t * (size.width + largo * 2)
          : size.width + largo - t * (size.width + largo * 2);
      final cola = cabeza - dir * largo;
      final rect = Rect.fromPoints(Offset(cola, y), Offset(cabeza, y));
      final trazo = Paint()
        ..shader = LinearGradient(
          colors: [neon.withValues(alpha: 0), neon.withValues(alpha: 0.95)],
          begin: dir > 0 ? Alignment.centerLeft : Alignment.centerRight,
          end: dir > 0 ? Alignment.centerRight : Alignment.centerLeft,
        ).createShader(rect.inflate(1))
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cola, y),
        Offset(cabeza, y),
        Paint()
          ..shader = trazo.shader
          ..strokeWidth = 7
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawLine(Offset(cola, y), Offset(cabeza, y), trazo);
      canvas.drawCircle(
        Offset(cabeza, y),
        2.6,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
    }
  }

  // ── Acogedora ─────────────────────────────────────────────────────────

  /// Luz cálida de lámpara que parpadea apenas, arriba a la izquierda.
  void _pintarLamparaCalida(Canvas canvas, Size size) {
    final fase = progreso * math.pi * 2;
    final parpadeo = 0.5 + math.sin(fase * 2) * 0.2 + math.sin(fase * 5) * 0.1;
    final centro = Offset(size.width * 0.08, size.height * 0.03);
    final radio = size.height * 0.55;
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFC27A).withValues(alpha: 0.26 + parpadeo * 0.10),
            const Color(0xFFFFC27A).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: radio)),
    );
  }

  /// Lluvia fina que cae en diagonal al otro lado de la ventana.
  void _pintarLluviaSuave(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.30)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 46; i++) {
      final x = _fraccion(i * 57.19) * (size.width + 40);
      final fase = (progreso * (2 + i % 2) + i * 0.0743) % 1;
      final y = -30 + fase * (size.height + 60);
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 24), paint);
    }
  }

  /// Gotas que resbalan despacio por el cristal.
  void _pintarGotasVentana(Canvas canvas, Size size) {
    for (var i = 0; i < 8; i++) {
      final x = _fraccion(i * 83.3) * size.width;
      final vida = _vida(i, 0.125);
      final env = _envolvente(vida);
      final y = size.height * (0.05 + vida * 0.55 + _fraccion(i * 5.3) * 0.3);
      canvas.drawLine(
        Offset(x, y - 26),
        Offset(x, y),
        Paint()
          ..color = color.withValues(alpha: 0.14 * env)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(x, y),
        3.2,
        Paint()..color = color.withValues(alpha: 0.30 * env),
      );
    }
  }

  // ── Histórica ─────────────────────────────────────────────────────────

  /// Cartas y sobres que flotan, giran y se vuelven de canto como papel.
  void _pintarCartasVolando(Canvas canvas, Size size) {
    final fase = progreso * math.pi * 2;
    for (var i = 0; i < 12; i++) {
      final vida = _vida(i, 0.0833);
      final env = _envolvente(vida);
      final x =
          _fraccion(i * 59.9) * size.width + math.sin(fase + i * 1.4) * 26;
      final y =
          size.height * (-0.05 + _fraccion(i * 17.3) * 0.65 + vida * 0.45);
      final sobre = i % 3 == 0;
      final ancho = sobre ? 30.0 : 22.0;
      final alto = sobre ? 20.0 : 29.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.sin(fase + i * 0.9) * 0.55);
      // Al girar sobre sí misma se ve de frente o de canto.
      canvas.scale(0.35 + 0.65 * math.cos(fase * (1 + i % 2) + i).abs(), 1);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: ancho,
        height: alto,
      );
      final papel = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      canvas.drawRRect(
        papel,
        Paint()..color = const Color(0xFFF4E8D2).withValues(alpha: 0.78 * env),
      );
      final trazo = Paint()
        ..color = color.withValues(alpha: 0.50 * env)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      canvas.drawRRect(papel, trazo);
      if (sobre) {
        canvas.drawPath(
          Path()
            ..moveTo(rect.left, rect.top)
            ..lineTo(0, rect.center.dy + 1)
            ..lineTo(rect.right, rect.top),
          trazo,
        );
        canvas.drawCircle(
          Offset(0, rect.center.dy + 1),
          2.6,
          Paint()
            ..color = const Color(0xFFB5493B).withValues(alpha: 0.75 * env),
        );
      } else {
        for (var l = 0; l < 4; l++) {
          final yl = rect.top + 6 + l * 5.0;
          canvas.drawLine(
            Offset(rect.left + 4, yl),
            Offset(rect.right - 4 - (l == 3 ? 7 : 0), yl),
            trazo..strokeWidth = 0.9,
          );
        }
      }
      canvas.restore();
    }
  }

  double _fraccion(double valor) {
    return valor - valor.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _AtmosferaPainter oldDelegate) {
    return oldDelegate.progreso != progreso ||
        oldDelegate.atmosfera != atmosfera ||
        oldDelegate.color != color ||
        oldDelegate.acento != acento;
  }
}
