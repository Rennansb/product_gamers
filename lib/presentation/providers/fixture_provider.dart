import 'package:flutter/material.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/usecases/get_fixtures_usecase.dart';
// CORREÇÃO DOS IMPORTS:

enum FixtureListStatus { initial, loading, loaded, error, empty }

class FixtureProvider with ChangeNotifier {
  final GetFixturesUseCase
  _getFixturesUseCase; // Agora GetFixturesUseCase deve ser reconhecido
  final int leagueId;
  final String season; // Ex: "2023"

  FixtureProvider(this._getFixturesUseCase, this.leagueId, this.season) {
    // O fetch é chamado pela UI (ex: initState da FixturesScreen)
  }

  FixtureListStatus _status = FixtureListStatus.initial;
  List<Fixture> _fixtures = [];
  String? _errorMessage;

  FixtureListStatus get status => _status;
  List<Fixture> get fixtures => _fixtures;
  String? get errorMessage => _errorMessage;

  Future<void> fetchFixtures({
    bool forceRefresh = false,
    int gamesToFetch = 20,
  }) async {
    if (_status == FixtureListStatus.loading && !forceRefresh) return;
    if (_status == FixtureListStatus.loaded &&
        _fixtures.isNotEmpty &&
        !forceRefresh) {
      return;
    }

    _status = FixtureListStatus.loading;
    if (forceRefresh) _fixtures = [];
    _errorMessage = null;
    notifyListeners();

    // A chamada ao use case agora deve estar correta
    final result = await _getFixturesUseCase(
      leagueId: leagueId,
      season: season,
      nextGames: gamesToFetch,
    );

    result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _status = FixtureListStatus.error;
        _fixtures = [];
      },
      (fixturesData) {
        _fixtures = fixturesData;
        if (_fixtures.isEmpty) {
          _status = FixtureListStatus.empty;
          _errorMessage =
              "Nenhum jogo futuro agendado encontrado para esta liga/temporada.";
        } else {
          _status = FixtureListStatus.loaded;
        }
      },
    );
    notifyListeners();
  }

  String _mapFailureToMessage(Failure failure) {
    // Supondo que ServerFailure, NetworkFailure, etc., estão definidas no arquivo failure.dart
    // Se não estiverem, você precisará importá-las de onde estiverem ou defini-las.
    // O código que geramos para failure.dart já inclui essas classes.
    if (failure is ServerFailure) {
      return 'Erro no servidor: ${failure.message}';
    } else if (failure is NetworkFailure) {
      return 'Falha de conexão: ${failure.message}';
    } else if (failure is AuthenticationFailure) {
      // Supondo que você definiu AuthenticationFailure
      return 'Erro de autenticação: ${failure.message}';
    } else if (failure is ApiFailure) {
      // Supondo que você definiu ApiFailure
      return 'Erro da API: ${failure.message}';
    } else if (failure is NoDataFailure) {
      // Supondo que você definiu NoDataFailure
      return failure.message;
    }
    // Fallback para outros tipos de Failure
    return 'Erro inesperado ao buscar jogos: ${failure.message}';
  }
}
