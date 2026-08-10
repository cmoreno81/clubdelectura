import 'dart:async';

import 'package:flutter/material.dart';
import 'clubvision_menu_page.dart';
import 'dashboard_page.dart';
import 'lecturas_page.dart';
import 'libros_page.dart';
import 'sagas_page.dart';
import '../models/club_membership.dart';

typedef HomePageBuilder = Widget Function();

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.club, this.pageBuilders});

  final ClubMembership club;
  final List<HomePageBuilder>? pageBuilders;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  final _dashboardController = DashboardPageController();
  final _librosController = LibrosPageController();
  final _sagasController = SagasPageController();

  late final List<HomePageBuilder> _pageBuilders;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
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
    _pages = List<Widget?>.filled(_pageBuilders.length, null);
    _pages[0] = _pageBuilders[0]();
  }

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();

    if (index == currentIndex) {
      if (index == 1) _librosController.refresh();
      if (index == 2) _sagasController.refresh();
      return;
    }

    setState(() {
      _pages[index] ??= _pageBuilders[index]();
      currentIndex = index;
    });
  }

  void _volverAlClub() {
    if (currentIndex == 0) return;
    FocusManager.instance.primaryFocus?.unfocus();
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

        body: IndexedStack(
          index: currentIndex,
          children: [
            for (final page in _pages) page ?? const SizedBox.shrink(),
          ],
        ),

        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'El Club',
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
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded),
              label: 'Lecturas',
            ),
            NavigationDestination(
              icon: Icon(Icons.mic_none_outlined),
              selectedIcon: Icon(Icons.mic_rounded),
              label: 'Clubvisión',
            ),
          ],
        ),
      ),
    );
  }
}
