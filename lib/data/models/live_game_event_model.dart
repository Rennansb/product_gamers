// lib/data/models/live_game_event_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/live_fixture_update.dart';
// Para a entidade LiveGameEvent

class LiveGameEventModel extends Equatable {
  final int? timeElapsed;
  final int? timeExtra;
  final int? teamId;
  final String? teamName; // A API pode não fornecer o nome do time aqui
  final int? playerId;
  final String? playerName;
  final int? assistPlayerId;
  final String? assistPlayerName;
  final String type; // "Goal", "Card", "subst", "Var"
  final String detail; // "Normal Goal", "Yellow Card", "Substitution 1"
  final String? comments;

  const LiveGameEventModel({
    this.timeElapsed,
    this.timeExtra,
    this.teamId,
    this.teamName,
    this.playerId,
    this.playerName,
    this.assistPlayerId,
    this.assistPlayerName,
    required this.type,
    required this.detail,
    this.comments,
  });

  factory LiveGameEventModel.fromJson(Map<String, dynamic> json) {
    return LiveGameEventModel(
      timeElapsed: json['time']?['elapsed'] as int?,
      timeExtra: json['time']?['extra'] as int?,
      teamId: json['team']?['id'] as int?,
      teamName:
          json['team']?['name']
              as String?, // API-Football geralmente fornece o nome do time no evento
      playerId: json['player']?['id'] as int?,
      playerName: json['player']?['name'] as String?,
      assistPlayerId: json['assist']?['id'] as int?,
      assistPlayerName: json['assist']?['name'] as String?,
      type: json['type'] as String? ?? 'Unknown',
      detail: json['detail'] as String? ?? 'Unknown Detail',
      comments: json['comments'] as String?,
    );
  }

  LiveGameEvent toEntity({String? homeTeamName, String? awayTeamName}) {
    // Passar nomes dos times para enriquecer
    String? resolvedTeamName = teamName;
    if (resolvedTeamName == null && teamId != null) {
      // Esta lógica de resolução precisaria dos IDs e nomes dos times do jogo principal.
      // Aqui é apenas um placeholder. O ideal é que o LiveFixtureUpdateModel enriqueça isso.
    }

    return LiveGameEvent(
      timeElapsed: timeElapsed,
      timeExtra: timeExtra,
      teamId: teamId,
      teamName: resolvedTeamName,
      playerId: playerId,
      playerName: playerName,
      assistPlayerId: assistPlayerId,
      assistPlayerName: assistPlayerName,
      type: type,
      detail: detail,
      comments: comments,
    );
  }

  @override
  List<Object?> get props => [
    timeElapsed,
    timeExtra,
    teamId,
    teamName,
    playerId,
    playerName,
    assistPlayerId,
    assistPlayerName,
    type,
    detail,
    comments,
  ];
}
