// lib/presentation/screens/fixtures_screen.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';
import 'package:product_gamers/presentation/providers/live_fixture_provider.dart';
import 'package:product_gamers/presentation/screens/live_fixture_screen.dart';
import 'package:provider/provider.dart';

// Core
import '../../core/utils/date_formatter.dart';

// Domain

// UseCases que serão lidos do contexto para injetar nos providers das próximas telas
import '../../domain/usecases/get_odds_usecase.dart';
import '../../domain/usecases/get_fixture_statistics_usecase.dart';
import '../../domain/usecases/get_h2h_usecase.dart';
import '../../domain/usecases/get_live_fixture_update_usecase.dart';
import '../../domain/usecases/get_live_odds_usecase.dart';

// Presentation
import '../providers/fixture_provider.dart'; // O provider desta tela
import '../providers/fixture_detail_provider.dart'; // Provider para a tela de detalhes pré-jogo
// Provider para a tela de detalhes ao vivo
import '../widgets/common/loading_indicator_widget.dart';
import '../widgets/common/error_display_widget.dart';
import '../widgets/fixture_card_widget.dart';
import 'fixture_detail_screen.dart'; // A tela de detalhes pré-jogo
// A tela de detalhes ao vivo

class FixturesScreen extends StatefulWidget {
  final League league;

  const FixturesScreen({super.key, required this.league});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  @override
  void initState() {
    super.initState();
    // O FixtureProvider já tem fetchFixtures chamado na HomeScreen
    // ao ser criado na navegação para esta tela.
  }

  Future<void> _refreshFixtures() async {
    if (!mounted) return;
    await context.read<FixtureProvider>().fetchFixtures(forceRefresh: true);
  }

  void _navigateToFixtureDetails(BuildContext context, Fixture fixture) {
    final now = DateTime.now();
    final gameTime = fixture.date.toLocal();
    final difference = gameTime.difference(now);

    bool isLiveOrImminent =
        (!["NS", "PST"].contains(fixture.statusShort.toUpperCase()) ||
            (fixture.statusShort.toUpperCase() == "NS" &&
                difference.inMinutes < 15 &&
                difference.inMinutes > -120)) &&
        ![
          "FT",
          "AET",
          "PEN",
          "CANC",
          "PST",
          "ABD",
          "SUSP",
          "INT",
        ].contains(fixture.statusShort.toUpperCase());

    if (isLiveOrImminent) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (ctx) => ChangeNotifierProvider(
                create:
                    (_) => LiveFixtureProvider(
                      fixtureId: fixture.id,
                      // === CORREÇÃO AQUI: Passando os parâmetros nomeados requeridos ===
                      homeTeamName: fixture.homeTeam.name,
                      awayTeamName: fixture.awayTeam.name,
                      homeTeamId: fixture.homeTeam.id,
                      awayTeamId: fixture.awayTeam.id,
                      // ==============================================================
                      getLiveFixtureUpdateUseCase:
                          ctx.read<GetLiveFixtureUpdateUseCase>(),
                      getLiveOddsUseCase: ctx.read<GetLiveOddsUseCase>(),
                    ),
                child: LiveFixtureScreen(
                  fixtureBasicInfo: fixture,
                ), // Usar o nome da classe
              ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (ctx) => ChangeNotifierProvider(
                create:
                    (_) => FixtureDetailProvider(
                      baseFixture: fixture,
                      getFixtureStatsUseCase:
                          ctx.read<GetFixtureStatisticsUseCase>(),
                      getOddsUseCase: ctx.read<GetOddsUseCase>(),
                      getH2HUseCase: ctx.read<GetH2HUseCase>(),
                    ),
                child: FixtureDetailScreen(
                  baseFixture: fixture,
                ), // Usar o nome da classe
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fixtureProvider = context.watch<FixtureProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.league.friendlyName)),
      body: RefreshIndicator(
        onRefresh: _refreshFixtures,
        child: _buildContent(context, fixtureProvider),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FixtureProvider provider) {
    switch (provider.status) {
      case FixtureListStatus.initial:
      case FixtureListStatus.loading:
        return const Center(
          child: LoadingIndicatorWidget(message: 'Buscando próximos jogos...'),
        );
      case FixtureListStatus.error:
        return Center(
          child: ErrorDisplayWidget(
            message: provider.errorMessage ?? 'Falha ao carregar jogos.',
            onRetry: _refreshFixtures,
          ),
        );
      case FixtureListStatus.empty:
        return Center(
          child: ErrorDisplayWidget(
            message:
                provider.errorMessage ??
                'Nenhum jogo futuro agendado para ${widget.league.friendlyName}.',
            onRetry: _refreshFixtures,
            showRetryButton: true,
          ),
        );
      case FixtureListStatus.loaded:
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: provider.fixtures.length,
          itemBuilder: (context, index) {
            final fixture = provider.fixtures[index];
            return FixtureCardWidget(
              fixture: fixture,
              onTap: () => _navigateToFixtureDetails(context, fixture),
            );
          },
        );
    }
  }
}
