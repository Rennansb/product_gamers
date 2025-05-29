// lib/domain/entities/fixture.dart
import 'package:equatable/equatable.dart';
import 'team.dart'; // Importa TeamInFixture

class Fixture extends Equatable {
  final int id;
  final DateTime date;
  final String statusShort; // Ex: "NS", "FT", "HT", "LIVE"
  final String statusLong; // Ex: "Not Started", "Match Finished"

  final TeamInFixture homeTeam;
  final TeamInFixture awayTeam;

  final int? homeGoals; // Gols atuais/finais
  final int? awayGoals; // Gols atuais/finais

  final int leagueId;
  final String leagueName;
  final String? leagueLogoUrl; // Logo da liga associada

  // Informações adicionais que o FixtureModel.toEntity() mapeia
  final String? refereeName;
  final String? venueName;
  final int? elapsedMinutes; // Minutos decorridos se ao vivo

  // Placar de diferentes períodos
  final int? halftimeHomeScore;
  final int? halftimeAwayScore;
  final int? fulltimeHomeScore;
  final int? fulltimeAwayScore;
  // Poderia adicionar extratime e penalty scores se necessário

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
