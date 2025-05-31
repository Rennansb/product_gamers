// lib/domain/usecases/get_leagues_usecase.dart
import 'package:dartz/dartz.dart'; // Para o tipo Either
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/league.dart'
    as entities;
import 'package:product_gamers/main.dart';
// A entidade League
import '../entities/entities/league.dart';
import '../repositories/football_repository.dart'
    as repo; // A interface do Repositório

// UseCase para buscar a lista de ligas populares.
class GetLeaguesUseCase {
  final repo.FootballRepository
      repository; // Depende da abstração, não da implementação

  GetLeaguesUseCase(this.repository); // Injeção de dependência

  // O método 'call' permite que a instância do UseCase seja chamada como uma função.
  Future<Either<Failure, List<League>>> call() async {
    // Delega a chamada para o método correspondente no repositório.
    // Em UseCases mais complexos, poderia haver lógica adicional aqui.
    return await repository.getLeagues();
  }
}
