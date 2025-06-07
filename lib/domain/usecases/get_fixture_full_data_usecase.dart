import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/data/repositories/football_repository.dart';
import 'package:product_gamers/domain/entities/entities/fixture_full_data.dart';

class GetFixtureFullDataUseCase {
  final FootballRepository _repository;

  GetFixtureFullDataUseCase(this._repository);

  Future<Either<Failure, FixtureFullData>> call(int fixtureId) async {
    return await _repository.getFixtureFullData(fixtureId);
  }
}
