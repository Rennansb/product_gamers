// lib/presentation/providers/fixture_provider.dart
import 'package:flutter/foundation.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_league_info_entity.dart';
import 'package:product_gamers/domain/entities/entities/team.dart';
// Para FixtureLeagueInfoEntity
import '../../domain/usecases/get_fixtures_usecase.dart';

enum FixtureListStatus { initial, loading, loaded, error, empty }

class FixtureProvider with ChangeNotifier {
  final GetFixturesUseCase _getFixturesUseCase;
  final int leagueId;
  final String season;
  bool _isDisposed = false;

  FixtureProvider({
    required GetFixturesUseCase getFixturesUseCase,
    required this.leagueId,
    required this.season,
  }) : _getFixturesUseCase = getFixturesUseCase;

  FixtureListStatus _status = FixtureListStatus.initial;
  List<Fixture> _fixtures = [];
  String? _errorMessage;

  FixtureListStatus get status => _status;
  List<Fixture> get fixtures => _fixtures;
  String? get errorMessage => _errorMessage;

  final bool _useMockData = true; // Mude para false para usar a API real

  Future<void> fetchFixtures(
      {bool forceRefresh = false, int gamesToFetch = 5}) async {
    // Reduzido gamesToFetch para mocks
    if (_isDisposed) return;
    if (_status == FixtureListStatus.loading && !forceRefresh) return;
    // ... (lógica de prevenção de fetch)

    _status = FixtureListStatus.loading;
    _errorMessage = null;
    if (forceRefresh) _fixtures = [];

    Future.microtask(() {
      if (!_isDisposed && _status == FixtureListStatus.loading)
        notifyListeners();
    });

    if (kDebugMode)
      print(
          "FixtureProvider: Buscando jogos para liga $leagueId (mock: $_useMockData)...");

    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (_isDisposed) return;

      // Criar alguns Fixtures mockados
      // Usar o leagueId para diferenciar um pouco os mocks
      String leagueNameMock = "Liga Mock $leagueId";
      if (leagueId == 39) leagueNameMock = "Premier League Mock";
      if (leagueId == 71) leagueNameMock = "Brasileirão Mock";

      _fixtures = List.generate(gamesToFetch, (index) {
        final homeTeamId = leagueId * 100 + index * 2;
        final awayTeamId = leagueId * 100 + index * 2 + 1;
        return Fixture(
            id: leagueId * 1000 + index,
            date:
                DateTime.now().add(Duration(days: index + 1, hours: index * 2)),
            statusShort: "NS",
            statusLong: "Not Started",
            homeTeam: TeamInFixture(
                id: homeTeamId,
                name: "Time Casa ${index + 1}",
                logoUrl:
                    "https://media.api-sports.io/football/teams/$homeTeamId.png"),
            awayTeam: TeamInFixture(
                id: awayTeamId,
                name: "Time Fora ${index + 1}",
                logoUrl:
                    "https://media.api-sports.io/football/teams/$awayTeamId.png"),
            league: FixtureLeagueInfoEntity(
                id: leagueId,
                name: leagueNameMock,
                season: int.tryParse(season)),
            refereeName: "Arbitro Mock ${index + 1}",
            venueName: "Estádio Mock ${index + 1}");
      });
      _status = _fixtures.isEmpty
          ? FixtureListStatus.empty
          : FixtureListStatus.loaded;
      if (_fixtures.isEmpty)
        _errorMessage = "Nenhum jogo mockado para liga $leagueId.";
      if (kDebugMode)
        print(
            "FixtureProvider: Jogos mockados carregados para liga $leagueId - ${_fixtures.length} jogos.");
    } else {
      // ===== CÓDIGO REAL DA API (MANTIDO COMENTADO) =====
      // final result = await _getFixturesUseCase(leagueId: leagueId, season: season, nextGames: gamesToFetch);
      // if (_isDisposed) return;
      // if (_status == FixtureListStatus.loading) {
      //   result.fold(
      //     (failure) { /* ... */ },
      //     (fixturesData) { /* ... */ },
      //   );
      // }
      // ====================================================
      await Future.delayed(const Duration(milliseconds: 300));
      _errorMessage = "API real desativada (usando mock).";
      _status = FixtureListStatus.error;
    }
    if (!_isDisposed) notifyListeners();
  }

  String _mapFailureToMessage(Failure failure) {
    /* ... como antes ... */ return failure.message;
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (kDebugMode) print("FixtureProvider para liga $leagueId disposed.");
    super.dispose();
  }
}

// lib/presentation/providers/fixture_provider.dart
/*
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

*/
