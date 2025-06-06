// lib/domain/usecases/get_team_recent_fixtures_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';

import '../repositories/football_repository.dart';

class GetTeamRecentFixturesUseCase {
  final FootballRepository repository;
  GetTeamRecentFixturesUseCase(this.repository);
  Future<Either<Failure, List<Fixture>>> call({
    required int teamId,
    int lastN = 5,
    String? status = 'FT',
  }) async =>
      repository.getTeamRecentFixtures(
          teamId: teamId, lastN: lastN, status: status);
}
