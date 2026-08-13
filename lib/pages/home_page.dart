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
import '../services/api_service.dart';

typedef HomePageBuilder = Widget Function();

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.club, this.pageBuilders});

  final ClubMembership club;
  final List<HomePageBuilder>? pageBuilders;

  @override
  State<HomePage> createState() => _HomePageState();
}

const _kLecturasIndex    = 3;
const _kClubvisionIndex  = 4;


class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  int _noLeidasClub       = 0; // El Club (actividad social del club)
  int _noLeidasLecturas   = 0; // Lecturas (comentarios, lecturas nuevas)
  int _noLeidasClubvision = 0; // Clubvisión (votaciones)

  final _dashboardController = DashboardPageController();
  final _librosController = LibrosPageController();
  final _sagasController = SagasPageController();

  late final List<HomePageBuilder> _pageBuilders;
  late final List<Widget?> _pages;

  bool get _esPersonal => widget.club.esPersonal;

  @override
  void initState() {
    super.initState();
    if (_esPersonal) {
      // Modo lector solitario: 4 tabs sin Lecturas ni Clubvisión
      _pageBuilders = widget.pageBuilders ?? [
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
    if (!_esPersonal) _cargarNoLeidas();
  }

  Future<void> _cargarNoLeidas() async {
    try {
      final data = await ApiService().getNotificaciones();
      if (!mounted) return;
      setState(() {
        _noLeidasClub       = data.noLeidasClub;
        _noLeidasLecturas   = data.noLeidasLecturas;
        _noLeidasClubvision = data.noLeidasClubvision;
      });
    } catch (_) {
      // Si falla, los badges simplemente no se muestran.
    }
  }

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();

    if (index == currentIndex) {
      if (index == 1) _librosController.refresh();
      if (index == 2) _sagasController.refresh();
      return;
    }

    HapticFeedback.selectionClick();

    // Al salir de cualquier tab con notificaciones el usuario puede haber
    // marcado notificaciones como leídas, así que refrescamos los badges.
    final salimosDeNotifTab = !_esPersonal && (
        currentIndex == 0 || // El Club
        currentIndex == _kLecturasIndex ||
        currentIndex == _kClubvisionIndex
    );

    setState(() {
      _pages[index] ??= _pageBuilders[index]();
      currentIndex = index;
    });

    if (salimosDeNotifTab) unawaited(_cargarNoLeidas());
  }

  List<NavigationDestination> _socialDestinations() => [
        NavigationDestination(
          icon: Badge(
            isLabelVisible: _noLeidasClub > 0,
            label: Text(_noLeidasClub < 10 ? '$_noLeidasClub' : '9+'),
            child: const Icon(Icons.dashboard_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: _noLeidasClub > 0,
            label: Text(_noLeidasClub < 10 ? '$_noLeidasClub' : '9+'),
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
            isLabelVisible: _noLeidasLecturas > 0,
            label: Text(_noLeidasLecturas < 10 ? '$_noLeidasLecturas' : '9+'),
            child: const Icon(Icons.auto_stories_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: _noLeidasLecturas > 0,
            label: Text(_noLeidasLecturas < 10 ? '$_noLeidasLecturas' : '9+'),
            child: const Icon(Icons.auto_stories_rounded),
          ),
          label: 'Lecturas',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: _noLeidasClubvision > 0,
            label: Text(
              _noLeidasClubvision < 10 ? '$_noLeidasClubvision' : '9+',
            ),
            child: const Icon(Icons.mic_none_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: _noLeidasClubvision > 0,
            label: Text(
              _noLeidasClubvision < 10 ? '$_noLeidasClubvision' : '9+',
            ),
            child: const Icon(Icons.mic_rounded),
          ),
          label: 'Clubvisión',
        ),
      ];

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
    final salimosDeNotifTab = !_esPersonal && (
        currentIndex == _kLecturasIndex ||
        currentIndex == _kClubvisionIndex
    );
    setState(() => currentIndex = 0);
    unawaited(_dashboardController.refresh());
    if (salimosDeNotifTab) unawaited(_cargarNoLeidas());
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

        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: _selectTab,
          destinations: _esPersonal
              ? _personalDestinations()
              : _socialDestinations(),
        ),
      ),
    );
  }
}
