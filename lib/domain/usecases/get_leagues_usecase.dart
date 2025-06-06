// lib/domain/usecases/get_leagues_usecase.dart
import 'package:dartz/dartz.dart'; // Para o tipo Either
import 'package:product_gamers/core/config/failure.dart';

// A entidade League
import '../entities/entities/league.dart';
import '../repositories/football_repository.dart'
    as repo; // A interface do Repositório

// UseCase para buscar a lista de ligas populares.
class GetLeaguesUseCase {
  final repo.FootballRepository repository;
  GetLeaguesUseCase(this.repository);
  Future<Either<Failure, List<League>>> call() async => repository.getLeagues();
}
