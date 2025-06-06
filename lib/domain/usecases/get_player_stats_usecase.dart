// lib/domain/usecases/get_player_stats_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/player_stats.dart';

import '../repositories/football_repository.dart';

class GetPlayerStatsUseCase {
  final FootballRepository repository;
  GetPlayerStatsUseCase(this.repository);
  Future<Either<Failure, PlayerSeasonStats?>> call({
    required int playerId,
    required String season,
  }) async =>
      repository.getPlayerStats(playerId: playerId, season: season);
}
