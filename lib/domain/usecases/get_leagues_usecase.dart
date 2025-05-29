// lib/domain/usecases/get_leagues_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart' show Failure;
import 'package:product_gamers/domain/entities/entities/league.dart';

import '../repositories/football_repository.dart';

// UseCase para buscar a lista de ligas populares.
// Cada UseCase geralmente tem uma única responsabilidade e um método público.
class GetLeaguesUseCase {
  // O UseCase depende da abstração do repositório, não da implementação concreta.
  // Isso facilita os testes e a inversão de dependência.
  final FootballRepository repository;

  GetLeaguesUseCase(this.repository);

  // O método 'call' permite que a instância do UseCase seja chamada como uma função.
  // Ex: final getLeagues = GetLeaguesUseCase(myRepository);
  //     final result = await getLeagues();
  Future<Either<Failure, List<League>>> call() async {
    // Simplesmente repassa a chamada para o método correspondente no repositório.
    // UseCases mais complexos poderiam ter lógica adicional aqui, como combinar
    // dados de múltiplos métodos do repositório ou aplicar regras de negócio.
    return await repository.getLeagues();
  }
}
