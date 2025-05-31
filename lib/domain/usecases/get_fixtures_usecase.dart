// lib/domain/usecases/get_fixtures_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';

import '../repositories/football_repository.dart';

class GetFixturesUseCase {
  final FootballRepository repository;

  GetFixturesUseCase(this.repository);

  Future<Either<Failure, List<Fixture>>> call({
    required int leagueId,
    required String season,
    int nextGames = 15,
  }) async {
    return await repository.getFixturesForLeague(
      leagueId, // posicional
      season, // posicional
      nextGames: nextGames, // nomeado
    );
  }
}
