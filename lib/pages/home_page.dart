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
import '../services/notificaciones_service.dart';

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
              controller: _dashboardController,
            ),
            () => LibrosPage(
              controller: _librosController,
              onBackToClub: _volverAlClub,
            ),
            () => SagasPage(controller: _sagasController),
            () => LecturasPage(onBackToClub: _volverAlClub),
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
        isLabelVisible: _notifications.noLeidasClub > 0,
        label: Text(_badge(_notifications.noLeidasClub)),
        child: const Icon(Icons.dashboard_outlined),
      ),
      selectedIcon: Badge(
        isLabelVisible: _notifications.noLeidasClub > 0,
        label: Text(_badge(_notifications.noLeidasClub)),
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
        isLabelVisible: _notifications.noLeidasLecturas > 0,
        label: Text(_badge(_notifications.noLeidasLecturas)),
        child: const Icon(Icons.auto_stories_outlined),
      ),
      selectedIcon: Badge(
        isLabelVisible: _notifications.noLeidasLecturas > 0,
        label: Text(_badge(_notifications.noLeidasLecturas)),
        child: const Icon(Icons.auto_stories_rounded),
      ),
      label: 'Lecturas',
    ),
    NavigationDestination(
      icon: Badge(
        isLabelVisible: _notifications.noLeidasClubvision > 0,
        label: Text(_badge(_notifications.noLeidasClubvision)),
        child: const Icon(Icons.mic_none_outlined),
      ),
      selectedIcon: Badge(
        isLabelVisible: _notifications.noLeidasClubvision > 0,
        label: Text(_badge(_notifications.noLeidasClubvision)),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && currentIndex != 0) {
          _volverAlClub();
        }
      },
      child: Scaffold(
        extendBody: false,

        // Stack + AnimatedOpacity preserva el estado de cada pestaña
        // (scroll, datos cargados) mientras anima la transición.
        body: Stack(
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
        ),

        bottomNavigationBar: _esPersonal
            ? NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: _selectTab,
                destinations: _personalDestinations(),
              )
            : ListenableBuilder(
                listenable: _notifications,
                builder: (context, _) => NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: _selectTab,
                  destinations: _socialDestinations(),
                ),
              ),
      ),
    );
  }
}
