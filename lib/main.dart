// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

// Import para flutter_localizations
import 'package:flutter_localizations/flutter_localizations.dart';

// Core
import 'core/theme/app_theme.dart';

// Data Layer
import 'data/datasources/football_remote_datasource.dart';
import 'data/repositories/football_repository_impl.dart';

// Domain Layer - Repositories
import 'domain/repositories/football_repository.dart';

// Domain Layer - UseCases (Importe TODOS os seus arquivos de UseCase)
import 'domain/usecases/get_leagues_usecase.dart';
import 'domain/usecases/get_fixtures_usecase.dart';
import 'domain/usecases/get_odds_usecase.dart';
import 'domain/usecases/generate_suggested_slips_usecase.dart';
import 'domain/usecases/get_fixture_statistics_usecase.dart';
import 'domain/usecases/get_h2h_usecase.dart';
import 'domain/usecases/get_league_standings_usecase.dart';
import 'domain/usecases/get_live_fixture_update_usecase.dart';
import 'domain/usecases/get_live_odds_usecase.dart';
import 'domain/usecases/get_player_stats_usecase.dart'; // Assumindo que você o criou
import 'domain/usecases/get_referee_stats_usecase.dart'; // Assumindo que você o criou
// Adicione outros usecases se tiver mais (ex: GetLeagueTopScorersUseCase)

// Presentation Layer - Providers
import 'presentation/providers/league_provider.dart';
import 'presentation/providers/suggested_slips_provider.dart';
// Os outros providers (FixtureProvider, FixtureDetailProvider, LiveFixtureProvider)
// são criados dinamicamente durante a navegação, então não precisam ser providos globalmente aqui
// se eles leem seus UseCases do contexto (o que é a abordagem atual).

// Presentation Layer - Screens
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('pt_BR', null);

  // --- Injeção de Dependência Manual Simples ---
  final httpClient = http.Client();
  // DataSource
  final remoteDataSource = FootballRemoteDataSourceImpl(client: httpClient);
  // Repository
  final FootballRepository footballRepository = FootballRepositoryImpl(
      remoteDataSource: remoteDataSource); // Use a interface como tipo

  // UseCases
  final getLeaguesUseCase = GetLeaguesUseCase(footballRepository);
  final getFixturesUseCase = GetFixturesUseCase(footballRepository);
  final getOddsUseCase = GetOddsUseCase(footballRepository);
  final getFixtureStatisticsUseCase =
      GetFixtureStatisticsUseCase(footballRepository);
  final getH2HUseCase = GetH2HUseCase(footballRepository);
  final getLeagueStandingsUseCase =
      GetLeagueStandingsUseCase(footballRepository);
  // O GenerateSuggestedSlipsUseCase precisa do GetLeagueStandingsUseCase
  // E o GetFixturesUseCase (que já temos) para buscar os jogos do dia.
  // Ele usa o footballRepository para as outras chamadas internas.
  final generateSuggestedSlipsUseCase = GenerateSuggestedSlipsUseCase(
      footballRepository, getLeagueStandingsUseCase // Injetando explicitamente
      );
  final getLiveFixtureUpdateUseCase =
      GetLiveFixtureUpdateUseCase(footballRepository);
  final getLiveOddsUseCase = GetLiveOddsUseCase(footballRepository);
  final getPlayerStatsUseCase =
      GetPlayerStatsUseCase(footballRepository); // Instanciar
  final getRefereeStatsUseCase =
      GetRefereeStatsUseCase(footballRepository); // Instanciar
  // Adicione instanciações para outros UseCases aqui

  runApp(
    MultiProvider(
      providers: [
        // --- Providers de Estado da Aplicação (ChangeNotifiers) ---
        ChangeNotifierProvider(
          create: (_) => LeagueProvider(getLeaguesUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => SuggestedSlipsProvider(
            getFixturesUseCase, // Para buscar os jogos do dia
            generateSuggestedSlipsUseCase,
          ),
        ),

        // --- Providers de Valor para UseCases (para injeção em outros providers) ---
        // Isso permite que providers criados dinamicamente (como FixtureProvider, FixtureDetailProvider, LiveFixtureProvider)
        // acessem os UseCases via context.read<UseCaseType>()
        Provider<GetFixturesUseCase>.value(value: getFixturesUseCase),
        Provider<GetOddsUseCase>.value(value: getOddsUseCase),
        Provider<GetFixtureStatisticsUseCase>.value(
            value: getFixtureStatisticsUseCase),
        Provider<GetH2HUseCase>.value(value: getH2HUseCase),
        Provider<GetLeagueStandingsUseCase>.value(
            value: getLeagueStandingsUseCase),
        Provider<GetLiveFixtureUpdateUseCase>.value(
            value: getLiveFixtureUpdateUseCase),
        Provider<GetLiveOddsUseCase>.value(value: getLiveOddsUseCase),
        Provider<GetPlayerStatsUseCase>.value(value: getPlayerStatsUseCase),
        Provider<GetRefereeStatsUseCase>.value(value: getRefereeStatsUseCase),
        // Adicione outros UseCases aqui
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
      title: 'Prognósticos de Futebol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Configuração de Localização para Português do Brasil
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        // Locale('en', 'US'), // Exemplo se você adicionar suporte a inglês
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
