import 'dart:async';

import 'package:flutter/material.dart';

/// Panel de detalle de las tablets anchas (iPad en horizontal): al abrir la
/// ficha de un libro, se muestra a la derecha, con la lista de la izquierda a
/// la vista, como en Mail o Notas. En pantallas más estrechas no existe y la
/// ficha se abre a pantalla completa como siempre.
///
/// Dentro del panel vive su propio navegador: lo que se abra desde la ficha
/// (comentarios, kit…) se queda en el panel.
class DetalleLateral extends ChangeNotifier {
  DetalleLateral._();

  static final DetalleLateral instance = DetalleLateral._();

  static const double ancho = 460;

  /// Ancho mínimo de la zona de contenido (sin barra lateral) para poder
  /// mostrar lista + panel con comodidad.
  static const double anchoMinimoDisponible = 1100;

  final GlobalKey<NavigatorState> navegador = GlobalKey<NavigatorState>();

  /// La tablet tiene sitio para el panel (lo fija el marco en cada fotograma).
  bool disponible = false;

  bool _abierto = false;
  bool get abierto => _abierto && disponible;

  Completer<void>? _pendiente;

  /// ¿Esta pantalla vive dentro del panel? Lo abierto desde dentro se apila
  /// en el panel en vez de sustituir la ficha.
  bool contextoEnPanel(BuildContext context) =>
      navegador.currentState != null &&
      Navigator.maybeOf(context) == navegador.currentState;

  /// Muestra [ruta] en el panel, sustituyendo la ficha anterior. El futuro
  /// termina cuando el panel se cierra o se sustituye por otra ficha.
  Future<void> mostrar(Route<dynamic> ruta) async {
    _completar();
    final completer = Completer<void>();
    _pendiente = completer;
    final eraAbierto = abierto;
    _abierto = true;
    if (!eraAbierto) notifyListeners();
    // El navegador del panel solo existe una vez abierto.
    await WidgetsBinding.instance.endOfFrame;
    final nav = navegador.currentState;
    if (nav == null) {
      _completar();
      return completer.future;
    }
    unawaited(nav.pushAndRemoveUntil(ruta, (r) => r.isFirst));
    return completer.future;
  }

  void cerrar() {
    if (!_abierto) return;
    _abierto = false;
    _completar();
    notifyListeners();
  }

  /// El marco avisa de si hay sitio; si ya no lo hay, el panel se cierra.
  void actualizarDisponible(bool hayHueco) {
    if (disponible == hayHueco) return;
    disponible = hayHueco;
    if (!hayHueco && _abierto) {
      _abierto = false;
      _completar();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  void _completar() {
    final c = _pendiente;
    _pendiente = null;
    if (c != null && !c.isCompleted) c.complete();
  }
}

/// Observa el navegador del panel: al volver a su raíz (la ficha se cierra
/// con su flecha), el panel se cierra.
class ObservadorDetalle extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && previousRoute.isFirst) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => DetalleLateral.instance.cerrar(),
      );
    }
  }
}

/// Panel derecho: cabecera con el botón de cerrar y el navegador del detalle.
class PanelDetalle extends StatelessWidget {
  const PanelDetalle({
    super.key,
    required this.colorFondo,
    required this.colorBorde,
  });

  final Color colorFondo;
  final Color colorBorde;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('panel-detalle'),
      width: DetalleLateral.ancho,
      decoration: BoxDecoration(
        color: colorFondo,
        border: Border(left: BorderSide(color: colorBorde)),
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            left: false,
            child: Align(
              alignment: Alignment.centerRight,
              // Sin «tooltip»: este botón vive fuera de cualquier Overlay.
              child: Semantics(
                button: true,
                label: 'Cerrar',
                child: IconButton(
                  key: const Key('panel-detalle-cerrar'),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: DetalleLateral.instance.cerrar,
                ),
              ),
            ),
          ),
          Expanded(
            child: ClipRect(
              // Sin el controlador de «Hero» de la app: dos navegadores no
              // pueden compartirlo y, al abrir el panel, el de la app dejaba
              // de funcionar (ni la X ni la barra lateral respondían).
              child: HeroControllerScope.none(
                child: Navigator(
                  key: DetalleLateral.instance.navegador,
                  observers: [ObservadorDetalle()],
                  onGenerateInitialRoutes: (_, _) => [
                    PageRouteBuilder<void>(
                      pageBuilder: (_, _, _) => const SizedBox.expand(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Abre una pantalla de detalle (ficha de libro, perfil de una amiga…): a
/// pantalla completa o, en un iPad ancho, en el panel de la derecha. Si la
/// llamada viene de dentro del propio panel, se apila en él.
Future<T?> empujarDetalle<T>(BuildContext context, Route<T> ruta) {
  final detalle = DetalleLateral.instance;
  if (detalle.disponible && !detalle.contextoEnPanel(context)) {
    return detalle.mostrar(ruta).then<T?>((_) => null);
  }
  return Navigator.push<T>(context, ruta);
}
