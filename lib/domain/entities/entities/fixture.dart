// lib/domain/entities/fixture.dart
import 'package:equatable/equatable.dart';
import 'team.dart'; // Importa TeamInFixture (que deve estar em lib/domain/entities/team.dart)

class Fixture extends Equatable {
  final int id;
  final DateTime date;
  final String statusShort;
  final String statusLong;
  final TeamInFixture homeTeam;
  final TeamInFixture awayTeam;
  final int? homeGoals;
  final int? awayGoals;
  final int leagueId;
  final String leagueName;
  final String? leagueLogoUrl;
  final String? refereeName;
  final String? venueName;
  final int? elapsedMinutes;
  final int? halftimeHomeScore;
  final int? halftimeAwayScore;
  final int? fulltimeHomeScore;
  final int? fulltimeAwayScore;

  const Fixture({
    required this.id,
    required this.date,
    required this.statusShort,
    required this.statusLong,
    required this.homeTeam,
    required this.awayTeam,
    this.homeGoals,
    this.awayGoals,
    required this.leagueId,
    required this.leagueName,
    this.leagueLogoUrl,
    this.refereeName,
    this.venueName,
    this.elapsedMinutes,
    this.halftimeHomeScore,
    this.halftimeAwayScore,
    this.fulltimeHomeScore,
    this.fulltimeAwayScore,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        statusShort,
        statusLong,
        homeTeam,
        awayTeam,
        homeGoals,
        awayGoals,
        leagueId,
        leagueName,
        leagueLogoUrl,
        refereeName,
        venueName,
        elapsedMinutes,
        halftimeHomeScore,
        halftimeAwayScore,
        fulltimeHomeScore,
        fulltimeAwayScore,
      ];
}
