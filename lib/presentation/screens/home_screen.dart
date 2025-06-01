// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';
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
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData({bool forceRefresh = false}) async {
    if (!mounted) return;
    // Busca apenas as ligas por enquanto.
    // A busca de "Bilhetes Sugeridos" será adicionada quando o SuggestedSlipsProvider for implementado.
    await Provider.of<LeagueProvider>(context, listen: false)
        .fetchLeagues(forceRefresh: forceRefresh);
    // await Provider.of<SuggestedSlipsProvider>(context, listen: false).generateDailySlips(forceRefresh: forceRefresh);
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
            // Passa o UseCase e os parâmetros
            getFixturesUseCase: getFixturesUseCase,
            leagueId: league.id,
            season: seasonToFetch,
          )..fetchFixtures(), // Inicia o fetch aqui
          child: FixturesScreen(league: league),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _fetchInitialData(forceRefresh: true),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Ligas Populares'),
              pinned: true,
              floating: false,
              snap: false,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),

            // --- SEÇÃO DE BILHETES SUGERIDOS (SERÁ REINTRODUZIDA NA FASE 4) ---
            // _buildSectionHeader(context, "Bilhetes do Dia 🎲"),
            // Consumer<SuggestedSlipsProvider>( ... )

            // --- SEÇÃO DE JOGOS AO VIVO (SERÁ REINTRODUZIDA NA FASE 5) ---
            // _buildSectionHeader(context, "Ao Vivo Agora 🔥"),
            // Consumer<GlobalLiveMonitorProvider>( ... ) // Exemplo de nome de provider

            _buildSectionHeader(context, "Escolha uma Liga 🏆"),
            Consumer<LeagueProvider>(
              builder: (context, provider, child) {
                if (provider.status == LeagueStatus.loading &&
                    provider.leagues.isEmpty) {
                  return const LoadingIndicatorWidget(
                      isSliver: true, message: "Buscando ligas...");
                } else if (provider.status == LeagueStatus.error) {
                  return ErrorDisplayWidget(
                    isSliver: true,
                    message:
                        provider.errorMessage ?? 'Falha ao carregar ligas.',
                    onRetry: () => provider.fetchLeagues(forceRefresh: true),
                  );
                } else if (provider.status == LeagueStatus.empty ||
                    provider.leagues.isEmpty) {
                  return ErrorDisplayWidget(
                    isSliver: true,
                    message:
                        provider.errorMessage ?? 'Nenhuma liga encontrada.',
                    onRetry: () => provider.fetchLeagues(forceRefresh: true),
                    showRetryButton: true,
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final league = provider.leagues[index];
                      return LeagueTileWidget(
                        league: league,
                        onTap: () => _navigateToFixturesScreen(
                            context, league), // NAVEGAÇÃO IMPLEMENTADA
                      );
                    },
                    childCount: provider.leagues.length,
                  ),
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
        padding:
            const EdgeInsets.only(top: 20.0, left: 16, right: 16, bottom: 8),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
