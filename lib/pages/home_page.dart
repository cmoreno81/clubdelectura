import 'package:flutter/material.dart';
import 'clubvision_menu_page.dart';
import 'dashboard_page.dart';
import 'lecturas_page.dart';
import 'libros_page.dart';
import 'ranking_page.dart';
import '../services/atmosfera_scope.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  static const List<Widget> pages = [
    DashboardPage(),
    LibrosPage(),
    LecturasPage(),
    RankingPage(),
    ClubvisionMenuPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,

      body: IndexedStack(
        index: currentIndex,
        children: List.generate(
          pages.length,
          (index) =>
              HeroMode(enabled: currentIndex == index, child: pages[index]),
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == currentIndex) return;

          final atmosfera = AtmosferaScope.of(context);

          // Si abandonamos la lectura actual,
          // volvemos a la atmósfera neutra.
          atmosfera.usarAtmosferaNeutra();

          setState(() {
            currentIndex = index;
          });
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
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Lecturas',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_outlined),
            selectedIcon: Icon(Icons.mic_rounded),
            label: 'Clubvisión',
          ),
        ],
      ),
    );
  }
}
