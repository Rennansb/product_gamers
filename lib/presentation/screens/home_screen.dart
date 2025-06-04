// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/core/theme/app_theme.dart';
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
  bool _initialDataFetchedByDidChange = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_initialDataFetchedByDidChange) {
        _fetchAllInitialData(
            forceRefresh: false, calledFrom: "initState_postFrame");
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialDataFetchedByDidChange) {
      _fetchAllInitialData(
          forceRefresh: false, calledFrom: "didChangeDependencies");
      _initialDataFetchedByDidChange = true;
    }
  }

  Future<void> _fetchAllInitialData(
      {bool forceRefresh = false, String calledFrom = "unknown"}) async {
    if (!mounted) return;

    final leagueProv = context.read<LeagueProvider>();
    final suggestionsProv = context.read<SuggestedSlipsProvider>();

    if (kDebugMode) {
      print(
          "HomeScreen ($calledFrom): Iniciando _fetchAllInitialData (forceRefresh: $forceRefresh)");
    }

    try {
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
          )..fetchFixtures(),
          child: FixturesScreen(league: league),
        ),
      ),
    );
  }

  String _getMarketCategoryTitle(String marketKey) {
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
    return SliverToBoxAdapter(
      child: Padding(
        padding:
            const EdgeInsets.only(top: 24.0, left: 16, right: 16, bottom: 10),
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              // Cor já definida no tema
              fontWeight: FontWeight.bold,
              fontSize: 20 // Ajuste de tamanho se necessário
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            _fetchAllInitialData(forceRefresh: true, calledFrom: "onRefresh"),
        color: AppTheme.goldAccent,
        backgroundColor: AppTheme.slightlyLighterDark,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 130.0, // Altura da AppBar expandida
              floating: false,
              pinned: true,
              snap: false,
              centerTitle: true,
              // backgroundColor e foregroundColor são herdados do appBarTheme em AppTheme.darkGoldTheme

              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(
                    bottom: 14.0), // Ajustar padding para o título recolhido

                title: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      color: AppTheme.goldAccentLight,
                      // O tamanho será interpolado pelo Flutter. Este é o tamanho base/recolhido.
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "ProGreen",
                      style: TextStyle(
                          color: AppTheme.goldAccentLight,
                          fontSize: 18.0, // Tamanho base/recolhido
                          fontWeight: FontWeight.bold,
                          shadows: [
                            // Sombra sutil para destacar no gradiente
                            Shadow(
                                blurRadius: 2.0,
                                color: Colors.black38,
                                offset: Offset(1, 1))
                          ]),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [
                          AppTheme.darkBackground, // Cor mais escura no topo
                          AppTheme.slightlyLighterDark
                              .withOpacity(0.85), // Cor da AppBar no meio/fim
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.1, 0.9]),
                  ),
                  // Opcional: Ícone de fundo maior e mais sutil
                  child: Center(
                    child: Opacity(
                      opacity: 0.08,
                      child: Icon(
                        Icons.insights_rounded,
                        size: 90,
                        color: AppTheme.goldAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Card Principal: "Sugestões de Entradas"
            _buildSectionHeaderSliver(context, "Sugestões de Entradas 🔥"),
            SliverToBoxAdapter(
              child: Card(
                // Estilo do card vem do AppTheme.darkGoldTheme
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Consumer<SuggestedSlipsProvider>(
                    builder: (context, suggestionsProvider, child) {
                      if (suggestionsProvider.status ==
                              SuggestionsStatus.loading &&
                          (suggestionsProvider.marketSuggestions.isEmpty &&
                              suggestionsProvider.accumulatedSlips.isEmpty)) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 40.0, horizontal: 10),
                          child: LoadingIndicatorWidget(
                              message: "Analisando os melhores jogos..."),
                        );
                      } else if (suggestionsProvider.status ==
                          SuggestionsStatus.error) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ErrorDisplayWidget(
                              message: suggestionsProvider.errorMessage ??
                                  "Não foi possível carregar as sugestões.",
                              onRetry: () => suggestionsProvider
                                  .fetchAndGeneratePotentialBets(
                                      forceRefresh: true)),
                        );
                      } else if (suggestionsProvider
                              .marketSuggestions.isEmpty &&
                          suggestionsProvider.accumulatedSlips.isEmpty &&
                          suggestionsProvider.status !=
                              SuggestionsStatus.loading) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 30.0),
                          child: Center(
                              child: Text(
                            suggestionsProvider.errorMessage ??
                                "Nenhuma sugestão para hoje. Verifique mais tarde!",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          )),
                        );
                      }

                      List<Widget> suggestionWidgets = [];

                      // Adicionar Bilhetes Acumulados (se houver)
                      if (suggestionsProvider.accumulatedSlips.isNotEmpty) {
                        suggestionWidgets.add(Padding(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 6, left: 8, right: 8),
                          child: Text("Bilhetes Múltiplos 🎟️",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: AppTheme.goldAccentLight)),
                        ));
                        // TODO: Substituir por SuggestedSlipCardWidget quando estiver pronto e estilizado
                        suggestionsProvider.accumulatedSlips.forEach((slip) {
                          suggestionWidgets.add(Card(
                              color: AppTheme.darkCardSurface.withOpacity(
                                  0.7), // Card interno um pouco diferente
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: AppTheme.subtleBorder
                                          .withOpacity(0.7),
                                      width: 0.7)),
                              child: ListTile(
                                title: Text(slip.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                subtitle: Text(
                                    "Odd Total: ${slip.totalOddsDisplay} (${slip.selections.length} sel.)",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium),
                                trailing: Icon(Icons.arrow_forward_ios,
                                    size: 14,
                                    color: AppTheme.goldAccentLight
                                        .withOpacity(0.7)),
                                onTap: () {
                                  /* TODO: Navegar para detalhes do bilhete acumulado */
                                },
                              )));
                        });
                        suggestionWidgets.add(const SizedBox(height: 10));
                        if (suggestionsProvider.marketSuggestions.entries
                            .where((e) => e.value.isNotEmpty)
                            .isNotEmpty) {
                          suggestionWidgets.add(Divider(
                              height: 24,
                              indent: 16,
                              endIndent: 16,
                              color: AppTheme.subtleBorder.withOpacity(0.3)));
                        }
                      }

                      final categories = suggestionsProvider
                          .marketSuggestions.entries
                          .where((e) => e.value.isNotEmpty)
                          .toList();
                      if (categories.isEmpty &&
                          suggestionWidgets.isEmpty &&
                          suggestionsProvider.status ==
                              SuggestionsStatus.loaded) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 30.0),
                          child: Center(
                              child: Text(
                                  "Nenhuma sugestão específica encontrada.",
                                  textAlign: TextAlign.center,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium)),
                        );
                      }

                      for (var category in categories) {
                        String title = _getMarketCategoryTitle(category.key);
                        suggestionWidgets.add(Padding(
                          padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 6,
                              left: 8,
                              right: 8), // Ajustado top padding
                          child: Text(title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: AppTheme.goldAccentLight)),
                        ));
                        suggestionWidgets.addAll(category.value
                            .map((bet) => MarketSuggestionCardWidget(
                                potentialBet: bet, marketCategoryTitle: title))
                            .toList());
                        if (categories.last != category ||
                            suggestionsProvider.accumulatedSlips.isNotEmpty &&
                                category == categories.first &&
                                suggestionWidgets.whereType<Padding>().length >
                                    1) {
                          // Evitar SizedBox duplo
                          suggestionWidgets.add(const SizedBox(height: 10));
                        }
                      }

                      if (suggestionWidgets.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      // Retorna uma Column, pois estamos dentro de um Card que já está em SliverToBoxAdapter
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: suggestionWidgets);
                    },
                  ),
                ),
              ),
            ),

            // Card Principal: "Explorar Ligas"
            _buildSectionHeaderSliver(context, "Explorar Ligas 🌍"),
            SliverToBoxAdapter(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Consumer<LeagueProvider>(
                    builder: (context, leagueProvider, child) {
                      if (leagueProvider.status == LeagueStatus.loading &&
                          leagueProvider.leagues.isEmpty) {
                        return const LoadingIndicatorWidget(
                            message: "Buscando ligas...");
                      } else if (leagueProvider.status == LeagueStatus.error) {
                        return ErrorDisplayWidget(
                          message: leagueProvider.errorMessage ??
                              'Falha ao carregar ligas.',
                          onRetry: () =>
                              leagueProvider.fetchLeagues(forceRefresh: true),
                        );
                      } else if ((leagueProvider.status == LeagueStatus.empty ||
                              leagueProvider.leagues.isEmpty) &&
                          leagueProvider.status != LeagueStatus.loading) {
                        return ErrorDisplayWidget(
                          message: leagueProvider.errorMessage ??
                              'Nenhuma liga encontrada.',
                          onRetry: () =>
                              leagueProvider.fetchLeagues(forceRefresh: true),
                          showRetryButton: true,
                        );
                      }
                      if (leagueProvider.leagues.isEmpty) {
                        return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                                child: Text("Nenhuma liga para mostrar.")));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: leagueProvider.leagues.length,
                        itemBuilder: (context, index) {
                          final league = leagueProvider.leagues[index];
                          return LeagueTileWidget(
                            league: league,
                            onTap: () =>
                                _navigateToFixturesScreen(context, league),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
