// lib/data/models/team_season_aggregated_stats_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/core/utils/date_formatter.dart';
import 'package:product_gamers/domain/entities/entities/team_aggregated_stats.dart';

// Sub-modelo para valores de gols (total e média) dentro de "for" ou "against"
class AggregatedNumericValueModel extends Equatable {
  final int?
      totalOverall; // Representa o valor de "total" dentro de um sub-objeto "total" ou um "total" direto.
  final double?
      averageOverall; // Representa o valor de "total" dentro de um sub-objeto "average" ou uma "average" direta.

  const AggregatedNumericValueModel({this.totalOverall, this.averageOverall});

  factory AggregatedNumericValueModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AggregatedNumericValueModel();

    // A API da API-Football para /teams/statistics em "goals" e "corners" tem:
    // "for": { "total": {"total": X}, "average": {"total": Y_str_or_num} }
    // O 'json' aqui é o conteúdo de "for" ou "against"

    int? parsedTotal;
    if (json['total'] is Map) {
      // Se "total" é um objeto, pegue o sub-campo "total"
      parsedTotal = (json['total'] as Map<String, dynamic>)['total'] as int?;
    } else if (json['total'] is int) {
      // Se "total" é um int direto (menos comum para esta API neste nó)
      parsedTotal = json['total'] as int?;
    } else if (json['total'] is String) {
      // Se for string, tentar parsear
      parsedTotal = int.tryParse(json['total']);
    }

    double? parsedAverage;
    if (json['average'] is Map) {
      // Se "average" é um objeto, pegue o sub-campo "total"
      parsedAverage = double.tryParse(
          (json['average'] as Map<String, dynamic>)['total']?.toString() ?? "");
    } else if (json['average'] != null) {
      // Se "average" é um num ou string direto
      parsedAverage = (json['average'] is num)
          ? (json['average'] as num).toDouble()
          : double.tryParse(json['average'].toString());
    }

    return AggregatedNumericValueModel(
      totalOverall: parsedTotal,
      averageOverall: parsedAverage,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': {
          'total': totalOverall
        }, // Mantém a estrutura aninhada para consistência
        'average': {'total': averageOverall?.toStringAsFixed(2)}
      };

  @override
  List<Object?> get props => [totalOverall, averageOverall];
}

// Sub-modelo para "for" e "against" (usado para gols e escanteios)
class ForAgainstAggregatedModel extends Equatable {
  final AggregatedNumericValueModel? forStats;
  final AggregatedNumericValueModel? againstStats;

  const ForAgainstAggregatedModel({this.forStats, this.againstStats});

  factory ForAgainstAggregatedModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ForAgainstAggregatedModel();
    // 'json' aqui é o objeto que contém as chaves "for" e "against"
    // Ex: json = {"for": {"total": {...}, "average": {...}}, "against": {"total": {...}, "average": {...}}}
    return ForAgainstAggregatedModel(
      forStats: AggregatedNumericValueModel.fromJson(
          json['for'] as Map<String, dynamic>?),
      againstStats: AggregatedNumericValueModel.fromJson(
          json['against'] as Map<String, dynamic>?),
    );
  }
  Map<String, dynamic> toJson() =>
      {'for': forStats?.toJson(), 'against': againstStats?.toJson()};
  @override
  List<Object?> get props => [forStats, againstStats];
}

// Sub-modelo para um tipo de cartão (amarelo ou vermelho) e seus totais
class AggregatedCardDetailModel extends Equatable {
  final int? totalOverall;

  const AggregatedCardDetailModel({this.totalOverall});

  factory AggregatedCardDetailModel.fromJson(
      Map<String, dynamic>? jsonPeriodMap) {
    if (jsonPeriodMap == null)
      return const AggregatedCardDetailModel(totalOverall: 0);

    // API-Football /teams/statistics/cards/yellow (ou red) pode ter um campo "total" no nível superior
    // OU precisa somar os períodos ("0-15", "16-30", etc.)
    if (jsonPeriodMap['total'] is int) {
      return AggregatedCardDetailModel(
          totalOverall: jsonPeriodMap['total'] as int);
    }

    int sumTotal = 0;
    jsonPeriodMap.forEach((periodKey, periodStats) {
      // Evitar somar o próprio campo 'total' se ele existir como string ou nulo e não for int
      if (periodKey != 'total' &&
          periodStats is Map<String, dynamic> &&
          periodStats['total'] is int) {
        sumTotal += periodStats['total'] as int;
      }
    });
    // Retorna nulo se a soma for 0, indicando que não há dados de período ou todos são 0.
    // Ou retorna 0 se preferir. Para médias, nulo é melhor para evitar divisão por zero se gamesPlayed também for 0.
    return AggregatedCardDetailModel(
        totalOverall: sumTotal > 0 ? sumTotal : null);
  }
  Map<String, dynamic> toJson() => {'totalOverall': totalOverall};
  @override
  List<Object?> get props => [totalOverall];
}

// Sub-modelo para todos os cartões (amarelo e vermelho)
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
  Map<String, dynamic> toJson() =>
      {'yellow': yellow?.toJson(), 'red': red?.toJson()};
  @override
  List<Object?> get props => [yellow, red];
}

// Modelo Principal para Estatísticas Agregadas da Temporada de um Time
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

  final ForAgainstAggregatedModel? goalsStats;
  final ForAgainstAggregatedModel?
      cornersStats; // Usando o modelo ForAgainstAggregatedModel
  final AggregatedCardsModel? cardsStats;

  // Campos de médias que este MODELO armazena, derivados dos dados parseados.
  final double? finalAvgGoalsScoredPerGame;
  final double? finalAvgGoalsConcededPerGame;
  final double? finalAvgCornersGeneratedPerGame;
  final double? finalAvgCornersConcededPerGame;
  final double? finalAvgYellowCardsPerGame;
  final double? finalAvgRedCardsPerGame;

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
    this.finalAvgGoalsScoredPerGame,
    this.finalAvgGoalsConcededPerGame,
    this.finalAvgCornersGeneratedPerGame,
    this.finalAvgCornersConcededPerGame,
    this.finalAvgYellowCardsPerGame,
    this.finalAvgRedCardsPerGame,
  });

  // ===== FACTORY fromJson COM OS PARÂMETROS NOMEADOS CORRIGIDOS PARA FALLBACK =====
  factory TeamSeasonAggregatedStatsModel.fromJson(
    Map<String, dynamic> json, {
    // json é o objeto raiz da resposta de /teams/statistics para um time
    // Parâmetros nomeados opcionais para fallback, usados se a API não fornecer no corpo
    int? fallbackTeamId,
    int? fallbackLeagueId,
    String? fallbackSeason,
  }) {
    final leagueData = json['league'] as Map<String, dynamic>? ?? {};
    final teamDataAPI = json['team'] as Map<String, dynamic>? ?? {};
    final fixturesData = json['fixtures'] as Map<String, dynamic>? ?? {};

    final goalsDataFromApi = json['goals'] as Map<String, dynamic>?;
    // O seu exemplo de JSON para /teams/statistics mostrava 'corners' no mesmo nível de 'goals'
    final cornersDataFromApi = json['corners'] as Map<String, dynamic>?;
    final cardsDataFromApi = json['cards'] as Map<String, dynamic>?;

    int? gamesPlayed = fixturesData['played']?['total'] as int?;

    ForAgainstAggregatedModel parsedGoals =
        ForAgainstAggregatedModel.fromJson(goalsDataFromApi);
    ForAgainstAggregatedModel parsedCorners =
        ForAgainstAggregatedModel.fromJson(cornersDataFromApi);
    AggregatedCardsModel parsedCards =
        AggregatedCardsModel.fromJson(cardsDataFromApi);

    // Calcular médias se não fornecidas diretamente ou se quisermos recalcular
    double? calculatedAvgGoalsScored = parsedGoals.forStats?.averageOverall;
    if (calculatedAvgGoalsScored == null &&
        parsedGoals.forStats?.totalOverall != null &&
        gamesPlayed != null &&
        gamesPlayed > 0) {
      calculatedAvgGoalsScored =
          parsedGoals.forStats!.totalOverall! / gamesPlayed;
    }

    double? calculatedAvgGoalsConceded =
        parsedGoals.againstStats?.averageOverall;
    if (calculatedAvgGoalsConceded == null &&
        parsedGoals.againstStats?.totalOverall != null &&
        gamesPlayed != null &&
        gamesPlayed > 0) {
      calculatedAvgGoalsConceded =
          parsedGoals.againstStats!.totalOverall! / gamesPlayed;
    }

    double? calculatedAvgCornersGen = parsedCorners
        .forStats?.averageOverall; // Usa a média direta da API para escanteios
    if (calculatedAvgCornersGen == null &&
        parsedCorners.forStats?.totalOverall != null &&
        gamesPlayed != null &&
        gamesPlayed > 0) {
      calculatedAvgCornersGen =
          parsedCorners.forStats!.totalOverall! / gamesPlayed;
    }
    double? calculatedAvgCornersCon = parsedCorners.againstStats
        ?.averageOverall; // Usa a média direta da API para escanteios
    if (calculatedAvgCornersCon == null &&
        parsedCorners.againstStats?.totalOverall != null &&
        gamesPlayed != null &&
        gamesPlayed > 0) {
      calculatedAvgCornersCon =
          parsedCorners.againstStats!.totalOverall! / gamesPlayed;
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
      teamId: teamDataAPI['id'] as int? ?? fallbackTeamId ?? 0,
      leagueId: leagueData['id'] as int? ?? fallbackLeagueId ?? 0,
      leagueName: leagueData['name'] as String? ?? 'N/A',
      leagueLogoUrl: leagueData['logo'] as String?,
      season: leagueData['season']?.toString() ??
          fallbackSeason ??
          DateFormatter.getYear(DateTime.now()),
      playedTotal: gamesPlayed,
      winsTotal: fixturesData['wins']?['total'] as int?,
      drawsTotal: fixturesData['draws']?['total'] as int?,
      lossesTotal: fixturesData['loses']?['total'] as int?,
      form: json['form'] as String?,
      goalsStats: parsedGoals,
      cornersStats: parsedCorners,
      cardsStats: parsedCards,
      finalAvgGoalsScoredPerGame: calculatedAvgGoalsScored,
      finalAvgGoalsConcededPerGame: calculatedAvgGoalsConceded,
      finalAvgCornersGeneratedPerGame: calculatedAvgCornersGen,
      finalAvgCornersConcededPerGame: calculatedAvgCornersCon,
      finalAvgYellowCardsPerGame: calculatedAvgYellows,
      finalAvgRedCardsPerGame: calculatedAvgReds,
    );
  }
  // ====================================================================

  TeamAggregatedStats toEntity() {
    return TeamAggregatedStats(
      teamId: teamId,
      leagueId: leagueId,
      leagueName: leagueName,
      season: season,
      played: playedTotal ?? 0,
      wins: winsTotal ?? 0,
      draws: drawsTotal ?? 0,
      losses: lossesTotal ?? 0,
      goalsFor: goalsStats?.forStats?.totalOverall ?? 0,
      goalsAgainst: goalsStats?.againstStats?.totalOverall ?? 0,
      formStreak: form,
      averageGoalsScoredPerGame: finalAvgGoalsScoredPerGame,
      averageGoalsConcededPerGame: finalAvgGoalsConcededPerGame,
      averageCornersGeneratedPerGame: finalAvgCornersGeneratedPerGame,
      averageCornersConcededPerGame: finalAvgCornersConcededPerGame,
      averageYellowCardsPerGame: finalAvgYellowCardsPerGame,
      averageRedCardsPerGame: finalAvgRedCardsPerGame,
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
        finalAvgGoalsScoredPerGame,
        finalAvgGoalsConcededPerGame,
        finalAvgCornersGeneratedPerGame,
        finalAvgCornersConcededPerGame,
        finalAvgYellowCardsPerGame,
        finalAvgRedCardsPerGame
      ];
}
