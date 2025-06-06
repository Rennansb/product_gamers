import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/player_stats.dart';

import '../repositories/football_repository.dart';

class GetLeagueTopScorersUseCase {
  final FootballRepository repository;
  GetLeagueTopScorersUseCase(this.repository);
  Future<Either<Failure, List<PlayerSeasonStats>>> call({
    required int leagueId,
    required String season,
    int topN = 10,
  }) async =>
      repository.getLeagueTopScorers(
          // AQUI ESTÁ O PROBLEMA
          leagueId: leagueId, // Correto (nomeado)
          season: season, // Correto (nomeado)
          topN: topN // Correto (nomeado)
          );
}
