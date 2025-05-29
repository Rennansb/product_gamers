// lib/domain/entities/standing_info.dart
import 'package:equatable/equatable.dart';

// Entidade para representar uma linha da tabela de classificação para um time
class StandingInfo extends Equatable {
  final int rank;
  final int teamId;
  final String teamName;
  final String? teamLogoUrl;
  final int points;
  final int goalsDiff;
  final String groupName; // Nome do grupo/fase
  final String formStreak; // Sequência de resultados (ex: "WWLDW")
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final String? description; // Ex: "Promotion - Champions League Qualification"

  const StandingInfo({
    required this.rank,
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    required this.points,
    required this.goalsDiff,
    required this.groupName,
    required this.formStreak,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    this.description,
  });

  @override
  List<Object?> get props => [
    rank,
    teamId,
    teamName,
    teamLogoUrl,
    points,
    goalsDiff,
    groupName,
    formStreak,
    played,
    wins,
    draws,
    losses,
    goalsFor,
    goalsAgainst,
    description,
  ];
}
