// lib/main.dart
// ... (imports para todos os use cases)

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:product_gamers/core/theme/app_theme.dart';
import 'package:product_gamers/data/repositories/football_repository_impl.dart';
import 'package:product_gamers/domain/usecases/generate_suggested_slips_usecase.dart';
import 'package:product_gamers/domain/usecases/get_fixtures_usecase.dart';
import 'package:product_gamers/domain/usecases/get_leagues_usecase.dart';
import 'package:product_gamers/presentation/app_shell.dart';
import 'package:product_gamers/presentation/providers/league_provider.dart';
import 'package:product_gamers/presentation/providers/suggested_slips_provider.dart';
import 'package:provider/provider.dart';

import 'data/datasources/football_remote_datasource.dart';
import 'domain/repositories/football_repository.dart';

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
      FootballRepositoryImpl(remoteDataSource: remoteDataSource)
          as FootballRepository;

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
    return MaterialApp(
      title: 'App Prognósticos Expert V3',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkGoldTheme,

      // ... (theme, locale, etc.)
      home:
          const AppShell(), // HomeScreen está ABAIXO do MultiProvider na árvore
    );
  }
}
