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

  final double? averageGoalsScoredPerGame;
  final double? averageGoalsConcededPerGame;
  // ===== NOMES CORRIGIDOS/ADICIONADOS PARA ESCANTEIOS =====
  final double? averageCornersGeneratedPerGame;
  final double? averageCornersConcededPerGame; // Adicionado para consistência
  // =====================================================
  final double? averageYellowCardsPerGame;
  final double? averageRedCardsPerGame;

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
    // ===== PARÂMETROS CORRIGIDOS/ADICIONADOS =====
    this.averageCornersGeneratedPerGame,
    this.averageCornersConcededPerGame,
    // ============================================
    this.averageYellowCardsPerGame,
    this.averageRedCardsPerGame,
  });

  @override
  List<Object?> get props => [
        teamId, leagueId, leagueName, season, played, wins, draws, losses,
        goalsFor, goalsAgainst, formStreak,
        averageGoalsScoredPerGame, averageGoalsConcededPerGame,
        averageCornersGeneratedPerGame,
        averageCornersConcededPerGame, // Adicionado
        averageYellowCardsPerGame, averageRedCardsPerGame,
      ];
}
