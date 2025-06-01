// lib/domain/usecases/get_team_aggregated_stats_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/team_aggregated_stats.dart';

import '../repositories/football_repository.dart';

class GetTeamAggregatedStatsUseCase {
  final FootballRepository repository;
  GetTeamAggregatedStatsUseCase(this.repository);

  Future<Either<Failure, TeamAggregatedStats?>> call({
    required int teamId,
    required int leagueId,
    required String season,
  }) async {
    return repository.getTeamSeasonAggregatedStats(
        teamId: teamId, leagueId: leagueId, season: season);
  }
}
