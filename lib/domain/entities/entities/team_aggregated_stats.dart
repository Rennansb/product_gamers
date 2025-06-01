// lib/domain/entities/team_aggregated_stats.dart
import 'package:equatable/equatable.dart';

class TeamAggregatedStats extends Equatable {
  final int teamId;
  final int leagueId;
  final String leagueName;
  final String season;

  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final String? formStreak;

  // Nomes dos campos na ENTIDADE que devem corresponder aos parâmetros do construtor
  final double? averageGoalsScoredPerGame;
  final double? averageGoalsConcededPerGame;
  final double? averageCornersGeneratedPerGame; // <- Nome usado na entidade
  final double? averageYellowCardsPerGame; // <- Nome usado na entidade
  final double? averageRedCardsPerGame; // <- Nome usado na entidade

  // CONSTRUTOR DA ENTIDADE - Parâmetros nomeados DEVEM corresponder
  const TeamAggregatedStats({
    required this.teamId,
    required this.leagueId,
    required this.leagueName,
    required this.season,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    this.formStreak,
    this.averageGoalsScoredPerGame,
    this.averageGoalsConcededPerGame,
    this.averageCornersGeneratedPerGame, // <--- PARÂMETRO NOMEADO CORRETO
    this.averageYellowCardsPerGame, // <--- PARÂMETRO NOMEADO CORRETO
    this.averageRedCardsPerGame, // <--- PARÂMETRO NOMEADO CORRETO
  });

  @override
  List<Object?> get props => [
        teamId,
        leagueId,
        leagueName,
        season,
        played,
        wins,
        draws,
        losses,
        goalsFor,
        goalsAgainst,
        formStreak,
        averageGoalsScoredPerGame,
        averageGoalsConcededPerGame,
        averageCornersGeneratedPerGame,
        averageYellowCardsPerGame,
        averageRedCardsPerGame,
      ];
}
