import 'package:flutter/material.dart';
import 'clubvision_menu_page.dart';
import 'dashboard_page.dart';
import 'lecturas_page.dart';
import 'libros_page.dart';
import 'sagas_page.dart';
import '../models/club_membership.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.club});

  final ClubMembership club;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  final _librosController = LibrosPageController();
  final _sagasController = SagasPageController();

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      DashboardPage(clubName: widget.club.nombre),
      LibrosPage(controller: _librosController, onBackToClub: _volverAlClub),
      SagasPage(controller: _sagasController),
      LecturasPage(onBackToClub: _volverAlClub),
      ClubvisionMenuPage(onBackToClub: _volverAlClub),
    ];
  }

  void _volverAlClub() {
    if (currentIndex == 0) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      pages[0] = DashboardPage(key: UniqueKey(), clubName: widget.club.nombre);
      currentIndex = 0;
    });
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

        body: IndexedStack(index: currentIndex, children: pages),

        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            FocusManager.instance.primaryFocus?.unfocus();

            if (index == currentIndex) {
              if (index == 1) _librosController.refresh();
              if (index == 2) _sagasController.refresh();
              return;
            }
            setState(() => currentIndex = index);
            if (index == 1) _librosController.refresh();
            if (index == 2) _sagasController.refresh();
          },
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
