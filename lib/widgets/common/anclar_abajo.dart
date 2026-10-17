import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Pone [arriba] en la parte superior y [abajo] pegado al fondo. Si le dan más
/// altura de la que necesitan, el sobrante queda en medio; si no, [abajo]
/// va justo después de [arriba], separado por [hueco].
///
/// No usa `Expanded`, así que se puede medir con altura libre (primero se
/// mide a su altura natural y luego la fila lo estira), algo que un `Column`
/// con `Expanded` no admite.
class AnclarAbajo extends MultiChildRenderObjectWidget {
  AnclarAbajo({
    super.key,
    required Widget arriba,
    required Widget abajo,
    this.hueco = 0,
  }) : super(children: [arriba, abajo]);

  final double hueco;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderAnclarAbajo(hueco);

  @override
  void updateRenderObject(BuildContext context, _RenderAnclarAbajo r) {
    r.hueco = hueco;
  }
}

class _Datos extends ContainerBoxParentData<RenderBox> {}

class _RenderAnclarAbajo extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _Datos>,
        RenderBoxContainerDefaultsMixin<RenderBox, _Datos> {
  _RenderAnclarAbajo(this._hueco);

  double _hueco;
  set hueco(double v) {
    if (v == _hueco) return;
    _hueco = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _Datos) child.parentData = _Datos();
  }

  RenderBox get _arriba => firstChild!;
  RenderBox get _abajo => childAfter(firstChild!)!;

  @override
  void performLayout() {
    final c = BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
    );
    _arriba.layout(c, parentUsesSize: true);
    _abajo.layout(c, parentUsesSize: true);
    final natural = _arriba.size.height + _hueco + _abajo.size.height;
    final alto = natural > constraints.minHeight
        ? natural
        : constraints.minHeight;
    size = constraints.constrain(Size(constraints.maxWidth, alto));
    (_arriba.parentData! as _Datos).offset = Offset.zero;
    (_abajo.parentData! as _Datos).offset = Offset(
      0,
      size.height - _abajo.size.height,
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) => _intrinseco(width);
  @override
  double computeMaxIntrinsicHeight(double width) => _intrinseco(width);

  double _intrinseco(double width) =>
      _arriba.getMaxIntrinsicHeight(width) +
      _hueco +
      _abajo.getMaxIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
    );
    final natural =
        _arriba.getDryLayout(c).height + _hueco + _abajo.getDryLayout(c).height;
    return constraints.constrain(
      Size(
        constraints.maxWidth,
        natural > constraints.minHeight ? natural : constraints.minHeight,
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
