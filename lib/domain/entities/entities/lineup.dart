// lib/domain/entities/lineup.dart
import 'package:equatable/equatable.dart';

class PlayerInLineup extends Equatable {
  final int playerId;
  final String playerName;
  final int? playerNumber;
  final String? position; // Ex: "G", "D", "M", "F"
  final String? gridPosition; // Ex: "4:2:3:1" -> "1:1"

  const PlayerInLineup({
    required this.playerId,
    required this.playerName,
    this.playerNumber,
    this.position,
    this.gridPosition,
  });

  @override
  List<Object?> get props =>
      [playerId, playerName, playerNumber, position, gridPosition];
}

class TeamLineup extends Equatable {
  final int teamId;
  final String teamName;
  final String? teamLogoUrl;
  final String? coachName;
  final String? formation; // Ex: "4-3-3"
  final List<PlayerInLineup> startingXI;
  final List<PlayerInLineup> substitutes;

  const TeamLineup({
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    this.coachName,
    this.formation,
    required this.startingXI,
    required this.substitutes,
  });

  @override
  List<Object?> get props =>
      [teamId, teamName, coachName, formation, startingXI, substitutes];
}

// Entidade principal para as escalações da partida
class LineupsForFixture extends Equatable {
  final TeamLineup? homeTeamLineup;
  final TeamLineup? awayTeamLineup;

  const LineupsForFixture({
    this.homeTeamLineup,
    this.awayTeamLineup,
  });

  // Helper para verificar se as lineups estão disponíveis
  bool get areAvailable =>
      homeTeamLineup != null &&
      awayTeamLineup != null &&
      homeTeamLineup!.startingXI.isNotEmpty &&
      awayTeamLineup!.startingXI.isNotEmpty;

  @override
  List<Object?> get props => [homeTeamLineup, awayTeamLineup];
}
