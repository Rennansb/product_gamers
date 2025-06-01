// lib/domain/usecases/generate_suggested_slips_usecase.dart
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/data_for_prediction.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'package:product_gamers/domain/entities/entities/lineup.dart';
import 'package:product_gamers/domain/entities/entities/player_stats.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
import 'package:product_gamers/domain/entities/entities/referee_stats.dart';
import 'package:product_gamers/domain/entities/entities/standing_info.dart';
import 'package:product_gamers/domain/entities/entities/suggested_bet_slip.dart';
import 'package:product_gamers/domain/entities/entities/team_aggregated_stats.dart';

// Core

import '../../core/utils/date_formatter.dart';
// Entities

// Repositories
import '../repositories/football_repository.dart';
// Sub-UseCases
import 'get_league_standings_usecase.dart';
import 'get_referee_stats_usecase.dart';
import 'get_team_aggregated_stats_usecase.dart';
import 'search_referee_by_name_usecase.dart';
import 'get_fixture_lineups_usecase.dart';
import 'get_player_stats_usecase.dart';
import 'get_team_recent_fixtures_usecase.dart'; // NOVO IMPORT

// Classe auxiliar
class PotentialBet {
  final Fixture fixture;
  final BetSelection selection;
  final double confidence;
  PotentialBet(
      {required this.fixture,
      required this.selection,
      required this.confidence});
}

class GenerateSuggestedSlipsUseCase {
  final FootballRepository
      _footballRepository; // Ainda necessário para alguns acessos diretos

  // Sub-UseCases
  final GetLeagueStandingsUseCase _getLeagueStandingsUseCase;
  final GetRefereeStatsUseCase _getRefereeStatsUseCase;
  final GetTeamAggregatedStatsUseCase _getTeamAggregatedStatsUseCase;
  final SearchRefereeByNameUseCase _searchRefereeByNameUseCase;
  final GetFixtureLineupsUseCase _getFixtureLineupsUseCase;
  final GetPlayerStatsUseCase _getPlayerStatsUseCase;
  final GetTeamRecentFixturesUseCase
      _getTeamRecentFixturesUseCase; // NOVO CAMPO

  GenerateSuggestedSlipsUseCase(this._footballRepository)
      : _getLeagueStandingsUseCase =
            GetLeagueStandingsUseCase(_footballRepository),
        _getRefereeStatsUseCase = GetRefereeStatsUseCase(_footballRepository),
        _getTeamAggregatedStatsUseCase =
            GetTeamAggregatedStatsUseCase(_footballRepository),
        _searchRefereeByNameUseCase =
            SearchRefereeByNameUseCase(_footballRepository),
        _getFixtureLineupsUseCase =
            GetFixtureLineupsUseCase(_footballRepository),
        _getPlayerStatsUseCase = GetPlayerStatsUseCase(_footballRepository),
        _getTeamRecentFixturesUseCase =
            GetTeamRecentFixturesUseCase(_footballRepository); // NOVO

  Future<Either<Failure, List<SuggestedBetSlip>>> call({
    required List<Fixture> fixturesForToday,
    double targetTotalOdd = 8.0,
    int maxSelectionsPerSlip = 3,
  }) async {
    // ... (corpo do call como antes, sem alterações aqui)
    try {
      List<PotentialBet> allPotentialBets = [];
      if (fixturesForToday.isEmpty) return Right([]);

      for (var fixture in fixturesForToday) {
        final Either<Failure, DataForPrediction> dataResult =
            await _gatherDataForFixture(fixture);
        dataResult.fold(
          (failure) => print(
              "Falha ao obter dados para ${fixture.id}: ${failure.message}"),
          (predictionData) => allPotentialBets
              .addAll(_analyzeMarketsForFixture(predictionData)),
        );
      }
      if (allPotentialBets.isEmpty) return Right([]);
      return Right(_buildSlipsFromPotentialBets(
          allPotentialBets, targetTotalOdd, maxSelectionsPerSlip));
    } catch (e, s) {
      print("Erro GSSUC: $e\n$s");
      return Left(
          UnknownFailure(message: "Erro ao gerar bilhetes: ${e.toString()}"));
    }
  }

  Future<Either<Failure, DataForPrediction>> _gatherDataForFixture(
      Fixture fixture) async {
    try {
      final String currentSeason = fixture.league.season?.toString() ??
          DateFormatter.getYear(fixture.date); // Usa fixture.league.season
      const int numRecentGames = 5;

      Future<Either<Failure, RefereeStats?>>
          fetchRefereeStatsWithSearch() async {
        if (fixture.refereeName != null && fixture.refereeName!.isNotEmpty) {
          final searchResult =
              await _searchRefereeByNameUseCase(name: fixture.refereeName!);
          return await searchResult.fold(
            (failure) async => Left(failure),
            (refList) async {
              if (refList.isNotEmpty) {
                final foundRefereeId = refList.first.id;
                if (foundRefereeId != 0) {
                  return await _getRefereeStatsUseCase(
                      refereeId: foundRefereeId, season: currentSeason);
                } else {
                  return Left(NoDataFailure(
                      message:
                          "ID do árbitro inválido para '${fixture.refereeName}'."));
                }
              }
              return Left(NoDataFailure(
                  message: "Árbitro '${fixture.refereeName}' não encontrado."));
            },
          );
        }
        return Future.value(
            Left(NoDataFailure(message: "Nome do árbitro não disponível.")));
      }

      // Odds são cruciais, buscamos primeiro.
      final oddsResult = await _footballRepository
          .getOddsForFixture(fixture.id); // CORRIGIDO: argumento posicional
      if (oddsResult.isLeft()) {
        // Se foldLeft não existir, usar isLeft() e getLeft()
        return Left(oddsResult.fold((l) => l,
            (r) => UnknownFailure(message: "Erro inesperado em odds")));
      }
      final List<PrognosticMarket> odds = oddsResult.getOrElse(() => []);
      if (odds.isEmpty) {
        return Left(NoDataFailure(
            message: "Nenhuma odd encontrada para o jogo ${fixture.id}"));
      }

      final lineupsResult = await _getFixtureLineupsUseCase(
          fixtureId: fixture.id,
          homeTeamId: fixture.homeTeam.id,
          awayTeamId: fixture.awayTeam.id);
      LineupsForFixture? lineups = lineupsResult.fold((l) => null, (r) => r);

      Map<int, PlayerSeasonStats> playerStatsMap = {};
      if (lineups?.areAvailable ?? false) {
        List<int> startingPlayerIds = [];
        startingPlayerIds
            .addAll(lineups!.homeTeamLineup!.startingXI.map((p) => p.playerId));
        startingPlayerIds
            .addAll(lineups.awayTeamLineup!.startingXI.map((p) => p.playerId));

        final List<Future<Either<Failure, PlayerSeasonStats?>>>
            playerStatsFutures = startingPlayerIds
                .toSet()
                .map((playerId) => _getPlayerStatsUseCase(
                    playerId: playerId, season: currentSeason))
                .toList();
        final List<Either<Failure, PlayerSeasonStats?>> resolvedPlayerStats =
            await Future.wait(playerStatsFutures);
        for (var result in resolvedPlayerStats) {
          result.fold((l) => null, (r) {
            if (r != null) playerStatsMap[r.playerId] = r;
          });
        }
      }

      final List<Either<dynamic, dynamic>> otherDataResults =
          await Future.wait([
        _footballRepository.getFixtureStatistics(
            fixtureId: fixture.id,
            homeTeamId: fixture.homeTeam.id,
            awayTeamId: fixture.awayTeam.id),
        _footballRepository.getHeadToHead(
            team1Id: fixture.homeTeam.id,
            team2Id: fixture.awayTeam.id,
            lastN: 5,
            status: 'FT'),
        _getLeagueStandingsUseCase(
            leagueId: fixture.league.id,
            season: currentSeason), // Usa fixture.league.id
        _getTeamRecentFixturesUseCase(
            teamId: fixture.homeTeam.id,
            lastN: numRecentGames,
            status: 'FT'), // Usa UseCase
        _getTeamRecentFixturesUseCase(
            teamId: fixture.awayTeam.id,
            lastN: numRecentGames,
            status: 'FT'), // Usa UseCase
        fetchRefereeStatsWithSearch(),
        _getTeamAggregatedStatsUseCase(
            teamId: fixture.homeTeam.id,
            leagueId: fixture.league.id,
            season: currentSeason),
        _getTeamAggregatedStatsUseCase(
            teamId: fixture.awayTeam.id,
            leagueId: fixture.league.id,
            season: currentSeason),
      ]);

      // Função helper para extrair resultado ou null e logar erro
      T? extractResult<T>(Either<Failure, T?> eitherResult, String dataType) {
        return eitherResult.fold((l) {
          print("Erro ao buscar $dataType para ${fixture.id}: ${l.message}");
          return null;
        }, (r) => r);
      }

      return Right(DataForPrediction(
        fixture: fixture,
        odds: odds,
        fixtureStats: extractResult(
            otherDataResults[0] as Either<Failure, FixtureStatsEntity?>,
            "stats da partida"),
        h2hFixtures: extractResult(
            otherDataResults[1] as Either<Failure, List<Fixture>?>, "H2H"),
        leagueStandings: extractResult(
            otherDataResults[2] as Either<Failure, List<StandingInfo>?>,
            "classificações"),
        homeTeamRecentFixtures: extractResult(
            otherDataResults[3] as Either<Failure, List<Fixture>?>,
            "forma casa"),
        awayTeamRecentFixtures: extractResult(
            otherDataResults[4] as Either<Failure, List<Fixture>?>,
            "forma fora"),
        refereeStats: extractResult(
            otherDataResults[5] as Either<Failure, RefereeStats?>, "árbitro"),
        homeTeamAggregatedStats: extractResult(
            otherDataResults[6] as Either<Failure, TeamAggregatedStats?>,
            "stats agreg. casa"),
        awayTeamAggregatedStats: extractResult(
            otherDataResults[7] as Either<Failure, TeamAggregatedStats?>,
            "stats agreg. fora"),
        lineups: lineups,
        playerSeasonStats: playerStatsMap.isNotEmpty ? playerStatsMap : null,
      ));
    } catch (e, s) {
      print(
          "Erro catastrófico em _gatherDataForFixture para ${fixture.id}: $e\n$s");
      return Left(UnknownFailure(
          message: "Erro ao coletar dados para análise: ${e.toString()}"));
    }
  }

  // ... (TODOS os métodos de análise e helpers como _factorial, _poissonProbability, etc. devem estar aqui)
  // _analyzeMarketsForFixture, _analyzeMatchWinnerMarket, _analyzeGoalsOverUnderMarket,
  // _analyzeBothTeamsToScoreMarket, _analyzeCornersMarket, _analyzeCardsMarket,
  // _analyzeAnytimeGoalscorerMarket, _checkGenericLine, _buildSlipsFromPotentialBets

  /// Analyzes all relevant markets for a given fixture and returns a list of potential bets.
  List<PotentialBet> _analyzeMarketsForFixture(DataForPrediction data) {
    final List<PotentialBet> bets = [];
    _analyzeMatchWinnerMarket(data, bets);
    _analyzeGoalsOverUnderMarket(data, bets);
    _analyzeBothTeamsToScoreMarket(data, bets);
    _analyzeCornersMarket(data, bets);
    _analyzeCardsMarket(data, bets);
    _analyzeAnytimeGoalscorerMarket(data, bets);
    return bets;
  }

  // Cole o restante dos métodos que já tínhamos aqui.
  // Vou adicionar os stubs para eles por enquanto para o código compilar.
  int _factorial(int n) {
    if (n < 0) return 1;
    if (n == 0) return 1;
    int r = 1;
    for (int i = 1; i <= n; i++) r *= i;
    return r;
  }

  double _poissonProbability(double lambda, int k) {
    if (lambda <= 0) return 0;
    if (k > 10 && lambda < 0.5) return 0;
    try {
      var p = (pow(lambda, k) * exp(-lambda)) / _factorial(k);
      return p.isNaN || p.isInfinite ? 0.0 : p;
    } catch (e) {
      return 0;
    }
  }

  Map<String, double> _calculatePoissonScoreProbabilities(
      double lambdaHome, double lambdaAway,
      {int maxGoals = 4}) {
    Map<String, double> p = {};
    if (lambdaHome <= 0 || lambdaAway <= 0) return p;
    for (int i = 0; i <= maxGoals; i++) {
      for (int j = 0; j <= maxGoals; j++) {
        p["$i-$j"] = _poissonProbability(lambdaHome, i) *
            _poissonProbability(lambdaAway, j);
      }
    }
    return p;
  }

  int _calculateFormPoints(List<Fixture>? recentFixtures, int currentTeamId) {
    if (recentFixtures == null || recentFixtures.isEmpty) return 0;
    int fp = 0;
    for (var g in recentFixtures.take(5)) {
      if (!["FT", "AET", "PEN"].contains(g.statusShort.toUpperCase())) continue;
      final hg = g.homeGoals ?? 0;
      final ag = g.awayGoals ?? 0;
      if (g.homeTeam.id == currentTeamId) {
        if (hg > ag)
          fp += 3;
        else if (hg == ag) fp += 1;
      } else if (g.awayTeam.id == currentTeamId) {
        if (ag > hg)
          fp += 3;
        else if (hg == ag) fp += 1;
      }
    }
    return fp;
  }

  int _analyzeH2HScore(List<Fixture>? h2hFixtures, int team1Id, int team2Id) {
    if (h2hFixtures == null || h2hFixtures.isEmpty) return 0;
    int t1w = 0;
    int t2w = 0;
    for (var g in h2hFixtures.take(5)) {
      if (!["FT", "AET", "PEN"].contains(g.statusShort.toUpperCase())) continue;
      final hg = g.homeGoals ?? 0;
      final ag = g.awayGoals ?? 0;
      if (g.homeTeam.id == team1Id && hg > ag)
        t1w++;
      else if (g.awayTeam.id == team1Id && ag > hg)
        t1w++;
      else if (g.homeTeam.id == team2Id && hg > ag)
        t2w++;
      else if (g.awayTeam.id == team2Id && ag > hg) t2w++;
    }
    if (t1w > t2w + 1) return 1;
    if (t2w > t1w + 1) return -1;
    return 0;
  }

  void _analyzeMatchWinnerMarket(
      DataForPrediction data, List<PotentialBet> bets) {
    /* ... implementação anterior ... */
  }
  void _analyzeGoalsOverUnderMarket(
      DataForPrediction data, List<PotentialBet> bets) {
    /* ... implementação anterior ... */
  }
  void _analyzeBothTeamsToScoreMarket(
      DataForPrediction data, List<PotentialBet> bets) {
    /* ... implementação anterior ... */
  }
  void _analyzeCornersMarket(DataForPrediction data, List<PotentialBet> bets) {
    /* ... implementação anterior ... */
  }
  void _analyzeCardsMarket(DataForPrediction data, List<PotentialBet> bets) {
    /* ... implementação anterior ... */
  }
  void _analyzeAnytimeGoalscorerMarket(
      DataForPrediction data, List<PotentialBet> bets) {
    /* ... implementação anterior ... */
  }
  void _checkGenericLine(
      Fixture fixture,
      PrognosticMarket marketData,
      double expectedValue,
      double lineValueFromLabel,
      List<PotentialBet> bets,
      String reasoningBasis,
      {String marketType = "Genérico",
      OddOption? specificOption}) {
    /* ... implementação anterior, mas specificOption deve ser required se usado assim */
  }
  List<SuggestedBetSlip> _buildSlipsFromPotentialBets(
      List<PotentialBet> allPotentialBets,
      double targetTotalOdd,
      int maxSelectionsPerSlip) {
    /* ... implementação anterior ... */ return [];
  }
}
