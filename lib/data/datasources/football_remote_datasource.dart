// lib/data/datasources/football_remote_datasource.dart
import 'dart:convert';
import 'dart:io'; // Para SocketException
import 'dart:async'; // Para TimeoutException
import 'dart:math'; // Para a simulação no getRefereeDetailsAndAggregateStats
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/data/models/team_season_aggregated_stats_model.dart';
import 'package:product_gamers/data/repositories/football_repository.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';
import 'package:product_gamers/domain/entities/entities/lineup.dart';
import 'package:product_gamers/domain/entities/entities/live_fixture_update.dart';
import 'package:product_gamers/domain/entities/entities/player_stats.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
import 'package:product_gamers/domain/entities/entities/referee_stats.dart';
import 'package:product_gamers/domain/entities/entities/standing_info.dart';
import 'package:product_gamers/domain/entities/entities/team_aggregated_stats.dart';

// Core
import '../../core/config/app_constants.dart';
import '../../core/error/exceptions.dart';

// Models (Certifique-se de que TODOS estes arquivos existem em lib/data/models/)
import '../models/league_model.dart';
import '../models/fixture_model.dart';
import '../models/fixture_odds_response_model.dart';
import '../models/fixture_statistics_response_model.dart';
import '../models/player_season_stats_model.dart'; // Contém PlayerInfoModel e PlayerCompetitionStatsModel
import '../models/referee_stats_model.dart'; // Contém RefereeSeasonGamesModel
import '../models/league_standings_model.dart'; // Contém StandingItemModel e StandingStatsModel
import '../models/live_fixture_update_model.dart'; // Contém LiveGameEventModel e TeamLiveStatsDataModel
import '../models/team_model.dart'; // Usado por vários outros modelos
import '../models/referee_search_result_model.dart';
import '../models/fixture_lineups_response_model.dart'; // Contém TeamLineupModel e LineupPlayerModel
// Contém AggregatedGoalsStatsModel

// Interface para o Data Source Remoto
abstract class FootballRemoteDataSource {
  Future<List<LeagueModel>> getLeagues();
  Future<List<FixtureModel>> getFixturesForLeague(int leagueId, String season,
      {int nextGames = 15});
  Future<FixtureOddsResponseModel> getOddsForFixture(int fixtureId,
      {int? bookmakerId});
  Future<FixtureOddsResponseModel> fetchLiveOddsForFixture(int fixtureId,
      {int? bookmakerId});
  Future<FixtureStatisticsResponseModel> getFixtureStatistics(
      {required int fixtureId,
      required int homeTeamId,
      required int awayTeamId});
  Future<List<FixtureModel>> getHeadToHead(
      {required int team1Id,
      required int team2Id,
      int lastN = 10,
      String? status});
  Future<List<PlayerSeasonStatsModel>> getPlayersFromSquad(
      {required int teamId});
  Future<PlayerSeasonStatsModel?> getPlayerStats(
      {required int playerId, required String season});
  Future<List<PlayerSeasonStatsModel>> getLeagueTopScorers(
      {required int leagueId, required String season, int topN = 10});
  Future<RefereeStatsModel> getRefereeDetailsAndAggregateStats(
      {required int refereeId, required String season});
  Future<LeagueStandingsModel?> getLeagueStandings(
      {required int leagueId, required String season});
  Future<LiveFixtureUpdateModel> fetchLiveFixtureUpdate(int fixtureId);
  Future<List<RefereeSearchResultModel>> searchRefereeByName(
      {required String name});
  Future<FixtureLineupsResponseModel?> getFixtureLineups(
      {required int fixtureId,
      required int homeTeamId,
      required int awayTeamId});
  Future<List<FixtureModel>> getTeamRecentFixtures(
      {required int teamId, int lastN = 5, String? status});
  Future<TeamSeasonAggregatedStatsModel?> getTeamSeasonAggregatedStats(
      {required int teamId, required int leagueId, required String season});
}

// -------------------- IMPLEMENTAÇÃO --------------------
class FootballRemoteDataSourceImpl implements FootballRemoteDataSource {
  final http.Client client; // Declarado como campo da classe

  FootballRemoteDataSourceImpl({required this.client}); // Construtor correto

  // _headers como um getter da classe
  Map<String, String> get _headers => {
        'x-rapidapi-key': AppConstants.rapidApiKey,
        'x-rapidapi-host': AppConstants.rapidApiHost,
        'Content-Type': 'application/json',
      };

  // _get como um método da classe
  Future<T> _get<T>(
    String endpoint,
    T Function(dynamic jsonResponse) parser, {
    String? queryParams,
  }) async {
    final Uri url =
        Uri.parse('${AppConstants.baseUrl}$endpoint${queryParams ?? ''}');
    if (kDebugMode) print("API Call: $url");

    try {
      final response = await this
          .client
          .get(url, headers: _headers) // Uso de this.client e _headers
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        final errors = jsonResponse['errors'];
        if (errors != null &&
            ((errors is List && errors.isNotEmpty) ||
                (errors is Map && errors.isNotEmpty) ||
                (errors is String && errors.isNotEmpty))) {
          String errorMessage = "Erro da API: ";
          if (errors is List)
            errorMessage += errors.join(", ");
          else if (errors is Map)
            errors.forEach((key, value) => errorMessage += "$key: $value; ");
          else if (errors is String) errorMessage += errors;

          if (kDebugMode) print("API-Football Error Response: $errorMessage");
          if (errorMessage.toLowerCase().contains("rate limit") ||
              errorMessage.toLowerCase().contains("quota")) {
            throw ApiException(
                message: "Limite de requisições da API excedido.");
          }
          if (errorMessage.toLowerCase().contains("invalid") &&
              errorMessage.toLowerCase().contains("key")) {
            throw AuthenticationException(
                message: "Chave de API inválida ou não fornecida.");
          }
          throw ApiException(message: errorMessage.trim());
        }

        final resultsCount = jsonResponse['results'];
        if (resultsCount != null &&
            resultsCount == 0 &&
            (jsonResponse['response'] == null ||
                (jsonResponse['response'] is List &&
                    jsonResponse['response'].isEmpty))) {
          final allowedEmptyEndpoints = [
            "/odds",
            "/fixtures/lineups",
            "/fixtures/headtohead",
            "/referees"
          ];
          if (!allowedEmptyEndpoints.any((e) => endpoint.contains(e))) {
            throw NoDataException(
                message:
                    "Nenhum dado encontrado para: $endpoint${queryParams ?? ''} (API results: 0)");
          }
        }
        return parser(jsonResponse['response'] ?? jsonResponse);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthenticationException(
            message:
                "API Key inválida/não autorizada (Status: ${response.statusCode}).");
      } else if (response.statusCode == 429 || response.statusCode == 499) {
        throw ApiException(
            message:
                "Limite de requisições da API excedido (Status: ${response.statusCode}).");
      } else if (response.statusCode >= 500) {
        throw ServerException(
            message:
                'Erro no servidor da API (Status: ${response.statusCode}).',
            statusCode: response.statusCode);
      } else {
        final String bodyMessage = response.body.isNotEmpty
            ? "Detalhes: ${response.body.substring(0, min(200, response.body.length))}"
            : "(sem corpo na resposta)";
        throw ServerException(
            message:
                'Erro na API (Status: ${response.statusCode}). $bodyMessage',
            statusCode: response.statusCode);
      }
    } on SocketException catch (e) {
      throw NetworkException(
          message:
              "Sem conexão com a internet ou API indisponível. (${e.message})");
    } on TimeoutException {
      throw NetworkException(
          message: "Tempo limite da requisição para API excedido.");
    } on NoDataException {
      rethrow;
    } catch (e) {
      if (kDebugMode)
        print(
            "Erro DataSource _get $endpoint: $e (${e.runtimeType.toString()})");
      if (e is FormatException) {
        throw ServerException(
            message:
                "Erro ao processar resposta da API (FormatException): ${e.message}");
      }
      throw ServerException(
          message: "Erro inesperado na chamada API: ${e.toString()}");
    }
  }

  @override
  Future<List<LeagueModel>> getLeagues() async {
    List<LeagueModel> leagues = [];
    for (var entry in AppConstants.popularLeagues.entries) {
      final String endpoint = '/leagues';
      final String queryParams = '?id=${entry.value}';
      try {
        final List<dynamic> responseList = await _get(
            endpoint, (jsonR) => (jsonR is List) ? jsonR : [],
            queryParams: queryParams);
        if (responseList.isNotEmpty &&
            responseList.first is Map<String, dynamic>) {
          leagues.add(
              LeagueModel.fromJson(responseList.first as Map<String, dynamic>)
                  .copyWith(friendlyName: entry.key));
        }
      } on NoDataException catch (e) {
        if (kDebugMode) print("NoData Liga ${entry.key}: ${e.message}");
      } catch (e) {
        if (kDebugMode) print("Erro Liga ${entry.key}: $e");
      }
    }
    if (leagues.isEmpty && AppConstants.popularLeagues.isNotEmpty)
      throw NoDataException(message: "Nenhuma liga popular carregada.");
    return leagues;
  }

  @override
  Future<List<FixtureModel>> getFixturesForLeague(int leagueId, String season,
      {int nextGames = 15}) async {
    final endpoint = '/fixtures';
    final queryParams =
        '?league=$leagueId&season=$season&next=$nextGames&status=NS';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List) {
        if (jsonResponse is Map &&
            jsonResponse.isEmpty &&
            (jsonResponse['results'] == 0 || jsonResponse['results'] == null))
          return <FixtureModel>[];
        throw ServerException(
            message: "Formato inesperado para fixtures: $leagueId");
      }
      return (jsonResponse)
          .map((item) => FixtureModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<FixtureOddsResponseModel> getOddsForFixture(int fixtureId,
      {int? bookmakerId}) async {
    final bkId = bookmakerId ?? AppConstants.preferredBookmakerId;
    final endpoint = '/odds';
    final queryParams = '?fixture=$fixtureId&bookmaker=$bkId';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List) {
        if (jsonResponse is Map && jsonResponse.isEmpty)
          return FixtureOddsResponseModel(fixtureId: fixtureId, bookmakers: []);
        throw ServerException(
            message: "Formato inesperado para odds pré-jogo.");
      }
      return FixtureOddsResponseModel.fromApiResponse(jsonResponse, fixtureId);
    }, queryParams: queryParams);
  }

  @override
  Future<FixtureOddsResponseModel> fetchLiveOddsForFixture(int fixtureId,
      {int? bookmakerId}) async {
    return getOddsForFixture(fixtureId, bookmakerId: bookmakerId);
  }

  @override
  Future<FixtureStatisticsResponseModel> getFixtureStatistics(
      {required int fixtureId,
      required int homeTeamId,
      required int awayTeamId}) async {
    final endpoint = '/fixtures/statistics';
    final queryParams = '?fixture=$fixtureId';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List) {
        if (jsonResponse is Map &&
            jsonResponse.isEmpty &&
            (jsonResponse['results'] == 0 || jsonResponse['results'] == null))
          return FixtureStatisticsResponseModel.fromJson([],
              homeTeamId: homeTeamId, awayTeamId: awayTeamId);
        throw ServerException(
            message: "Formato inesperado para estatísticas da partida.");
      }
      return FixtureStatisticsResponseModel.fromJson(jsonResponse,
          homeTeamId: homeTeamId, awayTeamId: awayTeamId);
    }, queryParams: queryParams);
  }

  @override
  Future<List<FixtureModel>> getHeadToHead(
      {required int team1Id,
      required int team2Id,
      int lastN = 10,
      String? status}) async {
    final endpoint = '/fixtures/headtohead';
    String queryParams = '?h2h=${team1Id}-${team2Id}&last=$lastN';
    if (status != null && status.isNotEmpty) queryParams += '&status=$status';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List) {
        if (jsonResponse is Map &&
            jsonResponse.isEmpty &&
            (jsonResponse['results'] == 0 || jsonResponse['results'] == null))
          return <FixtureModel>[];
        throw ServerException(message: "Formato inesperado para H2H.");
      }
      return (jsonResponse)
          .map((item) => FixtureModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<List<PlayerSeasonStatsModel>> getPlayersFromSquad(
      {required int teamId}) async {
    final endpoint = '/players/squads';
    final queryParams = '?team=$teamId';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List || jsonResponse.isEmpty) return [];
      final squadData = jsonResponse.first as Map<String, dynamic>;
      final playersListJson = squadData['players'] as List<dynamic>? ?? [];
      return playersListJson
          .map((playerJson) => PlayerSeasonStatsModel.fromJson(
              {'player': playerJson, 'statistics': []}))
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<PlayerSeasonStatsModel?> getPlayerStats(
      {required int playerId, required String season}) async {
    final endpoint = '/players';
    final queryParams = '?id=$playerId&season=$season';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List || jsonResponse.isEmpty) return null;
      return PlayerSeasonStatsModel.fromJson(
          jsonResponse.first as Map<String, dynamic>);
    }, queryParams: queryParams);
  }

  @override
  Future<List<PlayerSeasonStatsModel>> getLeagueTopScorers(
      {required int leagueId, required String season, int topN = 10}) async {
    final endpoint = '/players/topscorers';
    final queryParams = '?league=$leagueId&season=$season';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List)
        throw ServerException(message: "Formato inesperado para artilheiros.");
      return (jsonResponse)
          .map((item) =>
              PlayerSeasonStatsModel.fromJson(item as Map<String, dynamic>))
          .take(topN)
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<RefereeStatsModel> getRefereeDetailsAndAggregateStats(
      {required int refereeId, required String season}) async {
    final String refereeDetailsEndpoint = '/referees';
    final String refereeDetailsQueryParams = '?id=$refereeId';
    final refereeBaseModel = await _get(refereeDetailsEndpoint, (jsonResponse) {
      if (jsonResponse is! List || jsonResponse.isEmpty)
        throw NoDataException(
            message: "Árbitro com ID $refereeId não encontrado.");
      return RefereeStatsModel.fromJson(
          jsonResponse.first as Map<String, dynamic>);
    }, queryParams: refereeDetailsQueryParams);

    final String fixturesOfficiatedEndpoint = '/fixtures';
    final String fixturesOfficiatedQueryParams =
        '?referee=$refereeId&season=$season&status=FT&last=50';

    int totalYellowAggregated = 0;
    int totalRedAggregated = 0;
    int gamesCountForAggregation = 0;

    try {
      final List<dynamic> jsonResponseFixtures =
          await _get(fixturesOfficiatedEndpoint, (jsonResponse) {
        if (jsonResponse is! List) return [];
        return jsonResponse;
      }, queryParams: fixturesOfficiatedQueryParams);

      for (var fixtureJsonRaw in jsonResponseFixtures) {
        if (fixtureJsonRaw is! Map<String, dynamic>) continue;
        final fixtureWithEvents = FixtureModel.fromJson(fixtureJsonRaw);

        if (fixtureWithEvents.totalYellowCardsInFixture != null ||
            fixtureWithEvents.totalRedCardsInFixture != null) {
          totalYellowAggregated +=
              fixtureWithEvents.totalYellowCardsInFixture ?? 0;
          totalRedAggregated += fixtureWithEvents.totalRedCardsInFixture ?? 0;
          gamesCountForAggregation++;
        } else if (fixtureWithEvents.status.shortName == "FT") {
          gamesCountForAggregation++;
        }
      }
    } on NoDataException {
      if (kDebugMode)
        print(
            "DataSource: Nenhum jogo para árbitro $refereeId na temp. $season para agregar cartões.");
    }

    final aggregatedStatsList = gamesCountForAggregation > 0
        ? [
            RefereeSeasonGamesModel(
              leagueName: "Agregado $season",
              gamesOfficiated: gamesCountForAggregation,
              totalYellowCards: totalYellowAggregated,
              totalRedCards: totalRedAggregated,
            )
          ]
        : <RefereeSeasonGamesModel>[];

    return refereeBaseModel.copyWithAggregatedStats(aggregatedStatsList);
  }

  @override
  Future<LeagueStandingsModel?> getLeagueStandings(
      {required int leagueId, required String season}) async {
    final String endpoint = '/standings';
    final String queryParams = '?league=$leagueId&season=$season';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List || jsonResponse.isEmpty) return null;
      return LeagueStandingsModel.fromJson(
          jsonResponse.first as Map<String, dynamic>);
    }, queryParams: queryParams);
  }

  @override
  Future<LiveFixtureUpdateModel> fetchLiveFixtureUpdate(int fixtureId) async {
    final String endpoint = '/fixtures';
    final String queryParams = '?id=$fixtureId';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List || jsonResponse.isEmpty)
        throw ServerException(
            message: "Nenhum dado ao vivo para fixture $fixtureId.");
      return LiveFixtureUpdateModel.fromJson(
          jsonResponse.first as Map<String, dynamic>);
    }, queryParams: queryParams);
  }

  @override
  Future<List<RefereeSearchResultModel>> searchRefereeByName(
      {required String name}) async {
    final String endpoint = '/referees';
    final String queryParams = '?search=${Uri.encodeComponent(name)}';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List) return [];
      return (jsonResponse)
          .map((item) =>
              RefereeSearchResultModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<FixtureLineupsResponseModel?> getFixtureLineups(
      {required int fixtureId,
      required int homeTeamId,
      required int awayTeamId}) async {
    final String endpoint = '/fixtures/lineups';
    final String queryParams = '?fixture=$fixtureId';
    try {
      return await _get(endpoint, (jsonResponse) {
        if (jsonResponse is! List || jsonResponse.isEmpty) return null;
        return FixtureLineupsResponseModel.fromApiList(jsonResponse,
            homeTeamIdApi: homeTeamId, awayTeamIdApi: awayTeamId);
      }, queryParams: queryParams);
    } on NoDataException {
      return null;
    }
  }

  @override
  Future<List<FixtureModel>> getTeamRecentFixtures(
      {required int teamId, int lastN = 5, String? status = 'FT'}) async {
    final String endpoint = '/fixtures';
    String queryParams = '?team=$teamId&last=$lastN';
    if (status != null && status.isNotEmpty) queryParams += '&status=$status';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List)
        throw ServerException(
            message: "Formato inesperado para jogos recentes do time.");
      return (jsonResponse)
          .map((item) => FixtureModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<TeamSeasonAggregatedStatsModel?> getTeamSeasonAggregatedStats({
    required int teamId,
    required int leagueId,
    required String season,
  }) async {
    final String endpoint = '/teams/statistics';
    final String queryParams = '?team=$teamId&league=$leagueId&season=$season';
    try {
      return await _get(endpoint, (jsonResponse) {
        if (jsonResponse == null ||
            (jsonResponse is Map &&
                jsonResponse.isEmpty &&
                (jsonResponse['results'] == 0 ||
                    jsonResponse['results'] == null))) return null;
        return TeamSeasonAggregatedStatsModel.fromJson(
            jsonResponse as Map<String, dynamic>,
            fallbackTeamId: teamId,
            fallbackLeagueId: leagueId,
            fallbackSeason: season);
      }, queryParams: queryParams);
    } on NoDataException {
      return null;
    }
  }
}
