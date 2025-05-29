// lib/domain/usecases/get_fixtures_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
// Entidade que representa uma partida
import '../repositories/football_repository.dart'; // A interface do nosso repositório

class GetFixturesUseCase {
  final FootballRepository repository;

  GetFixturesUseCase(this.repository);

  // O método 'call' permite que a instância do UseCase seja chamada como uma função.
  // Este UseCase busca uma lista de jogos (fixtures) para uma liga e temporada específicas.
  Future<Either<Failure, List<Fixture>>> call({
    required int leagueId, // ID da liga para buscar os jogos
    required String season, // Ano da temporada (ex: "2023")
    int nextGames =
        15, // Número de próximos jogos a serem buscados (parâmetro opcional com valor padrão)
  }) async {
    // A lógica é delegada ao repositório.
    // O repositório, por sua vez, chama o DataSource, que faz a chamada à API.
    // O UseCase garante que a chamada ao repositório seja feita com os parâmetros corretos
    // e retorna o resultado encapsulado em um Either (sucesso ou falha).

    // No FootballRepository, o método getFixturesForLeague tem:
    // leagueId (posicional), season (posicional), nextGames (nomeado opcional)
    return await repository.getFixturesForLeague(
      leagueId, // Passado como primeiro argumento posicional
      season, // Passado como segundo argumento posicional
      nextGames: nextGames, // Passado como argumento nomeado
    );
  }
}
