// lib/data/repositories/football_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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

// Core
import '../../core/config/app_constants.dart'; // Usado para AppConstants.preferredBookmakerId

import '../../core/error/exceptions.dart';

// Data Layer
import '../datasources/football_remote_datasource.dart'; // A interface do DataSource

// Domain Layer - Entidades (o que este repositório retorna)

// Não precisamos importar os Models aqui, pois a conversão Model -> Entity acontece aqui dentro.

// Domain Layer - Repositório (a interface que esta classe implementa)
import '../../domain/repositories/football_repository.dart';

class FootballRepositoryImpl implements FootballRepository {
  final FootballRemoteDataSource remoteDataSource;

  FootballRepositoryImpl({
    required this.remoteDataSource,
  });

  Future<Either<Failure, T>> _tryCatch<T>(
      Future<T> Function() remoteCall) async {
    try {
      final T result = await remoteCall();
      return Right(result);
    } on ServerException catch (e) {
      return Left(
          ServerFailure(message: e.message ?? 'Falha no servidor da API.'));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(
          message: e.message ?? 'Falha na autenticação com a API.'));
    } on ApiException catch (e) {
      return Left(ApiFailure(message: e.message ?? 'Erro retornado pela API.'));
    } on NetworkException catch (e) {
      return Left(
          NetworkFailure(message: e.message ?? 'Falha de conexão de rede.'));
    } on NoDataException catch (e) {
      return Left(
          NoDataFailure(message: e.message ?? 'Nenhum dado encontrado.'));
    } on CacheException catch (e) {
      return Left(
          CacheFailure(message: e.message ?? 'Erro ao acessar o cache.'));
    } catch (e) {
      if (kDebugMode)
        print("Erro desconhecido pego no repositório: $e (${e.runtimeType})");
      return Left(UnknownFailure(
          message: "Falha inesperada no repositório: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, List<League>>> getLeagues() async {
    return _tryCatch<List<League>>(() async {
      final leagueModels = await remoteDataSource.getLeagues();
      return leagueModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<Fixture>>> getFixturesForLeague(
    int leagueId,
    String season, {
    int nextGames = 15,
  }) async {
    return _tryCatch<List<Fixture>>(() async {
      final fixtureModels = await remoteDataSource.getFixturesForLeague(
        leagueId,
        season,
        nextGames: nextGames,
      );
      return fixtureModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<PrognosticMarket>>> getOddsForFixture(
    int fixtureId, {
    int? bookmakerId,
  }) async {
    return _tryCatch<List<PrognosticMarket>>(() async {
      final oddsResponseModel = await remoteDataSource.getOddsForFixture(
        fixtureId,
        bookmakerId: bookmakerId ?? AppConstants.preferredBookmakerId,
      );
      return oddsResponseModel.toEntityList(
          preferredBookmakerId:
              bookmakerId ?? AppConstants.preferredBookmakerId);
    });
  }

  @override
  Future<Either<Failure, List<PrognosticMarket>>> getLiveOddsForFixture(
    int fixtureId, {
    int? bookmakerId,
  }) async {
    return _tryCatch<List<PrognosticMarket>>(() async {
      final oddsResponseModel = await remoteDataSource.fetchLiveOddsForFixture(
        fixtureId,
        bookmakerId: bookmakerId ?? AppConstants.preferredBookmakerId,
      );
      return oddsResponseModel.toEntityList(
          preferredBookmakerId:
              bookmakerId ?? AppConstants.preferredBookmakerId);
    });
  }

  @override
  Future<Either<Failure, FixtureStatsEntity?>> getFixtureStatistics({
    required int fixtureId,
    required int homeTeamId,
    required int awayTeamId,
  }) async {
    return _tryCatch<FixtureStatsEntity?>(() async {
      final model = await remoteDataSource.getFixtureStatistics(
          fixtureId: fixtureId, homeTeamId: homeTeamId, awayTeamId: awayTeamId);
      // O FixtureStatisticsResponseModel.toEntity() deve retornar FixtureStatsEntity.
      // A nulidade aqui é gerenciada pelo tipo de retorno de _tryCatch.
      return model.toEntity(fixtureId);
    });
  }

  @override
  Future<Either<Failure, List<Fixture>>> getHeadToHead({
    required int team1Id,
    required int team2Id,
    int lastN = 10,
    String? status,
  }) async {
    return _tryCatch<List<Fixture>>(() async {
      final models = await remoteDataSource.getHeadToHead(
          team1Id: team1Id, team2Id: team2Id, lastN: lastN, status: status);
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<PlayerSeasonStats>>> getPlayersFromSquad({
    required int teamId,
  }) async {
    return _tryCatch<List<PlayerSeasonStats>>(() async {
      final models = await remoteDataSource.getPlayersFromSquad(teamId: teamId);
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, PlayerSeasonStats?>> getPlayerStats({
    required int playerId,
    required String season,
  }) async {
    return _tryCatch<PlayerSeasonStats?>(() async {
      final model = await remoteDataSource.getPlayerStats(
          playerId: playerId, season: season);
      return model?.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<PlayerSeasonStats>>> getLeagueTopScorers({
    required int leagueId,
    required String season,
    int topN = 10,
  }) async {
    return _tryCatch<List<PlayerSeasonStats>>(() async {
      final models = await remoteDataSource.getLeagueTopScorers(
          leagueId: leagueId, season: season, topN: topN);
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, RefereeStats?>> getRefereeDetailsAndAggregateStats({
    required int refereeId,
    required String season,
  }) async {
    return _tryCatch<RefereeStats?>(() async {
      // remoteDataSource.getRefereeDetailsAndAggregateStats retorna RefereeStatsModel (não anulável)
      final model = await remoteDataSource.getRefereeDetailsAndAggregateStats(
          refereeId: refereeId, season: season);
      return model.toEntity(season);
    });
  }

  @override
  Future<Either<Failure, List<StandingInfo>>> getLeagueStandings({
    required int leagueId,
    required String season,
  }) async {
    return _tryCatch<List<StandingInfo>>(() async {
      final model = await remoteDataSource.getLeagueStandings(
          leagueId: leagueId, season: season);
      if (model == null)
        return []; // Se DataSource retornar nulo (ex: liga não encontrada)
      return model.toEntityList();
    });
  }

  @override
  Future<Either<Failure, LiveFixtureUpdate?>> getLiveFixtureUpdate(
      int fixtureId) async {
    return _tryCatch<LiveFixtureUpdate?>(() async {
      // remoteDataSource.fetchLiveFixtureUpdate retorna LiveFixtureUpdateModel (não anulável)
      final model = await remoteDataSource.fetchLiveFixtureUpdate(fixtureId);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<RefereeBasicInfo>>> searchRefereeByName(
      {required String name}) async {
    return _tryCatch<List<RefereeBasicInfo>>(() async {
      final models = await remoteDataSource.searchRefereeByName(name: name);
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, LineupsForFixture?>> getFixtureLineups({
    required int fixtureId,
    required int homeTeamId,
    required int awayTeamId,
  }) async {
    return _tryCatch<LineupsForFixture?>(() async {
      final model = await remoteDataSource.getFixtureLineups(
          fixtureId: fixtureId, homeTeamId: homeTeamId, awayTeamId: awayTeamId);
      return model?.toEntity();
    });
  }

  @override
  Future<Either<Failure, TeamAggregatedStats?>> getTeamSeasonAggregatedStats({
    required int teamId,
    required int leagueId,
    required String season,
  }) async {
    return _tryCatch<TeamAggregatedStats?>(() async {
      final model = await remoteDataSource.getTeamSeasonAggregatedStats(
          teamId: teamId, leagueId: leagueId, season: season);
      return model?.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<Fixture>>> getTeamRecentFixtures({
    required int teamId,
    int lastN = 5,
    String? status,
  }) async {
    return _tryCatch<List<Fixture>>(() async {
      final fixtureModels = await remoteDataSource.getTeamRecentFixtures(
          teamId: teamId, lastN: lastN, status: status);
      return fixtureModels.map((model) => model.toEntity()).toList();
    });
  }
}
