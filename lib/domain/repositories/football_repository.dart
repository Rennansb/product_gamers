// lib/domain/repositories/football_repository.dart
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

// Não precisamos importar DataForPrediction, SuggestedBetSlip, LiveGameInsight, LiveBetSuggestion aqui
// porque o repositório não lida diretamente com esses objetos de agregação ou sugestão;
// eles são construídos/usados pelos UseCases ou Providers.

abstract class FootballRepository {
  // --- Métodos para Dados Pré-Jogo ---
  Future<Either<Failure, List<League>>> getLeagues();

  Future<Either<Failure, List<Fixture>>> getFixturesForLeague(
    int leagueId,
    String season, {
    int nextGames, // Parâmetro nomeado opcional
  });

  Future<Either<Failure, List<PrognosticMarket>>> getOddsForFixture(
    int fixtureId, {
    int? bookmakerId, // Parâmetro nomeado opcional
  });

  Future<Either<Failure, FixtureStatsEntity>> getFixtureStatistics({
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
    // Pode retornar nulo se jogador/stats não encontrados
    required int playerId,
    required String season,
  });

  Future<Either<Failure, List<PlayerSeasonStats>>> getLeagueTopScorers({
    required int leagueId,
    required String season,
    int topN = 10,
  });

  Future<Either<Failure, RefereeStats>> getRefereeDetailsAndAggregateStats({
    required int refereeId,
    required String season,
  });

  Future<Either<Failure, List<StandingInfo>>> getLeagueStandings({
    required int leagueId,
    required String season,
  });

  // --- Métodos para Dados Ao Vivo ---
  Future<Either<Failure, LiveFixtureUpdate>> getLiveFixtureUpdate(
    int fixtureId,
  );

  Future<Either<Failure, List<PrognosticMarket>>> getLiveOddsForFixture(
    int fixtureId, {
    int? bookmakerId,
  });

  // Você poderia adicionar mais métodos conforme necessário, por exemplo:
  // Future<Either<Failure, TeamDetailsEntity>> getTeamDetails(int teamId);
  // Future<Either<Failure, PlayerDetailsEntity>> getPlayerDetails(int playerId);
}
