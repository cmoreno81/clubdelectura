import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'clubvision_menu_page.dart';
import 'dashboard_page.dart';
import 'lecturas_page.dart';
import 'libros_page.dart';
import 'mi_espacio_page.dart';
import 'sagas_page.dart';
import '../models/club_membership.dart';
import '../services/libros_data_cache.dart';
import '../services/notificaciones_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_breakpoints.dart';

typedef HomePageBuilder = Widget Function();

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.club,
    this.pageBuilders,
    this.notificationService,
  });

  final ClubMembership club;
  final List<HomePageBuilder>? pageBuilders;
  final NotificacionesService? notificationService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int currentIndex = 0;

  final _dashboardController = DashboardPageController();
  final _librosController = LibrosPageController();
  final _sagasController = SagasPageController();

  late final List<HomePageBuilder> _pageBuilders;
  late final List<Widget?> _pages;

  bool get _esPersonal => widget.club.esPersonal;
  NotificacionesService get _notifications =>
      widget.notificationService ?? NotificacionesService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Invalidar caché al entrar en cualquier club para no arrastrar datos
    // del club anterior (en navegación push/pop se crea un nuevo HomePage).
    LibrosDataCache.instance.invalidate();
    if (_esPersonal) {
      // Modo lector solitario: 4 tabs sin Lecturas ni Clubvisión
      _pageBuilders =
          widget.pageBuilders ??
          [
            () => DashboardPage(
              clubName: widget.club.nombre,
              esPersonal: true,
              controller: _dashboardController,
            ),
            () => LibrosPage(
              controller: _librosController,
              onBackToClub: _volverAlClub,
              esPersonal: true,
              clubId: widget.club.id,
            ),
            () => SagasPage(controller: _sagasController),
            () => const MiEspacioPage(),
          ];
      assert(_pageBuilders.length == 4);
    } else {
      // Modo club social: 5 tabs completos
      _pageBuilders =
          widget.pageBuilders ??
          [
            () => DashboardPage(
              clubName: widget.club.nombre,
              clubId: widget.club.id,
              controller: _dashboardController,
            ),
            () => LibrosPage(
              controller: _librosController,
              onBackToClub: _volverAlClub,
              clubId: widget.club.id,
            ),
            () => SagasPage(controller: _sagasController),
            () => LecturasPage(onBackToClub: _volverAlClub, clubId: widget.club.id),
            () => ClubvisionMenuPage(onBackToClub: _volverAlClub),
          ];
      assert(_pageBuilders.length == 5);
    }
    _pages = List<Widget?>.filled(_pageBuilders.length, null);
    _pages[0] = _pageBuilders[0]();
    if (!_esPersonal) {
      _notifications.limpiar();
      unawaited(_notifications.cargar());
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.club.id == widget.club.id) return;
    // Al cambiar de club: invalidar caché de biblioteca y resetear todas las
    // páginas para que se reconstruyan frescas con el nuevo contexto de club.
    LibrosDataCache.instance.invalidate();
    for (var i = 0; i < _pages.length; i++) {
      _pages[i] = null;
    }
    _pages[0] = _pageBuilders[0]();
    _notifications.limpiar();
    if (!_esPersonal) {
      unawaited(_notifications.cargar());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_esPersonal) {
      unawaited(_notifications.cargar());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    // Limpiar snackbars al cambiar de pestaña para que no persistan
    ScaffoldMessenger.of(context).clearSnackBars();

    if (index == currentIndex) {
      if (index == 1) _librosController.refresh();
      if (index == 2) _sagasController.refresh();
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _pages[index] ??= _pageBuilders[index]();
      currentIndex = index;
    });
  }

  List<NavigationDestination> _socialDestinations() => [
    NavigationDestination(
      icon: Badge(
        isLabelVisible: _notifications.noLeidasClubPara(widget.club.id) > 0,
        label: Text(_badge(_notifications.noLeidasClubPara(widget.club.id))),
        child: const Icon(Icons.dashboard_outlined),
      ),
      selectedIcon: Badge(
        isLabelVisible: _notifications.noLeidasClubPara(widget.club.id) > 0,
        label: Text(_badge(_notifications.noLeidasClubPara(widget.club.id))),
        child: const Icon(Icons.dashboard_rounded),
      ),
      label: 'El Club',
    ),
    const NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: 'Libros',
    ),
    const NavigationDestination(
      icon: Icon(Icons.view_week_outlined),
      selectedIcon: Icon(Icons.view_week_rounded),
      label: 'Sagas',
    ),
    NavigationDestination(
      icon: Badge(
        isLabelVisible: _notifications.noLeidasLecturasPara(widget.club.id) > 0,
        label: Text(_badge(_notifications.noLeidasLecturasPara(widget.club.id))),
        child: const Icon(Icons.auto_stories_outlined),
      ),
      selectedIcon: Badge(
        isLabelVisible: _notifications.noLeidasLecturasPara(widget.club.id) > 0,
        label: Text(_badge(_notifications.noLeidasLecturasPara(widget.club.id))),
        child: const Icon(Icons.auto_stories_rounded),
      ),
      label: 'Lecturas',
    ),
    NavigationDestination(
      icon: Badge(
        isLabelVisible: _notifications.noLeidasClubvisionPara(widget.club.id) > 0,
        label: Text(_badge(_notifications.noLeidasClubvisionPara(widget.club.id))),
        child: const Icon(Icons.mic_none_outlined),
      ),
      selectedIcon: Badge(
        isLabelVisible: _notifications.noLeidasClubvisionPara(widget.club.id) > 0,
        label: Text(_badge(_notifications.noLeidasClubvisionPara(widget.club.id))),
        child: const Icon(Icons.mic_rounded),
      ),
      label: 'Clubvisión',
    ),
  ];

  String _badge(int value) => value < 10 ? '$value' : '9+';

  List<NavigationDestination> _personalDestinations() => const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: 'Libros',
    ),
    NavigationDestination(
      icon: Icon(Icons.view_week_outlined),
      selectedIcon: Icon(Icons.view_week_rounded),
      label: 'Sagas',
    ),
    NavigationDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events_rounded),
      label: 'Mi espacio',
    ),
  ];

  void _volverAlClub() {
    if (currentIndex == 0) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    setState(() => currentIndex = 0);
    unawaited(_dashboardController.refresh());
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tablet = AppBreakpoints.isTablet(context);

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && currentIndex != 0) _volverAlClub();
      },
      child: tablet ? _buildTablet(context) : _buildMobile(context),
    );
  }

  // ── Layout móvil (NavigationBar inferior) ──────────────────────────────────

  // Vuelve directa a "Mi universo lector" (el dashboard global), sin
  // importar cuántas pantallas se hayan apilado por encima — toda la app
  // corre sobre un único Navigator, así que popUntil llega hasta la raíz
  // desde cualquier punto. Antes había que ir hacia atrás pantalla por
  // pantalla (p. ej. desde dentro de Clubvisión).
  void _volverAlDashboardGlobal() {
    HapticFeedback.selectionClick();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // Con el mismo peso visual que un NavigationDestination (icono + etiqueta)
  // para que no se vea como un botón suelto pegado al menú.
  //
  // En pantallas estrechas (compact=true) se queda solo con el icono: con
  // 5 pestañas de club más este botón no cabe la etiqueta completa sin
  // apretar demasiado el resto del menú.
  Widget _homeShortcutButton({bool compact = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _volverAlDashboardGlobal,
        child: Tooltip(
          message: 'Volver a Mi universo lector',
          child: SizedBox(
            width: compact ? 40 : 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home_outlined,
                  color: AppColors.textSecondary,
                ),
                if (!compact) ...[
                  const SizedBox(height: 3),
                  Text(
                    'ClubReads',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: _pageStack(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFCFB8E0), width: 1.0),
          ),
        ),
        child: SafeArea(
          top: false,
          // Alto fijo (algo mayor que el de NavigationBar, 80) para que el
          // separador vertical tenga una altura acotada en la que dibujarse
          // (sin esto el Row queda con altura indefinida y el layout se
          // rompe) y para que el contenido quede centrado con un pelín de
          // aire arriba y abajo en vez de pegado al borde superior.
          child: SizedBox(
            height: 88,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Con 5 pestañas de club + este botón, una pantalla estrecha
                // (iPhone mini/SE) no tiene sitio para la etiqueta completa.
                final compact = constraints.maxWidth < 380;
                return Row(
                  children: [
                    const SizedBox(width: 8),
                    _homeShortcutButton(compact: compact),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFE3D5EF),
                    ),
                    Expanded(
                      child: _esPersonal
                          ? NavigationBar(
                              selectedIndex: currentIndex,
                              onDestinationSelected: _selectTab,
                              labelBehavior: compact
                                  ? NavigationDestinationLabelBehavior
                                        .onlyShowSelected
                                  : NavigationDestinationLabelBehavior
                                        .alwaysShow,
                              destinations: _personalDestinations(),
                            )
                          : ListenableBuilder(
                              listenable: _notifications,
                              builder: (context, _) => NavigationBar(
                                selectedIndex: currentIndex,
                                onDestinationSelected: _selectTab,
                                labelBehavior: compact
                                    ? NavigationDestinationLabelBehavior
                                          .onlyShowSelected
                                    : NavigationDestinationLabelBehavior
                                          .alwaysShow,
                                destinations: _socialDestinations(),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Layout tablet (NavigationRail lateral) ─────────────────────────────────

  Widget _buildTablet(BuildContext context) {
    final extended = AppBreakpoints.isExpanded(context);

    Widget railHomeButton() => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: IconButton(
        tooltip: 'Volver a Mi universo lector',
        icon: const Icon(Icons.home_outlined),
        onPressed: _volverAlDashboardGlobal,
      ),
    );

    // Rail para modo personal (sin notificaciones)
    NavigationRail personalRail() => NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: _selectTab,
      extended: extended,
      minWidth: 72,
      minExtendedWidth: 180,
      leading: railHomeButton(),
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: _railPersonalDestinations(),
    );

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: _esPersonal
                ? personalRail()
                : ListenableBuilder(
                    listenable: _notifications,
                    builder: (context, _) {
                      // Reconstruir el rail cuando cambian las notificaciones
                      // para actualizar los badges.
                      final updatedDestinations =
                          _railSocialDestinations();
                      return NavigationRail(
                        selectedIndex: currentIndex,
                        onDestinationSelected: _selectTab,
                        extended: extended,
                        minWidth: 72,
                        minExtendedWidth: 180,
                        leading: railHomeButton(),
                        labelType: extended
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        destinations: updatedDestinations,
                      );
                    },
                  ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: _pageStack()),
        ],
      ),
    );
  }

  // ── Stack de páginas compartido ────────────────────────────────────────────

  Widget _pageStack() {
    return Stack(
      children: [
        for (int i = 0; i < _pageBuilders.length; i++)
          AnimatedOpacity(
            key: ValueKey(i),
            opacity: i == currentIndex ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: IgnorePointer(
              ignoring: i != currentIndex,
              child: _pages[i] ?? const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }

  // ── Destinations para NavigationRail ──────────────────────────────────────

  List<NavigationRailDestination> _railSocialDestinations() => [
    NavigationRailDestination(
      icon: Badge(
        isLabelVisible: _notifications.noLeidasClubPara(widget.club.id) > 0,
        label: Text(_badge(_notifications.noLeidasClubPara(widget.club.id))),
        child: const Icon(Icons.dashboard_outlined),
      ),
      selectedIcon: const Icon(Icons.dashboard_rounded),
      label: const Text('El Club'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: Text('Libros'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.view_week_outlined),
      selectedIcon: Icon(Icons.view_week_rounded),
      label: Text('Sagas'),
    ),
    NavigationRailDestination(
      icon: Badge(
        isLabelVisible: _notifications.noLeidasLecturasPara(widget.club.id) > 0,
        label: Text(_badge(_notifications.noLeidasLecturasPara(widget.club.id))),
        child: const Icon(Icons.auto_stories_outlined),
      ),
      selectedIcon: const Icon(Icons.auto_stories_rounded),
      label: const Text('Lecturas'),
    ),
    NavigationRailDestination(
      icon: Badge(
        isLabelVisible: _notifications.noLeidasClubvisionPara(widget.club.id) > 0,
        label: Text(_badge(_notifications.noLeidasClubvisionPara(widget.club.id))),
        child: const Icon(Icons.mic_none_outlined),
      ),
      selectedIcon: const Icon(Icons.mic_rounded),
      label: const Text('Clubvisión'),
    ),
  ];

  List<NavigationRailDestination> _railPersonalDestinations() => const [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: Text('Inicio'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: Text('Libros'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.view_week_outlined),
      selectedIcon: Icon(Icons.view_week_rounded),
      label: Text('Sagas'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events_rounded),
      label: Text('Mi espacio'),
    ),
  ];
}
