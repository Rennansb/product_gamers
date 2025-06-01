// lib/domain/entities/live_fixture_update.dart
import 'package:equatable/equatable.dart';

// LiveGameEvent e TeamLiveStats permanecem como definidos anteriormente
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

  LiveGameEvent copyWith({String? teamName}) {
    // Assegurar que este copyWith existe
    return LiveGameEvent(
      timeElapsed: timeElapsed,
      timeExtra: timeExtra,
      teamId: teamId,
      teamName: teamName ?? this.teamName,
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
        comments
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
        expectedGoalsLive
      ];
}
// FIM DE LiveGameEvent e TeamLiveStats

// Entidade principal para a atualização ao vivo de um fixture
class LiveFixtureUpdate extends Equatable {
  final int fixtureId;
  final DateTime date;
  final String? referee;
  final String? statusLong;
  final String? statusShort;
  final int? elapsedMinutes;

  final String? leagueName; // Nome da liga

  // ===== CAMPOS ADICIONADOS/CORRIGIDOS =====
  final String homeTeamName;
  final String? homeTeamLogoUrl;
  final int homeTeamId;
  final String awayTeamName;
  final String? awayTeamLogoUrl;
  final int awayTeamId; // Adicionar ID
  // =======================================

  final int? homeScore;
  final int? awayScore;

  final List<LiveGameEvent> events;
  final TeamLiveStats? homeTeamLiveStats;
  final TeamLiveStats? awayTeamLiveStats;

  const LiveFixtureUpdate({
    required this.fixtureId,
    required this.date,
    this.referee,
    this.statusLong,
    this.statusShort,
    this.elapsedMinutes,
    this.leagueName,
    // ===== PARÂMETROS ADICIONADOS/CORRIGIDOS NO CONSTRUTOR =====
    required this.homeTeamName,
    this.homeTeamLogoUrl,
    required this.homeTeamId,
    required this.awayTeamName,
    this.awayTeamLogoUrl,
    required this.awayTeamId,
    // =========================================================
    this.homeScore,
    this.awayScore,
    required this.events,
    this.homeTeamLiveStats,
    this.awayTeamLiveStats,
  });

  @override
  List<Object?> get props => [
        fixtureId, date, statusShort, elapsedMinutes,
        leagueName,
        homeTeamName, homeTeamLogoUrl, homeTeamId, // Adicionado
        awayTeamName, awayTeamLogoUrl, awayTeamId, // Adicionado
        homeScore, awayScore,
        events, homeTeamLiveStats, awayTeamLiveStats
      ];
}
