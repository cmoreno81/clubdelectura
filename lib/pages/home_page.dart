import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'libros_page.dart';
import 'ranking_page.dart';
import 'clubvision_menu_page.dart';

class HomePage extends StatefulWidget {

  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {

  int currentIndex = 0;

  final pages = const [

    DashboardPage(),

    LibrosPage(),

    RankingPage(),

    ClubvisionMenuPage(),

  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[currentIndex],

      bottomNavigationBar:

          NavigationBar(

        selectedIndex:
            currentIndex,

        onDestinationSelected:
            (index) {

          setState(() {

            currentIndex =
                index;

          });
        },

        destinations: const [

        NavigationDestination(
            icon:
                Icon(Icons.dashboard),
            label:
                'Dashboard',
        ),

        NavigationDestination(
            icon:
                Icon(Icons.menu_book),
            label:
                'Libros',
        ),

        NavigationDestination(
            icon:
                Icon(Icons.emoji_events),
            label:
                'Ranking',
        ),

        NavigationDestination(
            icon:
                Icon(Icons.mic),
            label:
                'Clubvisión',
          ),
        ],
      ),
    );
  }
}