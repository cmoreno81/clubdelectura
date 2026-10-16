import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_reads_mark.dart';
import 'detalle_lateral.dart';
import 'shell_navegacion.dart';

/// Ancho a partir del cual una pantalla se trata como tablet. Se mira el lado
/// corto para que un iPhone en horizontal no cuente, y el ancho para que una
/// ventana estrecha de multitarea (Split View) vuelva al diseño de móvil.
bool esTablet(Size tamano) => tamano.shortestSide >= 600;

/// Tablets estrechas (7" en vertical): la barra lateral va compacta, solo con
/// iconos y rótulos pequeños, para dejar sitio al contenido.
bool barraCompacta(Size tamano) => tamano.width < 800;

/// Ancho de la barra lateral compacta.
const double kAnchoBarraCompacta = 84;

/// Ancho de la barra lateral.
const double kAnchoBarraLateral = 248;

/// Ancho máximo de la columna de contenido (lectura cómoda, como las apps de
/// Apple: contenido centrado, no estirado de borde a borde).
const double kAnchoColumna = 820;

final GlobalKey _claveColumna = GlobalKey(debugLabel: 'columna-tablet');

/// Envuelve el navegador de la app. En un móvil no hace nada. En una tablet:
/// barra lateral persistente (si hay sesión) y el contenido en una columna
/// centrada. Las pantallas ven el ancho de la columna, no el de la tablet.
class MarcoTablet extends StatelessWidget {
  const MarcoTablet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (!esTablet(mq.size)) return child;

    return ListenableBuilder(
      listenable: Listenable.merge([
        ShellNavegacion.instance,
        DetalleLateral.instance,
      ]),
      builder: (context, _) {
        final shell = ShellNavegacion.instance;
        final detalle = DetalleLateral.instance;
        final conBarra = shell.activo;
        // La pantalla de arranque ocupa todo el ancho (degradado a sangre).
        if (!conBarra && shell.pantallaCompleta) return child;
        final anchoBarra = barraCompacta(mq.size)
            ? kAnchoBarraCompacta
            : kAnchoBarraLateral;
        final anchoDisponible = mq.size.width - (conBarra ? anchoBarra : 0);
        // Panel de detalle: solo con barra lateral y mucho ancho (iPad en horizontal).
        detalle.disponible =
            conBarra && anchoDisponible >= DetalleLateral.anchoMinimoDisponible;
        if (!detalle.disponible && detalle.abierto) {
          WidgetsBinding.instance.addPostFrameCallback((_) => detalle.cerrar());
        }
        final conPanel = detalle.abierto;
        final anchoZona =
            anchoDisponible - (conPanel ? DetalleLateral.ancho : 0);
        // Sin sesión (acceso, bienvenida) la columna es más estrecha.
        final anchoColumna = (conBarra ? kAnchoColumna : 560.0).clamp(
          0.0,
          anchoZona,
        );

        // Sin la línea bajo la cabecera: con la columna centrada se cortaba a
        // mitad de pantalla.
        final tema = Theme.of(context);
        final contenido = BarraLateralVisible(
          visible: conBarra,
          child: Theme(
            data: tema.copyWith(
              appBarTheme: tema.appBarTheme.copyWith(shape: const Border()),
            ),
            child: MediaQuery(
              data: mq.copyWith(size: Size(anchoColumna, mq.size.height)),
              child: ClipRect(child: child),
            ),
          ),
        );

        return Row(
          children: [
            if (conBarra) BarraLateral(compacta: barraCompacta(mq.size)),
            // Los márgenes a los lados de la columna también hacen desplazar
            // la pantalla: se puede arrastrar desde cualquier punto.
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _MargenDesplazable(
                      columna: _claveColumna,
                      izquierda: true,
                    ),
                  ),
                  SizedBox(
                    key: _claveColumna,
                    width: anchoColumna,
                    child: contenido,
                  ),
                  Expanded(
                    child: _MargenDesplazable(
                      columna: _claveColumna,
                      izquierda: false,
                    ),
                  ),
                ],
              ),
            ),
            if (conPanel)
              MediaQuery(
                data: mq.copyWith(
                  size: Size(DetalleLateral.ancho, mq.size.height),
                  padding: mq.padding.copyWith(left: 0),
                ),
                child: const PanelDetalle(
                  colorFondo: AppColors.background,
                  colorBorde: AppColors.divider,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Barra lateral de la tablet: las cinco secciones de siempre, en una columna
/// con selección suave, como la de Música o Notas.
class BarraLateral extends StatelessWidget {
  const BarraLateral({super.key, this.compacta = false});

  /// Solo iconos con el rótulo debajo (tablets estrechas).
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ShellNavegacion.instance,
      builder: (context, _) => _construir(context),
    );
  }

  Widget _construir(BuildContext context) {
    final shell = ShellNavegacion.instance;
    final secciones = <({IconData icono, IconData seleccionado, String texto})>[
      (
        icono: Icons.home_outlined,
        seleccionado: Icons.home_rounded,
        texto: 'Inicio',
      ),
      (
        icono: Icons.travel_explore_outlined,
        seleccionado: Icons.travel_explore_rounded,
        texto: 'Catálogo',
      ),
      (
        icono: Icons.emoji_events_outlined,
        seleccionado: Icons.emoji_events_rounded,
        texto: 'Ligas',
      ),
      (
        icono: Icons.groups_outlined,
        seleccionado: Icons.groups_rounded,
        texto: shell.tieneClub ? 'Mi club' : 'Mi espacio',
      ),
    ];

    return Container(
      key: const Key('barra-lateral'),
      width: compacta ? kAnchoBarraCompacta : kAnchoBarraLateral,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft.withValues(alpha: .86),
        border: const Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: compacta
              ? const EdgeInsets.fromLTRB(6, 18, 6, 14)
              : const EdgeInsets.fromLTRB(14, 22, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: compacta
                    ? const EdgeInsets.only(bottom: 20)
                    : const EdgeInsets.fromLTRB(8, 0, 8, 26),
                child: Row(
                  mainAxisAlignment: compacta
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: const ClubReadsMark(size: 22, animate: false),
                    ),
                    if (!compacta) const SizedBox(width: 10),
                    if (!compacta)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Club',
                                  style: AppTextStyles.title.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 21,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Reads',
                                  style: AppTextStyles.title.copyWith(
                                    color: AppColors.gold,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 21,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (var i = 0; i < secciones.length; i++)
                _ItemLateral(
                  clave: Key('barra-lateral-$i'),
                  icono: shell.seleccion == i
                      ? secciones[i].seleccionado
                      : secciones[i].icono,
                  texto: secciones[i].texto,
                  seleccionado: shell.seleccion == i,
                  compacta: compacta,
                  alPulsar: () {
                    DetalleLateral.instance.cerrar();
                    shell.seleccionar(i);
                  },
                ),
              const Spacer(),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 10),
              _ItemLateral(
                clave: const Key('barra-lateral-4'),
                icono: shell.seleccion == 4
                    ? Icons.settings_rounded
                    : Icons.settings_outlined,
                texto: 'Ajustes',
                seleccionado: shell.seleccion == 4,
                compacta: compacta,
                alPulsar: () {
                  DetalleLateral.instance.cerrar();
                  shell.seleccionar(4);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemLateral extends StatelessWidget {
  const _ItemLateral({
    required this.clave,
    required this.icono,
    required this.texto,
    required this.seleccionado,
    required this.alPulsar,
    this.compacta = false,
  });

  final bool compacta;
  final Key clave;
  final IconData icono;
  final String texto;
  final bool seleccionado;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final color = seleccionado ? AppColors.primary : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        button: true,
        selected: seleccionado,
        label: texto,
        child: Material(
          color: seleccionado
              ? AppColors.primary.withValues(alpha: .12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: clave,
            borderRadius: BorderRadius.circular(12),
            onTap: alPulsar,
            child: Padding(
              padding: compacta
                  ? const EdgeInsets.symmetric(horizontal: 2, vertical: 9)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: compacta
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icono, size: 24, color: color),
                        const SizedBox(height: 3),
                        Text(
                          texto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: color,
                            fontSize: 10.5,
                            fontWeight: seleccionado
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(icono, size: 22, color: color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            texto,
                            style: AppTextStyles.body.copyWith(
                              color: color,
                              fontWeight: seleccionado
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avisa a las pantallas de que la barra lateral está visible (y, por tanto,
/// sobran los menús inferiores que repiten sus secciones).
class BarraLateralVisible extends InheritedWidget {
  const BarraLateralVisible({
    super.key,
    required this.visible,
    required super.child,
  });

  final bool visible;

  static bool de(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BarraLateralVisible>()
          ?.visible ??
      false;

  @override
  bool updateShouldNotify(BarraLateralVisible oldWidget) =>
      visible != oldWidget.visible;
}

/// Envuelve una pantalla que debe verse a todo el ancho en una tablet (p. ej.
/// la de arranque con su degradado), sin la columna centrada.
class PantallaCompleta extends StatefulWidget {
  const PantallaCompleta({super.key, required this.child});

  final Widget child;

  @override
  State<PantallaCompleta> createState() => _PantallaCompletaState();
}

class _PantallaCompletaState extends State<PantallaCompleta> {
  @override
  void initState() {
    super.initState();
    ShellNavegacion.instance.entrarPantallaCompleta();
  }

  @override
  void dispose() {
    ShellNavegacion.instance.salirPantallaCompleta();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// En la columna de una tablet, centra verticalmente su contenido (acceso,
/// bienvenida…) en lugar de dejarlo pegado arriba con todo el hueco debajo.
/// En móvil no cambia nada.
class CentradoEnTablet extends StatelessWidget {
  const CentradoEnTablet({super.key, required this.child});

  /// Normalmente un [ListView] o similar; en tablet se limita a su altura.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tamano = MediaQuery.sizeOf(context);
    final columnaDeTablet = tamano.width >= 500 && tamano.height >= 800;
    return columnaDeTablet ? Center(child: child) : child;
  }
}

/// Franja vacía a un lado de la columna de una tablet. Arrastrar o usar la
/// rueda sobre ella desplaza la lista de la pantalla visible, como si se
/// hubiera tocado dentro de la columna.
class _MargenDesplazable extends StatelessWidget {
  const _MargenDesplazable({required this.columna, required this.izquierda});

  final GlobalKey columna;
  final bool izquierda;

  /// La posición de scroll vertical que hay en el borde de la columna a la
  /// altura [global].
  ScrollPositionWithSingleContext? _buscar(
    BuildContext context,
    Offset global,
  ) {
    final caja = columna.currentContext?.findRenderObject();
    if (caja is! RenderBox || !caja.attached) return null;
    final origen = caja.localToGlobal(Offset.zero);
    final x = izquierda ? origen.dx + 2 : origen.dx + caja.size.width - 2;
    final resultado = HitTestResult();
    WidgetsBinding.instance.hitTestInView(
      resultado,
      Offset(x, global.dy),
      View.of(context).viewId,
    );
    for (final entrada in resultado.path) {
      final destino = entrada.target;
      if (destino is RenderViewportBase &&
          destino.axis == Axis.vertical &&
          destino.offset is ScrollPositionWithSingleContext) {
        final posicion = destino.offset as ScrollPositionWithSingleContext;
        if (posicion.hasContentDimensions && posicion.maxScrollExtent > 0) {
          return posicion;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Drag? arrastre;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerSignal: (evento) {
        if (evento is! PointerScrollEvent) return;
        final posicion = _buscar(context, evento.position);
        if (posicion == null) return;
        GestureBinding.instance.pointerSignalResolver.register(evento, (e) {
          posicion.pointerScroll((e as PointerScrollEvent).scrollDelta.dy);
        });
      },
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          VerticalDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                VerticalDragGestureRecognizer
              >(VerticalDragGestureRecognizer.new, (r) {
                r
                  ..onStart = (d) {
                    arrastre = _buscar(
                      context,
                      d.globalPosition,
                    )?.drag(d, () => arrastre = null);
                  }
                  ..onUpdate = (d) {
                    arrastre?.update(d);
                  }
                  ..onEnd = (d) {
                    arrastre?.end(d);
                    arrastre = null;
                  }
                  ..onCancel = () {
                    arrastre?.cancel();
                    arrastre = null;
                  };
              }),
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}
