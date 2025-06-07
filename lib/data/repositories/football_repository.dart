// lib/domain/repositories/football_repository.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_full_data.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';
import 'package:product_gamers/domain/entities/entities/lineup.dart';
import 'package:product_gamers/main.dart'; // Para o tipo Either
// A entidade League que acabamos de definir

// Interface (contrato) para o repositório de dados de futebol.
// Define quais operações de dados a camada de domínio pode solicitar.

abstract class FootballRepository {
  Future<Either<Failure, FixtureFullData>> getFixtureFullData(int fixtureId);

  Future<Either<Failure, LineupsForFixture?>> getFixtureLineups(
      {required int fixtureId,
      required int homeTeamId,
      required int awayTeamId});
  // Método para buscar a lista de ligas populares.
  // Retorna um Future que resolverá para Either:
  // - Left(Failure) em caso de erro.
  // - Right(List<League>) em caso de sucesso.
  Future<Either<Failure, List<Fixture>>> getTeamRecentFixtures(
      {required int teamId, int lastN = 5, String? status});
  Future<Either<Failure, List<League>>> getLeagues();

  // --- Outros métodos para buscar fixtures, odds, stats, etc., serão adicionados aqui ---
  // --- à medida que implementarmos as funcionalidades correspondentes. ---
  // Exemplo:
  // Future<Either<Failure, List<Fixture>>> getFixturesForLeague(int leagueId, String season);
  // Future<Either<Failure, FixtureDetails>> getFixtureDetails(int fixtureId);
}
