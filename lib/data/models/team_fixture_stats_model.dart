// lib/data/models/team_fixture_stats_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'statistic_item_model.dart';
import 'team_model.dart';
// Para a entidade TeamFixtureStats

class TeamFixtureStatsModel extends Equatable {
  final TeamModel team;
  final List<StatisticItemModel> statisticsRaw;

  final double? expectedGoals;
  final int? shotsOnGoal;
  final int? shotsOffGoal;
  final int? shotsTotal;
  final int? shotsBlocked;
  final int? corners;
  final int? fouls;
  final int? yellowCards;
  final int? redCards;
  final double? ballPossessionPercent;
  final int? passesTotal;
  final int? passesAccurate;
  final double? passAccuracyPercent;
  final double? averageCornersGenerated;
  final double? averageYellowCardsReceived;

  const TeamFixtureStatsModel({
    required this.team,
    required this.statisticsRaw,
    this.expectedGoals,
    this.shotsOnGoal,
    this.shotsOffGoal,
    this.shotsTotal,
    this.shotsBlocked,
    this.corners,
    this.fouls,
    this.yellowCards,
    this.redCards,
    this.ballPossessionPercent,
    this.passesTotal,
    this.passesAccurate,
    this.passAccuracyPercent,
    this.averageCornersGenerated,
    this.averageYellowCardsReceived,
  });

  factory TeamFixtureStatsModel.fromJson(Map<String, dynamic> json) {
    final teamData = TeamModel.fromJson(
      json['team'] as Map<String, dynamic>? ?? {},
    );
    final statsListRaw =
        (json['statistics'] as List<dynamic>?)
            ?.map(
              (item) =>
                  StatisticItemModel.fromJson(item as Map<String, dynamic>),
            )
            .toList() ??
        [];

    // CORREÇÃO AQUI na assinatura do 'converter'
    T? extractStatValue<T>(
      String typeName,
      T? Function(dynamic value) converter, {
      List<String>? alternativeTypeNames,
    }) {
      final statItem = statsListRaw.firstWhere(
        (s) {
          final sTypeLower = s.type.toLowerCase();
          if (sTypeLower == typeName.toLowerCase()) return true;
          if (alternativeTypeNames != null) {
            for (var altName in alternativeTypeNames) {
              if (sTypeLower == altName.toLowerCase()) return true;
            }
          }
          return false;
        },
        // orElse: () => const StatisticItemModel(type: '', value: null), // Removido para permitir que firstWhere lance erro se não encontrar, se desejado, ou manter para retornar nulo
        orElse:
            () => const StatisticItemModel(
              type: 'NOT_FOUND',
              value: null,
            ), // Para identificar se não achou
      );
      if (statItem.type == 'NOT_FOUND' || statItem.value == null)
        return null; // Retorna nulo se não encontrou ou valor é nulo
      return converter(statItem.value);
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String)
        return int.tryParse(
          value.replaceAll(RegExp(r'[^0-9\-]'), ''),
        ); // Mantém sinal negativo
      if (value is double) return value.toInt();
      return null;
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      // Tenta remover o '%' e outros caracteres não numéricos, exceto ponto decimal e sinal negativo.
      if (value is String)
        return double.tryParse(
          value.replaceAll('%', '').replaceAll(RegExp(r'[^0-9.\-]'), ''),
        );
      return null;
    }

    return TeamFixtureStatsModel(
      team: teamData,
      statisticsRaw: statsListRaw,
      expectedGoals: extractStatValue(
        "expected goals",
        parseDouble,
        alternativeTypeNames: ["xg"],
      ),
      shotsOnGoal: extractStatValue("shots on goal", parseInt),
      shotsOffGoal: extractStatValue("shots off goal", parseInt),
      shotsTotal: extractStatValue(
        "total shots",
        parseInt,
        alternativeTypeNames: ["shots total"],
      ),
      shotsBlocked: extractStatValue(
        "blocked shots",
        parseInt,
        alternativeTypeNames: ["shots blocked"],
      ),
      corners: extractStatValue(
        "corner kicks",
        parseInt,
        alternativeTypeNames: ["corners"],
      ),
      fouls: extractStatValue(
        "fouls",
        parseInt,
        alternativeTypeNames: ["total fouls", "fouls committed"],
      ),
      yellowCards: extractStatValue("yellow cards", parseInt),
      redCards: extractStatValue("red cards", parseInt),
      ballPossessionPercent: extractStatValue("ball possession", parseDouble),
      passesTotal: extractStatValue(
        "total passes",
        parseInt,
        alternativeTypeNames: ["passes total"],
      ),
      passesAccurate: extractStatValue(
        "passes accurate",
        parseInt,
        alternativeTypeNames: ["accurate passes"],
      ),
      passAccuracyPercent: extractStatValue(
        "passes %",
        parseDouble,
        alternativeTypeNames: ["pass accuracy"],
      ),
      // Lógica para averageCornersGenerated e averageYellowCardsReceived precisaria ser implementada
      // se você calcular essas médias a partir de outros dados ou se a API as fornecer.
    );
  }

  // toEntity e props como antes...
  TeamFixtureStats toEntity() {
    return TeamFixtureStats(
      teamId: team.id,
      teamName: team.name,
      teamLogoUrl: team.logoUrl,
      expectedGoals: expectedGoals,
      shotsOnGoal: shotsOnGoal,
      shotsOffGoal: shotsOffGoal,
      shotsTotal: shotsTotal,
      shotsBlocked: shotsBlocked,
      corners: corners,
      fouls: fouls,
      yellowCards: yellowCards,
      redCards: redCards,
      ballPossessionPercent: ballPossessionPercent,
      passesTotal: passesTotal,
      passesAccurate: passesAccurate,
      passAccuracyPercent: passAccuracyPercent,
      averageCornersGenerated: averageCornersGenerated,
      averageYellowCardsReceived: averageYellowCardsReceived,
    );
  }

  @override
  List<Object?> get props => [
    team,
    statisticsRaw,
    expectedGoals,
    shotsOnGoal,
    shotsOffGoal,
    shotsTotal,
    shotsBlocked,
    corners,
    fouls,
    yellowCards,
    redCards,
    ballPossessionPercent,
    passesTotal,
    passesAccurate,
    passAccuracyPercent,
    averageCornersGenerated,
    averageYellowCardsReceived,
  ];
}
