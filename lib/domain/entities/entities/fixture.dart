// lib/domain/entities/fixture.dart
import 'package:equatable/equatable.dart';
import 'team.dart'; // Contém TeamInFixture
import 'fixture_league_info_entity.dart'; // Importa a entidade para informações da liga

class Fixture extends Equatable {
  final int id;
  final DateTime date;
  final String statusShort;
  final String statusLong;
  final TeamInFixture homeTeam;
  final TeamInFixture awayTeam;
  final int? homeGoals;
  final int? awayGoals;

  // ESTE É O CAMPO CORRETO PARA INFORMAÇÕES DA LIGA
  final FixtureLeagueInfoEntity league;

  final String? refereeName;
  final String? venueName;
  final int? elapsedMinutes;
  final int? halftimeHomeScore;
  final int? halftimeAwayScore;
  final int? fulltimeHomeScore;
  final int? fulltimeAwayScore;

  // CONSTRUTOR CORRETO DA ENTIDADE
  const Fixture({
    required this.id,
    required this.date,
    required this.statusShort,
    required this.statusLong,
    required this.homeTeam,
    required this.awayTeam,
    this.homeGoals,
    this.awayGoals,
    required this.league, // <--- DEVE SER 'league', NÃO 'leagueId', 'leagueName', etc.
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
        id, date, statusShort, statusLong, homeTeam, awayTeam, homeGoals,
        awayGoals,
        league, // <--- 'league' EM PROPS
        refereeName, venueName, elapsedMinutes,
        halftimeHomeScore, halftimeAwayScore, fulltimeHomeScore,
        fulltimeAwayScore,
      ];
}
