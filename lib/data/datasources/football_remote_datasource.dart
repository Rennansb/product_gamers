// lib/data/datasources/football_remote_datasource.dart
import 'dart:convert';
import 'dart:io'; // Para SocketException
import 'dart:async'; // Para TimeoutException
import 'dart:math'; // Para a simulação no getRefereeDetailsAndAggregateStats
import 'package:http/http.dart' as http;
import 'package:product_gamers/data/models/fixture_statistics_response_model.dart';
import 'package:product_gamers/data/models/live_fixture_update_model.dart';
import 'package:product_gamers/data/models/player_season_stats_model.dart';
import 'package:product_gamers/data/models/referee_stats_model.dart';
import '../../core/config/app_constants.dart';
import '../../core/error/exceptions.dart';

// Importe todos os seus modelos aqui à medida que os cria
import '../models/league_model.dart';
import '../models/fixture_model.dart';
import '../models/fixture_odds_response_model.dart'; // Odds pré-jogo

// ===== INÍCIO DOS IMPORTS QUE FALTAVAM =====
// Este importará RefereeSeasonGamesModel também se estiver no mesmo arquivo ou referenciado.
// Se RefereeSeasonGamesModel for um arquivo separado, importe-o.
import '../models/league_standings_model.dart';

// Se RefereeSeasonGamesModel estiver em um arquivo separado:
// import '../models/referee_season_games_model.dart';
// ===== FIM DOS IMPORTS QUE FALTAVAM =====

abstract class FootballRemoteDataSource {
  Future<List<LeagueModel>> getLeagues();
  Future<List<FixtureModel>> getFixturesForLeague(
    int leagueId,
    String season, {
    int nextGames = 15, // Default value for optional named parameter
  });
  Future<FixtureOddsResponseModel> getOddsForFixture(
    int fixtureId, {
    int? bookmakerId,
  });
  Future<FixtureOddsResponseModel> fetchLiveOddsForFixture(
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
    required int teamId,
  });
  Future<PlayerSeasonStatsModel?> getPlayerStats({
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
}

// Implementação
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
    final Uri url = Uri.parse(
      '${AppConstants.baseUrl}$endpoint${queryParams ?? ''}',
    );
    // print("Chamando API: $url"); // Para Debug
    try {
      final response = await client
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['errors'] != null &&
            ((jsonResponse['errors'] is List &&
                    (jsonResponse['errors'] as List).isNotEmpty) ||
                (jsonResponse['errors'] is Map &&
                    (jsonResponse['errors'] as Map).isNotEmpty &&
                    (jsonResponse['errors'] as Map).length > 0) ||
                (jsonResponse['errors'] is String &&
                    (jsonResponse['errors'] as String).isNotEmpty))) {
          String errorMessage = "Erro da API: ";
          if (jsonResponse['errors'] is List) {
            errorMessage += (jsonResponse['errors'] as List).join(", ");
          } else if (jsonResponse['errors'] is Map) {
            (jsonResponse['errors'] as Map).forEach((key, value) {
              errorMessage += "$key: $value; ";
            });
          } else if (jsonResponse['errors'] is String) {
            errorMessage += jsonResponse['errors'];
          }

          print("Erro da API-Football: $errorMessage");
          if (errorMessage.toLowerCase().contains("rate limit") ||
              errorMessage.toLowerCase().contains(
                "you have exceeded your an api key quota",
              ) ||
              errorMessage.toLowerCase().contains(
                "you have exceeded your quota",
              ) // Outra variação comum
              ) {
            throw ApiException(
              message:
                  "Limite de requisições da API excedido. Tente novamente mais tarde.",
            );
          }
          if (errorMessage.toLowerCase().contains(
                "invalid or unprovided api key",
              ) ||
              errorMessage.toLowerCase().contains(
                "invalid key",
              ) || // Outra variação
              errorMessage.toLowerCase().contains("api key not valid")) {
            throw AuthenticationException(
              message: "Chave de API inválida ou não fornecida.",
            );
          }
          throw ApiException(message: errorMessage.trim());
        }

        // A API-Football usa o campo 'results' para indicar o número de resultados retornados
        // e 'paging' para paginação. Se 'results' for 0, significa que não há dados para os parâmetros.
        if (jsonResponse['results'] == 0 &&
            (jsonResponse['response'] == null ||
                (jsonResponse['response'] is List &&
                    jsonResponse['response'].isEmpty))) {
          // Lançar NoDataException se 'results' for 0, para ser tratado como "sem dados" em vez de erro de parsing.
          // Exceto para alguns endpoints como /odds que podem retornar lista vazia validamente.
          if (!endpoint.contains("/odds")) {
            // Endpoints de odds podem retornar lista vazia se não houver odds.
            throw NoDataException(
              message:
                  "Nenhum dado encontrado para os parâmetros fornecidos em $endpoint.",
            );
          }
        }

        // A maioria dos endpoints da API-Football tem os dados dentro de jsonResponse['response']
        return parser(jsonResponse['response'] ?? jsonResponse);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthenticationException(
          message:
              "Chave de API inválida ou não autorizada (Status: ${response.statusCode}).",
        );
      } else if (response.statusCode == 429 || response.statusCode == 499) {
        throw ApiException(
          message:
              "Limite de requisições da API excedido (Status: ${response.statusCode}). Tente novamente mais tarde.",
        );
      } else if (response.statusCode >= 500) {
        throw ServerException(
          message:
              'Erro no servidor da API: ${response.statusCode}. Detalhes: ${response.reasonPhrase}',
        );
      } else {
        // Para outros erros 4xx não tratados especificamente
        final String bodyMessage =
            response.body.isNotEmpty ? "Detalhes: ${response.body}" : "";
        throw ServerException(
          message: 'Erro na API: ${response.statusCode}. $bodyMessage',
        );
      }
    } on SocketException catch (e) {
      throw NetworkException(
        message:
            "Sem conexão com a internet ou servidor da API indisponível. ${e.message}",
      );
    } on TimeoutException {
      throw NetworkException(
        message: "Tempo limite da requisição para API excedido.",
      );
    } on NoDataException {
      // Re-lança NoDataException para ser tratada mais acima
      rethrow;
    } catch (e) {
      print(
        "Erro desconhecido no datasource em _get para $endpoint: $e (${e.runtimeType})",
      );
      if (e is ServerException ||
          e is AuthenticationException ||
          e is ApiException ||
          e is NetworkException) {
        rethrow;
      }
      // Se for um erro de formatação ao decodificar JSON, pode ser um FormatException
      if (e is FormatException) {
        throw ServerException(
          message:
              "Erro ao parsear a resposta da API: ${e.message}. Endpoint: $endpoint",
        );
      }
      throw ServerException(
        message:
            "Ocorreu um erro inesperado durante a chamada à API: ${e.toString()}",
      );
    }
  }

  @override
  Future<List<LeagueModel>> getLeagues() async {
    List<LeagueModel> leagues = [];
    for (var entry in AppConstants.popularLeagues.entries) {
      final String endpoint = '/leagues';
      final String queryParams = '?id=${entry.value}';
      try {
        await _get(endpoint, (jsonResponse) {
          if (jsonResponse is List && jsonResponse.isNotEmpty) {
            final leagueData = LeagueModel.fromJson(
              jsonResponse.first as Map<String, dynamic>,
            );
            leagues.add(leagueData.copyWith(friendlyName: entry.key));
          } else {
            print(
              "Nenhuma liga encontrada para ID ${entry.value} ou formato de resposta inesperado.",
            );
          }
        }, queryParams: queryParams);
      } on NoDataException catch (e) {
        // Captura NoDataException se _get lançar
        print(
          "Dados não encontrados para liga ${entry.key} (ID: ${entry.value}): ${e.message}. Pulando esta liga.",
        );
      } catch (e) {
        print(
          "Erro ao buscar detalhes da liga ${entry.key} (ID: ${entry.value}): $e. Pulando esta liga.",
        );
      }
    }
    if (leagues.isEmpty && AppConstants.popularLeagues.isNotEmpty) {
      throw NoDataException(
        message:
            "Nenhuma das ligas populares pôde ser carregada. Verifique a API Key ou a conexão.",
      );
    }
    return leagues;
  }

  @override
  Future<List<FixtureModel>> getFixturesForLeague(
    int leagueId,
    String season, {
    int nextGames = 15,
  }) async {
    final String endpoint = '/fixtures';
    final String queryParams =
        '?league=$leagueId&season=$season&status=NS&next=$nextGames';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List)
        throw ServerException(
          message: "Formato de resposta inesperado para fixtures.",
        );
      return (jsonResponse as List)
          .map((item) => FixtureModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<FixtureOddsResponseModel> getOddsForFixture(
    int fixtureId, {
    int? bookmakerId,
  }) async {
    final int bkId = bookmakerId ?? AppConstants.preferredBookmakerId;
    final String endpoint = '/odds';
    final String queryParams = '?fixture=$fixtureId&bookmaker=$bkId';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List) {
        if (jsonResponse is Map && jsonResponse.isEmpty)
          return FixtureOddsResponseModel(fixtureId: fixtureId, bookmakers: []);
        throw ServerException(
          message: "Formato de resposta inesperado para odds pré-jogo.",
        );
      }
      return FixtureOddsResponseModel.fromApiResponse(
        jsonResponse as List<dynamic>,
        fixtureId,
      );
    }, queryParams: queryParams);
  }

  @override
  Future<FixtureOddsResponseModel> fetchLiveOddsForFixture(
    int fixtureId, {
    int? bookmakerId,
  }) async {
    return getOddsForFixture(fixtureId, bookmakerId: bookmakerId);
  }

  @override
  Future<FixtureStatisticsResponseModel> getFixtureStatistics({
    required int fixtureId,
    required int homeTeamId,
    required int awayTeamId,
  }) async {
    final String endpoint = '/fixtures/statistics';
    final String queryParams = '?fixture=$fixtureId';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List) {
        if (jsonResponse is Map && jsonResponse.isEmpty)
          return FixtureStatisticsResponseModel.fromJson(
            [],
            homeTeamId: homeTeamId,
            awayTeamId: awayTeamId,
          );
        throw ServerException(
          message:
              "Formato de resposta inesperado para estatísticas da partida.",
        );
      }
      return FixtureStatisticsResponseModel.fromJson(
        jsonResponse as List<dynamic>,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
      );
    }, queryParams: queryParams);
  }

  @override
  Future<List<FixtureModel>> getHeadToHead({
    required int team1Id,
    required int team2Id,
    int lastN = 10,
    String? status,
  }) async {
    final String endpoint = '/fixtures/headtohead';
    String queryParams = '?h2h=${team1Id}-${team2Id}&last=$lastN';
    if (status != null && status.isNotEmpty) {
      queryParams += '&status=$status';
    }
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List)
        throw ServerException(
          message: "Formato de resposta inesperado para H2H.",
        );
      return (jsonResponse as List)
          .map((item) => FixtureModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<List<PlayerSeasonStatsModel>> getPlayersFromSquad({
    required int teamId,
  }) async {
    final String endpoint = '/players/squads';
    final String queryParams = '?team=$teamId';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List || jsonResponse.isEmpty) return [];

      final squadData =
          jsonResponse.first
              as Map<String, dynamic>; // API retorna lista com 1 elemento
      final playersListJson = squadData['players'] as List<dynamic>? ?? [];

      return playersListJson.map((playerJson) {
        // O endpoint /squads retorna o jogador diretamente, sem a estrutura 'player' e 'statistics'
        // que o PlayerSeasonStatsModel.fromJson espera.
        // Precisamos criar um Map que simule essa estrutura.
        return PlayerSeasonStatsModel.fromJson({
          'player': playerJson, // O objeto do jogador
          'statistics':
              [], // Não há estatísticas detalhadas por competição aqui
        });
      }).toList();
    }, queryParams: queryParams);
  }

  @override
  Future<PlayerSeasonStatsModel?> getPlayerStats({
    required int playerId,
    required String season,
  }) async {
    final String endpoint = '/players';
    final String queryParams = '?id=$playerId&season=$season';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List || jsonResponse.isEmpty) return null;
      return PlayerSeasonStatsModel.fromJson(
        jsonResponse.first as Map<String, dynamic>,
      );
    }, queryParams: queryParams);
  }

  @override
  Future<List<PlayerSeasonStatsModel>> getLeagueTopScorers({
    required int leagueId,
    required String season,
    int topN = 10,
  }) async {
    final String endpoint = '/players/topscorers';
    final String queryParams = '?league=$leagueId&season=$season';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List)
        throw ServerException(
          message: "Formato de resposta inesperado para artilheiros.",
        );
      return (jsonResponse as List)
          .map(
            (item) =>
                PlayerSeasonStatsModel.fromJson(item as Map<String, dynamic>),
          )
          .take(topN)
          .toList();
    }, queryParams: queryParams);
  }

  @override
  Future<RefereeStatsModel> getRefereeDetailsAndAggregateStats({
    required int refereeId,
    required String season,
  }) async {
    final String refereeDetailsEndpoint = '/referees';
    final String refereeDetailsQueryParams = '?id=$refereeId';
    final refereeBaseModel = await _get(refereeDetailsEndpoint, (jsonResponse) {
      if (jsonResponse is! List || jsonResponse.isEmpty)
        throw ServerException(
          message: "Árbitro com ID $refereeId não encontrado.",
        );
      return RefereeStatsModel.fromJson(
        jsonResponse.first as Map<String, dynamic>,
      );
    }, queryParams: refereeDetailsQueryParams);

    final String fixturesOfficiatedEndpoint = '/fixtures';
    final String fixturesOfficiatedQueryParams =
        '?referee=$refereeId&season=$season&status=FT';

    int totalYellowAggregated = 0;
    int totalRedAggregated = 0;
    int gamesCountForAggregation = 0;

    try {
      await _get(fixturesOfficiatedEndpoint, (jsonResponseFixtures) {
        if (jsonResponseFixtures is! List) {
          print(
            "Nenhum jogo encontrado para o árbitro $refereeId na temporada $season ou formato de resposta inválido.",
          );
          return;
        }
        // SIMULAÇÃO DE AGREGAÇÃO DE CARTÕES - SUBSTITUIR PELA LÓGICA REAL
        for (var fixtureJson in (jsonResponseFixtures as List)) {
          // Lógica real para extrair cartões do fixtureJson (pode exigir parseamento do FixtureModel)
          // ou chamadas aninhadas a /fixtures/statistics (NÃO RECOMENDADO DIRETAMENTE AQUI)
          totalYellowAggregated += Random().nextInt(3) + 1;
          if (Random().nextDouble() < 0.1) totalRedAggregated++;
          gamesCountForAggregation++;
        }
      }, queryParams: fixturesOfficiatedQueryParams);
    } on NoDataException {
      // Se _get lançar NoDataException para os jogos do árbitro
      print(
        "Nenhum jogo encontrado para o árbitro $refereeId na temporada $season. Estatísticas de cartões estarão vazias.",
      );
    }
    // Outros erros serão propagados por _get e tratados por _tryCatch no repositório.

    final aggregatedStatsList =
        gamesCountForAggregation > 0
            ? [
              RefereeSeasonGamesModel(
                leagueName: "Agregado $season", // Nome genérico da temporada
                gamesOfficiated: gamesCountForAggregation,
                totalYellowCards: totalYellowAggregated,
                totalRedCards: totalRedAggregated,
              ),
            ]
            : <RefereeSeasonGamesModel>[];

    return refereeBaseModel.copyWithAggregatedStats(aggregatedStatsList);
  }

  @override
  Future<LeagueStandingsModel?> getLeagueStandings({
    required int leagueId,
    required String season,
  }) async {
    final String endpoint = '/standings';
    final String queryParams = '?league=$leagueId&season=$season';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List || jsonResponse.isEmpty) return null;
      return LeagueStandingsModel.fromJson(
        jsonResponse.first as Map<String, dynamic>,
      );
    }, queryParams: queryParams);
  }

  @override
  Future<LiveFixtureUpdateModel> fetchLiveFixtureUpdate(int fixtureId) async {
    final String endpoint =
        '/fixtures'; // O endpoint /fixtures com id=X também retorna dados ao vivo
    final String queryParams = '?id=$fixtureId';
    return _get(endpoint, (jsonResponse) {
      if (jsonResponse is! List || jsonResponse.isEmpty)
        throw ServerException(
          message: "Nenhum dado ao vivo encontrado para fixture $fixtureId.",
        );
      return LiveFixtureUpdateModel.fromJson(
        jsonResponse.first as Map<String, dynamic>,
      );
    }, queryParams: queryParams);
  }
}
