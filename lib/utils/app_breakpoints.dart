import 'package:flutter/widgets.dart';

/// Breakpoints de layout siguiendo las guías de Material 3.
///
///  compact   < 600 px  → NavigationBar inferior (móvil)
///  medium   600–840 px → NavigationRail lateral (tablet pequeño / iPad mini)
///  expanded  > 840 px  → NavigationRail extendido (iPad / tablet grande)
abstract final class AppBreakpoints {
  static const double medium = 600;
  static const double expanded = 840;

  /// Ancho máximo del área de contenido en layouts expanded.
  static const double contentMaxWidth = 900;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < medium;

  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= medium && w < expanded;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;

  /// true si la pantalla es lo suficientemente ancha para usar NavigationRail.
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium;
}
