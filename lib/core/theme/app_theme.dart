// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Paleta "Dark Gold"
  static const Color darkBackground =
      Color(0xFF121212); // Um preto bem escuro, quase absoluto
  static const Color slightlyLighterDark =
      Color(0xFF1E1E1E); // Para superfícies de cards
  static const Color darkCardSurface =
      Color(0xFF242424); // Um pouco mais claro para cards internos
  static const Color goldAccent = Color(0xFFFFD700); // Dourado principal
  static const Color goldAccentLight =
      Color(0xFFFFE033); // Um dourado mais claro para highlights
  static const Color goldAccentDark =
      Color(0xFFCCA300); // Um dourado mais escuro para sombras ou texto
  static const Color textWhite = Colors.white;
  static const Color textWhite70 = Colors.white70;
  static const Color textWhite54 = Colors.white54;
  static const Color subtleBorder =
      Color(0x55FFD700); // Dourado com opacidade para bordas finas

  static ThemeData get darkGoldTheme {
    final baseDarkTheme =
        ThemeData.dark(); // Começa com o tema escuro padrão do Flutter

    return baseDarkTheme.copyWith(
      useMaterial3: true,
      primaryColor: goldAccent, // Cor primária pode ser o dourado
      scaffoldBackgroundColor: darkBackground,

      // Esquema de Cores Detalhado
      colorScheme: ColorScheme.dark(
        primary: goldAccent,
        onPrimary: Colors.black, // Texto em botões/elementos primários dourados
        secondary: goldAccentLight, // Usado para FloatingActionButtons, etc.
        onSecondary: Colors.black,
        surface:
            slightlyLighterDark, // Cor de fundo de Cards, Dialogs, BottomNavigationBar
        onSurface: textWhite, // Cor do texto principal em superfícies
        background: darkBackground, // Cor de fundo principal da Scaffold
        onBackground: textWhite, // Cor do texto principal no fundo da Scaffold
        error: Colors.redAccent.shade200,
        onError: Colors.black,
        brightness: Brightness.dark,
        surfaceVariant:
            darkCardSurface, // Para variantes de superfície, como cards internos
        onSurfaceVariant: textWhite70,
      ),

      // Tema da AppBar
      appBarTheme: AppBarTheme(
        backgroundColor:
            slightlyLighterDark, // Ou darkBackground para se misturar
        foregroundColor: goldAccent, // Cor do título e ícones na AppBar
        elevation: 2.0,
        titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: goldAccent,
            fontFamily: 'Roboto'), // Exemplo de fonte
        iconTheme: IconThemeData(color: goldAccent),
      ),

      // Tema do Card
      cardTheme: CardTheme(
        color: slightlyLighterDark, // Fundo do card
        elevation: 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: subtleBorder, width: 0.8), // Borda dourada sutil
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // Tema do ListTile (pode ser usado dentro de cards ou listas)
      listTileTheme: ListTileThemeData(
        iconColor: goldAccentLight,
        textColor: textWhite,
        selectedTileColor: goldAccent.withOpacity(0.1),
      ),

      // Tema do Texto
      textTheme: baseDarkTheme.textTheme
          .copyWith(
            // Títulos grandes (pouco usado no app, mas para consistência)
            displayLarge: baseDarkTheme.textTheme.displayLarge
                ?.copyWith(color: goldAccentLight, fontWeight: FontWeight.bold),
            // Headers de Seção
            headlineSmall: baseDarkTheme.textTheme.headlineSmall?.copyWith(
                color: textWhite, fontWeight: FontWeight.bold, fontSize: 20),
            // Títulos principais em cards ou listas
            titleLarge: baseDarkTheme.textTheme.titleLarge?.copyWith(
                color: textWhite, fontWeight: FontWeight.w600, fontSize: 18),
            // Títulos secundários
            titleMedium: baseDarkTheme.textTheme.titleMedium?.copyWith(
                color: textWhite70, fontWeight: FontWeight.w500, fontSize: 16),
            // Títulos menores
            titleSmall: baseDarkTheme.textTheme.titleSmall?.copyWith(
                color: textWhite70, fontWeight: FontWeight.w500, fontSize: 14),
            // Corpo de texto principal
            bodyLarge: baseDarkTheme.textTheme.bodyLarge
                ?.copyWith(color: textWhite, fontSize: 16),
            // Corpo de texto secundário, legendas
            bodyMedium: baseDarkTheme.textTheme.bodyMedium
                ?.copyWith(color: textWhite70, fontSize: 14),
            // Labels de botões, texto pequeno
            labelLarge: baseDarkTheme.textTheme.labelLarge
                ?.copyWith(color: goldAccent, fontWeight: FontWeight.w600),
            labelMedium: baseDarkTheme.textTheme.labelMedium
                ?.copyWith(color: textWhite54, fontSize: 12),
            labelSmall: baseDarkTheme.textTheme.labelSmall
                ?.copyWith(color: textWhite54, fontSize: 11),
          )
          .apply(
            bodyColor: textWhite,
            displayColor: goldAccentLight,
            fontFamily: 'Roboto', // Exemplo de fonte padrão
          ),

      // Tema de Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldAccent,
          foregroundColor: Colors.black, // Texto do botão
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Tema de Chips
      chipTheme: ChipThemeData(
        backgroundColor: darkCardSurface,
        selectedColor: goldAccent,
        secondarySelectedColor: goldAccentLight,
        labelStyle: TextStyle(color: textWhite70, fontSize: 12),
        secondaryLabelStyle:
            TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: StadiumBorder(
            side: BorderSide(color: subtleBorder.withOpacity(0.5))),
      ),

      // Tema da BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: slightlyLighterDark, // Fundo da barra
        selectedItemColor: goldAccent,
        unselectedItemColor: textWhite54,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        elevation: 8.0,
        // Para a linha dourada superior, precisaremos de um wrapper ou custom painter
        // ou uma borda no Container que envolve a BottomNavigationBar no AppShell.
      ),

      // Tema do Divider
      dividerTheme: DividerThemeData(
        color: textWhite.withOpacity(0.15),
        thickness: 0.8,
      ),

      // Cor de destaque para inputs, etc.
      hintColor: textWhite54,
      iconTheme: IconThemeData(color: textWhite70),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: goldAccent,
      ),
    );
  }

  // Manter o lightTheme como antes ou criar um lightGoldTheme se desejar
  static ThemeData get lightTheme {
    // Por enquanto, manteremos o tema claro que tínhamos, para contraste.
    // Se quiser um tema "Gold" claro, a lógica seria similar, mas com cores claras.
    final baseLightTheme = ThemeData.light();
    return baseLightTheme.copyWith(
      useMaterial3: true,
      primaryColor: Colors.green.shade700,
      scaffoldBackgroundColor: Colors.grey[100],
      colorScheme: ColorScheme.light(
        primary: Colors.green.shade700,
        secondary: Colors.teal.shade600,
        surface: Colors.white,
        background: Colors.grey[100]!,
        error: Colors.red.shade700,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Roboto'),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: Colors.white,
      ),
      textTheme: baseLightTheme.textTheme.apply(fontFamily: 'Roboto'),
      // ... (pode adicionar mais customizações para o tema claro se necessário)
    );
  }
}
