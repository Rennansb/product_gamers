// lib/domain/repositories/football_repository.dart
// ... (imports existentes, incluindo fixture.dart)
// import '../entities/fixture.dart'; // Já deve estar lá

import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';
import 'package:product_gamers/domain/entities/entities/lineup.dart';
import 'package:product_gamers/domain/entities/entities/live_fixture_update.dart';
import 'package:product_gamers/domain/entities/entities/player_stats.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
import 'package:product_gamers/domain/entities/entities/referee_stats.dart';
import 'package:product_gamers/domain/entities/entities/standing_info.dart';
import 'package:product_gamers/domain/entities/entities/team_aggregated_stats.dart';
import 'package:product_gamers/main.dart';

abstract class FootballRepository {
  // --- Métodos para Dados Pré-Jogo ---
  Future<Either<Failure, List<League>>> getLeagues();

  Future<Either<Failure, List<Fixture>>> getFixturesForLeague(
    int leagueId,
    String season, {
    int nextGames = 15,
  });

  Future<Either<Failure, List<PrognosticMarket>>> getOddsForFixture(
    // Odds Pré-Jogo
    int fixtureId, {
    int? bookmakerId,
  });

  Future<Either<Failure, FixtureStatsEntity?>> getFixtureStatistics({
    required int fixtureId,
    required int homeTeamId,
    required int awayTeamId,
  });

  Future<Either<Failure, List<Fixture>>> getHeadToHead({
    required int team1Id,
    required int team2Id,
    int lastN = 10,
    String? status,
  });

  Future<Either<Failure, List<PlayerSeasonStats>>> getPlayersFromSquad({
    required int teamId,
  });

  Future<Either<Failure, PlayerSeasonStats?>> getPlayerStats({
    required int playerId,
    required String season,
  });

  Future<Either<Failure, List<PlayerSeasonStats>>> getLeagueTopScorers({
    required int leagueId,
    required String season,
    int topN = 10,
  });

  Future<Either<Failure, RefereeStats?>> getRefereeDetailsAndAggregateStats({
    required int refereeId,
    required String season,
  });

  Future<Either<Failure, List<StandingInfo>>> getLeagueStandings({
    required int leagueId,
    required String season,
  });

  Future<Either<Failure, LineupsForFixture?>> getFixtureLineups({
    required int fixtureId,
    required int homeTeamId,
    required int awayTeamId,
  });

  Future<Either<Failure, TeamAggregatedStats?>> getTeamSeasonAggregatedStats({
    required int teamId,
    required int leagueId,
    required String season,
  });

  Future<Either<Failure, List<Fixture>>> getTeamRecentFixtures({
    required int teamId,
    int lastN = 5,
    String? status,
  });

  Future<Either<Failure, List<RefereeBasicInfo>>> searchRefereeByName({
    required String name,
  });

  // --- Métodos para Dados Ao Vivo ---
  Future<Either<Failure, LiveFixtureUpdate?>> getLiveFixtureUpdate(
      int fixtureId); // CORRIGIDO: Definição única

  Future<Either<Failure, List<PrognosticMarket>>> getLiveOddsForFixture(
    // CORRIGIDO: Definição única
    int fixtureId, {
    int? bookmakerId,
  });
}
