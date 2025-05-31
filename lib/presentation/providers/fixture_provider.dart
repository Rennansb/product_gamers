// lib/presentation/providers/fixture_provider.dart
import 'package:flutter/foundation.dart'; // Para ChangeNotifier e kDebugMode
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';

// Core

import '../../core/utils/date_formatter.dart'; // Para obter o ano atual como string para 'season'

// Domain

import '../../domain/usecases/get_fixtures_usecase.dart';

enum FixtureListStatus { initial, loading, loaded, error, empty }

class FixtureProvider with ChangeNotifier {
  final GetFixturesUseCase _getFixturesUseCase;
  final int leagueId;
  final String
      season; // Ex: "2023" - será determinado a partir da LeagueEntity ou data atual

  FixtureProvider({
    required GetFixturesUseCase getFixturesUseCase, // Injetado
    required this.leagueId,
    required this.season,
  }) : _getFixturesUseCase = getFixturesUseCase {
    // A busca inicial é disparada pela FixturesScreen em seu initState
    // ou quando o provider é criado, se quisermos carregar imediatamente.
    // Vamos manter a chamada no initState da tela para melhor controle.
  }

  FixtureListStatus _status = FixtureListStatus.initial;
  List<Fixture> _fixtures = [];
  String? _errorMessage;

  FixtureListStatus get status => _status;
  List<Fixture> get fixtures => _fixtures;
  String? get errorMessage => _errorMessage;

  Future<void> fetchFixtures(
      {bool forceRefresh = false, int gamesToFetch = 20}) async {
    if (_status == FixtureListStatus.loading && !forceRefresh) return;
    if ((_status == FixtureListStatus.loaded ||
            _status == FixtureListStatus.empty) &&
        _fixtures.isNotEmpty &&
        !forceRefresh) {
      if (kDebugMode)
        print(
            "FixtureProvider: Dados de jogos já carregados para liga $leagueId e não é forceRefresh.");
      return;
    }
    if (_status == FixtureListStatus.empty &&
        !forceRefresh &&
        _fixtures.isEmpty) {
      if (kDebugMode)
        print(
            "FixtureProvider: Status é empty para liga $leagueId, não buscando novamente sem forceRefresh.");
      return;
    }

    _status = FixtureListStatus.loading;
    _errorMessage = null;
    if (forceRefresh) _fixtures = [];
    notifyListeners();

    if (kDebugMode) {
      print(
          "FixtureProvider: Buscando jogos para liga $leagueId, temporada $season (forceRefresh: $forceRefresh)...");
    }

    final result = await _getFixturesUseCase(
      leagueId: leagueId,
      season: season,
      nextGames: gamesToFetch,
    );

    if (_status == FixtureListStatus.loading) {
      // Checa se o estado não mudou (ex: disposed)
      result.fold(
        (failure) {
          _errorMessage = _mapFailureToMessage(failure);
          _status = FixtureListStatus.error;
          _fixtures = [];
          if (kDebugMode)
            print(
                "FixtureProvider: Erro ao buscar jogos para liga $leagueId - $_errorMessage");
        },
        (fixturesData) {
          _fixtures = fixturesData;
          if (_fixtures.isEmpty) {
            _status = FixtureListStatus.empty;
            _errorMessage =
                "Nenhum jogo futuro agendado encontrado para esta liga na temporada $season.";
            if (kDebugMode)
              print(
                  "FixtureProvider: Nenhum jogo encontrado para liga $leagueId.");
          } else {
            _status = FixtureListStatus.loaded;
            if (kDebugMode)
              print(
                  "FixtureProvider: Jogos carregados para liga $leagueId - ${_fixtures.length} jogos.");
          }
        },
      );
      notifyListeners();
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) return 'Erro no servidor: ${failure.message}';
    if (failure is NetworkFailure)
      return 'Falha de conexão: ${failure.message}';
    if (failure is AuthenticationFailure)
      return 'Erro de autenticação: ${failure.message}';
    if (failure is ApiFailure) return 'Erro da API: ${failure.message}';
    if (failure is NoDataFailure) return failure.message;
    return 'Erro inesperado ao buscar jogos: ${failure.message}';
  }
}
