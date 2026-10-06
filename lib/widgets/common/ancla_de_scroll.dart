import 'package:flutter/material.dart';

/// Evita los saltos de scroll cuando un bloque que está **por encima** de lo
/// que se está viendo cambia de altura (algo que se carga tarde: una tarjeta
/// que aparece, una sección que se rellena…).
///
/// Una `ListView` mantiene la posición en píxeles, así que si un bloque de
/// arriba crece 200 px, el contenido que estás leyendo se desplaza 200 px de
/// golpe. Este widget detecta el cambio y corrige la posición en la misma
/// medida, de modo que lo que ves se queda donde estaba. Solo actúa cuando
/// el bloque está entero por encima de la parte visible; si lo estás viendo,
/// crece con normalidad.
class AnclaDeScroll extends StatefulWidget {
  const AnclaDeScroll({super.key, required this.child});

  final Widget child;

  @override
  State<AnclaDeScroll> createState() => _AnclaDeScrollState();
}

class _AnclaDeScrollState extends State<AnclaDeScroll> {
  double? _alto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
  }

  void _medir() {
    if (!mounted) return;
    final caja = context.findRenderObject();
    if (caja is! RenderBox || !caja.hasSize) return;
    final nuevo = caja.size.height;
    final anterior = _alto;
    _alto = nuevo;
    if (anterior == null || (nuevo - anterior).abs() < 0.5) return;

    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;
    final position = scrollable.position;
    if (position.pixels <= 0) return; // arriba del todo: nada que mantener
    final viewport = scrollable.context.findRenderObject();
    if (viewport is! RenderBox) return;

    // Parte superior del bloque respecto al viewport. Como solo ha cambiado
    // su altura, su borde inferior anterior era `arriba + anterior`.
    final arriba = caja.localToGlobal(Offset.zero, ancestor: viewport).dy;
    if (arriba + anterior <= 0) position.correctBy(nuevo - anterior);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
        return false;
      },
      child: SizeChangedLayoutNotifier(child: widget.child),
    );
  }
}
