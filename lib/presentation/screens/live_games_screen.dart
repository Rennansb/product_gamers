// lib/presentation/screens/live_games_screen.dart
import 'package:flutter/material.dart';

class LiveGamesScreen extends StatelessWidget {
  const LiveGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jogos Ao Vivo 🔥"),
        // backgroundColor: Colors.redAccent, // Cor distinta para a aba Ao Vivo
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Aqui serão listados os jogos que estão acontecendo em tempo real.\nFuncionalidade em desenvolvimento!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
