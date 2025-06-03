// lib/domain/usecases/generate_suggested_slips_usecase.dart
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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
// lib/domain/usecases/generate_suggested_slips_usecase.dart
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

// Core

// Repositories
import '../repositories/football_repository.dart';
// Sub-UseCases
import 'get_league_standings_usecase.dart';
import 'get_referee_stats_usecase.dart';
import 'get_team_aggregated_stats_usecase.dart';
import 'search_referee_by_name_usecase.dart';
import 'get_fixture_lineups_usecase.dart';
import 'get_player_stats_usecase.dart';
import 'get_team_recent_fixtures_usecase.dart';

// Estrutura do resultado do UseCase
class PotentialBet {
  final Fixture fixture;
  final BetSelection selection;
  final double confidence;

  PotentialBet({
    required this.fixture,
    required this.selection,
    required this.confidence,
  });
}

// Estrutura do resultado do UseCase
class SlipGenerationResult {
  final List<PotentialBet> allPotentialBets;
  final List<SuggestedBetSlip> suggestedSlips;
  SlipGenerationResult(
      {required this.allPotentialBets, required this.suggestedSlips});
}

class GenerateSuggestedSlipsUseCase {
  final FootballRepository _footballRepository;
  final GetLeagueStandingsUseCase _getLeagueStandingsUseCase;
  final GetRefereeStatsUseCase _getRefereeStatsUseCase;
  final GetTeamAggregatedStatsUseCase _getTeamAggregatedStatsUseCase;
  final SearchRefereeByNameUseCase _searchRefereeByNameUseCase;
  final GetFixtureLineupsUseCase _getFixtureLineupsUseCase;
  final GetPlayerStatsUseCase _getPlayerStatsUseCase;
  final GetTeamRecentFixturesUseCase _getTeamRecentFixturesUseCase;

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
            GetTeamRecentFixturesUseCase(_footballRepository);

  Future<Either<Failure, SlipGenerationResult>> call({
    required List<Fixture> fixturesForToday,
    double targetTotalOdd = 7.0,
    int maxSelectionsPerSlip = 3,
  }) async {
    try {
      List<PotentialBet> allPotentialBets = [];
      if (fixturesForToday.isEmpty) {
        if (kDebugMode) print("GSSUC: Nenhum jogo para hoje.");
        return Right(
            SlipGenerationResult(allPotentialBets: [], suggestedSlips: []));
      }

      final List<Fixture> fixturesToProcess = fixturesForToday.length > 7
          ? fixturesForToday.sublist(0, 7)
          : fixturesForToday;
      if (kDebugMode)
        print("GSSUC: Processando ${fixturesToProcess.length} jogos.");

      for (var fixture in fixturesToProcess) {
        if (kDebugMode)
          print(
              "GSSUC: Coletando dados para ${fixture.id} (${fixture.homeTeam.name} vs ${fixture.awayTeam.name})");
        final dataResult = await _gatherDataForFixture(fixture);

        dataResult.fold(
          (failure) {
            if (kDebugMode)
              print(
                  "GSSUC: Falha ao obter DataForPrediction para ${fixture.id}: ${failure.message}");
          },
          (predictionData) {
            if (kDebugMode)
              print(
                  "GSSUC: Dados para ${fixture.id} COLETADOS. Analisando mercados...");
            allPotentialBets.addAll(_analyzeMarketsForFixture(predictionData));
          },
        );
      }

      if (allPotentialBets.isEmpty) {
        if (kDebugMode) print("GSSUC: Nenhuma aposta potencial gerada.");
        return Right(
            SlipGenerationResult(allPotentialBets: [], suggestedSlips: []));
      }

      List<SuggestedBetSlip> slips = _buildSlipsFromPotentialBets(
          allPotentialBets, targetTotalOdd, maxSelectionsPerSlip);
      return Right(SlipGenerationResult(
          allPotentialBets: allPotentialBets, suggestedSlips: slips));
    } catch (e, s) {
      if (kDebugMode) print("Erro GERAL em GSSUC.call: $e\n$s");
      return Left(UnknownFailure(
          message: "Erro crítico ao gerar bilhetes: ${e.toString()}"));
    }
  }

  Future<Either<Failure, DataForPrediction>> _gatherDataForFixture(
      Fixture fixture) async {
    try {
      final String currentSeason = fixture.league.season?.toString() ??
          DateFormatter.getYear(fixture.date);
      const int numRecentGames = 5;
      const int numH2HGames = 5;

      Future<Either<Failure, RefereeStats?>>
          fetchRefereeStatsWithSearch() async {
        if (fixture.refereeName != null && fixture.refereeName!.isNotEmpty) {
          final searchResult =
              await _searchRefereeByNameUseCase(name: fixture.refereeName!);
          return await searchResult
              .fold<Future<Either<Failure, RefereeStats?>>>(
            (failure) async =>
                Future.value(Left<Failure, RefereeStats?>(failure)),
            (refList) async {
              if (refList.isNotEmpty) {
                final foundRefereeId = refList.first.id;
                return (foundRefereeId != 0)
                    ? await _getRefereeStatsUseCase(
                        refereeId: foundRefereeId, season: currentSeason)
                    : Future.value(Left<Failure, RefereeStats?>(NoDataFailure(
                        message:
                            "ID do árbitro '${fixture.refereeName}' inválido (0).")));
              }
              return Future.value(Left<Failure, RefereeStats?>(NoDataFailure(
                  message:
                      "Árbitro '${fixture.refereeName}' não encontrado.")));
            },
          );
        }
        return Future.value(Left<Failure, RefereeStats?>(
            NoDataFailure(message: "Nome do árbitro não disponível.")));
      }

      final oddsResult =
          await _footballRepository.getOddsForFixture(fixture.id);
      if (oddsResult.isLeft())
        return Left(oddsResult.fold(
            (l) => l, (r) => UnknownFailure(message: 'Falha odds')));
      final List<PrognosticMarket> odds = oddsResult.getOrElse(() => []);
      if (odds.isEmpty)
        return Left(NoDataFailure(message: "Nenhuma odd para ${fixture.id}."));

      final lineupsResult = await _getFixtureLineupsUseCase(
          fixtureId: fixture.id,
          homeTeamId: fixture.homeTeam.id,
          awayTeamId: fixture.awayTeam.id);
      LineupsForFixture? lineups = lineupsResult.fold((l) => null, (r) => r);

      Map<int, PlayerSeasonStats> playerStatsMap = {};
      if (lineups?.areAvailable ?? false) {
        List<int> startingPlayerIds = [];
        lineups!.homeTeamLineup?.startingXI.forEach((player) {
          if (player.playerId != 0) startingPlayerIds.add(player.playerId);
        });
        lineups.awayTeamLineup?.startingXI.forEach((player) {
          if (player.playerId != 0) startingPlayerIds.add(player.playerId);
        });
        startingPlayerIds = startingPlayerIds.toSet().toList();
        if (startingPlayerIds.isNotEmpty) {
          final List<Future<Either<Failure, PlayerSeasonStats?>>>
              playerStatsFutures = startingPlayerIds
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
      }

      final List<Either<dynamic, dynamic>> otherDataResults =
          await Future.wait([
        _footballRepository.getFixtureStatistics(
            fixtureId: fixture.id,
            homeTeamId: fixture.homeTeam.id,
            awayTeamId: fixture.awayTeam.id), //0
        _footballRepository.getHeadToHead(
            team1Id: fixture.homeTeam.id,
            team2Id: fixture.awayTeam.id,
            lastN: numH2HGames,
            status: 'FT'), //1
        _getLeagueStandingsUseCase(
            leagueId: fixture.league.id, season: currentSeason), //2
        _getTeamRecentFixturesUseCase(
            teamId: fixture.homeTeam.id,
            lastN: numRecentGames,
            status: 'FT'), //3
        _getTeamRecentFixturesUseCase(
            teamId: fixture.awayTeam.id,
            lastN: numRecentGames,
            status: 'FT'), //4
        fetchRefereeStatsWithSearch(), //5
        _getTeamAggregatedStatsUseCase(
            teamId: fixture.homeTeam.id,
            leagueId: fixture.league.id,
            season: currentSeason), //6
        _getTeamAggregatedStatsUseCase(
            teamId: fixture.awayTeam.id,
            leagueId: fixture.league.id,
            season: currentSeason), //7
      ]);

      T? extractResult<T>(
          Either<Failure, T?> eitherResult, String dataTypeForLog) {
        return eitherResult.fold((l) {
          if (kDebugMode)
            print(
                "GSSUC _gatherData: Erro ao buscar $dataTypeForLog para ${fixture.id}: ${l.message}");
          return null;
        }, (r) => r);
      }

      return Right(DataForPrediction(
        fixture: fixture,
        odds: odds,
        lineups: lineups,
        playerSeasonStats: playerStatsMap.isNotEmpty ? playerStatsMap : null,
        fixtureStats: extractResult(
            otherDataResults[0] as Either<Failure, FixtureStatsEntity?>,
            "stats partida"),
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
      ));
    } catch (e, s) {
      if (kDebugMode)
        print(
            "Erro catastrófico em _gatherDataForFixture ${fixture.id}: $e\n$s");
      return Left(UnknownFailure(
          message:
              "Erro ao coletar dados para ${fixture.id}: ${e.toString()}"));
    }
  }

  // --- FUNÇÕES HELPER DE CÁLCULO ---
  int _factorial(int n) {
    if (n < 0) return 1;
    if (n == 0) return 1;
    int r = 1;
    for (int i = 1; i <= n; i++) r *= i;
    return r;
  }

  double _poissonProbability(double lambda, int k) {
    if (lambda <= 0.01) return (k == 0 ? 1.0 : 0.0);
    if (k > 10 && lambda < 0.5) return 0.0;
    try {
      var p = (pow(lambda, k) * exp(-lambda)) / _factorial(k);
      return p.isNaN || p.isInfinite ? 0.0 : p;
    } catch (e) {
      return 0.0;
    }
  }

  Map<String, double> _calculatePoissonScoreProbabilities(
      double lambdaHome, double lambdaAway,
      {int maxGoals = 4}) {
    Map<String, double> p = {};
    if (lambdaHome <= 0.01 && lambdaAway <= 0.01) {
      p["0-0"] = 1.0;
      return p;
    }
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
    if (t1w > t2w && t1w >= (h2hFixtures.length * 0.55).ceil()) return 1;
    if (t2w > t1w && t2w >= (h2hFixtures.length * 0.55).ceil()) return -1;
    return 0;
  }

  // --- MÉTODOS DE ANÁLISE DE MERCADO ---
  List<PotentialBet> _analyzeMarketsForFixture(DataForPrediction data) {
    List<PotentialBet> potentialBets = [];
    if (data.odds.isEmpty) {
      if (kDebugMode)
        print("GSSUC _analyzeMarkets: Nenhuma odd para ${data.fixture.id}.");
      return potentialBets;
    }
    _analyzeMatchWinnerMarket(data, potentialBets);
    _analyzeGoalsOverUnderMarket(data, potentialBets);
    _analyzeBothTeamsToScoreMarket(data, potentialBets);
    _analyzeCornersMarket(data, potentialBets);
    _analyzeCardsMarket(data, potentialBets);
    _analyzeAnytimeGoalscorerMarket(data, potentialBets);
    return potentialBets;
  }

  void _analyzeMatchWinnerMarket(
      DataForPrediction data, List<PotentialBet> bets) {
    final fixture = data.fixture;
    final odds1X2 = data.odds.firstWhereOrNull((o) =>
        o.marketId == 1 && o.marketName.toLowerCase().contains("match winner"));
    if (odds1X2 == null) return;

    double probHomeWinPoisson = 0.0,
        probDrawPoisson = 0.0,
        probAwayWinPoisson = 0.0;
    double finalProbHome = 0.33,
        finalProbDraw = 0.34,
        finalProbAway = 0.33; // Fallbacks
    double scoreHome = 0.0, scoreAway = 0.0;
    List<String> reasonsHome = [], reasonsAway = [], reasonsDraw = [];

    double? xgHome = data.fixtureStats?.homeTeam?.expectedGoals;
    double? xgAway = data.fixtureStats?.awayTeam?.expectedGoals;
    bool xgValidForPoisson =
        xgHome != null && xgAway != null && xgHome >= 0.05 && xgAway >= 0.05;

    if (xgValidForPoisson) {
      Map<String, double> scoreProbs =
          _calculatePoissonScoreProbabilities(xgHome!, xgAway!, maxGoals: 4);
      scoreProbs.forEach((score, prob) {
        final s = score.split('-').map(int.parse).toList();
        if (s[0] > s[1])
          probHomeWinPoisson += prob;
        else if (s[0] == s[1])
          probDrawPoisson += prob;
        else
          probAwayWinPoisson += prob;
      });
      String xgReason =
          "Poisson(xG ${xgHome.toStringAsFixed(1)}-${xgAway.toStringAsFixed(1)})";
      if (probHomeWinPoisson > 0.001 ||
          probDrawPoisson > 0.001 ||
          probAwayWinPoisson > 0.001) {
        reasonsHome.add(
            "$xgReason P(H):${(probHomeWinPoisson * 100).toStringAsFixed(0)}%");
        reasonsAway.add(
            "$xgReason P(A):${(probAwayWinPoisson * 100).toStringAsFixed(0)}%");
        reasonsDraw.add(
            "$xgReason P(D):${(probDrawPoisson * 100).toStringAsFixed(0)}%");
      }
      if (probHomeWinPoisson > probAwayWinPoisson + 0.08)
        scoreHome +=
            2.0 * (probHomeWinPoisson - probAwayWinPoisson).clamp(0, 1);
      else if (probAwayWinPoisson > probHomeWinPoisson + 0.08)
        scoreAway +=
            2.0 * (probAwayWinPoisson - probHomeWinPoisson).clamp(0, 1);
      else if ((probHomeWinPoisson - probAwayWinPoisson).abs() < 0.05 &&
          probDrawPoisson > 0.25) {
        scoreHome += 0.1;
        scoreAway += 0.1;
      }
    } else {/* ... fallback com médias de gols agregados ... */}

    // ... (lógica para Classificação, Forma, H2H como na resposta anterior, adicionando a reasonsHome/Away/Draw) ...
    int? homeR = data.leagueStandings
        ?.firstWhereOrNull((s) => s.teamId == fixture.homeTeam.id)
        ?.rank;
    int? awayR = data.leagueStandings
        ?.firstWhereOrNull((s) => s.teamId == fixture.awayTeam.id)
        ?.rank;
    if (homeR != null && awayR != null) {
      /* ... add to scores and reasons ... */
    }

    int homeFP =
        _calculateFormPoints(data.homeTeamRecentFixtures, fixture.homeTeam.id);
    int awayFP =
        _calculateFormPoints(data.awayTeamRecentFixtures, fixture.awayTeam.id);
    if ((data.homeTeamRecentFixtures?.length ?? 0) >= 3 &&
        (data.awayTeamRecentFixtures?.length ?? 0) >= 3) {
      /* ... add to scores and reasons ... */
    }

    int h2hD = _analyzeH2HScore(
        data.h2hFixtures, fixture.homeTeam.id, fixture.awayTeam.id);
    if (h2hD == 1) {/* ... */} else if (h2hD == -1) {/* ... */} else {/* ... */}

    // Normalizar scores e combinar com Poisson para probabilidades finais
    double totalScoreForProbs = (scoreHome.abs() + scoreAway.abs()) +
        1.2; // Evita zero, dá peso base ao empate
    if (totalScoreForProbs < 0.1) totalScoreForProbs = 1.2; // Mínimo divisor

    double pHomeFromFactors = (scoreHome + 0.4) / totalScoreForProbs;
    double pAwayFromFactors = (scoreAway + 0.4) / totalScoreForProbs;
    double pDrawFromFactors =
        (1.0 - pHomeFromFactors - pAwayFromFactors).clamp(0.05, 0.55);

    double sumP = pHomeFromFactors + pAwayFromFactors + pDrawFromFactors;
    if (sumP > 0.01) {
      pHomeFromFactors /= sumP;
      pAwayFromFactors /= sumP;
      pDrawFromFactors /= sumP;
    }

    finalProbHome = xgValidForPoisson
        ? (probHomeWinPoisson * 0.6 + pHomeFromFactors * 0.4)
        : pHomeFromFactors;
    finalProbAway = xgValidForPoisson
        ? (probAwayWinPoisson * 0.6 + pAwayFromFactors * 0.4)
        : pAwayFromFactors;
    finalProbDraw = xgValidForPoisson
        ? (probDrawPoisson * 0.6 + pDrawFromFactors * 0.4)
        : pDrawFromFactors;

    double finalSum = finalProbHome + finalProbDraw + finalProbAway;
    if (finalSum > 0.01) {
      finalProbHome /= finalSum;
      finalProbDraw /= finalSum;
      finalProbAway /= finalSum;
    } else {
      finalProbHome = 0.35;
      finalProbDraw = 0.30;
      finalProbAway = 0.35;
    }

    final OddOption? homeOpt = odds1X2.options
        .firstWhereOrNull((o) => o.label.toLowerCase() == "home");
    final OddOption? drawOpt = odds1X2.options
        .firstWhereOrNull((o) => o.label.toLowerCase() == "draw");
    final OddOption? awayOpt = odds1X2.options
        .firstWhereOrNull((o) => o.label.toLowerCase() == "away");
    BetSelection? chosenSel;
    String fReason = "";
    double conf = 0.50;
    const double scoreDiffThresh = 1.5;
    const double minOddW = 1.30;
    const double minOddD = 2.55;

    if (scoreHome > scoreAway + scoreDiffThresh && homeOpt != null) {
      chosenSel = BetSelection(
          marketName: odds1X2.marketName,
          selectionName: homeOpt.label,
          odd: homeOpt.odd);
      fReason =
          "Casa: ${reasonsHome.where((r) => !r.contains("N/D")).take(3).join('; ')}.";
      conf = 0.55 +
          (scoreHome - scoreAway - scoreDiffThresh) * 0.045 +
          (finalProbHome > 0.50 ? 0.08 : 0);
    } else if (scoreAway > scoreHome + scoreDiffThresh && awayOpt != null) {
      chosenSel = BetSelection(
          marketName: odds1X2.marketName,
          selectionName: awayOpt.label,
          odd: awayOpt.odd);
      fReason =
          "Vis.: ${reasonsAway.where((r) => !r.contains("N/D")).take(3).join('; ')}.";
      conf = 0.55 +
          (scoreAway - scoreHome - scoreDiffThresh) * 0.045 +
          (finalProbAway > 0.50 ? 0.08 : 0);
    } else if ((scoreHome - scoreAway).abs() < 1.0 &&
        reasonsDraw.where((r) => !r.contains("N/D")).length >= 2 &&
        drawOpt != null) {
      chosenSel = BetSelection(
          marketName: odds1X2.marketName,
          selectionName: drawOpt.label,
          odd: drawOpt.odd);
      fReason =
          "Empate: ${reasonsDraw.where((r) => !r.contains("N/D")).take(2).join('; ')}.";
      conf = 0.55 +
          (finalProbDraw > 0.28 ? 0.07 : 0) -
          (scoreHome - scoreAway).abs() * 0.04;
    }

    if (chosenSel != null) {
      double calcProb = 0.0;
      if (chosenSel.selectionName.toLowerCase() == "home")
        calcProb = finalProbHome;
      else if (chosenSel.selectionName.toLowerCase() == "away")
        calcProb = finalProbAway;
      else if (chosenSel.selectionName.toLowerCase() == "draw")
        calcProb = finalProbDraw;
      calcProb = calcProb.clamp(0.05, 0.95);
      conf = conf.clamp(0.50, 0.88);

      double oddV = double.tryParse(chosenSel.odd) ?? 100.0;
      bool passesOddThold = (chosenSel.selectionName.toLowerCase() == "draw")
          ? (oddV >= minOddD)
          : (oddV >= minOddW);
      if (!passesOddThold || oddV > 7.5) return;

      double impliedP = 1 / oddV;
      if (calcProb > (impliedP + 0.025) ||
          (calcProb > impliedP && conf > 0.60)) {
        bets.add(PotentialBet(
            fixture: fixture,
            selection: chosenSel.copyWith(
                reasoning: fReason.trim().replaceAll(RegExp(r';\s*$'), ''),
                probability: calcProb),
            confidence: conf));
      }
    }
  }

  void _analyzeGoalsOverUnderMarket(
      DataForPrediction data, List<PotentialBet> bets) {
    final fixture = data.fixture;
    final oddsMarket = data.odds.firstWhereOrNull(
        (o) => o.marketName.toLowerCase().contains("goals over/under"));
    if (oddsMarket == null) return;
    double? xgHome = data.fixtureStats?.homeTeam?.expectedGoals;
    double? xgAway = data.fixtureStats?.awayTeam?.expectedGoals;
    if (xgHome == null || xgAway == null || xgHome <= 0.01 || xgAway <= 0.01)
      return;
    double totalXG = xgHome + xgAway;
    Map<String, double> scoreProbs =
        _calculatePoissonScoreProbabilities(xgHome, xgAway, maxGoals: 6);
    for (var option in oddsMarket.options) {
      String labelLower = option.label.toLowerCase();
      if (labelLower.startsWith("over ") || labelLower.startsWith("under ")) {
        try {
          double line = double.parse(
              labelLower.replaceAll("over ", "").replaceAll("under ", ""));
          double probForLine = 0.0;
          if (labelLower.startsWith("over ")) {
            scoreProbs.forEach((s, p) {
              final sc = s.split('-').map(int.parse).toList();
              if ((sc[0] + sc[1]) > line) probForLine += p;
            });
          } else {
            scoreProbs.forEach((s, p) {
              final sc = s.split('-').map(int.parse).toList();
              if ((sc[0] + sc[1]) < line) probForLine += p;
            });
          }
          probForLine = probForLine.clamp(0.01, 0.99);
          double oddVal = double.tryParse(option.odd) ?? 100.0;
          if (oddVal < 1.40 || oddVal > 3.2) continue;
          double impliedProb = 1 / oddVal;
          if (probForLine > (impliedProb + 0.05)) {
            // Valor de 5%
            bets.add(PotentialBet(
                fixture: fixture,
                selection: BetSelection(
                    marketName: oddsMarket.marketName,
                    selectionName: option.label,
                    odd: option.odd,
                    reasoning:
                        "Poisson(xG Tot:${totalXG.toStringAsFixed(1)}) P(${(probForLine * 100).toStringAsFixed(0)}%) ${option.label}",
                    probability: probForLine),
                confidence: (0.58 + (probForLine - impliedProb) * 1.7)
                    .clamp(0.58, 0.85)));
          }
        } catch (e) {
          continue;
        }
      }
    }
  }

  void _analyzeBothTeamsToScoreMarket(
      DataForPrediction data, List<PotentialBet> bets) {
    final fixture = data.fixture;
    final oddsBTTS = data.odds.firstWhereOrNull((o) => o.marketId == 12);
    if (oddsBTTS == null) return;
    double? xgHome = data.fixtureStats?.homeTeam?.expectedGoals;
    double? xgAway = data.fixtureStats?.awayTeam?.expectedGoals;
    if (xgHome == null || xgAway == null || xgHome <= 0.01 || xgAway <= 0.01)
      return;
    double probH0 = _poissonProbability(xgHome, 0);
    double probA0 = _poissonProbability(xgAway, 0);
    double pYes = (1 - probH0) * (1 - probA0);
    double pNo =
        probH0 * (1 - probA0) + probA0 * (1 - probH0) + probH0 * probA0;
    double sumP = pYes + pNo;
    if (sumP > 0.01) {
      pYes /= sumP;
      pNo /= sumP;
    } else {
      pYes = 0.5;
      pNo = 0.5;
    }
    final yesOpt = oddsBTTS.options
        .firstWhereOrNull((o) => o.label.toLowerCase() == "yes");
    final noOpt =
        oddsBTTS.options.firstWhereOrNull((o) => o.label.toLowerCase() == "no");
    if (yesOpt != null) {
      double oV = double.tryParse(yesOpt.odd) ?? 100;
      if (oV >= 1.4 && oV <= 2.8) {
        double iP = 1 / oV;
        if (pYes > (iP + 0.04)) {
          bets.add(PotentialBet(
              fixture: fixture,
              selection: BetSelection(
                  marketName: oddsBTTS.marketName,
                  selectionName: yesOpt.label,
                  odd: yesOpt.odd,
                  reasoning:
                      "Poisson(xG H:${xgHome.toStringAsFixed(1)},A:${xgAway.toStringAsFixed(1)}) P(${(pYes * 100).toStringAsFixed(0)}%) Sim",
                  probability: pYes.clamp(0.01, 0.99)),
              confidence: (0.60 + (pYes - iP) * 1.6).clamp(0.60, 0.87)));
        }
      }
    }
    if (noOpt != null) {
      double oV = double.tryParse(noOpt.odd) ?? 100;
      if (oV >= 1.4 && oV <= 2.8) {
        double iP = 1 / oV;
        if (pNo > (iP + 0.04)) {
          bets.add(PotentialBet(
              fixture: fixture,
              selection: BetSelection(
                  marketName: oddsBTTS.marketName,
                  selectionName: noOpt.label,
                  odd: noOpt.odd,
                  reasoning:
                      "Poisson(xG H:${xgHome.toStringAsFixed(1)},A:${xgAway.toStringAsFixed(1)}) P(${(pNo * 100).toStringAsFixed(0)}%) Não",
                  probability: pNo.clamp(0.01, 0.99)),
              confidence: (0.60 + (pNo - iP) * 1.6).clamp(0.60, 0.87)));
        }
      }
    }
  }

  void _analyzeCornersMarket(DataForPrediction data, List<PotentialBet> bets) {
    final fixture = data.fixture;
    final oddsMarket = data.odds.firstWhereOrNull((o) =>
        o.marketName.toLowerCase().contains("corners over/under") ||
        o.marketId == 6);
    if (oddsMarket == null) return;
    double? avgHG =
        data.homeTeamAggregatedStats?.averageCornersGeneratedPerGame;
    double? avgHC = data.homeTeamAggregatedStats?.averageCornersConcededPerGame;
    double? avgAG =
        data.awayTeamAggregatedStats?.averageCornersGeneratedPerGame;
    double? avgAC = data.awayTeamAggregatedStats?.averageCornersConcededPerGame;
    String warn = "";
    if (avgHG == null || avgHC == null || avgAG == null || avgAC == null) {
      warn = " (Aviso: médias fallback)";
      avgHG ??= 5.1;
      avgHC ??= 5.4;
      avgAG ??= 4.2;
      avgAC ??= 5.9;
    }
    double expTotal = ((avgHG + avgAC) / 2.0) + ((avgAG + avgHC) / 2.0);
    String rBasis = "Est. Cantos: ${expTotal.toStringAsFixed(1)}$warn";
    for (var opt in oddsMarket.options) {
      String lblL = opt.label.toLowerCase();
      if (lblL.startsWith("over ") || lblL.startsWith("under ")) {
        try {
          double line = double.parse(
              lblL.replaceAll("over ", "").replaceAll("under ", ""));
          _checkGenericLine(fixture, oddsMarket, expTotal, line, bets, rBasis,
              marketType: "Escanteios", specificOption: opt);
        } catch (e) {
          continue;
        }
      }
    }
  }

  void _analyzeCardsMarket(DataForPrediction data, List<PotentialBet> bets) {
    final fixture = data.fixture;
    final oddsMarket = data.odds.firstWhereOrNull((o) =>
        o.marketName.toLowerCase().contains("card") ||
        o.marketId == 11 ||
        o.marketId == 46);
    if (oddsMarket == null) return;
    final referee = data.refereeStats;
    if (referee == null || (referee.gamesOfficiatedInCalculation) < 3) return;
    double avgHY =
        data.homeTeamAggregatedStats?.averageYellowCardsPerGame ?? 1.9;
    double avgAY =
        data.awayTeamAggregatedStats?.averageYellowCardsPerGame ?? 2.1;
    double avgRY = referee.averageYellowCardsPerGame;
    double expY = (avgHY * 0.28) + (avgAY * 0.28) + (avgRY * 0.44);
    expY = (expY * 10).round() / 10;
    String rBasis =
        "Est. Amarelos: ${expY.toStringAsFixed(1)} (Árb: ${referee.refereeName})";
    for (var opt in oddsMarket.options) {
      String lblL = opt.label.toLowerCase();
      if (lblL.startsWith("over ") || lblL.startsWith("under ")) {
        try {
          double line = double.parse(lblL.replaceAll(RegExp(r'[^0-9.]'), ''));
          _checkGenericLine(fixture, oddsMarket, expY, line, bets, rBasis,
              marketType: "Cartões", specificOption: opt);
        } catch (e) {}
      }
    }
  }

  void _analyzeAnytimeGoalscorerMarket(
      DataForPrediction data, List<PotentialBet> bets) {
    final fixture = data.fixture;
    final lineups = data.lineups;
    final playerStatsMap = data.playerSeasonStats;
    final oddsMarket = data.odds.firstWhereOrNull((o) =>
        o.marketName.toLowerCase().contains("goalscorer") &&
        !o.marketName.toLowerCase().contains("first") &&
        !o.marketName.toLowerCase().contains("last") &&
        !o.marketName.toLowerCase().contains("2 or more") &&
        !o.marketName.toLowerCase().contains("hat-trick") &&
        !o.marketName.toLowerCase().contains("assist"));
    if (oddsMarket == null ||
        lineups == null ||
        !lineups.areAvailable ||
        playerStatsMap == null) return;
    List<PlayerInLineup> starters = [];
    starters.addAll(lineups.homeTeamLineup?.startingXI ?? []);
    starters.addAll(lineups.awayTeamLineup?.startingXI ?? []);
    if (starters.isEmpty) return;

    for (var oddOpt in oddsMarket.options) {
      final pNameOdds = oddOpt.label;
      final oddVal = double.tryParse(oddOpt.odd) ?? 100.0;
      if (oddVal > 5.0 || oddVal < 1.70) continue;
      PlayerInLineup? starter = starters.firstWhereOrNull((p) =>
          p.playerName.toLowerCase() == pNameOdds.toLowerCase() ||
          p.playerName.toLowerCase().contains(pNameOdds.toLowerCase()) ||
          pNameOdds.toLowerCase().contains(p.playerName
              .split(" ")
              .lastWhere((s) => s.length > 1, orElse: () => "")
              .toLowerCase()));
      if (starter == null || starter.playerId == 0) continue;
      PlayerSeasonStats? pS = playerStatsMap[starter.playerId];
      if (pS == null && !(starter.position?.toUpperCase() == "F")) continue;
      double prop = 0.04;
      String rsn = "Titular(${starter.position ?? 'N/A'})";
      bool hasOS = false;
      if (pS != null) {
        double xgi90 = pS.xaIndividualPer90;
        double xa90 = pS.xaIndividualPer90;
        if (xgi90 > 0.22) {
          prop = xgi90 * 0.89;
          rsn += ", xGi/90:${xgi90.toStringAsFixed(2)}";
          hasOS = true;
        } else if (pS.goalsPer90 > 0.26) {
          prop = pS.goalsPer90 * 0.72;
          rsn += ", G/90:${pS.goalsPer90.toStringAsFixed(2)}";
          hasOS = true;
        }
        if (xa90 > 0.12 && prop > 0.05) {
          prop += xa90 * 0.20;
          rsn += ", xA/90:${xa90.toStringAsFixed(2)}";
        }
      }
      if (!hasOS && (starter.position?.toUpperCase() ?? "") == "F")
        prop = 0.09;
      else if (!hasOS) continue;
      bool isH = lineups.homeTeamLineup?.startingXI
              .any((p) => p.playerId == starter.playerId) ??
          false;
      double? tXG = isH
          ? data.fixtureStats?.homeTeam?.expectedGoals
          : data.fixtureStats?.awayTeam?.expectedGoals;
      double? oXGA = isH
          ? data.fixtureStats?.awayTeam?.expectedGoals
          : data.fixtureStats?.homeTeam?.expectedGoals;
      if (tXG != null) {
        if (tXG > 1.68)
          prop *= 1.12;
        else if (tXG < 1.05) prop *= 0.88;
      }
      if (oXGA != null) {
        if (oXGA > 1.68)
          prop *= 1.07;
        else if (oXGA < 1.05) prop *= 0.93;
      }
      if (prop > 0.09) {
        double iOP = 1 / oddVal;
        if (prop > (iOP + 0.03)) {
          bets.add(PotentialBet(
              fixture: fixture,
              selection: BetSelection(
                  marketName: "Jogador Marca",
                  selectionName: pNameOdds,
                  odd: oddOpt.odd,
                  reasoning: "$rsn. P(${(prop * 100).toStringAsFixed(0)}%)",
                  probability: prop.clamp(0.01, 0.99)),
              confidence: (0.50 + (prop - iOP) * 2.2).clamp(0.50, 0.80)));
        }
      }
    }
  }

  void _checkGenericLine(
      Fixture fixture,
      PrognosticMarket marketData,
      double expectedValue,
      double lineValueFromLabel,
      List<PotentialBet> bets,
      String reasoningBasis,
      {String marketType = "Genérico",
      required OddOption specificOption}) {
    final String optionLabelLower = specificOption.label.toLowerCase();
    final bool isOver = optionLabelLower.startsWith("over ");
    final bool isUnder = optionLabelLower.startsWith("under ");
    if (!isOver && !isUnder) return;

    double oddValue = double.tryParse(specificOption.odd) ?? 100.0;
    double threshold =
        marketType.toLowerCase().contains("cartões") ? 0.55 : 0.75;
    double minOdd = 1.48, maxOdd = 3.8; // Aumentada a odd máxima aceitável

    double calcProb = 0.5;
    if (isOver)
      calcProb = 0.5 + (expectedValue - lineValueFromLabel) * 0.12;
    else
      calcProb = 0.5 + (lineValueFromLabel - expectedValue) * 0.12;
    calcProb = calcProb.clamp(0.05, 0.95);

    double impliedOddProb = 1 / oddValue;

    if (oddValue >= minOdd && oddValue <= maxOdd) {
      bool conditionMet = false;
      if (isOver && expectedValue > (lineValueFromLabel + threshold))
        conditionMet = true;
      else if (isUnder && expectedValue < (lineValueFromLabel - threshold))
        conditionMet = true;

      // Sugerir se a probabilidade calculada tiver um "edge" (vantagem) sobre a odd implícita
      if (conditionMet && calcProb > (impliedOddProb + 0.04)) {
        // Ex: nossa prob 4% maior
        bets.add(PotentialBet(
            fixture: fixture,
            selection: BetSelection(
                marketName: marketData.marketName,
                selectionName: specificOption.label,
                odd: specificOption.odd,
                reasoning:
                    "$reasoningBasis (${expectedValue.toStringAsFixed(1)}). P(${(calcProb * 100).toStringAsFixed(0)}%)",
                probability: calcProb),
            // Confiança baseada na diferença entre prob calculada e implícita, e no threshold
            confidence: (0.55 +
                    (calcProb - impliedOddProb) * 1.8 +
                    ((isOver
                            ? expectedValue - (lineValueFromLabel + threshold)
                            : (lineValueFromLabel - threshold) -
                                expectedValue) *
                        0.05))
                .clamp(0.55, 0.87)));
      }
    }
  }

  List<SuggestedBetSlip> _buildSlipsFromPotentialBets(
      List<PotentialBet> allPotentialBets,
      double targetTotalOdd,
      int maxSelectionsPerSlip) {
    List<SuggestedBetSlip> builtSlips = [];
    if (allPotentialBets.isEmpty) return builtSlips;
    allPotentialBets.sort((a, b) => b.confidence.compareTo(a.confidence));

    for (int numSel = 2; numSel <= maxSelectionsPerSlip; numSel++) {
      if (allPotentialBets.length < numSel) continue;
      List<PotentialBet> currentSelections = [];
      Set<int> usedFixtures = {};
      double currentOddProduct = 1.0;
      for (var bet in allPotentialBets) {
        if (currentSelections.length == numSel) break;
        if (!usedFixtures.contains(bet.fixture.id) &&
            bet.confidence >= (numSel == 2 ? 0.67 : 0.61) &&
            bet.selection.oddValue >= (numSel == 2 ? 1.36 : 1.31)) {
          currentSelections.add(bet);
          usedFixtures.add(bet.fixture.id);
          currentOddProduct *= bet.selection.oddValue;
        }
      }
      if (currentSelections.length == numSel &&
          currentOddProduct >= (numSel == 2 ? 1.80 : 2.25)) {
        String title = numSel == 2 ? "Dupla Analisada 🛡️" : "Trio Analisado ✨";
        if (builtSlips.any((s) => s.title == title))
          title += " (${(currentOddProduct).toStringAsFixed(1)})";
        if (builtSlips.any((s) => s.title == title)) continue;
        builtSlips.add(SuggestedBetSlip(
            title: title,
            fixturesInvolved:
                currentSelections.map((e) => e.fixture).toSet().toList(),
            selections: currentSelections.map((e) => e.selection).toList(),
            totalOddsDisplay: currentOddProduct.toStringAsFixed(2),
            dateGenerated: DateTime.now(),
            overallReasoning:
                "Combinação de ${numSel} seleções com boa confiança e odds.",
            totalOdds: ''));
      }
    }

    List<PotentialBet> targetOddSelectionsAttempt = [];
    Set<int> usedFixturesTargetAttempt = {};
    double currentOddTargetAttempt = 1.0;
    List candidates = List.from(allPotentialBets)
        .where((b) => b.selection.oddValue >= 1.28 && b.confidence >= 0.56)
        .toList();
    candidates.sort((a, b) {
      double probA = a.selection.probability ??
          (1 / (a.selection.oddValue == 0 ? 100 : a.selection.oddValue) * 0.75);
      double probB = b.selection.probability ??
          (1 / (b.selection.oddValue == 0 ? 100 : b.selection.oddValue) * 0.75);
      double scoreA = a.confidence * a.selection.oddValue * probA;
      double scoreB = b.confidence * b.selection.oddValue * probB;
      return scoreB.compareTo(scoreA);
    });
    for (var bet in candidates) {
      if (targetOddSelectionsAttempt.length < maxSelectionsPerSlip &&
          !usedFixturesTargetAttempt.contains(bet.fixture.id)) {
        if ((currentOddTargetAttempt * bet.selection.oddValue) <=
                (targetTotalOdd * 2.0) ||
            targetOddSelectionsAttempt.length < 2) {
          targetOddSelectionsAttempt.add(bet);
          usedFixturesTargetAttempt.add(bet.fixture.id);
          currentOddTargetAttempt *= bet.selection.oddValue;
        }
      }
      if (targetOddSelectionsAttempt.length >= 2 &&
          targetOddSelectionsAttempt.length <= maxSelectionsPerSlip &&
          currentOddTargetAttempt >= (targetTotalOdd * 0.88)) break;
      if (targetOddSelectionsAttempt.length == maxSelectionsPerSlip) break;
    }
    if (targetOddSelectionsAttempt.length >= 2 &&
        targetOddSelectionsAttempt.length <= maxSelectionsPerSlip &&
        currentOddTargetAttempt >= (targetTotalOdd * 0.68)) {
      String title =
          "Múltipla Alvo (${currentOddTargetAttempt.toStringAsFixed(1)}) 🎯";
      if (builtSlips.any((s) => s.title.startsWith("Múltipla Alvo")))
        title +=
            " #${builtSlips.where((s) => s.title.startsWith("Múltipla Alvo")).length + 1}";
      if (!builtSlips.any((s) => s.title == title)) {
        builtSlips.add(SuggestedBetSlip(
            title: title,
            fixturesInvolved: targetOddSelectionsAttempt
                .map((e) => e.fixture)
                .toSet()
                .toList(),
            selections:
                targetOddSelectionsAttempt.map((e) => e.selection).toList(),
            totalOddsDisplay: currentOddTargetAttempt.toStringAsFixed(2),
            dateGenerated: DateTime.now(),
            overallReasoning:
                "Combinação buscando odd alvo com análise e confiança.",
            totalOdds: ''));
      }
    }

    builtSlips.removeWhere((slip) {
      bool isReliable =
          slip.title.contains("Analisada") || slip.title.contains("Confiável");
      if (isReliable) return slip.selections.length < 2;
      return slip.selections.length < 2 || slip.totalOddsValue < 1.80;
    });
    builtSlips.sort((a, b) {
      if (a.selections.length != b.selections.length)
        return b.selections.length.compareTo(a.selections.length);
      return b.totalOddsValue.compareTo(a.totalOddsValue);
    });
    return builtSlips.take(4).toList();
  }

  // Helper para debug (opcional)
  void _printDataForPrediction(DataForPrediction data) {
    if (!kDebugMode) return;
    print("----------------------------------------------------------");
    print("--- DataForPrediction para Fixture ID: ${data.fixture.id} ---");
    print(
        "  Times: ${data.fixture.homeTeam.name} vs ${data.fixture.awayTeam.name}");
    print("  Odds: ${data.odds.length} mercados.");
    print(
        "  Lineups: ${data.lineups?.areAvailable ?? false ? 'Disponíveis' : 'Ausentes'}");
    print("  Player Stats (Titulares): ${data.playerSeasonStats?.length ?? 0}");
    print(
        "  Fixture Stats: ${data.fixtureStats != null ? 'xG H:${data.fixtureStats?.homeTeam?.expectedGoals?.toStringAsFixed(2)} A:${data.fixtureStats?.awayTeam?.expectedGoals?.toStringAsFixed(2)}' : 'Ausente'}");
    print("  H2H: ${data.h2hFixtures?.length ?? 'N/A'} jogos.");
    print("  Standings: ${data.leagueStandings?.length ?? 'N/A'} times.");
    print(
        "  Home Form: ${data.homeTeamRecentFixtures?.length ?? 'N/A'} jogos.");
    print(
        "  Away Form: ${data.awayTeamRecentFixtures?.length ?? 'N/A'} jogos.");
    print(
        "  Referee: ${data.refereeStats?.refereeName ?? 'N/A'} (AvgCards Y:${data.refereeStats?.averageYellowCardsPerGame.toStringAsFixed(2)})");
    print(
        "  Home Agg Stats: ${data.homeTeamAggregatedStats != null ? 'Presente' : 'Ausente'} (Form: ${data.homeTeamAggregatedStats?.formStreak}, AvgGoalsS: ${data.homeTeamAggregatedStats?.averageGoalsScoredPerGame?.toStringAsFixed(2)})");
    print(
        "  Away Agg Stats: ${data.awayTeamAggregatedStats != null ? 'Presente' : 'Ausente'} (Form: ${data.awayTeamAggregatedStats?.formStreak}, AvgGoalsS: ${data.awayTeamAggregatedStats?.averageGoalsScoredPerGame?.toStringAsFixed(2)})");
    print("----------------------------------------------------------\n");
  }
}
