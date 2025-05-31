// lib/presentation/screens/fixtures_screen.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';
import 'package:provider/provider.dart';

// Core
import '../../core/utils/date_formatter.dart'; // Para o ano da temporada, se necessário

// Domain
// Para o tipo de dado na navegação
// UseCases são lidos do contexto global via Provider.of ou context.read na navegação
import '../../domain/usecases/get_odds_usecase.dart';
import '../../domain/usecases/get_fixture_statistics_usecase.dart';
import '../../domain/usecases/get_h2h_usecase.dart';
import '../../domain/usecases/get_live_fixture_update_usecase.dart';
import '../../domain/usecases/get_live_odds_usecase.dart';

// Presentation
import '../providers/fixture_provider.dart'; // Consome este provider
import '../providers/fixture_detail_provider.dart'; // Proverá para a próxima tela
import '../providers/live_fixture_provider.dart'; // Proverá para a tela ao vivo
import '../widgets/common/loading_indicator_widget.dart';
import '../widgets/common/error_display_widget.dart';
import '../widgets/fixture_card_widget.dart'; // Usa este widget
import 'fixture_detail_screen.dart'; // Tela de detalhes pré-jogo/finalizado
import 'live_fixture_screen.dart'; // Tela de detalhes ao vivo

class FixturesScreen extends StatefulWidget {
  final League league; // Recebe a liga selecionada da HomeScreen

  const FixturesScreen({super.key, required this.league});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  @override
  void initState() {
    super.initState();
    // O FixtureProvider é criado e o fetchFixtures é chamado
    // quando navegamos da HomeScreen para esta tela.
    // Se precisasse ser chamado aqui, seria:
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<FixtureProvider>(context, listen: false).fetchFixtures();
    // });
  }

  Future<void> _refreshFixtures() async {
    if (!mounted) return;
    // Ao fazer refresh, busca mais jogos caso o usuário tenha rolado muito (ex: 30)
    await Provider.of<FixtureProvider>(context, listen: false)
        .fetchFixtures(forceRefresh: true, gamesToFetch: 30);
  }

  // lib/presentation/screens/fixtures_screen.dart
// ... (imports e o resto da classe como antes)

  void _navigateToDetails(BuildContext navContext, Fixture fixture) {
    final now = DateTime.now();
    final gameTime = fixture.date.toLocal();
    final difference = gameTime.difference(now);

    final bool isImminentOrLive = (!["NS", "PST", "CANC", "TBD"]
            .contains(fixture.statusShort.toUpperCase())) ||
        (fixture.statusShort.toUpperCase() == "NS" &&
            (difference.isNegative && difference.abs().inMinutes < 120 ||
                !difference.isNegative && difference.inMinutes < 15));

    final bool isTrulyFinished = [
      "FT",
      "AET",
      "PEN",
      "CANC",
      "ABD",
      "PST",
      "WO"
    ].contains(fixture.statusShort.toUpperCase());

    if (isImminentOrLive && !isTrulyFinished) {
      // Navegar para LiveFixtureScreen
      Navigator.push(
        navContext,
        MaterialPageRoute(
          builder: (contextForProvider) => ChangeNotifierProvider(
            create: (_) => LiveFixtureProvider(
              fixtureId: fixture.id,
              // === CORREÇÃO AQUI: Adicionar os parâmetros faltantes ===
              homeTeamId: fixture.homeTeam.id,
              homeTeamName: fixture.homeTeam.name,
              awayTeamId: fixture.awayTeam.id,
              awayTeamName: fixture.awayTeam.name,
              // ======================================================
              getLiveFixtureUpdateUseCase:
                  contextForProvider.read<GetLiveFixtureUpdateUseCase>(),
              getLiveOddsUseCase: contextForProvider.read<GetLiveOddsUseCase>(),
            ),
            child: LiveFixtureScreen(fixtureBasicInfo: fixture),
          ),
        ),
      );
    } else {
      // Navegar para FixtureDetailScreen (pré-jogo ou finalizado)
      Navigator.push(
        navContext,
        MaterialPageRoute(
          builder: (contextForProvider) => ChangeNotifierProvider(
            create: (_) => FixtureDetailProvider(
              baseFixture:
                  fixture, // baseFixture já contém os IDs e nomes dos times
              getFixtureStatsUseCase:
                  contextForProvider.read<GetFixtureStatisticsUseCase>(),
              getOddsUseCase: contextForProvider.read<GetOddsUseCase>(),
              getH2HUseCase: contextForProvider.read<GetH2HUseCase>(),
            ),
            child: FixtureDetailScreen(baseFixture: fixture),
          ),
        ),
      );
    }
  }

// ... (o resto da classe FixturesScreen)

  @override
  Widget build(BuildContext context) {
    // Consome o FixtureProvider que foi provido pela HomeScreen durante a navegação
    final fixtureProvider = context.watch<FixtureProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.league.friendlyName),
        // actions: [ // Opcional, já temos RefreshIndicator
        //   IconButton(
        //     icon: const Icon(Icons.refresh),
        //     onPressed: _refreshFixtures,
        //   ),
        // ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFixtures,
        child: _buildContent(context, fixtureProvider),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FixtureProvider provider) {
    switch (provider.status) {
      case FixtureListStatus.initial:
      // No estado inicial, o FixtureProvider pode não ter sido chamado ainda se a lógica de fetch
      // estiver no initState desta tela. Se o fetch é no construtor do provider (feito na HomeScreen),
      // o status mudará rapidamente para loading.
      // Para evitar um frame "vazio", podemos mostrar loading também no initial.
      case FixtureListStatus.loading:
        return const LoadingIndicatorWidget(
            message: 'Buscando próximos jogos...');
      case FixtureListStatus.error:
        return ErrorDisplayWidget(
          message: provider.errorMessage ?? 'Falha ao carregar jogos.',
          onRetry: _refreshFixtures,
        );
      case FixtureListStatus.empty:
        return ErrorDisplayWidget(
          message: provider.errorMessage ??
              'Nenhum jogo futuro agendado para ${widget.league.friendlyName} na temporada ${provider.season}.',
          onRetry: _refreshFixtures,
          showRetryButton: true,
        );
      case FixtureListStatus.loaded:
        return ListView.builder(
          padding:
              const EdgeInsets.only(top: 8, bottom: 16), // Padding para a lista
          itemCount: provider.fixtures.length,
          itemBuilder: (context, index) {
            final fixture = provider.fixtures[index];
            return FixtureCardWidget(
              fixture: fixture,
              onTap: () => _navigateToDetails(context, fixture),
            );
          },
        );
    }
  }
}
