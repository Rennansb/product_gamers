// lib/main.dart
import 'package:dartz/dartz.dart'; // Necessário por causa dos placeholders que usavam Right([])
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:product_gamers/domain/usecases/get_fixture_lineups_usecase.dart';
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
import 'presentation/providers/suggested_slips_provider.dart';
// FixtureProvider, FixtureDetailProvider, LiveFixtureProvider serão criados dinamicamente
import 'presentation/screens/home_screen.dart';

// lib/main.dart
// ... (imports para todos os use cases)

void main() async {
  // ... (inicialização)

  final httpClient = http.Client();
  final FootballRemoteDataSource remoteDataSource =
      FootballRemoteDataSourceImpl(client: httpClient);
  final FootballRepository footballRepository =
      FootballRepositoryImpl(remoteDataSource: remoteDataSource);
  final getFixtureLineupsUseCase = GetFixtureLineupsUseCase(footballRepository);
  // USE CASES (garanta que todos estes existem e estão instanciados)
  final getLeaguesUseCase = GetLeaguesUseCase(footballRepository);
  final getFixturesUseCase = GetFixturesUseCase(footballRepository);
  final getOddsUseCase =
      GetOddsUseCase(footballRepository); // Para FixtureDetailProvider
  final getFixtureStatisticsUseCase = GetFixtureStatisticsUseCase(
      footballRepository); // Para FixtureDetailProvider
  final getH2HUseCase =
      GetH2HUseCase(footballRepository); // Para FixtureDetailProvider
  final getLiveFixtureUpdateUseCase = GetLiveFixtureUpdateUseCase(
      footballRepository); // Para LiveFixtureProvider
  final getLiveOddsUseCase =
      GetLiveOddsUseCase(footballRepository); // Para LiveFixtureProvider
  // ... (outros use cases como generateSuggestedSlipsUseCase, etc., que já devem estar lá)

  runApp(
    MultiProvider(
      providers: [
        // Prover TODOS os use cases
        Provider<GetFixtureLineupsUseCase>.value(
            value: getFixtureLineupsUseCase),
        Provider<GetLeaguesUseCase>.value(value: getLeaguesUseCase),
        Provider<GetFixturesUseCase>.value(value: getFixturesUseCase),
        Provider<GetOddsUseCase>.value(value: getOddsUseCase),
        Provider<GetFixtureStatisticsUseCase>.value(
            value: getFixtureStatisticsUseCase),
        Provider<GetH2HUseCase>.value(value: getH2HUseCase),
        Provider<GetLiveFixtureUpdateUseCase>.value(
            value: getLiveFixtureUpdateUseCase),
        Provider<GetLiveOddsUseCase>.value(value: getLiveOddsUseCase),
        // ... (prover outros use cases)

        // Providers de Estado Iniciais
        ChangeNotifierProvider(
          create: (context) =>
              LeagueProvider(context.read<GetLeaguesUseCase>()),
        ),
        // ... (SuggestedSlipsProvider, etc.)
      ],
      child: const MyApp(),
    ),
  );
}
// ... (MyApp)

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Prognósticos Expert', // Nome atualizado
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        // Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
