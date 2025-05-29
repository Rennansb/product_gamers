// lib/domain/usecases/get_league_standings_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/standing_info.dart';

import '../repositories/football_repository.dart';

class GetLeagueStandingsUseCase {
  final FootballRepository repository;

  GetLeagueStandingsUseCase(this.repository);

  Future<Either<Failure, List<StandingInfo>>> call({
    required int leagueId,
    required String season,
  }) async {
    return await repository.getLeagueStandings(
      leagueId: leagueId,
      season: season,
    );
  }
}
