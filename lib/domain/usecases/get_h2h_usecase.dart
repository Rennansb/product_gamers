// lib/domain/usecases/get_h2h_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';

import '../repositories/football_repository.dart';

class GetH2HUseCase {
  final FootballRepository repository;
  GetH2HUseCase(this.repository);
  Future<Either<Failure, List<Fixture>>> call({
    required int team1Id,
    required int team2Id,
    int lastN = 5, // Ajustado padrão
    String? status = 'FT',
  }) async =>
      repository.getHeadToHead(
          team1Id: team1Id, team2Id: team2Id, lastN: lastN, status: status);
}
