// lib/presentation/screens/history_screen.dart
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico de Entradas 📈📉"),
        // backgroundColor: Colors.blueAccent, // Cor distinta
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Seu histórico de entradas (sugestões do app ou suas marcações) com resultados (Green/Red) aparecerá aqui.\nFuncionalidade em desenvolvimento!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
