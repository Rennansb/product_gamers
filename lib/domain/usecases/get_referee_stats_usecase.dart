// lib/domain/usecases/get_referee_stats_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/referee_stats.dart';

import '../repositories/football_repository.dart';

class GetRefereeStatsUseCase {
  final FootballRepository repository;
  GetRefereeStatsUseCase(this.repository);

  Future<Either<Failure, RefereeStats>> call({
    required int refereeId, // Assumindo que temos o ID
    required String season,
  }) async {
    return repository.getRefereeDetailsAndAggregateStats(
      refereeId: refereeId,
      season: season,
    );
  }
}
