// lib/presentation/app_shell.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/core/theme/app_theme.dart';
import 'package:product_gamers/presentation/screens/home_screen.dart'; // Nossa tela inicial existente
import 'screens/live_games_screen.dart'; // Nova tela placeholder
import 'screens/history_screen.dart'; // Nova tela placeholder
import 'screens/user_profile_screen.dart'; // Nova tela placeholder

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0; // Índice da aba atualmente selecionada

  // Lista das telas principais para cada aba
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Aba 0: Nossa tela inicial atual
    LiveGamesScreen(), // Aba 1: Jogos Ao Vivo
    HistoryScreen(), // Aba 2: Histórico
    UserProfileScreen(), // Aba 3: Usuário
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O corpo do Scaffold será a tela selecionada na BottomNavigationBar
      // Usar IndexedStack para manter o estado das telas quando se alterna entre elas
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        // Envolver com Container
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
                color: AppTheme.goldAccent.withOpacity(0.6),
                width: 0.8), // Linha dourada no topo
          ),
          // A cor de fundo virá do BottomNavigationBarTheme ou pode ser definida aqui
          // color: AppTheme.slightlyLighterDark,
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer_outlined),
              activeIcon: Icon(Icons.sports_soccer),
              label: 'Ao Vivo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Histórico',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
          currentIndex: _selectedIndex,
          // selectedItemColor e unselectedItemColor virão do BottomNavigationBarTheme
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          // backgroundColor: Colors.transparent, // Deixar transparente se o Container já tem cor
          // Ou deixar o tema cuidar disso.
        ),
      ),
    );
  }
}
