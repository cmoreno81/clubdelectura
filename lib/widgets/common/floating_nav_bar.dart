import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Espacio a dejar al final de cualquier contenido con scroll que viva bajo
/// un [FloatingNavBar] (`extendBody: true`), para que la última tarjeta no
/// quede tapada por la píldora al hacer scroll hasta el final — cubre su
/// altura + el margen inferior + el área segura del dispositivo, con un
/// poco de aire extra.
const kFloatingNavClearance = 140.0;

/// Envuelve un [NavigationBar] (u otro contenido de menú inferior, p. ej. un
/// Row con un botón adicional + NavigationBar) en una píldora flotante —
/// separada de los bordes de la pantalla, con esquinas redondeadas y sombra —
/// al estilo del menú inferior de WhatsApp, en vez de una barra convencional
/// pegada de borde a borde.
///
/// No reimplementa la selección de pestañas ni el comportamiento de las
/// etiquetas: sigue siendo un [NavigationBar] real por dentro (accesibilidad,
/// ripple y `labelBehavior` intactos), solo cambia el "marco" que lo rodea.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.child, this.height = 64});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final navTheme = Theme.of(context).navigationBarTheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.midnight.withValues(alpha: .18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: navTheme.copyWith(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              height: height,
              indicatorShape: const StadiumBorder(),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Fila de pestañas para dentro de un [FloatingNavBar]. Un [NavigationBar]
/// normal solo resalta el icono al seleccionar (su "indicador" tiene un
/// tamaño fijo que no crece con el contenido); esta fila usa pestañas
/// propias cuya burbuja cubre icono + etiqueta juntos, con un margen de
/// seguridad para no tocar el borde redondeado de la píldora. Reutiliza la
/// misma paleta que [NavigationBarThemeData] (respeta la atmósfera activa).
class FloatingNavRow extends StatelessWidget {
  const FloatingNavRow({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.showLabelForUnselected = true,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// false = solo la pestaña seleccionada muestra su etiqueta (equivalente a
  /// [NavigationDestinationLabelBehavior.onlyShowSelected]); true = todas la
  /// muestran siempre ([NavigationDestinationLabelBehavior.alwaysShow]).
  final bool showLabelForUnselected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          for (var i = 0; i < destinations.length; i++)
            Expanded(
              child: _FloatingNavItem(
                destination: destinations[i],
                selected: selectedIndex == i,
                showLabel: showLabelForUnselected || selectedIndex == i,
                onTap: () => onDestinationSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

/// Una pestaña de [FloatingNavRow]. A diferencia del indicador de
/// [NavigationBar] (tamaño fijo, solo rodea el icono), esta burbuja crece
/// para cubrir icono + etiqueta cuando está seleccionada.
class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.destination,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final navTheme = Theme.of(context).navigationBarTheme;
    final states = <WidgetState>{if (selected) WidgetState.selected};
    final indicatorColor =
        navTheme.indicatorColor ??
        Theme.of(context).colorScheme.secondaryContainer;
    final indicatorShape = navTheme.indicatorShape ?? const StadiumBorder();
    final iconTheme =
        navTheme.iconTheme?.resolve(states) ??
        IconThemeData(color: AppColors.textMuted, size: 24);
    final labelStyle = navTheme.labelTextStyle?.resolve(states);

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Padding(
        // Margen propio, FUERA del InkWell/burbuja: así el ripple y el
        // resaltado quedan exactamente del tamaño de la píldora, sin
        // invadir este hueco de seguridad hasta el borde redondeado del
        // menú flotante.
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: indicatorShape,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              decoration: ShapeDecoration(
                color: selected ? indicatorColor : Colors.transparent,
                shape: indicatorShape,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                    data: iconTheme,
                    child: selected
                        ? (destination.selectedIcon ?? destination.icon)
                        : destination.icon,
                  ),
                  if (showLabel) ...[
                    const SizedBox(height: 2),
                    // FittedBox en vez de maxLines+ellipsis: con 6 pestañas
                    // ("Clubvisión", "Lecturas"...) el hueco es demasiado
                    // estrecho para el texto completo a tamaño normal — mejor
                    // encogerlo entero que cortarlo con "...".
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          destination.label,
                          maxLines: 1,
                          style: labelStyle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pon este menú en una pantalla que normalmente se abre como "atajo" desde
/// el dashboard global (Inicio/Catálogo/Ligas/Mi club|espacio/Ajustes) —
/// [LibrosPage] en modo catálogo, [LigaPage] — para que no lo pierda al
/// entrar, en vez de quedarse sin menú inferior hasta volver atrás.
/// `null` en cualquier otro punto de entrada a esa misma pantalla (se abre
/// desde muchos otros sitios) simplemente no la muestra: mismo widget, sin
/// tocar su comportamiento fuera de este caso.
class GlobalNavConfig {
  const GlobalNavConfig({
    required this.selectedIndex,
    required this.hasClub,
    required this.onSelectHome,
    required this.onSelectCatalogo,
    required this.onSelectLigas,
    required this.onSelectClub,
    required this.onSelectAjustes,
  });

  /// 0=Inicio, 1=Catálogo, 2=Ligas, 3=Mi club/espacio, 4=Ajustes.
  final int selectedIndex;
  final bool hasClub;
  final VoidCallback onSelectHome;
  final VoidCallback onSelectCatalogo;
  final VoidCallback onSelectLigas;
  final VoidCallback onSelectClub;
  final VoidCallback onSelectAjustes;

  Widget buildFloatingNavBar() {
    return FloatingNavBar(
      height: 72,
      child: FloatingNavRow(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              onSelectHome();
            case 1:
              onSelectCatalogo();
            case 2:
              onSelectLigas();
            case 3:
              onSelectClub();
            case 4:
              onSelectAjustes();
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore_rounded),
            label: 'Catálogo',
          ),
          const NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Ligas',
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: hasClub ? 'Mi club' : 'Mi espacio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
