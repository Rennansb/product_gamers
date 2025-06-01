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
class SlipGenerationResult {
  final List<PotentialBet>
      allPotentialBets; // Todas as apostas individuais analisadas
  final List<SuggestedBetSlip>
      suggestedSlips; // Os bilhetes acumulados construídos

  SlipGenerationResult({
    required this.allPotentialBets,
    required this.suggestedSlips,
  });
}

// Classe auxiliar para guardar uma aposta potencial
class PotentialBet {
  final Fixture fixture;
  final BetSelection
      selection; // BetSelection já inclui a 'probability' calculada
  final double
      confidence; // 0.0 a 1.0 (Quão "forte" é o sinal para esta aposta)

  PotentialBet({
    required this.fixture,
    required this.selection,
    required this.confidence,
  });
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
        if (kDebugMode) print("GSSUC: Nenhum jogo para hoje fornecido.");
        // Retorna o novo tipo de resultado com listas vazias
        return Right(
            SlipGenerationResult(allPotentialBets: [], suggestedSlips: []));
      }

      final List<Fixture> fixturesToProcess = fixturesForToday.length > 8
          ? fixturesForToday.sublist(0, 8)
          : fixturesForToday;
      if (kDebugMode)
        print(
            "GSSUC: Processando ${fixturesToProcess.length} jogos para bilhetes.");

      for (var fixture in fixturesToProcess) {
        // ... (lógica para chamar _gatherDataForFixture e _analyzeMarketsForFixture)
        // ... (como na sua versão completa mais recente do GSSUC)
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
        // Retorna o novo tipo de resultado com listas vazias
        return Right(
            SlipGenerationResult(allPotentialBets: [], suggestedSlips: []));
      }

      if (kDebugMode)
        print("GSSUC: Total de apostas potenciais: ${allPotentialBets.length}");

      List<SuggestedBetSlip> slips = _buildSlipsFromPotentialBets(
          allPotentialBets, targetTotalOdd, maxSelectionsPerSlip);
      if (kDebugMode) print("GSSUC: Bilhetes construídos: ${slips.length}");

      // Retorna o objeto SlipGenerationResult
      return Right(SlipGenerationResult(
          allPotentialBets: allPotentialBets, suggestedSlips: slips));
    } catch (e, s) {
      if (kDebugMode)
        print("Erro GERAL em GenerateSuggestedSlipsUseCase.call: $e\n$s");
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
            (failure) async => Left<Failure, RefereeStats?>(failure),
            (refList) async {
              if (refList.isNotEmpty) {
                final foundRefereeId = refList.first.id;
                if (foundRefereeId != 0) {
                  return await _getRefereeStatsUseCase(
                      refereeId: foundRefereeId, season: currentSeason);
                } else {
                  return Left<Failure, RefereeStats?>(NoDataFailure(
                      message:
                          "ID do árbitro '${fixture.refereeName}' inválido (0)."));
                }
              }
              return Left<Failure, RefereeStats?>(NoDataFailure(
                  message:
                      "Árbitro '${fixture.refereeName}' não encontrado via busca."));
            },
          );
        }
        return Left<Failure, RefereeStats?>(NoDataFailure(
            message: "Nome do árbitro não disponível no fixture."));
      }

      final oddsResult =
          await _footballRepository.getOddsForFixture(fixture.id);
      if (oddsResult.isLeft())
        return Left(oddsResult.fold(
            (l) => l, (r) => UnknownFailure(message: 'Falha ao buscar odds.')));
      final List<PrognosticMarket> odds = oddsResult.getOrElse(() => []);
      if (odds.isEmpty)
        return Left(NoDataFailure(
            message: "Nenhuma odd encontrada para o jogo ${fixture.id}."));

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
            awayTeamId: fixture.awayTeam.id),
        _footballRepository.getHeadToHead(
            team1Id: fixture.homeTeam.id,
            team2Id: fixture.awayTeam.id,
            lastN: numH2HGames,
            status: 'FT'),
        _getLeagueStandingsUseCase(
            leagueId: fixture.league.id, season: currentSeason),
        _getTeamRecentFixturesUseCase(
            teamId: fixture.homeTeam.id, lastN: numRecentGames, status: 'FT'),
        _getTeamRecentFixturesUseCase(
            teamId: fixture.awayTeam.id, lastN: numRecentGames, status: 'FT'),
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
      ));
    } catch (e, s) {
      if (kDebugMode)
        print(
            "Erro catastrófico em _gatherDataForFixture para ${fixture.id}: $e\n$s");
      return Left(UnknownFailure(
          message:
              "Erro ao coletar dados para análise do jogo ${fixture.id}: ${e.toString()}"));
    }
  }

  // --- FUNÇÕES HELPER PARA CÁLCULOS ESTATÍSTICOS ---
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
        print(
            "GSSUC _analyzeMarkets: Nenhuma odd disponível para ${data.fixture.id}.");
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
    double scoreHome = 0.0, scoreAway = 0.0; // Pontuações de "força"
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
      } // Tendência a empate
    } else {
      String xgReason = "xG N/D";
      if (xgHome != null || xgAway != null)
        xgReason =
            "xG (${xgHome?.toStringAsFixed(1) ?? 'N/A'}-${xgAway?.toStringAsFixed(1) ?? 'N/A'}) insuf.";
      [reasonsHome, reasonsAway, reasonsDraw]
          .forEach((list) => list.add(xgReason));
      double? hAvgG = data.homeTeamAggregatedStats?.averageGoalsScoredPerGame;
      double? aAvgG = data.awayTeamAggregatedStats?.averageGoalsScoredPerGame;
      if (hAvgG != null && aAvgG != null) {
        if (hAvgG > aAvgG + 0.25)
          scoreHome += 0.7;
        else if (aAvgG > hAvgG + 0.25)
          scoreAway += 0.7;
        else {
          scoreHome += 0.2;
          scoreAway += 0.2;
        }
      }
    }

    int? homeR = data.leagueStandings
        ?.firstWhereOrNull((s) => s.teamId == fixture.homeTeam.id)
        ?.rank;
    int? awayR = data.leagueStandings
        ?.firstWhereOrNull((s) => s.teamId == fixture.awayTeam.id)
        ?.rank;
    if (homeR != null && awayR != null) {
      String rR = "Rank:${homeR}º vs ${awayR}º";
      if (homeR < awayR - 3) {
        scoreHome += 1.3;
        reasonsHome.add(rR);
      } else if (awayR < homeR - 3) {
        scoreAway += 1.3;
        reasonsAway.add(rR);
      } else if (homeR < awayR) {
        scoreHome += 0.65;
        reasonsHome.add(rR);
      } else if (awayR < homeR) {
        scoreAway += 0.65;
        reasonsAway.add(rR);
      } else {
        reasonsDraw.add(rR);
      }
    } else {
      [reasonsHome, reasonsAway, reasonsDraw]
          .forEach((list) => list.add("Rank N/D"));
    }

    int homeFP =
        _calculateFormPoints(data.homeTeamRecentFixtures, fixture.homeTeam.id);
    int awayFP =
        _calculateFormPoints(data.awayTeamRecentFixtures, fixture.awayTeam.id);
    if ((data.homeTeamRecentFixtures?.isNotEmpty ?? false) &&
        (data.awayTeamRecentFixtures?.isNotEmpty ?? false)) {
      double formDS = ((homeFP - awayFP) / 15.0) * 1.8;
      String formReason = "Forma(${homeFP}p vs ${awayFP}p)";
      if (formDS > 0.3) {
        scoreHome += formDS;
        reasonsHome.add(formReason);
      } else if (formDS < -0.3) {
        scoreAway += formDS.abs();
        reasonsAway.add(formReason);
      } else {
        reasonsDraw.add(formReason);
      }
    } else {
      [reasonsHome, reasonsAway, reasonsDraw]
          .forEach((list) => list.add("Forma N/D(<3j)"));
    }

    int h2hD = _analyzeH2HScore(
        data.h2hFixtures, fixture.homeTeam.id, fixture.awayTeam.id);
    if (h2hD == 1) {
      scoreHome += 0.9;
      reasonsHome.add("H2H Fav.");
    } else if (h2hD == -1) {
      scoreAway += 0.9;
      reasonsAway.add("H2H Fav.");
    } else if (data.h2hFixtures?.isNotEmpty ?? false) {
      reasonsDraw.add("H2H Equil.");
    }

    // Placeholder para análise de desfalques
    // bool keyHomePlayerMissing = _isKeyPlayerMissing(data.lineups?.homeTeamLineup, data.playerSeasonStats, fixture.homeTeam.id);
    // bool keyAwayPlayerMissing = _isKeyPlayerMissing(data.lineups?.awayTeamLineup, data.playerSeasonStats, fixture.awayTeam.id);
    // if(keyHomePlayerMissing && !keyAwayPlayerMissing) { scoreAway += 0.8; reasonsAway.add("Desfalque Casa Chave");}
    // if(keyAwayPlayerMissing && !keyHomePlayerMissing) { scoreHome += 0.8; reasonsHome.add("Desfalque Fora Chave");}

    final OddOption? homeOpt = odds1X2.options
        .firstWhereOrNull((o) => o.label.toLowerCase() == "home");
    final OddOption? drawOpt = odds1X2.options
        .firstWhereOrNull((o) => o.label.toLowerCase() == "draw");
    final OddOption? awayOpt = odds1X2.options
        .firstWhereOrNull((o) => o.label.toLowerCase() == "away");

    BetSelection? chosenSel;
    String fReason = "";
    double calcProb = 0.0;
    double conf = 0.50;
    const double scoreDiffThresh = 1.6;
    const double minOddW = 1.30;
    const double minOddD = 2.50;

    double pHomeFromScore = 0.33, pAwayFromScore = 0.33, pDrawFromScore = 0.34;
    double totalScoreForProbs =
        (scoreHome < 0 ? 0 : scoreHome) + (scoreAway < 0 ? 0 : scoreAway) + 1.2;
    if (totalScoreForProbs > 0.1) {
      pHomeFromScore =
          (scoreHome < 0 ? 0.1 : scoreHome + 0.4) / totalScoreForProbs;
      pAwayFromScore =
          (scoreAway < 0 ? 0.1 : scoreAway + 0.4) / totalScoreForProbs;
      pDrawFromScore =
          (1.0 - pHomeFromScore - pAwayFromScore).clamp(0.05, 0.60);
      double sumP = pHomeFromScore + pAwayFromScore + pDrawFromScore;
      if (sumP > 0) {
        pHomeFromScore /= sumP;
        pAwayFromScore /= sumP;
        pDrawFromScore /= sumP;
      }
    }

    double finalProbHome = xgValidForPoisson
        ? (probHomeWinPoisson * 0.6 + pHomeFromScore * 0.4)
        : pHomeFromScore;
    double finalProbAway = xgValidForPoisson
        ? (probAwayWinPoisson * 0.6 + pAwayFromScore * 0.4)
        : pAwayFromScore;
    double finalProbDraw = xgValidForPoisson
        ? (probDrawPoisson * 0.6 + pDrawFromScore * 0.4)
        : pDrawFromScore;
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

    if (scoreHome > scoreAway + scoreDiffThresh && homeOpt != null) {
      chosenSel = BetSelection(
          marketName: odds1X2.marketName,
          selectionName: homeOpt.label,
          odd: homeOpt.odd);
      fReason =
          "Casa: ${reasonsHome.where((r) => !r.contains("N/D")).take(3).join('; ')}.";
      calcProb = finalProbHome;
      conf = 0.55 +
          (scoreHome - scoreAway - scoreDiffThresh) * 0.045 +
          (calcProb > 0.50 ? 0.08 : 0);
    } else if (scoreAway > scoreHome + scoreDiffThresh && awayOpt != null) {
      chosenSel = BetSelection(
          marketName: odds1X2.marketName,
          selectionName: awayOpt.label,
          odd: awayOpt.odd);
      fReason =
          "Vis.: ${reasonsAway.where((r) => !r.contains("N/D")).take(3).join('; ')}.";
      calcProb = finalProbAway;
      conf = 0.55 +
          (scoreAway - scoreHome - scoreDiffThresh) * 0.045 +
          (calcProb > 0.50 ? 0.08 : 0);
    } else if ((scoreHome - scoreAway).abs() < 1.1 &&
        reasonsDraw.where((r) => !r.contains("N/D")).length >= 2 &&
        drawOpt != null) {
      chosenSel = BetSelection(
          marketName: odds1X2.marketName,
          selectionName: drawOpt.label,
          odd: drawOpt.odd);
      fReason =
          "Empate: ${reasonsDraw.where((r) => !r.contains("N/D")).take(2).join('; ')}.";
      if (reasonsHome.where((r) => !r.contains("N/D")).isNotEmpty)
        fReason +=
            " CasaF: ${reasonsHome.where((r) => !r.contains("N/D")).join('; ')}.";
      if (reasonsAway.where((r) => !r.contains("N/D")).isNotEmpty)
        fReason +=
            " VisF: ${reasonsAway.where((r) => !r.contains("N/D")).join('; ')}.";
      calcProb = finalProbDraw;
      conf = 0.55 +
          (calcProb > 0.28 ? 0.07 : 0) -
          (scoreHome - scoreAway).abs() * 0.04;
    }

    if (chosenSel != null) {
      calcProb = calcProb.clamp(0.05, 0.95);
      conf = conf.clamp(0.50, 0.88);
      double oddV = double.tryParse(chosenSel.odd) ?? 100.0;
      bool passesOddThold = (chosenSel.selectionName.toLowerCase() == "draw")
          ? (oddV >= minOddD)
          : (oddV >= minOddW);
      if (!passesOddThold || oddV > 7.0) return;

      double impliedP = 1 / oddV;
      if (calcProb > (impliedP + 0.03) ||
          (calcProb > impliedP && conf > 0.62)) {
        bets.add(PotentialBet(
            fixture: fixture,
            selection: chosenSel.copyWith(
              reasoning: fReason.trim().replaceAll(RegExp(r';\s*$'), ''),
              probability: calcProb,
            ),
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
            scoreProbs.forEach((score, prob) {
              final s = score.split('-').map(int.parse).toList();
              if ((s[0] + s[1]) > line) probForLine += prob;
            });
          } else {
            // Under
            scoreProbs.forEach((score, prob) {
              final s = score.split('-').map(int.parse).toList();
              if ((s[0] + s[1]) < line) probForLine += prob;
            });
          }
          probForLine = probForLine.clamp(0.01, 0.99);

          double oddVal = double.tryParse(option.odd) ?? 100.0;
          if (oddVal < 1.40 || oddVal > 3.5) continue;
          double impliedProb = 1 / oddVal;

          if (probForLine > (impliedProb + 0.06)) {
            bets.add(PotentialBet(
                fixture: fixture,
                selection: BetSelection(
                    marketName: oddsMarket.marketName,
                    selectionName: option.label,
                    odd: option.odd,
                    reasoning:
                        "Poisson (xG Total: ${totalXG.toStringAsFixed(1)}) -> P(${(probForLine * 100).toStringAsFixed(0)}%) para ${option.label}",
                    probability: probForLine),
                confidence: (0.58 + (probForLine - impliedProb) * 1.8)
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

    double probHomeNotScore = _poissonProbability(xgHome, 0);
    double probAwayNotScore = _poissonProbability(xgAway, 0);
    double probBTTS_Yes_Calc = (1 - probHomeNotScore) * (1 - probAwayNotScore);
    double probBTTS_No_Calc = (probHomeNotScore * (1 - probAwayNotScore)) +
        (probAwayNotScore * (1 - probHomeNotScore)) +
        (probHomeNotScore * probAwayNotScore);
    double sumBttsProbs = probBTTS_Yes_Calc + probBTTS_No_Calc;
    if (sumBttsProbs > 0.01 && sumBttsProbs.isFinite) {
      probBTTS_Yes_Calc /= sumBttsProbs;
      probBTTS_No_Calc /= sumBttsProbs;
    } else {
      probBTTS_Yes_Calc = 0.5;
      probBTTS_No_Calc = 0.5;
    }

    final bttsYesOpt = oddsBTTS.options
        .firstWhereOrNull((o) => o.label.toLowerCase() == "yes");
    final bttsNoOpt =
        oddsBTTS.options.firstWhereOrNull((o) => o.label.toLowerCase() == "no");

    if (bttsYesOpt != null) {
      double oddV = double.tryParse(bttsYesOpt.odd) ?? 100.0;
      if (oddV >= 1.40 && oddV <= 2.8) {
        double impliedP = 1 / oddV;
        if (probBTTS_Yes_Calc > (impliedP + 0.05)) {
          bets.add(PotentialBet(
              fixture: fixture,
              selection: BetSelection(
                  marketName: oddsBTTS.marketName,
                  selectionName: bttsYesOpt.label,
                  odd: bttsYesOpt.odd,
                  reasoning:
                      "Poisson (xG H:${xgHome.toStringAsFixed(1)},A:${xgAway.toStringAsFixed(1)}) -> P(${(probBTTS_Yes_Calc * 100).toStringAsFixed(0)}%) BTTS Sim.",
                  probability: probBTTS_Yes_Calc.clamp(0.01, 0.99)),
              confidence: (0.60 + (probBTTS_Yes_Calc - impliedP) * 1.7)
                  .clamp(0.60, 0.87)));
        }
      }
    }
    if (bttsNoOpt != null) {
      double oddV = double.tryParse(bttsNoOpt.odd) ?? 100.0;
      if (oddV >= 1.40 && oddV <= 2.8) {
        double impliedP = 1 / oddV;
        if (probBTTS_No_Calc > (impliedP + 0.05)) {
          bets.add(PotentialBet(
              fixture: fixture,
              selection: BetSelection(
                  marketName: oddsBTTS.marketName,
                  selectionName: bttsNoOpt.label,
                  odd: bttsNoOpt.odd,
                  reasoning:
                      "Poisson (xG H:${xgHome.toStringAsFixed(1)},A:${xgAway.toStringAsFixed(1)}) -> P(${(probBTTS_No_Calc * 100).toStringAsFixed(0)}%) BTTS Não.",
                  probability: probBTTS_No_Calc.clamp(0.01, 0.99)),
              confidence: (0.60 + (probBTTS_No_Calc - impliedP) * 1.7)
                  .clamp(0.60, 0.87)));
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

    // TODO: Implementar forma confiável de obter avgCornersGeneratedPerGame e avgCornersConcededPerGame
    // Se não vierem de TeamAggregatedStats, calcular a partir de data.homeTeamRecentFixtures (se tiverem stats de cantos)
    double avgHomeGen =
        data.homeTeamAggregatedStats?.averageCornersGeneratedPerGame ?? 5.2;
    double avgHomeCon =
        data.homeTeamAggregatedStats?.averageCornersConcededPerGame ?? 5.3;
    double avgAwayGen =
        data.awayTeamAggregatedStats?.averageCornersGeneratedPerGame ?? 4.4;
    double avgAwayCon =
        data.awayTeamAggregatedStats?.averageCornersConcededPerGame ?? 5.7;

    String warning = "";
    if (data.homeTeamAggregatedStats?.averageCornersGeneratedPerGame == null)
      warning = " (Aviso: médias de escanteios usam fallbacks)";

    double expectedTotalCorners =
        ((avgHomeGen + avgAwayCon) / 2.0) + ((avgAwayGen + avgHomeCon) / 2.0);
    String reasoningBasis =
        "Estimativa Escanteios: ${expectedTotalCorners.toStringAsFixed(1)}$warning";

    for (var option in oddsMarket.options) {
      String labelLower = option.label.toLowerCase();
      if (labelLower.startsWith("over ") || labelLower.startsWith("under ")) {
        try {
          double lineValue = double.parse(
              labelLower.replaceAll("over ", "").replaceAll("under ", ""));
          _checkGenericLine(fixture, oddsMarket, expectedTotalCorners,
              lineValue, bets, reasoningBasis,
              marketType: "Escanteios", specificOption: option);
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
    if (referee == null || (referee.gamesOfficiatedInCalculation) < 4) return;

    double avgHomeYellow =
        data.homeTeamAggregatedStats?.averageYellowCardsPerGame ?? 2.0;
    double avgAwayYellow =
        data.awayTeamAggregatedStats?.averageYellowCardsPerGame ?? 2.1;
    double avgRefereeYellow = referee.averageYellowCardsPerGame; // Já é double

    double expectedYellows = (avgHomeYellow * 0.28) +
        (avgAwayYellow * 0.28) +
        (avgRefereeYellow * 0.44); // Peso maior para árbitro
    expectedYellows = (expectedYellows * 10).round() / 10;

    String reasoningBasis =
        "Estimativa Amarelos: ${expectedYellows.toStringAsFixed(1)} (Árbitro: ${referee.refereeName})";

    for (var option in oddsMarket.options) {
      String labelLower = option.label.toLowerCase();
      if (labelLower.startsWith("over ") || labelLower.startsWith("under ")) {
        try {
          double lineValue =
              double.parse(labelLower.replaceAll(RegExp(r'[^0-9.]'), ''));
          _checkGenericLine(fixture, oddsMarket, expectedYellows, lineValue,
              bets, reasoningBasis,
              marketType: "Cartões", specificOption: option);
        } catch (e) {/* Ignora */}
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
        !o.marketName.toLowerCase().contains("to score or assist"));

    if (oddsMarket == null ||
        lineups == null ||
        !lineups.areAvailable ||
        playerStatsMap == null) return;

    List<PlayerInLineup> starters = [];
    starters.addAll(lineups.homeTeamLineup?.startingXI ?? []);
    starters.addAll(lineups.awayTeamLineup?.startingXI ?? []);
    if (starters.isEmpty) return;

    for (var oddOpt in oddsMarket.options) {
      final playerNameOdds = oddOpt.label;
      final oddVal = double.tryParse(oddOpt.odd) ?? 100.0;
      if (oddVal > 5.0 || oddVal < 1.75) continue; // Odds mais restritas

      PlayerInLineup? starterInfo = starters.firstWhereOrNull((p) =>
          p.playerName.toLowerCase() == playerNameOdds.toLowerCase() ||
          p.playerName.toLowerCase().contains(playerNameOdds.toLowerCase()) ||
          playerNameOdds.toLowerCase().contains(p.playerName
              .split(" ")
              .lastWhere((s) => s.length > 2, orElse: () => "")
              .toLowerCase()));
      if (starterInfo == null || starterInfo.playerId == 0) continue;

      PlayerSeasonStats? pStats = playerStatsMap[starterInfo.playerId];
      if (pStats == null && !(starterInfo.position?.toUpperCase() == "F"))
        continue;

      double propensity = 0.04;
      String reason = "Titular (${starterInfo.position ?? 'N/A'})";
      bool hasStrongSignal = false;

      if (pStats != null) {
        double xgi90 = pStats.expectedGoalsIndividualPer90 ??
            (pStats.goalsPer90 * 0.75); // Proxy
        if (xgi90 > 0.25) {
          propensity = xgi90 * 0.90;
          reason += ", xGi/90: ${xgi90.toStringAsFixed(2)}";
          hasStrongSignal = true;
        } else if (pStats.goalsPer90 > 0.28) {
          propensity = pStats.goalsPer90 * 0.70;
          reason += ", G/90: ${pStats.goalsPer90.toStringAsFixed(2)}";
          hasStrongSignal = true;
        }
      }

      if (!hasStrongSignal &&
          (starterInfo.position?.toUpperCase() ?? "") == "F")
        propensity = 0.10;
      else if (!hasStrongSignal) continue;

      bool isHome = lineups.homeTeamLineup?.startingXI
              .any((p) => p.playerId == starterInfo.playerId) ??
          false;
      double? teamXG = isHome
          ? data.fixtureStats?.homeTeam?.expectedGoals
          : data.fixtureStats?.awayTeam?.expectedGoals;
      double? opponentXGA = isHome
          ? data.fixtureStats?.awayTeam?.expectedGoals
          : data.fixtureStats?.homeTeam?.expectedGoals;

      if (teamXG != null) {
        if (teamXG > 1.65)
          propensity *= 1.10;
        else if (teamXG < 1.1) propensity *= 0.90;
      }
      if (opponentXGA != null) {
        if (opponentXGA > 1.65)
          propensity *= 1.08;
        else if (opponentXGA < 1.1) propensity *= 0.92;
      }

      if (propensity > 0.10) {
        double impliedOddProb = 1 / oddVal;
        if (propensity > (impliedOddProb + 0.03)) {
          // Valor de 3%
          bets.add(PotentialBet(
              fixture: fixture,
              selection: BetSelection(
                  marketName: "Jogador Marca",
                  selectionName: playerNameOdds,
                  odd: oddOpt.odd,
                  reasoning:
                      "$reason. P(${(propensity * 100).toStringAsFixed(0)}%)",
                  probability: propensity.clamp(0.01, 0.99)),
              confidence: (0.50 + (propensity - impliedOddProb) * 2.5)
                  .clamp(0.50, 0.78) // Confiança mais conservadora
              ));
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
        marketType.toLowerCase().contains("cartões") ? 0.60 : 0.80;
    double minOdd = 1.48, maxOdd = 3.6;

    double calcProb = 0.5;
    if (isOver)
      calcProb = 0.5 +
          (expectedValue - lineValueFromLabel) *
              0.11; // Ajuste de sensibilidade
    else
      calcProb = 0.5 + (lineValueFromLabel - expectedValue) * 0.11;
    calcProb = calcProb.clamp(0.05, 0.95);

    double impliedOddProb = 1 / oddValue;

    if (oddValue >= minOdd && oddValue <= maxOdd) {
      bool conditionMet = false;
      if (isOver && expectedValue > (lineValueFromLabel + threshold))
        conditionMet = true;
      else if (isUnder && expectedValue < (lineValueFromLabel - threshold))
        conditionMet = true;

      if (conditionMet && calcProb > (impliedOddProb + 0.035)) {
        // Valor de 3.5%
        bets.add(PotentialBet(
            fixture: fixture,
            selection: BetSelection(
                marketName: marketData.marketName,
                selectionName: specificOption.label,
                odd: specificOption.odd,
                reasoning:
                    "$reasoningBasis (${expectedValue.toStringAsFixed(1)}). P(${(calcProb * 100).toStringAsFixed(0)}%)",
                probability: calcProb),
            confidence:
                (0.55 + (calcProb - impliedOddProb) * 1.7).clamp(0.55, 0.85)));
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

    // TENTATIVA 1: "Dupla/Trio Confiável"
    for (int numSel = 2; numSel <= maxSelectionsPerSlip; numSel++) {
      if (allPotentialBets.length < numSel) continue;
      List<PotentialBet> currentSelections = [];
      Set<int> usedFixtures = {};
      double currentOddProduct = 1.0;

      for (var bet in allPotentialBets) {
        if (currentSelections.length == numSel) break;
        if (!usedFixtures.contains(bet.fixture.id) &&
            bet.confidence >= (numSel == 2 ? 0.68 : 0.62) &&
            bet.selection.oddValue >= (numSel == 2 ? 1.38 : 1.32)) {
          currentSelections.add(bet);
          usedFixtures.add(bet.fixture.id);
          currentOddProduct *= bet.selection.oddValue;
        }
      }

      if (currentSelections.length == numSel &&
          currentOddProduct >= (numSel == 2 ? 1.80 : 2.30)) {
        // Odd mínima total
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
          totalOdds: '',
        ));
      }
    }

    // TENTATIVA 2: Múltipla para atingir `targetTotalOdd`
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
          currentOddTargetAttempt >= (targetTotalOdd * 0.88)) {
        break;
      }
      if (targetOddSelectionsAttempt.length == maxSelectionsPerSlip) break;
    }

    if (targetOddSelectionsAttempt.length >= 2 &&
        targetOddSelectionsAttempt.length <= maxSelectionsPerSlip &&
        currentOddTargetAttempt >= (targetTotalOdd * 0.68)) {
      String title =
          "Múltipla Alvo (Odd: ${currentOddTargetAttempt.toStringAsFixed(1)}) 🎯";
      if (builtSlips.any((s) => s.title.startsWith("Múltipla Alvo")))
        title +=
            " #${builtSlips.where((s) => s.title.startsWith("Múltipla Alvo")).length + 1}";
      if (!builtSlips.any((s) => s.title == title)) {
        builtSlips.add(SuggestedBetSlip(
          title: title,
          fixturesInvolved:
              targetOddSelectionsAttempt.map((e) => e.fixture).toSet().toList(),
          selections:
              targetOddSelectionsAttempt.map((e) => e.selection).toList(),
          totalOddsDisplay: currentOddTargetAttempt.toStringAsFixed(2),
          dateGenerated: DateTime.now(),
          overallReasoning:
              "Combinação buscando odd alvo com análise e confiança.",
          totalOdds: '',
        ));
      }
    }

    builtSlips.removeWhere((slip) {
      bool isReliableType = slip.title.contains("Confiável") ||
          slip.title.contains("Segura") ||
          slip.title.contains("Analisada");
      if (isReliableType) return slip.selections.length < 2;
      return slip.selections.length < 2 || slip.totalOddsValue < 1.85;
    });

    builtSlips.sort((a, b) {
      if (a.selections.length != b.selections.length)
        return b.selections.length.compareTo(a.selections.length);
      return b.totalOddsValue.compareTo(a.totalOddsValue);
    });

    return builtSlips.take(4).toList();
  }
}
