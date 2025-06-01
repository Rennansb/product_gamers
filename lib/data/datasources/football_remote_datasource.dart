// lib/data/datasources/football_remote_datasource.dart
import 'dart:convert';
import 'dart:io'; // Para SocketException
import 'dart:async'; // Para TimeoutException
import 'dart:math'; // Para a simulação no getRefereeDetailsAndAggregateStats
import 'package:http/http.dart' as http;
import 'package:product_gamers/data/models/team_season_aggregated_stats_model.dart';

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

  Future<List<FixtureModel>> getFixturesForLeague(
    int leagueId,
    String season, {
    int nextGames = 15,
  });

  Future<FixtureOddsResponseModel> getOddsForFixture(
    // Pré-jogo
    int fixtureId, {
    int? bookmakerId,
  });

  Future<FixtureOddsResponseModel> fetchLiveOddsForFixture(
    // Ao Vivo
    int fixtureId, {
    int? bookmakerId,
  });

  Future<FixtureStatisticsResponseModel> getFixtureStatistics({
    required int fixtureId,
    required int homeTeamId,
    required int awayTeamId,
  });

  Future<List<FixtureModel>> getHeadToHead({
    required int team1Id,
    required int team2Id,
    int lastN = 10,
    String? status,
  });

  Future<List<PlayerSeasonStatsModel>> getPlayersFromSquad({
    // Retorna lista, pois /squads dá info de player sem stats de competição detalhadas
    required int teamId,
  });

  Future<PlayerSeasonStatsModel?> getPlayerStats({
    // Retorna um único jogador com suas stats detalhadas de competições
    required int playerId,
    required String season,
  });

  Future<List<PlayerSeasonStatsModel>> getLeagueTopScorers({
    required int leagueId,
    required String season,
    int topN = 10,
  });

  Future<RefereeStatsModel> getRefereeDetailsAndAggregateStats({
    required int refereeId,
    required String season,
  });

  Future<LeagueStandingsModel?> getLeagueStandings({
    required int leagueId,
    required String season,
  });

  Future<LiveFixtureUpdateModel> fetchLiveFixtureUpdate(int fixtureId);

  Future<List<RefereeSearchResultModel>> searchRefereeByName({
    required String name,
  });

  Future<FixtureLineupsResponseModel?> getFixtureLineups({
    required int fixtureId,
    required int homeTeamId,
    required int awayTeamId,
  });

  Future<List<FixtureModel>> getTeamRecentFixtures({
    // Para forma do time
    required int teamId,
    int lastN = 5,
    String? status,
  });

  Future<TeamSeasonAggregatedStatsModel?> getTeamSeasonAggregatedStats({
    // Para stats agregadas da temporada
    required int teamId,
    required int leagueId,
    required String season,
  });
}

// Implementação do Data Source Remoto
class FootballRemoteDataSourceImpl implements FootballRemoteDataSource {
  final http.Client client;

  FootballRemoteDataSourceImpl({required this.client});

  Map<String, String> get _headers => {
        'x-rapidapi-key': AppConstants.rapidApiKey,
        'x-rapidapi-host': AppConstants.rapidApiHost,
        'Content-Type': 'application/json',
      };

  Future<T> _get<T>(
    String endpoint,
    T Function(dynamic jsonResponse) parser, {
    String? queryParams,
  }) async {
    final Uri url =
        Uri.parse('${AppConstants.baseUrl}$endpoint${queryParams ?? ''}');
    // print("API Call: $url");

    try {
      final response = await this
          .client
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));

        final errors = jsonResponse['errors'];
        if (errors != null &&
            ((errors is List && errors.isNotEmpty) ||
                (errors is Map &&
                    errors.isNotEmpty &&
                    (errors as Map)
                        .isNotEmpty) || // Simplificado (isNotEmpty já checa)
                (errors is String && errors.isNotEmpty))) {
          String errorMessage = "Erro da API: ";
          if (errors is List)
            errorMessage += errors.join(", ");
          else if (errors is Map)
            errors.forEach((key, value) => errorMessage += "$key: $value; ");
          else if (errors is String) errorMessage += errors;

          print("API-Football Error Response: $errorMessage");
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
          // Alguns endpoints podem retornar results:0 e response:[] como válido se não houver dados.
          // Ex: /odds, /fixtures/lineups
          // Para outros, isso pode significar "No Data".
          if (!endpoint.contains("/odds") &&
              !endpoint.contains("/fixtures/lineups") &&
              !endpoint.contains("/fixtures/headtohead")) {
            throw NoDataException(
                message:
                    "Nenhum dado encontrado para: $endpoint${queryParams ?? ''} (results: 0)");
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
            ? "Detalhes: ${response.body.substring(0, (response.body.length > 200 ? 200 : response.body.length))}"
            : "";
        throw ServerException(
            message:
                'Erro na API (Status: ${response.statusCode}). $bodyMessage',
            statusCode: response.statusCode);
      }
    } on SocketException catch (e) {
      throw NetworkException(
          message:
              "Sem conexão com a internet ou servidor da API indisponível. (${e.message})");
    } on TimeoutException {
      throw NetworkException(
          message: "Tempo limite da requisição para API excedido.");
    } on NoDataException {
      // Propaga NoDataException
      rethrow;
    } catch (e) {
      print(
          "Erro desconhecido no DataSource em _get para $endpoint: $e (${e.runtimeType.toString()})");
      if (e is FormatException) {
        throw ServerException(
            message:
                "Erro ao processar a resposta da API (FormatException): ${e.message}");
      }
      throw ServerException(
          message: "Erro inesperado na chamada à API: ${e.toString()}");
    }
  }

  @override
  Future<List<LeagueModel>> getLeagues() async {
    List<LeagueModel> leagues = [];
    for (var entry in AppConstants.popularLeagues.entries) {
      final String endpoint = '/leagues';
      final String queryParams = '?id=${entry.value}';
      try {
        final List<dynamic> responseList = await _get(endpoint, (jsonResponse) {
          if (jsonResponse is List) return jsonResponse;
          return [];
        }, queryParams: queryParams);

        if (responseList.isNotEmpty &&
            responseList.first is Map<String, dynamic>) {
          final leagueData =
              LeagueModel.fromJson(responseList.first as Map<String, dynamic>);
          leagues.add(leagueData.copyWith(friendlyName: entry.key));
        } else {
          // Não loga erro aqui, pois NoDataException de _get deve ter sido lançada se 'results' era 0
        }
      } on NoDataException catch (e) {
        print(
            "Dados não encontrados para liga ${entry.key} (ID: ${entry.value}): ${e.message}.");
      } catch (e) {
        print(
            "Erro ao buscar detalhes da liga ${entry.key} (ID: ${entry.value}): $e. Pulando esta liga.");
      }
    }
    if (leagues.isEmpty && AppConstants.popularLeagues.isNotEmpty) {
      throw NoDataException(
          message:
              "Nenhuma das ligas populares pôde ser carregada. Verifique sua chave de API e conexão.");
    }
    return leagues;
  }

  @override
  Future<List<FixtureModel>> getFixturesForLeague(int leagueId, String season,
      {int nextGames = 15}) async {
    final String endpoint = '/fixtures';
    final String queryParams =
        '?league=$leagueId&season=$season&next=$nextGames&status=NS';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List) {
        if (jsonResponse is Map && jsonResponse.isEmpty)
          return <FixtureModel>[];
        throw ServerException(
            message:
                "Formato de resposta inesperado para fixtures da liga $leagueId.");
      }
      return (jsonResponse as List)
          .map((item) => FixtureModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<FixtureOddsResponseModel> getOddsForFixture(int fixtureId,
      {int? bookmakerId}) async {
    final int bkId = bookmakerId ?? AppConstants.preferredBookmakerId;
    final String endpoint = '/odds';
    final String queryParams = '?fixture=$fixtureId&bookmaker=$bkId';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List) {
        if (jsonResponse is Map && jsonResponse.isEmpty)
          return FixtureOddsResponseModel(fixtureId: fixtureId, bookmakers: []);
        throw ServerException(
            message: "Formato de resposta inesperado para odds pré-jogo.");
      }
      return FixtureOddsResponseModel.fromApiResponse(
          jsonResponse as List<dynamic>, fixtureId);
    }, queryParams: queryParams);
  }

  @override
  Future<FixtureOddsResponseModel> fetchLiveOddsForFixture(int fixtureId,
      {int? bookmakerId}) async {
    // Assume que o mesmo endpoint de odds retorna dados ao vivo se o jogo estiver em andamento.
    return getOddsForFixture(fixtureId, bookmakerId: bookmakerId);
  }

  @override
  Future<FixtureStatisticsResponseModel> getFixtureStatistics(
      {required int fixtureId,
      required int homeTeamId,
      required int awayTeamId}) async {
    final String endpoint = '/fixtures/statistics';
    final String queryParams =
        '?fixture=$fixtureId'; // A API também pode aceitar &team=ID para filtrar, mas geralmente retorna ambos.
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List) {
        if (jsonResponse is Map && jsonResponse.isEmpty)
          return FixtureStatisticsResponseModel.fromJson([],
              homeTeamId: homeTeamId, awayTeamId: awayTeamId);
        throw ServerException(
            message:
                "Formato de resposta inesperado para estatísticas da partida.");
      }
      return FixtureStatisticsResponseModel.fromJson(
          jsonResponse as List<dynamic>,
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId);
    }, queryParams: queryParams);
  }

  @override
  Future<List<FixtureModel>> getHeadToHead(
      {required int team1Id,
      required int team2Id,
      int lastN = 10,
      String? status}) async {
    final String endpoint = '/fixtures/headtohead';
    String queryParams = '?h2h=${team1Id}-${team2Id}&last=$lastN';
    if (status != null && status.isNotEmpty) queryParams += '&status=$status';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List) {
        if (jsonResponse is Map && jsonResponse.isEmpty)
          return <FixtureModel>[];
        throw ServerException(
            message: "Formato de resposta inesperado para H2H.");
      }
      return (jsonResponse as List)
          .map((item) => FixtureModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<List<PlayerSeasonStatsModel>> getPlayersFromSquad(
      {required int teamId}) async {
    final String endpoint = '/players/squads';
    final String queryParams = '?team=$teamId';
    return _get(endpoint, (jsonResponse) {
      // jsonResponse aqui é a lista que contém um objeto de time com a lista de jogadores
      if (jsonResponse is! List || jsonResponse.isEmpty) return [];
      final squadData = jsonResponse.first as Map<String, dynamic>;
      final playersListJson = squadData['players'] as List<dynamic>? ?? [];
      return playersListJson
          .map((playerJson) =>
              // PlayerSeasonStatsModel.fromJson espera um JSON com 'player' e 'statistics'
              PlayerSeasonStatsModel.fromJson(
                  {'player': playerJson, 'statistics': []}))
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<PlayerSeasonStatsModel?> getPlayerStats(
      {required int playerId, required String season}) async {
    final String endpoint = '/players';
    final String queryParams = '?id=$playerId&season=$season';
    return _get(endpoint, (jsonResponse) {
      // jsonResponse aqui é a lista que contém o jogador
      if (jsonResponse is! List || jsonResponse.isEmpty) return null;
      return PlayerSeasonStatsModel.fromJson(
          jsonResponse.first as Map<String, dynamic>);
    }, queryParams: queryParams);
  }

  @override
  Future<List<PlayerSeasonStatsModel>> getLeagueTopScorers(
      {required int leagueId, required String season, int topN = 10}) async {
    final String endpoint = '/players/topscorers';
    final String queryParams = '?league=$leagueId&season=$season';
    return _get(endpoint, (jsonResponse) {
      // jsonResponse aqui é a lista de jogadores artilheiros
      if (jsonResponse is! List)
        throw ServerException(
            message: "Formato de resposta inesperado para artilheiros.");
      return (jsonResponse as List)
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
      // jsonResponse é a lista com o árbitro
      if (jsonResponse is! List || jsonResponse.isEmpty)
        throw ServerException(
            message: "Árbitro com ID $refereeId não encontrado.");
      return RefereeStatsModel.fromJson(
          jsonResponse.first as Map<String, dynamic>);
    }, queryParams: refereeDetailsQueryParams);

    final String fixturesOfficiatedEndpoint = '/fixtures';
    final String fixturesOfficiatedQueryParams =
        '?referee=$refereeId&season=$season&status=FT';

    int totalYellowAggregated = 0;
    int totalRedAggregated = 0;
    int gamesCountForAggregation = 0;

    try {
      await _get(fixturesOfficiatedEndpoint, (jsonResponseFixtures) {
        // jsonResponseFixtures é a lista de jogos
        if (jsonResponseFixtures is! List) return;
        for (var fixtureJsonRaw in (jsonResponseFixtures as List)) {
          // ** SIMULAÇÃO DE AGREGAÇÃO DE CARTÕES - SUBSTITUA PELA LÓGICA REAL **
          // Você precisa extrair os cartões de 'fixtureJsonRaw' (que é um Map<String, dynamic> de um fixture)
          // Se FixtureModel.fromJson puder parsear cartões totais do jogo, use-o, ou lógica similar.
          // Exemplo (assumindo que fixtureJsonRaw tem os dados para isso, o que não é garantido):
          // final fixtureForCards = FixtureModel.fromJson(fixtureJsonRaw);
          // totalYellowAggregated += fixtureForCards.totalYellowCardsInFixture ?? (Random().nextInt(3) + 1);
          // totalRedAggregated += fixtureForCards.totalRedCardsInFixture ?? (Random().nextDouble() < 0.1 ? 1: 0) ;
          totalYellowAggregated += Random().nextInt(3) + 1;
          if (Random().nextDouble() < 0.1) totalRedAggregated++;
          gamesCountForAggregation++;
        }
      }, queryParams: fixturesOfficiatedQueryParams);
    } on NoDataException {
      // Captura se _get para jogos do árbitro lançar NoData
      print(
          "Nenhum jogo finalizado encontrado para o árbitro $refereeId na temporada $season para agregar estatísticas de cartões.");
    } // Outros erros serão propagados por _get e tratados pelo _tryCatch no repositório.

    final aggregatedStatsList = gamesCountForAggregation > 0
        ? [
            RefereeSeasonGamesModel(
              leagueName: "Agregado $season", // Nome genérico
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
      // jsonResponse é a lista com um objeto league+standings
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
      // jsonResponse é a lista com o fixture
      if (jsonResponse is! List || jsonResponse.isEmpty)
        throw ServerException(
            message: "Nenhum dado ao vivo encontrado para fixture $fixtureId.");
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
      // jsonResponse é a lista de árbitros encontrados
      if (jsonResponse is! List) return [];
      return (jsonResponse as List)
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
        // jsonResponse é a lista com 2 times e suas lineups
        if (jsonResponse is! List || jsonResponse.isEmpty) return null;
        return FixtureLineupsResponseModel.fromApiList(
            jsonResponse as List<dynamic>,
            homeTeamIdApi: homeTeamId,
            awayTeamIdApi: awayTeamId);
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
    if (status != null && status.isNotEmpty) {
      queryParams += '&status=$status';
    }
    return _get(endpoint, (jsonResponse) {
      // jsonResponse é a lista de fixtures
      if (jsonResponse is! List)
        throw ServerException(
            message:
                "Formato de resposta inesperado para jogos recentes do time.");
      return (jsonResponse as List)
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
        // /teams/statistics retorna um objeto direto, não uma lista
        if (jsonResponse == null ||
            (jsonResponse is Map && jsonResponse.isEmpty)) {
          return null;
        }
        return TeamSeasonAggregatedStatsModel.fromJson(
            jsonResponse as Map<String, dynamic>,
            leagueId,
            season as int,
            teamId as String);
      }, queryParams: queryParams);
    } on NoDataException {
      return null;
    }
  }
}
