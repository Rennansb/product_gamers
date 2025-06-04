// lib/main.dart
import 'package:dartz/dartz.dart'; // Necessário por causa dos placeholders que usavam Right([])
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:product_gamers/domain/usecases/get_fixture_lineups_usecase.dart';
import 'package:product_gamers/presentation/app_shell.dart';
import 'package:product_gamers/presentation/providers/suggested_slips_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Core
import 'core/theme/app_theme.dart';
// import 'core/config/app_constants.dart'; // AppConstants é usado em outras partes, não diretamente aqui

// Data Layer
import 'data/datasources/football_remote_datasource.dart';
import 'data/repositories/football_repository_impl.dart';

// Domain Layer
import 'domain/repositories/football_repository.dart';
// --- Importar TODOS os UseCases que serão providos globalmente ou usados por providers iniciais ---
import 'domain/usecases/get_leagues_usecase.dart';
import 'domain/usecases/get_fixtures_usecase.dart';
import 'domain/usecases/get_odds_usecase.dart';
import 'domain/usecases/get_fixture_statistics_usecase.dart';
import 'domain/usecases/get_h2h_usecase.dart';
import 'domain/usecases/get_league_standings_usecase.dart';
import 'domain/usecases/get_player_stats_usecase.dart';

import 'domain/usecases/get_referee_stats_usecase.dart';

import 'domain/usecases/generate_suggested_slips_usecase.dart'; // O principal para bilhetes
import 'domain/usecases/get_live_fixture_update_usecase.dart';
import 'domain/usecases/get_live_odds_usecase.dart';
// UseCase para stats agregadas de times
// Adicione aqui GetTeamRecentFixturesUseCase se você o criou e quer provê-lo globalmente

// Presentation Layer
import 'presentation/providers/league_provider.dart';

// FixtureProvider, FixtureDetailProvider, LiveFixtureProvider serão criados dinamicamente
import 'presentation/screens/home_screen.dart';

// lib/main.dart
// ... (imports para todos os use cases)

void main() async {
  // ... (inicialização)
  WidgetsFlutterBinding.ensureInitialized(); // PRIMEIRO
  await dotenv.load(fileName: ".env"); // SEGUNDO
  await initializeDateFormatting('pt_BR', null); // TERCEIRO, ANTES
  // --- DI Simples com as classes reais ---
  final httpClient = http.Client();
  final FootballRemoteDataSource remoteDataSource =
      FootballRemoteDataSourceImpl(client: httpClient);
  final FootballRepository footballRepository =
      FootballRepositoryImpl(remoteDataSource: remoteDataSource);

  final getLeaguesUseCase = GetLeaguesUseCase(footballRepository);
  final getFixturesUseCase = GetFixturesUseCase(footballRepository);
  // ... (INSTANCIE TODOS OS OUTROS USECASES AQUI)
  final generateSuggestedSlipsUseCase =
      GenerateSuggestedSlipsUseCase(footballRepository);

  runApp(
    // O runApp DEVE ter o MultiProvider no TOPO
    MultiProvider(
      providers: [
        // --- Prover todos os UseCases ---
        Provider<GetLeaguesUseCase>.value(value: getLeaguesUseCase),
        Provider<GetFixturesUseCase>.value(value: getFixturesUseCase),
        // ... (PROVER TODOS OS OUTROS USECASES)
        Provider<GenerateSuggestedSlipsUseCase>.value(
            value: generateSuggestedSlipsUseCase),

        // --- Providers de Estado (ChangeNotifiers) ---
        ChangeNotifierProvider(
          create: (context) =>
              LeagueProvider(context.read<GetLeaguesUseCase>()),
        ),
        ChangeNotifierProvider(
          create: (context) => SuggestedSlipsProvider(
            context.read<GetFixturesUseCase>(),
            context.read<GenerateSuggestedSlipsUseCase>(),
          ),
        ),
        // Adicione outros ChangeNotifierProviders aqui se necessário no nível do app
      ],
      child: const MyApp(), // MyApp é o child do MultiProvider
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'App Prognósticos Expert',
      // ... (theme, locale, etc.)
      home: AppShell(), // HomeScreen está ABAIXO do MultiProvider na árvore
    );
  }
}
