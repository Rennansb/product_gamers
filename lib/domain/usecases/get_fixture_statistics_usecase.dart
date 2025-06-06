// lib/domain/usecases/get_fixture_statistics_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';

import '../repositories/football_repository.dart';

class GetFixtureStatisticsUseCase {
  final FootballRepository repository;
  GetFixtureStatisticsUseCase(this.repository);
  Future<Either<Failure, FixtureStatsEntity?>> call({
    required int fixtureId,
    required int homeTeamId,
    required int awayTeamId,
  }) async =>
      repository.getFixtureStatistics(
          fixtureId: fixtureId, homeTeamId: homeTeamId, awayTeamId: awayTeamId);
}
