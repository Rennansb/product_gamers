// lib/data/models/team_season_aggregated_stats_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/team_aggregated_stats.dart';

// Sub-modelo para valores de gols (total e média) dentro de "for" ou "against"
class AggregatedGoalsStatsValuesModel extends Equatable {
  final int? totalOverall; // O valor de "total" dentro do sub-objeto "total"
  final double?
      averageOverall; // O valor de "total" dentro do sub-objeto "average"

  const AggregatedGoalsStatsValuesModel(
      {this.totalOverall, this.averageOverall});

  factory AggregatedGoalsStatsValuesModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AggregatedGoalsStatsValuesModel();

    // A API-Football tem:
    // json['for']['total']['total'] para o total de gols marcados
    // json['for']['average']['total'] para a média de gols marcados (como string)

    // Esta factory espera o objeto que está DENTRO de "for" ou "against",
    // ou seja, o objeto que contém as chaves "total" e "average".
    // Ex: json = {"total": {"home": 20, "away": 15, "total": 35}, "average": {"home": "2.0", ...}}

    int? parsedTotal;
    if (json['total'] is Map) {
      parsedTotal = (json['total'] as Map<String, dynamic>)['total'] as int?;
    } else if (json['total'] is int) {
      // Caso a API mude para um int direto
      parsedTotal = json['total'] as int?;
    }

    double? parsedAverage;
    if (json['average'] is Map) {
      parsedAverage = double.tryParse(
          (json['average'] as Map<String, dynamic>)['total']?.toString() ?? "");
    } else if (json['average'] != null) {
      // Caso a API mude para um double/string direto
      parsedAverage = double.tryParse(json['average'].toString());
    }

    return AggregatedGoalsStatsValuesModel(
      totalOverall: parsedTotal,
      averageOverall: parsedAverage,
    );
  }

  Map<String, dynamic> toJson() => {
        // Para consistência, embora não usado para enviar
        'total': {'total': totalOverall},
        'average': {'total': averageOverall?.toStringAsFixed(2)}
      };

  @override
  List<Object?> get props => [totalOverall, averageOverall];
}

// Sub-modelo para o objeto "goals" que contém "for" e "against"
class AggregatedGoalsModel extends Equatable {
  final AggregatedGoalsStatsValuesModel? goalsFor; // Para o nó "for"
  final AggregatedGoalsStatsValuesModel? goalsAgainst; // Para o nó "against"

  const AggregatedGoalsModel({this.goalsFor, this.goalsAgainst});

  factory AggregatedGoalsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AggregatedGoalsModel();
    // 'json' aqui é o objeto que contém as chaves "for" e "against"
    // Ex: json = {"for": {"total": {...}, "average": {...}}, "against": {...}}
    return AggregatedGoalsModel(
      goalsFor: AggregatedGoalsStatsValuesModel.fromJson(
          json['for'] as Map<String, dynamic>?),
      goalsAgainst: AggregatedGoalsStatsValuesModel.fromJson(
          json['against'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
        'for': goalsFor?.toJson(),
        'against': goalsAgainst?.toJson(),
      };

  @override
  List<Object?> get props => [goalsFor, goalsAgainst];
}

// Sub-modelo para escanteios (reutiliza AggregatedGoalsStatsValuesModel para a estrutura de total/average)
class AggregatedCornersModel extends Equatable {
  final AggregatedGoalsStatsValuesModel? cornersFor;
  final AggregatedGoalsStatsValuesModel? cornersAgainst;

  const AggregatedCornersModel({this.cornersFor, this.cornersAgainst});

  factory AggregatedCornersModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AggregatedCornersModel();
    // Seu JSON de exemplo para escanteios em /teams/statistics:
    // "corners": { "total": { "for": 180, "against": 160 }, "average": { "for": 6.0, "against": 5.33 } }
    // Precisamos criar Maps para simular a estrutura que AggregatedGoalsStatsValuesModel.fromJson espera

    Map<String, dynamic>? forData =
        (json['total']?['for'] != null || json['average']?['for'] != null)
            ? {
                'total': {
                  'total': json['total']?['for']
                }, // Passando o total geral
                'average': {
                  'total': json['average']?['for']
                } // Passando a média geral
              }
            : null;

    Map<String, dynamic>? againstData = (json['total']?['against'] != null ||
            json['average']?['against'] != null)
        ? {
            'total': {'total': json['total']?['against']},
            'average': {'total': json['average']?['against']}
          }
        : null;

    return AggregatedCornersModel(
      cornersFor: AggregatedGoalsStatsValuesModel.fromJson(forData),
      cornersAgainst: AggregatedGoalsStatsValuesModel.fromJson(againstData),
    );
  }
  @override
  List<Object?> get props => [cornersFor, cornersAgainst];
}

// Sub-modelo para um tipo de cartão (amarelo ou vermelho) e seus totais
class AggregatedCardDetailModel extends Equatable {
  final int? totalOverall;
  const AggregatedCardDetailModel({this.totalOverall});

  factory AggregatedCardDetailModel.fromJson(
      Map<String, dynamic>? jsonPeriodMap) {
    if (jsonPeriodMap == null)
      return const AggregatedCardDetailModel(totalOverall: 0);

    if (jsonPeriodMap['total'] is int) {
      // Checa se já existe um total geral fornecido
      return AggregatedCardDetailModel(
          totalOverall: jsonPeriodMap['total'] as int);
    }
    // Se não, soma os períodos
    int sumTotal = 0;
    jsonPeriodMap.forEach((periodKey, periodStats) {
      if (periodStats is Map<String, dynamic> && periodStats['total'] is int) {
        sumTotal += periodStats['total'] as int;
      }
    });
    return AggregatedCardDetailModel(totalOverall: sumTotal);
  }
  @override
  List<Object?> get props => [totalOverall];
}

// Sub-modelo para todos os cartões
class AggregatedCardsModel extends Equatable {
  final AggregatedCardDetailModel? yellow;
  final AggregatedCardDetailModel? red;
  const AggregatedCardsModel({this.yellow, this.red});

  factory AggregatedCardsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AggregatedCardsModel();
    return AggregatedCardsModel(
      yellow: AggregatedCardDetailModel.fromJson(
          json['yellow'] as Map<String, dynamic>?),
      red: AggregatedCardDetailModel.fromJson(
          json['red'] as Map<String, dynamic>?),
    );
  }
  @override
  List<Object?> get props => [yellow, red];
}

class TeamSeasonAggregatedStatsModel extends Equatable {
  final int teamId;
  final int leagueId;
  final String leagueName;
  final String? leagueLogoUrl;
  final String season;

  final int? playedTotal;
  final int? winsTotal;
  final int? drawsTotal;
  final int? lossesTotal;
  final String? form;

  final AggregatedGoalsModel? goalsStats; // Usando o modelo corrigido
  final AggregatedCornersModel? cornersStats;
  final AggregatedCardsModel? cardsStats;

  // Campos de médias calculadas/obtidas para a entidade
  final double? avgGoalsScoredPerGame;
  final double? avgGoalsConcededPerGame;
  final double? avgCornersGeneratedPerGame;
  final double? avgCornersConcededPerGame;
  final double? avgYellowCardsPerGame;
  final double? avgRedCardsPerGame;

  const TeamSeasonAggregatedStatsModel({
    required this.teamId,
    required this.leagueId,
    required this.leagueName,
    this.leagueLogoUrl,
    required this.season,
    this.playedTotal,
    this.winsTotal,
    this.drawsTotal,
    this.lossesTotal,
    this.form,
    this.goalsStats,
    this.cornersStats,
    this.cardsStats,
    this.avgGoalsScoredPerGame,
    this.avgGoalsConcededPerGame,
    this.avgCornersGeneratedPerGame,
    this.avgCornersConcededPerGame,
    this.avgYellowCardsPerGame,
    this.avgRedCardsPerGame,
  });

  factory TeamSeasonAggregatedStatsModel.fromJson(Map<String, dynamic> json,
      int reqTeamId, int reqLeagueId, String reqSeason) {
    final leagueData = json['league'] ?? {};
    final teamDataAPI = json['team'] ?? {};
    final fixturesData = json['fixtures'] ?? {};

    // Acessando os nós corretos baseados no seu JSON de exemplo
    final goalsDataFromApi = json['goals'] as Map<String, dynamic>?;
    // Para escanteios, o seu JSON exemplo mostra: json['statistics']['corners']
    final cornersDataFromApi = (json['statistics']
        as Map<String, dynamic>?)?['corners'] as Map<String, dynamic>?;
    final cardsDataFromApi = json['cards'] as Map<String, dynamic>?;

    int? gamesPlayed = fixturesData['played']?['total'] as int?;

    AggregatedGoalsModel parsedGoals =
        AggregatedGoalsModel.fromJson(goalsDataFromApi);
    AggregatedCornersModel parsedCorners =
        AggregatedCornersModel.fromJson(cornersDataFromApi);
    AggregatedCardsModel parsedCards =
        AggregatedCardsModel.fromJson(cardsDataFromApi);

    double? calculatedAvgGoalsScored =
        parsedGoals.goalsFor?.averageOverall; // Usa a média direto da API
    if (calculatedAvgGoalsScored == null &&
        parsedGoals.goalsFor?.totalOverall != null &&
        gamesPlayed != null &&
        gamesPlayed > 0) {
      calculatedAvgGoalsScored =
          parsedGoals.goalsFor!.totalOverall! / gamesPlayed;
    }

    double? calculatedAvgGoalsConceded =
        parsedGoals.goalsAgainst?.averageOverall;
    if (calculatedAvgGoalsConceded == null &&
        parsedGoals.goalsAgainst?.totalOverall != null &&
        gamesPlayed != null &&
        gamesPlayed > 0) {
      calculatedAvgGoalsConceded =
          parsedGoals.goalsAgainst!.totalOverall! / gamesPlayed;
    }

    double? calculatedAvgCornersGen =
        parsedCorners.cornersFor?.averageOverall; // Usa a média direto da API
    if (calculatedAvgCornersGen == null &&
        parsedCorners.cornersFor?.totalOverall != null &&
        gamesPlayed != null &&
        gamesPlayed > 0) {
      calculatedAvgCornersGen =
          parsedCorners.cornersFor!.totalOverall! / gamesPlayed;
    }
    double? calculatedAvgCornersCon = parsedCorners
        .cornersAgainst?.averageOverall; // Usa a média direto da API
    if (calculatedAvgCornersCon == null &&
        parsedCorners.cornersAgainst?.totalOverall != null &&
        gamesPlayed != null &&
        gamesPlayed > 0) {
      calculatedAvgCornersCon =
          parsedCorners.cornersAgainst!.totalOverall! / gamesPlayed;
    }

    double? calculatedAvgYellows = (gamesPlayed != null &&
            gamesPlayed > 0 &&
            parsedCards.yellow?.totalOverall != null)
        ? (parsedCards.yellow!.totalOverall! / gamesPlayed)
        : null;
    double? calculatedAvgReds = (gamesPlayed != null &&
            gamesPlayed > 0 &&
            parsedCards.red?.totalOverall != null)
        ? (parsedCards.red!.totalOverall! / gamesPlayed)
        : null;

    return TeamSeasonAggregatedStatsModel(
      teamId: teamDataAPI['id'] as int? ?? reqTeamId,
      leagueId: leagueData['id'] as int? ?? reqLeagueId,
      leagueName: leagueData['name'] as String? ?? 'N/A',
      leagueLogoUrl: leagueData['logo'] as String?,
      season: leagueData['season']?.toString() ?? reqSeason,
      playedTotal: gamesPlayed,
      winsTotal: fixturesData['wins']?['total'] as int?,
      drawsTotal: fixturesData['draws']?['total'] as int?,
      lossesTotal: fixturesData['loses']?['total'] as int?,
      form: json['form'] as String?,
      goalsStats: parsedGoals,
      cornersStats: parsedCorners,
      cardsStats: parsedCards,
      avgGoalsScoredPerGame: calculatedAvgGoalsScored,
      avgGoalsConcededPerGame: calculatedAvgGoalsConceded,
      avgCornersGeneratedPerGame: calculatedAvgCornersGen,
      avgCornersConcededPerGame: calculatedAvgCornersCon,
      avgYellowCardsPerGame: calculatedAvgYellows,
      avgRedCardsPerGame: calculatedAvgReds,
    );
  }

  TeamAggregatedStats toEntity() {
    return TeamAggregatedStats(
      teamId: teamId, leagueId: leagueId, leagueName: leagueName,
      season: season,
      played: playedTotal ?? 0, wins: winsTotal ?? 0, draws: drawsTotal ?? 0,
      losses: lossesTotal ?? 0,
      goalsFor: goalsStats?.goalsFor?.totalOverall ?? 0, // Usa totalOverall
      goalsAgainst:
          goalsStats?.goalsAgainst?.totalOverall ?? 0, // Usa totalOverall
      formStreak: form,
      averageGoalsScoredPerGame: avgGoalsScoredPerGame,
      averageGoalsConcededPerGame: avgGoalsConcededPerGame,
      averageCornersGeneratedPerGame: avgCornersGeneratedPerGame,
      averageCornersConcededPerGame: avgCornersConcededPerGame,
      averageYellowCardsPerGame: avgYellowCardsPerGame,
      averageRedCardsPerGame: avgRedCardsPerGame,
    );
  }

  @override
  List<Object?> get props => [
        teamId,
        leagueId,
        leagueName,
        leagueLogoUrl,
        season,
        playedTotal,
        winsTotal,
        drawsTotal,
        lossesTotal,
        form,
        goalsStats,
        cornersStats,
        cardsStats,
        avgGoalsScoredPerGame,
        avgGoalsConcededPerGame,
        avgCornersGeneratedPerGame,
        avgCornersConcededPerGame,
        avgYellowCardsPerGame,
        avgRedCardsPerGame
      ];
}
