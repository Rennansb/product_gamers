// lib/domain/repositories/football_repository.dart
// ... (imports existentes, incluindo fixture.dart)
// import '../entities/fixture.dart'; // Já deve estar lá

import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';
import 'package:product_gamers/domain/entities/entities/live_fixture_update.dart';
import 'package:product_gamers/domain/entities/entities/player_stats.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
import 'package:product_gamers/domain/entities/entities/referee_stats.dart';
import 'package:product_gamers/domain/entities/entities/standing_info.dart';
import 'package:product_gamers/main.dart';

abstract class FootballRepository {
  Future<Either<Failure, List<League>>> getLeagues();
  Future<Either<Failure, List<Fixture>>> getFixturesForLeague(
    // NOVO MÉTODO
    int leagueId,
    String season, {
    int nextGames = 15,
  });

  // --- Outros métodos (com stubs na implementação por enquanto) ---
  Future<Either<Failure, List<PrognosticMarket>>> getOddsForFixture(
      int fixtureId,
      {int? bookmakerId});
  Future<Either<Failure, List<PrognosticMarket>>> getLiveOddsForFixture(
      int fixtureId,
      {int? bookmakerId});
  Future<Either<Failure, FixtureStatsEntity?>> getFixtureStatistics(
      {required int fixtureId,
      required int homeTeamId,
      required int awayTeamId}); // Note: FixtureStatsEntity? para permitir nulo
  Future<Either<Failure, List<Fixture>>> getHeadToHead(
      {required int team1Id,
      required int team2Id,
      int lastN = 10,
      String? status});
  Future<Either<Failure, List<PlayerSeasonStats>>> getPlayersFromSquad(
      {required int teamId});
  Future<Either<Failure, PlayerSeasonStats?>> getPlayerStats(
      {required int playerId, required String season});
  Future<Either<Failure, List<PlayerSeasonStats>>> getLeagueTopScorers(
      {required int leagueId, required String season, int topN = 10});
  Future<Either<Failure, RefereeStats?>> getRefereeDetailsAndAggregateStats(
      {required int refereeId,
      required String season}); // Note: RefereeStats? para permitir nulo
  Future<Either<Failure, List<StandingInfo>>> getLeagueStandings(
      {required int leagueId, required String season});
  Future<Either<Failure, LiveFixtureUpdate?>> getLiveFixtureUpdate(
      int fixtureId); // Note: LiveFixtureUpdate?
}
