// lib/data/repositories/football_repository_impl.dart
import 'package:dartz/dartz.dart'; // Certifique-se de adicionar dartz: ^0.10.1 ao pubspec.yaml
import 'package:product_gamers/core/config/app_constants.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';
import 'package:product_gamers/domain/entities/entities/live_fixture_update.dart';
import 'package:product_gamers/domain/entities/entities/player_stats.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
import 'package:product_gamers/domain/entities/entities/referee_stats.dart';
import 'package:product_gamers/domain/entities/entities/standing_info.dart';
import '../../core/error/exceptions.dart';

// Data sources
import '../datasources/football_remote_datasource.dart';

// Models (usados internamente para conversão)
// import '../models/league_model.dart'; // Não precisa importar todos os models aqui
// import '../models/fixture_model.dart';
// ...

// Entities (tipos de retorno)

// Repository Abstraction
import '../../domain/repositories/football_repository.dart';

class FootballRepositoryImpl implements FootballRepository {
  final FootballRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo; // Opcional, para verificar conectividade

  FootballRepositoryImpl({
    required this.remoteDataSource,
    // required this.networkInfo,
  });

  // _tryCatch genérico para encapsular chamadas ao datasource
  Future<Either<Failure, T>> _tryCatch<T>(Future<T> Function() action) async {
    // if (!await networkInfo.isConnected) { // Descomente se for usar NetworkInfo
    //   return Left(NetworkFailure(message: 'Sem conexão com a internet.'));
    // }
    try {
      final result = await action();
      return Right(result);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Erro no servidor da API.'),
      );
    } on CacheException catch (e) {
      // Embora não estejamos usando cache ainda
      return Left(CacheFailure(message: e.message ?? 'Erro de cache.'));
    } on AuthenticationException catch (e) {
      return Left(
        AuthenticationFailure(
          message: e.message ?? 'Falha na autenticação com a API.',
        ),
      );
    } on ApiException catch (e) {
      return Left(ApiFailure(message: e.message ?? 'Erro retornado pela API.'));
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(message: e.message ?? 'Erro de rede ao contatar a API.'),
      );
    } on NoDataException catch (e) {
      // Captura a exceção de quando nenhuma liga popular é carregada
      return Left(
        NoDataFailure(message: e.message ?? 'Nenhum dado encontrado.'),
      );
    } catch (e) {
      print("Erro desconhecido no repositório: $e (${e.runtimeType})");
      return Left(UnknownFailure(message: "Falha inesperada: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, List<League>>> getLeagues() async {
    return _tryCatch<List<League>>(() async {
      // Especificar o tipo T para _tryCatch
      final leagueModels = await remoteDataSource.getLeagues();
      // Mapeia cada LeagueModel para sua entidade League
      return leagueModels.map((model) => model.toEntity()).toList();
    });
  }

  // ... Implementações dos outros métodos (getFixturesForLeague, getOddsForFixture, etc., como antes)
  // ... Certifique-se que eles usam o _tryCatch e convertem os models para entities.
  // ... (Vou colar o restante do código que já tínhamos para esses métodos)

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
        bookmakerId: bookmakerId,
      );
      return oddsResponseModel.toEntityList(
        preferredBookmakerId: AppConstants.preferredBookmakerId,
      );
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
        bookmakerId: bookmakerId,
      );
      return oddsResponseModel.toEntityList(
        preferredBookmakerId: AppConstants.preferredBookmakerId,
      );
    });
  }

  @override
  Future<Either<Failure, FixtureStatsEntity>> getFixtureStatistics({
    required int fixtureId,
    required int homeTeamId,
    required int awayTeamId,
  }) async {
    return _tryCatch<FixtureStatsEntity>(() async {
      final model = await remoteDataSource.getFixtureStatistics(
        fixtureId: fixtureId,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
      );
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
        team1Id: team1Id,
        team2Id: team2Id,
        lastN: lastN,
        status: status,
      );
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<PlayerSeasonStats>>> getPlayersFromSquad({
    required int teamId,
  }) async {
    return _tryCatch<List<PlayerSeasonStats>>(() async {
      final models = await remoteDataSource.getPlayersFromSquad(teamId: teamId);
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, PlayerSeasonStats?>> getPlayerStats({
    required int playerId,
    required String season,
  }) async {
    return _tryCatch<PlayerSeasonStats?>(() async {
      // Note o T? para resultado anulável
      final model = await remoteDataSource.getPlayerStats(
        playerId: playerId,
        season: season,
      );
      return model
          ?.toEntity(); // Usa o operador ?. para chamar toEntity se model não for nulo
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
        leagueId: leagueId,
        season: season,
        topN: topN,
      );
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, RefereeStats>> getRefereeDetailsAndAggregateStats({
    required int refereeId,
    required String season,
  }) async {
    return _tryCatch<RefereeStats>(() async {
      final model = await remoteDataSource.getRefereeDetailsAndAggregateStats(
        refereeId: refereeId,
        season: season,
      );
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
        leagueId: leagueId,
        season: season,
      );
      if (model == null) return <StandingInfo>[];
      return model.toEntityList();
    });
  }

  @override
  Future<Either<Failure, LiveFixtureUpdate>> getLiveFixtureUpdate(
    int fixtureId,
  ) async {
    return _tryCatch<LiveFixtureUpdate>(() async {
      final model = await remoteDataSource.fetchLiveFixtureUpdate(fixtureId);
      return model.toEntity();
    });
  }
}
