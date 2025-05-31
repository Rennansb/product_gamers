// lib/main.dart
import 'package:dartz/dartz.dart'; // Necessário por causa dos placeholders que usavam Right([])
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('pt_BR', null);

  // --- Injeção de Dependência Manual Simples ---
  final httpClient = http.Client();
  // DataSource
  final FootballRemoteDataSource remoteDataSource =
      FootballRemoteDataSourceImpl(client: httpClient);
  // Repository
  final FootballRepository footballRepository =
      FootballRepositoryImpl(remoteDataSource: remoteDataSource);

  // Instanciando TODOS os UseCases que podem ser necessários globalmente ou para providers iniciais
  final getLeaguesUseCase = GetLeaguesUseCase(footballRepository);
  final getFixturesUseCase = GetFixturesUseCase(footballRepository);
  final getOddsUseCase = GetOddsUseCase(footballRepository);
  final getFixtureStatisticsUseCase =
      GetFixtureStatisticsUseCase(footballRepository);
  final getH2HUseCase = GetH2HUseCase(footballRepository);
  final getLeagueStandingsUseCase =
      GetLeagueStandingsUseCase(footballRepository);
  final getPlayerStatsUseCase =
      GetPlayerStatsUseCase(footballRepository); // Para jogador individual

  final getRefereeStatsUseCase = GetRefereeStatsUseCase(footballRepository);

  final getLiveFixtureUpdateUseCase =
      GetLiveFixtureUpdateUseCase(footballRepository);
  final getLiveOddsUseCase = GetLiveOddsUseCase(footballRepository);
  // final getTeamRecentFixturesUseCase = GetTeamRecentFixturesUseCase(footballRepository); // Se criado

  // Defina ou importe o oddsCalculator antes de usá-lo

  // GenerateSuggestedSlipsUseCase (Opção A: recebe só o repo e cria sub-usecases internamente)
  final generateSuggestedSlipsUseCase =
      GenerateSuggestedSlipsUseCase(footballRepository);
  runApp(
    MultiProvider(
      providers: [
        // --- Prover todos os UseCases para que possam ser lidos por Providers/Widgets ---
        // Isso é útil para providers criados dinamicamente (ex: em rotas de navegação)
        // ou para providers que dependem de múltiplos use cases.
        Provider<GetLeaguesUseCase>.value(value: getLeaguesUseCase),
        Provider<GetFixturesUseCase>.value(value: getFixturesUseCase),
        Provider<GetOddsUseCase>.value(value: getOddsUseCase),
        Provider<GetFixtureStatisticsUseCase>.value(
            value: getFixtureStatisticsUseCase),
        Provider<GetH2HUseCase>.value(value: getH2HUseCase),
        Provider<GetLeagueStandingsUseCase>.value(
            value: getLeagueStandingsUseCase),
        Provider<GetPlayerStatsUseCase>.value(value: getPlayerStatsUseCase),

        Provider<GetRefereeStatsUseCase>.value(value: getRefereeStatsUseCase),

        Provider<GenerateSuggestedSlipsUseCase>.value(
            value: generateSuggestedSlipsUseCase),
        Provider<GetLiveFixtureUpdateUseCase>.value(
            value: getLiveFixtureUpdateUseCase),
        Provider<GetLiveOddsUseCase>.value(value: getLiveOddsUseCase),
        // Provider<GetTeamRecentFixturesUseCase>.value(value: getTeamRecentFixturesUseCase), // Se criado

        // --- Providers de Estado (ChangeNotifiers) ---
        ChangeNotifierProvider(
          create: (context) =>
              LeagueProvider(context.read<GetLeaguesUseCase>()),
        ),
        ChangeNotifierProvider(
          create: (context) => SuggestedSlipsProvider(
            // SuggestedSlipsProvider precisa de GetFixturesUseCase para buscar os jogos do dia
            // e GenerateSuggestedSlipsUseCase para criar os bilhetes.
            context.read<GetFixturesUseCase>(),
            context.read<GenerateSuggestedSlipsUseCase>(),
          ),
        ),
        // Outros providers como FixtureProvider, FixtureDetailProvider, LiveFixtureProvider
        // serão criados "on-the-fly" (dinamicamente) durante a navegação,
        // usando os UseCases providos acima através de context.read<UseCaseType>().
      ],
      child: const MyApp(),
    ),
  );
}

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
