// lib/data/models/team_season_aggregated_stats_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/team_aggregated_stats.dart';

// Sub-modelo para gols dentro das estatísticas agregadas do time
class AggregatedGoalsStatsValuesModel extends Equatable {
  final int? total;
  final double? average;
  const AggregatedGoalsStatsValuesModel({this.total, this.average});

  factory AggregatedGoalsStatsValuesModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AggregatedGoalsStatsValuesModel();
    return AggregatedGoalsStatsValuesModel(
      total: json['total'] as int?,
      average: double.tryParse(json['average']?.toString() ??
          "0.0"), // Default to 0.0 if parse fails
    );
  }
  @override
  List<Object?> get props => [total, average];
}

class AggregatedGoalsModel extends Equatable {
  final AggregatedGoalsStatsValuesModel? goalsFor;
  final AggregatedGoalsStatsValuesModel? goalsAgainst;
  const AggregatedGoalsModel({this.goalsFor, this.goalsAgainst});

  factory AggregatedGoalsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AggregatedGoalsModel();
    return AggregatedGoalsModel(
      goalsFor: AggregatedGoalsStatsValuesModel.fromJson(
          json['for'] as Map<String, dynamic>?),
      goalsAgainst: AggregatedGoalsStatsValuesModel.fromJson(
          json['against'] as Map<String, dynamic>?),
    );
  }
  @override
  List<Object?> get props => [goalsFor, goalsAgainst];
}

// Sub-modelo para cartões (agregado por tipo)
class AggregatedCardsTypeModel extends Equatable {
  final int? total;
  const AggregatedCardsTypeModel({this.total});

  factory AggregatedCardsTypeModel.fromJson(
      Map<String, dynamic>? jsonPeriodMap) {
    if (jsonPeriodMap == null)
      return const AggregatedCardsTypeModel(total: 0); // Default to 0
    int sumTotal = 0;
    jsonPeriodMap.forEach((period, stats) {
      if (stats is Map<String, dynamic> && stats['total'] is int) {
        sumTotal += stats['total'] as int;
      } else if (stats is Map<String, dynamic> &&
          stats['total'] == null &&
          stats.entries
              .where((e) => e.value is Map && (e.value as Map)['total'] is int)
              .isNotEmpty) {
        // Caso API-Football retorne null para o total mas tenha os períodos preenchidos
        // Ex: "yellow": {"0-15": {"total": 1, "percentage": "5.00%"}, "16-30": null, ... "total": null}
        // Esta lógica ainda não cobre esse caso perfeitamente, precisaria iterar os sub-períodos.
        // Para simplificar, se 'total' geral não existe, vamos manter o que foi somado até agora.
      }
    });
    return AggregatedCardsTypeModel(total: sumTotal);
  }
  @override
  List<Object?> get props => [total];
}

class TeamSeasonAggregatedStatsModel extends Equatable {
  final double? avgCornersConceded;
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

  final AggregatedGoalsModel? goalsOverall;

  // Campos de médias que este MODELO armazena
  final double? avgGoalsScored; // Média de gols marcados
  final double? avgGoalsConceded; // Média de gols sofridos
  final double? avgYellowCards; // Média de amarelos recebidos
  final double? avgRedCards; // Média de vermelhos recebidos
  final double?
      avgCornersGenerated; // Média de escanteios gerados (AINDA UM DESAFIO DE DADOS)

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
    this.goalsOverall,
    this.avgGoalsScored,
    this.avgGoalsConceded,
    this.avgYellowCards,
    this.avgRedCards,
    this.avgCornersGenerated,
    this.avgCornersConceded, // Adicionar ao construtor do modelo
  });

  factory TeamSeasonAggregatedStatsModel.fromJson(Map<String, dynamic> json,
      int reqTeamId, int reqLeagueId, String reqSeason) {
    final leagueData = json['league'] ?? {};
    final fixturesData = json['fixtures'] ?? {};
    final goalsData = json['goals'] as Map<String, dynamic>?;
    final cardsData = json['cards'] as Map<String, dynamic>? ?? {};

    int? gamesPlayed = fixturesData['played']?['total'] as int?;
    // Evitar divisão por zero, se gamesPlayed for nulo ou 0, as médias serão nulas ou 0.0

    AggregatedCardsTypeModel yellowCardStats =
        AggregatedCardsTypeModel.fromJson(
            cardsData['yellow'] as Map<String, dynamic>?);
    AggregatedCardsTypeModel redCardStats = AggregatedCardsTypeModel.fromJson(
        cardsData['red'] as Map<String, dynamic>?);
    AggregatedGoalsModel parsedGoals = AggregatedGoalsModel.fromJson(goalsData);

    double? calculatedAvgGoalsScored = (gamesPlayed != null &&
            gamesPlayed > 0 &&
            parsedGoals.goalsFor?.total != null)
        ? (parsedGoals.goalsFor!.total! / gamesPlayed)
        : parsedGoals.goalsFor?.average; // Usa a média da API se disponível

    double? calculatedAvgGoalsConceded = (gamesPlayed != null &&
            gamesPlayed > 0 &&
            parsedGoals.goalsAgainst?.total != null)
        ? (parsedGoals.goalsAgainst!.total! / gamesPlayed)
        : parsedGoals.goalsAgainst?.average;

    double? calculatedAvgYellows = (gamesPlayed != null &&
            gamesPlayed > 0 &&
            yellowCardStats.total != null)
        ? (yellowCardStats.total! / gamesPlayed)
        : null;

    double? calculatedAvgReds =
        (gamesPlayed != null && gamesPlayed > 0 && redCardStats.total != null)
            ? (redCardStats.total! / gamesPlayed)
            : null;

    // Para avgCornersGenerated, ainda não temos uma fonte de dados clara da API /teams/statistics
    // Se você encontrar, adicione a lógica de parseamento aqui. Por enquanto, será nulo.
    // double? parsedAvgCorners = ...;

    return TeamSeasonAggregatedStatsModel(
      teamId: json['team']?['id'] as int? ?? reqTeamId,
      leagueId: leagueData['id'] as int? ?? reqLeagueId,
      leagueName: leagueData['name'] as String? ?? 'N/A',
      leagueLogoUrl: leagueData['logo'] as String?,
      season: leagueData['season']?.toString() ?? reqSeason,

      playedTotal: fixturesData['played']?['total'] as int?,
      winsTotal: fixturesData['wins']?['total'] as int?,
      drawsTotal: fixturesData['draws']?['total'] as int?,
      lossesTotal: fixturesData['loses']?['total'] as int?,
      form: json['form'] as String?,
      goalsOverall: parsedGoals,

      avgGoalsScored: calculatedAvgGoalsScored,
      avgGoalsConceded: calculatedAvgGoalsConceded,
      avgYellowCards: calculatedAvgYellows,
      avgRedCards: calculatedAvgReds,
      // avgCornersGenerated: parsedAvgCorners, // Permanecerá nulo se não houver dados
    );
  }

  // ================== MÉTODO toEntity() CORRIGIDO ==================
  TeamAggregatedStats toEntity() {
    return TeamAggregatedStats(
      // Chamando o construtor da ENTIDADE
      teamId: teamId,
      leagueId: leagueId,
      leagueName: leagueName,
      season: season,
      played: playedTotal ?? 0,
      wins: winsTotal ?? 0,
      draws: drawsTotal ?? 0,
      losses: lossesTotal ?? 0,
      goalsFor: goalsOverall?.goalsFor?.total ?? 0,
      goalsAgainst: goalsOverall?.goalsAgainst?.total ?? 0,
      formStreak: form,
      averageGoalsScoredPerGame:
          avgGoalsScored, // Campo do modelo: avgGoalsScored -> Parâmetro da entidade: averageGoalsScoredPerGame
      averageGoalsConcededPerGame:
          avgGoalsConceded, // Campo do modelo: avgGoalsConceded -> Parâmetro da entidade: averageGoalsConcededPerGame
      // === CORREÇÕES AQUI ===
      averageCornersGeneratedPerGame:
          avgCornersGenerated, // Campo do modelo: avgCornersGenerated -> Parâmetro da entidade: averageCornersGeneratedPerGame
      averageYellowCardsPerGame:
          avgYellowCards, // Campo do modelo: avgYellowCards -> Parâmetro da entidade: averageYellowCardsPerGame
      averageRedCardsPerGame:
          avgRedCards, // Campo do modelo: avgRedCards -> Parâmetro da entidade: averageRedCardsPerGame
      // =======================
    );
  }
  // =================================================================

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
        goalsOverall,
        avgGoalsScored,
        avgGoalsConceded,
        avgYellowCards,
        avgRedCards,
        avgCornersGenerated
      ];
}
