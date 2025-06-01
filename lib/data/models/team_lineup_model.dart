// lib/data/models/team_lineup_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/lineup.dart';
import 'team_model.dart'; // Para TeamModel
import 'lineup_player_model.dart';
// Para TeamLineup

class TeamLineupModel extends Equatable {
  final TeamModel team; // Informações do time
  final String? coachName; // API-Football pode ter coach_id e coach_name
  final int? coachId;
  final String? formation; // Ex: "4-3-3"
  final List<LineupPlayerModel> startXI;
  final List<LineupPlayerModel> substitutes;

  const TeamLineupModel({
    required this.team,
    this.coachName,
    this.coachId,
    this.formation,
    required this.startXI,
    required this.substitutes,
  });

  factory TeamLineupModel.fromJson(Map<String, dynamic> json) {
    final coachData = json['coach'] ?? {};
    return TeamLineupModel(
      team: TeamModel.fromJson(json['team'] as Map<String, dynamic>? ?? {}),
      coachName: coachData['name'] as String?,
      coachId: coachData['id'] as int?,
      formation: json['formation'] as String?,
      startXI: (json['startXI'] as List<dynamic>?)
              ?.map(
                  (p) => LineupPlayerModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      substitutes: (json['substitutes'] as List<dynamic>?)
              ?.map(
                  (p) => LineupPlayerModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  TeamLineup toEntity() {
    return TeamLineup(
      teamId: team.id,
      teamName: team.name,
      teamLogoUrl: team.logoUrl,
      coachName: coachName,
      formation: formation,
      startingXI: startXI.map((p) => p.toEntity()).toList(),
      substitutes: substitutes.map((p) => p.toEntity()).toList(),
    );
  }

  @override
  List<Object?> get props => [team, coachName, formation, startXI, substitutes];
}
