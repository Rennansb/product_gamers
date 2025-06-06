import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/player_stats.dart';

import '../repositories/football_repository.dart';

class GetSquadPlayersUseCase {
  final FootballRepository repository;
  GetSquadPlayersUseCase(this.repository);
  Future<Either<Failure, List<PlayerSeasonStats>>> call(
          {required int teamId}) async =>
      repository.getPlayersFromSquad(teamId: teamId);
}
