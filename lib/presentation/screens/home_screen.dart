// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/presentation/widgets/suggested_slip_card_widget.dart';
import 'package:provider/provider.dart';

// Core
import '../../core/utils/date_formatter.dart';

// Domain - UseCases
import '../../domain/usecases/get_leagues_usecase.dart'; // Usado pelo LeagueProvider
import '../../domain/usecases/get_fixtures_usecase.dart'; // Usado pelo SuggestedSlipsProvider e passado para FixturesScreen
// Usado pelo SuggestedSlipsProvider
// UseCases que FixturesScreen precisará para injetar em FixtureDetailProvider/LiveFixtureProvider
import '../../domain/usecases/get_odds_usecase.dart';
import '../../domain/usecases/get_fixture_statistics_usecase.dart';
import '../../domain/usecases/get_h2h_usecase.dart';
import '../../domain/usecases/get_live_fixture_update_usecase.dart';
import '../../domain/usecases/get_live_odds_usecase.dart';

// Presentation - Providers
import '../providers/league_provider.dart';
import '../providers/suggested_slips_provider.dart'; // <<< IMPORT CORRETO
import '../providers/fixture_provider.dart';
import '../providers/fixture_detail_provider.dart'; // Para navegação
import '../providers/live_fixture_provider.dart'; // Para navegação

// Presentation - Widgets
import '../widgets/common/loading_indicator_widget.dart';
import '../widgets/common/error_display_widget.dart';
import '../widgets/league_tile_widget.dart';
// <<< IMPORT CORRETO

// Presentation - Screens
import 'fixtures_screen.dart';
import 'fixture_detail_screen.dart'; // Para navegação
import 'live_fixture_screen.dart'; // Para navegação

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllInitialData();
    });
  }

  Future<void> _fetchAllInitialData({bool forceRefresh = false}) async {
    if (!mounted) return;

    final leagueProv = Provider.of<LeagueProvider>(context, listen: false);
    final slipsProv = Provider.of<SuggestedSlipsProvider>(
      context,
      listen: false,
    ); // <<< NOME CORRETO

    // Para evitar chamar generateDailySlips se já estiver carregado e não for refresh
    bool shouldFetchSlips =
        forceRefresh ||
        slipsProv.status == SuggestedSlipsStatus.initial ||
        slipsProv.suggestedSlips.isEmpty;

    List<Future> futures = [
      leagueProv.fetchLeagues(forceRefresh: forceRefresh),
    ];

    if (shouldFetchSlips) {
      futures.add(slipsProv.generateDailySlips(forceRefresh: forceRefresh));
    }

    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _fetchAllInitialData(forceRefresh: true),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Prognósticos Futebol'),
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),

            _buildSectionHeader(context, "Bilhetes do Dia 🎲"),
            Consumer<SuggestedSlipsProvider>(
              // <<< NOME CORRETO
              builder: (context, provider, child) {
                // provider é SuggestedSlipsProvider
                if (provider.status == SuggestedSlipsStatus.loading &&
                    provider.suggestedSlips.isEmpty) {
                  // <<< ENUM CORRETO
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: LoadingIndicatorWidget(
                        message: "Gerando bilhetes...",
                      ),
                    ),
                  );
                } else if (provider.status == SuggestedSlipsStatus.error) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ErrorDisplayWidget(
                        message:
                            provider.errorMessage ?? "Erro ao gerar bilhetes.",
                        onRetry:
                            () =>
                                provider.generateDailySlips(forceRefresh: true),
                      ),
                    ),
                  );
                } else if (provider.suggestedSlips.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 24.0,
                      ),
                      child: Center(
                        child: Text(
                          provider.errorMessage ??
                              "Nenhum bilhete especial para hoje. Volte mais tarde!",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final slip = provider.suggestedSlips[index];
                    return SuggestedSlipCardWidget(
                      slip: slip,
                    ); // <<< INSTANCIANDO O WIDGET
                  }, childCount: provider.suggestedSlips.length),
                );
              },
            ),

            _buildSectionHeader(context, "Ligas Populares 🏆"),
            Consumer<LeagueProvider>(
              builder: (context, provider, child) {
                if (provider.status == LeagueStatus.loading &&
                    provider.leagues.isEmpty) {
                  return const LoadingIndicatorWidget(
                    isSliver: true,
                    message: "Buscando ligas...",
                  );
                } else if (provider.status == LeagueStatus.error) {
                  return ErrorDisplayWidget(
                    isSliver: true,
                    message:
                        provider.errorMessage ?? 'Falha ao carregar ligas.',
                    onRetry: () => provider.fetchLeagues(forceRefresh: true),
                  );
                } else if (provider.leagues.isEmpty) {
                  return ErrorDisplayWidget(
                    isSliver: true,
                    message:
                        provider.errorMessage ?? 'Nenhuma liga encontrada.',
                    onRetry: () => provider.fetchLeagues(forceRefresh: true),
                    showRetryButton: true,
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final league = provider.leagues[index];
                    return LeagueTileWidget(
                      league: league,
                      onTap: () {
                        // === Lendo os UseCases do contexto para injetar ===
                        final getFixturesUseCase =
                            context.read<GetFixturesUseCase>();
                        final getOddsUseCase = context.read<GetOddsUseCase>();
                        final getFixtureStatisticsUseCase =
                            context.read<GetFixtureStatisticsUseCase>();
                        final getH2HUseCase = context.read<GetH2HUseCase>();
                        final getLiveFixtureUpdateUseCase =
                            context.read<GetLiveFixtureUpdateUseCase>();
                        final getLiveOddsUseCase =
                            context.read<GetLiveOddsUseCase>();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => MultiProvider(
                                  providers: [
                                    ChangeNotifierProvider(
                                      create:
                                          (_) => FixtureProvider(
                                            getFixturesUseCase, // Injetando
                                            league.id,
                                            league.currentSeasonYear
                                                    ?.toString() ??
                                                DateFormatter.getYear(
                                                  DateTime.now(),
                                                ),
                                          )..fetchFixtures(),
                                    ),
                                    // Os providers para FixtureDetail e LiveFixture serão criados na FixturesScreen
                                    // quando o usuário clicar em um jogo específico, e eles também lerão
                                    // os UseCases do contexto.
                                  ],
                                  child: FixturesScreen(
                                    league: league,
                                    // Não precisa mais passar os usecases para FixturesScreen,
                                    // pois ela pode ler do contexto ao navegar para as telas de detalhe.
                                  ),
                                ),
                          ),
                        );
                      },
                    );
                  }, childCount: provider.leagues.length),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 24.0,
          left: 16,
          right: 16,
          bottom: 10,
        ),
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}
