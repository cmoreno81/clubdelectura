import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Dos tarjetas lado a lado que miden lo mismo (la altura de la más alta).
///
/// Como `IntrinsicHeight`, pero midiendo de verdad en vez de preguntar por
/// dimensiones intrínsecas: así admite listas con scroll (`ListView`,
/// `ReorderableListView` con `shrinkWrap`), que con `IntrinsicHeight` fallan
/// y hacen desaparecer la tarjeta.
class FilaIgualAltura extends MultiChildRenderObjectWidget {
  FilaIgualAltura({
    super.key,
    required Widget izquierda,
    required Widget derecha,
    this.separacion = 16,
  }) : super(children: [izquierda, derecha]);

  final double separacion;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFilaIgualAltura(separacion);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFilaIgualAltura renderObject,
  ) {
    renderObject.separacion = separacion;
  }
}

class _DatosFila extends ContainerBoxParentData<RenderBox> {}

class _RenderFilaIgualAltura extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DatosFila>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DatosFila> {
  _RenderFilaIgualAltura(this._separacion);

  double _separacion;
  double get separacion => _separacion;
  set separacion(double v) {
    if (v == _separacion) return;
    _separacion = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DatosFila) child.parentData = _DatosFila();
  }

  @override
  void performLayout() {
    final ancho = (constraints.maxWidth - _separacion) / 2;
    final hijos = <RenderBox>[];
    for (var h = firstChild; h != null; h = childAfter(h)) {
      hijos.add(h);
    }
    // 1) Se miden con su altura natural; 2) se vuelven a medir con la mayor.
    var alto = 0.0;
    for (final h in hijos) {
      h.layout(
        BoxConstraints(minWidth: ancho, maxWidth: ancho),
        parentUsesSize: true,
      );
      if (h.size.height > alto) alto = h.size.height;
    }
    var x = 0.0;
    for (final h in hijos) {
      // Altura mínima (no fija): con restricciones apretadas el hijo se
      // volvería «frontera de relayout» y, si cambiara de tamaño por su
      // cuenta (p. ej. al reordenar tomos), la fila no se enteraría.
      h.layout(
        BoxConstraints(minWidth: ancho, maxWidth: ancho, minHeight: alto),
        parentUsesSize: true,
      );
      (h.parentData! as _DatosFila).offset = Offset(x, 0);
      x += ancho + _separacion;
    }
    size = constraints.constrain(Size(constraints.maxWidth, alto));
  }

  @override
  double computeMinIntrinsicHeight(double width) => _alto(width);
  @override
  double computeMaxIntrinsicHeight(double width) => _alto(width);

  double _alto(double width) {
    final ancho = (width - _separacion) / 2;
    var alto = 0.0;
    for (var h = firstChild; h != null; h = childAfter(h)) {
      final v = h.getMaxIntrinsicHeight(ancho);
      if (v > alto) alto = v;
    }
    return alto;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final ancho = (constraints.maxWidth - _separacion) / 2;
    var alto = 0.0;
    for (var h = firstChild; h != null; h = childAfter(h)) {
      final s = h.getDryLayout(
        BoxConstraints(minWidth: ancho, maxWidth: ancho),
      );
      if (s.height > alto) alto = s.height;
    }
    return constraints.constrain(Size(constraints.maxWidth, alto));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
