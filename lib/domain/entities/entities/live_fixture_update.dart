// lib/domain/entities/live_fixture_update.dart
import 'package:equatable/equatable.dart';
import 'team.dart'; // <<< IMPORTAR TeamInFixture

// LiveGameEvent e TeamLiveStats como antes...
class LiveGameEvent extends Equatable {
  final int? timeElapsed;
  final int? timeExtra;
  final int? teamId;
  final String? teamName;
  final int? playerId;
  final String? playerName;
  final int? assistPlayerId;
  final String? assistPlayerName;
  final String type;
  final String detail;
  final String? comments;

  const LiveGameEvent({
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

  LiveGameEvent copyWith({
    int? timeElapsed,
    int? timeExtra,
    int? teamId,
    String? teamName,
    int? playerId,
    String? playerName,
    int? assistPlayerId,
    String? assistPlayerName,
    String? type,
    String? detail,
    String? comments,
    bool? clearComments,
  }) {
    return LiveGameEvent(
      timeElapsed: timeElapsed ?? this.timeElapsed,
      timeExtra: timeExtra ?? this.timeExtra,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      assistPlayerId: assistPlayerId ?? this.assistPlayerId,
      assistPlayerName: assistPlayerName ?? this.assistPlayerName,
      type: type ?? this.type,
      detail: detail ?? this.detail,
      comments: (clearComments == true) ? null : (comments ?? this.comments),
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

class TeamLiveStats extends Equatable {
  final int? shotsOnGoal;
  final int? shotsOffGoal;
  final int? totalShots;
  final int? blockedShots;
  final int? corners;
  final int? fouls;
  final int? yellowCards;
  final int? redCards;
  final String? ballPossession;
  final double? expectedGoalsLive;

  const TeamLiveStats({
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

class LiveFixtureUpdate extends Equatable {
  final int fixtureId;
  final DateTime date;
  final String? referee;
  final String? statusLong;
  final String? statusShort;
  final int? elapsedMinutes;
  final String? leagueName;

  final TeamInFixture homeTeam;
  final TeamInFixture awayTeam;

  final int? homeScore;
  final int? awayScore;

  final List<LiveGameEvent> events;
  final TeamLiveStats? homeTeamLiveStats;
  final TeamLiveStats? awayTeamLiveStats;

  // === CORREÇÃO NO CONSTRUTOR ===
  const LiveFixtureUpdate({
    required this.fixtureId,
    required this.date,
    this.referee,
    this.statusLong,
    this.statusShort,
    this.elapsedMinutes,
    this.leagueName,
    required this.homeTeam, // Mantém como posicional obrigatório (já que é TeamInFixture)
    required this.awayTeam, // Mantém como posicional obrigatório
    this.homeScore,
    this.awayScore,
    required this.events,
    this.homeTeamLiveStats,
    this.awayTeamLiveStats,
  });
  // ============================

  @override
  List<Object?> get props => [
    fixtureId, date, statusShort, elapsedMinutes,
    homeTeam, awayTeam, // Adicionar aos props
    homeScore, awayScore,
    events,
    homeTeamLiveStats, awayTeamLiveStats,
  ];
}
