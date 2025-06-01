// lib/domain/usecases/get_fixture_lineups_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/lineup.dart';

import '../repositories/football_repository.dart';

class GetFixtureLineupsUseCase {
  final FootballRepository repository;
  GetFixtureLineupsUseCase(this.repository);

  Future<Either<Failure, LineupsForFixture?>> call(
      {required int fixtureId,
      required int homeTeamId,
      required int awayTeamId}) async {
    return repository.getFixtureLineups(
        fixtureId: fixtureId, homeTeamId: homeTeamId, awayTeamId: awayTeamId);
  }
}
