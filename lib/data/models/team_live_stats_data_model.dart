// lib/data/models/team_live_stats_data_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/live_fixture_update.dart';
// Para TeamLiveStats

// Modelo para estatísticas ao vivo de um time (se a API fornecer no endpoint de live fixture)
class TeamLiveStatsDataModel extends Equatable {
  final int? shotsOnGoal;
  final int? shotsOffGoal;
  final int? totalShots;
  final int? blockedShots;
  final int? corners;
  final int? fouls;
  final int? yellowCards;
  final int? redCards;
  final String? ballPossession; // Ex: "55%" (API retorna como string)
  final double? expectedGoalsLive; // xG ao vivo

  const TeamLiveStatsDataModel({
    this.shotsOnGoal,
    this.shotsOffGoal,
    this.totalShots,
    this.blockedShots,
    this.corners,
    this.fouls,
    this.yellowCards,
    this.redCards,
    this.ballPossession,
    this.expectedGoalsLive,
  });

  factory TeamLiveStatsDataModel.fromJson(List<dynamic>? statsListFromApi) {
    if (statsListFromApi == null || statsListFromApi.isEmpty) {
      return const TeamLiveStatsDataModel(); // Retorna vazio se não houver dados
    }

    // CORREÇÃO AQUI na assinatura do 'converter'
    T? extract<T>(
      String typeName,
      T? Function(dynamic value) converter, {
      List<String>? altTypeNames,
    }) {
      final statJson = statsListFromApi.firstWhere((s) {
        if (s is! Map<String, dynamic>) return false;
        final type = s['type']?.toString().toLowerCase();
        if (type == null) return false; // Adicionado para segurança
        if (type == typeName.toLowerCase()) return true;
        if (altTypeNames != null) {
          for (var alt in altTypeNames) {
            if (type == alt.toLowerCase()) return true;
          }
        }
        return false;
      }, orElse: () => null);

      if (statJson == null || statJson['value'] == null)
        return null; // Retorna nulo se não encontrar ou valor for nulo
      return converter(statJson['value']);
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String)
        return int.tryParse(v.replaceAll(RegExp(r'[^0-9\-]'), ''));
      if (v is double) return v.toInt();
      return null;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String)
        return double.tryParse(
          v.replaceAll('%', '').replaceAll(RegExp(r'[^0-9.\-]'), ''),
        );
      return null;
    }

    // CORREÇÃO AQUI: Converter para string deve retornar String?, não String
    String? parseString(dynamic v) {
      return v?.toString();
    }

    return TeamLiveStatsDataModel(
      shotsOnGoal: extract("shots on goal", parseInt),
      shotsOffGoal: extract("shots off goal", parseInt),
      totalShots: extract(
        "total shots",
        parseInt,
        altTypeNames: ["shots total"],
      ),
      blockedShots: extract(
        "blocked shots",
        parseInt,
        altTypeNames: ["shots blocked"],
      ),
      corners: extract("corner kicks", parseInt, altTypeNames: ["corners"]),
      fouls: extract(
        "fouls",
        parseInt,
        altTypeNames: ["fouls committed", "total fouls"],
      ),
      yellowCards: extract("yellow cards", parseInt),
      redCards: extract("red cards", parseInt),
      ballPossession: extract(
        "ball possession",
        parseString,
      ), // Usar parseString
      expectedGoalsLive: extract(
        "expected goals",
        parseDouble,
        altTypeNames: ["xg"],
      ),
    );
  }

  // toEntity e props como antes...
  TeamLiveStats toEntity() {
    return TeamLiveStats(
      shotsOnGoal: shotsOnGoal,
      shotsOffGoal: shotsOffGoal,
      totalShots: totalShots,
      blockedShots: blockedShots,
      corners: corners,
      fouls: fouls,
      yellowCards: yellowCards,
      redCards: redCards,
      ballPossession: ballPossession,
      expectedGoalsLive: expectedGoalsLive,
    );
  }

  @override
  List<Object?> get props => [
    shotsOnGoal,
    shotsOffGoal,
    totalShots,
    blockedShots,
    corners,
    fouls,
    yellowCards,
    redCards,
    ballPossession,
    expectedGoalsLive,
  ];
}
