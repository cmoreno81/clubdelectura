import 'package:flutter/widgets.dart';

import 'atmosfera_controller.dart';

class AtmosferaScope extends InheritedNotifier<AtmosferaController> {
  const AtmosferaScope({
    super.key,
    required AtmosferaController controller,
    required super.child,
  }) : super(notifier: controller);

  static AtmosferaController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AtmosferaScope>();

    assert(scope != null, 'AtmosferaScope no encontrado');

    return scope!.notifier!;
  }
}
