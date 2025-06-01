// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';
import 'package:product_gamers/domain/entities/entities/suggested_bet_slip.dart';
import 'package:provider/provider.dart';

// Core
import '../../core/utils/date_formatter.dart'; // Usaremos para obter o ano da temporada

// Domain (UseCases que FixturesScreen precisará para injetar em seus providers filhos)
import '../../domain/usecases/get_fixtures_usecase.dart';
// Os UseCases para FixtureDetailProvider e LiveFixtureProvider serão lidos do contexto global
// dentro da FixturesScreen quando ela for construir a rota para essas telas de detalhe.

// Presentation
import '../providers/league_provider.dart';
import '../providers/fixture_provider.dart'; // Para prover para FixturesScreen
// import '../providers/suggested_slips_provider.dart'; // Adicionaremos depois
import '../widgets/common/loading_indicator_widget.dart';
import '../widgets/common/error_display_widget.dart';
import '../widgets/league_tile_widget.dart';
// import '../widgets/suggested_slip_card_widget.dart'; // Adicionaremos depois
import 'fixtures_screen.dart'; // A tela para onde navegaremos

// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_formatter.dart';

import '../../domain/usecases/get_fixtures_usecase.dart';
import '../../domain/usecases/generate_suggested_slips_usecase.dart'; // Para PotentialBet

import '../providers/league_provider.dart';
import '../providers/suggested_slips_provider.dart'; // Agora gerencia PotentialBet agrupadas
import '../providers/fixture_provider.dart';

import '../widgets/common/loading_indicator_widget.dart';
import '../widgets/common/error_display_widget.dart';
import '../widgets/league_tile_widget.dart';
import '../widgets/market_suggestion_card_widget.dart'; // NOVO WIDGET
import 'fixtures_screen.dart';

// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import '../../core/utils/date_formatter.dart';

// Domain

import '../../domain/usecases/get_fixtures_usecase.dart';
import '../../domain/usecases/generate_suggested_slips_usecase.dart'; // Para PotentialBet, se usado diretamente na navegação
// UseCases para navegação para telas de detalhe são lidos do contexto global

// Presentation
import '../providers/league_provider.dart';
import '../providers/suggested_slips_provider.dart'; // Gerencia as PotentialBet agrupadas
import '../providers/fixture_provider.dart'; // Para navegação para FixturesScreen

import '../widgets/common/loading_indicator_widget.dart';
import '../widgets/common/error_display_widget.dart';
import '../widgets/league_tile_widget.dart';
import '../widgets/market_suggestion_card_widget.dart'; // Exibe uma PotentialBet
// Placeholder para bilhetes acumulados, se você quiser reintroduzir
// import '../widgets/suggested_slip_card_widget.dart';

import 'fixtures_screen.dart';
// As telas FixtureDetailScreen e LiveFixtureScreen são navegadas a partir do MarketSuggestionCardWidget ou FixturesScreen

// lib/presentation/providers/suggested_slips_provider.dart
import 'package:flutter/foundation.dart'; // Para kDebugMode e ChangeNotifier

// Importar PotentialBet e SlipGenerationResult do GenerateSuggestedSlipsUseCase
import '../../domain/usecases/generate_suggested_slips_usecase.dart';
import '../../domain/usecases/get_fixtures_usecase.dart';
// AppConstants para IDs de ligas populares se a busca de jogos for mais genérica
import '../../core/config/app_constants.dart';
import '../../core/utils/date_formatter.dart';

// Enum para o status deste provider
// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import '../../core/utils/date_formatter.dart';

// Domain

import '../../domain/usecases/get_fixtures_usecase.dart';
import '../../domain/usecases/generate_suggested_slips_usecase.dart'; // Para PotentialBet, se usado diretamente na navegação
// UseCases para navegação para telas de detalhe são lidos do contexto global

// Presentation
import '../providers/league_provider.dart';
import '../providers/suggested_slips_provider.dart'; // Gerencia as PotentialBet agrupadas
import '../providers/fixture_provider.dart'; // Para navegação para FixturesScreen

import '../widgets/common/loading_indicator_widget.dart';
import '../widgets/common/error_display_widget.dart';
import '../widgets/league_tile_widget.dart';
import '../widgets/market_suggestion_card_widget.dart'; // Exibe uma PotentialBet
// Placeholder para bilhetes acumulados, se você quiser reintroduzir
// import '../widgets/suggested_slip_card_widget.dart';

import 'fixtures_screen.dart';

// As telas FixtureDetailScreen e LiveFixtureScreen são navegadas a partir do MarketSuggestionCardWidget ou FixturesScreen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialDataFetched = false; // Flag para controlar o fetch inicial
  @override
  void initState() {
    super.initState();
    // Disparar o fetch DEPOIS que o primeiro frame for construído
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Só executa se o widget ainda estiver montado
      if (mounted) {
        _fetchAllInitialData(
            forceRefresh:
                false); // Chamar com forceRefresh: false para carga inicial
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // didChangeDependencies é chamado após initState e quando as dependências do widget mudam.
    // É um local mais seguro para interagir com o context para buscar dados iniciais
    // em comparação com initState diretamente para Providers.
    if (!_isInitialDataFetched) {
      _fetchAllInitialData();
      _isInitialDataFetched = true;
    }
  }

  Future<void> _fetchAllInitialData({bool forceRefresh = false}) async {
    if (!mounted) return; // Boa prática

    final leagueProv = context.read<LeagueProvider>();
    final suggestionsProv = context.read<SuggestedSlipsProvider>();

    if (kDebugMode) {
      print(
          "HomeScreen: Iniciando _fetchAllInitialData (forceRefresh: $forceRefresh)");
    }

    try {
      // Se for forceRefresh, os providers devem limpar seus próprios dados internamente
      await Future.wait([
        leagueProv.fetchLeagues(forceRefresh: forceRefresh),
        suggestionsProv.fetchAndGeneratePotentialBets(
            forceRefresh: forceRefresh),
      ]);
      if (kDebugMode) print("HomeScreen: _fetchAllInitialData concluído.");
    } catch (e) {
      if (kDebugMode) print("HomeScreen: Erro em _fetchAllInitialData: $e");
    }
  }

  void _navigateToFixturesScreen(BuildContext navContext, League league) {
    final getFixturesUseCase = navContext.read<GetFixturesUseCase>();
    final String seasonToFetch = league.currentSeasonYear?.toString() ??
        DateFormatter.getYear(DateTime.now());

    Navigator.push(
      navContext,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => FixtureProvider(
            getFixturesUseCase: getFixturesUseCase,
            leagueId: league.id,
            season: seasonToFetch,
          )..fetchFixtures(), // Inicia o fetch aqui
          child: FixturesScreen(league: league),
        ),
      ),
    );
  }

  String _getMarketCategoryTitle(String marketKey) {
    // ... (como antes)
    switch (marketKey) {
      case "1X2":
        return "Resultado Final (1X2) 🏆";
      case "GolsOverUnder":
        return "Gols Acima/Abaixo ⚽";
      case "BTTS":
        return "Ambas Equipes Marcam? (BTTS) 🥅";
      case "Escanteios":
        return "Escanteios (Over/Under) 🚩";
      case "Cartoes":
        return "Cartões (Over/Under) 🟨🟥";
      case "JogadorAMarcar":
        return "Jogador para Marcar 🎯";
      default:
        return marketKey
            .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
            .trim();
    }
  }

  Widget _buildSectionHeaderSliver(BuildContext context, String title) {
    // ... (como antes)
    return SliverToBoxAdapter(
      child: Padding(
        padding:
            const EdgeInsets.only(top: 24.0, left: 16, right: 16, bottom: 10),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 21),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _fetchAllInitialData(forceRefresh: true),
        color: primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Prognósticos Expert'),
              pinned: true,
              floating: false,
              snap: false,
              expandedHeight: 100.0,
              backgroundColor: primaryColor,
              foregroundColor: onPrimaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            _buildSectionHeaderSliver(context, "Sugestões de Entradas 🔥"),
            Consumer<SuggestedSlipsProvider>(
              builder: (context, suggestionsProvider, child) {
                // A lógica de exibição de loading/error/empty/loaded para sugestões
                // (como na sua última versão da HomeScreen)
                if (suggestionsProvider.status == SuggestionsStatus.loading &&
                    suggestionsProvider.marketSuggestions.isEmpty) {
                  return const SliverToBoxAdapter(
                      child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 50.0, horizontal: 20),
                    child: LoadingIndicatorWidget(
                        message: "Analisando jogos e gerando sugestões..."),
                  ));
                } else if (suggestionsProvider.status ==
                    SuggestionsStatus.error) {
                  return SliverToBoxAdapter(
                      child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ErrorDisplayWidget(
                        message: suggestionsProvider.errorMessage ??
                            "Não foi possível carregar as sugestões de entrada.",
                        onRetry: () => suggestionsProvider
                            .fetchAndGeneratePotentialBets(forceRefresh: true)),
                  ));
                } else if (suggestionsProvider.marketSuggestions.isEmpty &&
                    suggestionsProvider.status != SuggestionsStatus.loading) {
                  // Adicionado check para não mostrar "empty" durante loading inicial
                  return SliverToBoxAdapter(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 30.0),
                    child: Center(
                        child: Text(
                      suggestionsProvider.errorMessage ??
                          "Nenhuma sugestão de entrada encontrada para hoje. Verifique mais tarde!",
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Theme.of(context).hintColor),
                    )),
                  ));
                }

                final categories = suggestionsProvider.marketSuggestions.entries
                    .where((e) => e.value.isNotEmpty)
                    .toList();
                if (categories.isEmpty &&
                    suggestionsProvider.status == SuggestionsStatus.loaded) {
                  return SliverToBoxAdapter(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 30.0),
                    child: Center(
                        child: Text(
                            "Nenhuma sugestão específica encontrada após análise.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    color: Theme.of(context).hintColor))),
                  ));
                }
                if (categories.isEmpty) {
                  // Se ainda está carregando ou erro, já foi tratado. Se chegou aqui e é vazio, não mostra nada.
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                List<Widget> flatListOfMarketContent = [];
                for (var category in categories) {
                  String title = _getMarketCategoryTitle(category.key);
                  flatListOfMarketContent.add(Padding(
                    padding: const EdgeInsets.only(
                        top: 18, left: 16, right: 16, bottom: 8),
                    child: Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ));
                  flatListOfMarketContent.addAll(category.value
                      .map((bet) => MarketSuggestionCardWidget(
                          potentialBet: bet, marketCategoryTitle: title))
                      .toList());
                  flatListOfMarketContent.add(const SizedBox(height: 10));
                }
                return SliverList(
                    delegate: SliverChildListDelegate(flatListOfMarketContent));
              },
            ),
            _buildSectionHeaderSliver(context, "Explorar Ligas 🌍"),
            Consumer<LeagueProvider>(
              builder: (context, leagueProvider, child) {
                // Lógica de loading/error/empty/loaded para ligas
                if (leagueProvider.status == LeagueStatus.loading &&
                    leagueProvider.leagues.isEmpty) {
                  return const LoadingIndicatorWidget(
                      isSliver: true, message: "Buscando ligas...");
                } else if (leagueProvider.status == LeagueStatus.error) {
                  return ErrorDisplayWidget(
                    isSliver: true,
                    message: leagueProvider.errorMessage ??
                        'Falha ao carregar ligas.',
                    onRetry: () =>
                        leagueProvider.fetchLeagues(forceRefresh: true),
                  );
                } else if ((leagueProvider.status == LeagueStatus.empty ||
                        leagueProvider.leagues.isEmpty) &&
                    leagueProvider.status != LeagueStatus.loading) {
                  return ErrorDisplayWidget(
                    isSliver: true,
                    message: leagueProvider.errorMessage ??
                        'Nenhuma liga encontrada.',
                    onRetry: () =>
                        leagueProvider.fetchLeagues(forceRefresh: true),
                    showRetryButton: true,
                  );
                }
                return SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final league = leagueProvider.leagues[index];
                        return LeagueTileWidget(
                          league: league,
                          onTap: () =>
                              _navigateToFixturesScreen(context, league),
                        );
                      },
                      childCount: leagueProvider.leagues.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
