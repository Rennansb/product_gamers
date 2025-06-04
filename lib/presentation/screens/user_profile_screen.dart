// lib/presentation/screens/user_profile_screen.dart
import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Perfil 👤"),
        // backgroundColor: Colors.purpleAccent, // Cor distinta
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Informações do usuário, configurações do aplicativo e estatísticas de uso.\nFuncionalidade em desenvolvimento!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
