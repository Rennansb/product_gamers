// lib/domain/usecases/get_live_odds_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';

import '../repositories/football_repository.dart';

class GetLiveOddsUseCase {
  final FootballRepository repository;

  GetLiveOddsUseCase(this.repository);

  Future<Either<Failure, List<PrognosticMarket>>> call({
    required int fixtureId,
    int? bookmakerId,
  }) async {
    return await repository.getLiveOddsForFixture(
      // Chama o método para odds AO VIVO
      fixtureId,
      bookmakerId: bookmakerId,
    );
  }
}
