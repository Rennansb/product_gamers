// lib/domain/usecases/get_live_fixture_update_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/live_fixture_update.dart';

import '../repositories/football_repository.dart';

class GetLiveFixtureUpdateUseCase {
  final FootballRepository repository;
  GetLiveFixtureUpdateUseCase(this.repository);
  Future<Either<Failure, LiveFixtureUpdate?>> call(int fixtureId) async =>
      repository.getLiveFixtureUpdate(fixtureId);
}
