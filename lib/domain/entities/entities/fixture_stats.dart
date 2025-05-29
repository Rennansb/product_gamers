// lib/domain/entities/fixture_stats.dart
import 'package:equatable/equatable.dart';

// Entidade para as estatísticas de UM time em uma partida
class TeamFixtureStats extends Equatable {
  final int teamId;
  final String teamName;
  final String? teamLogoUrl; // Útil para exibição na UI

  // Estatísticas Chave
  final double? expectedGoals; // xG (Gols Esperados)
  final int? shotsOnGoal; // Finalizações no Gol
  final int? shotsOffGoal; // Finalizações Fora do Gol
  final int? shotsTotal; // Total de Finalizações
  final int? shotsBlocked; // Finalizações Bloqueadas
  final int? corners; // Escanteios
  final int? fouls; // Faltas Cometidas
  final int? yellowCards; // Cartões Amarelos
  final int? redCards; // Cartões Vermelhos
  final double? ballPossessionPercent; // Posse de Bola (ex: 55.0 para 55%)
  final int? passesTotal; // Total de Passes
  final int? passesAccurate; // Passes Certos
  final double? passAccuracyPercent; // Precisão dos Passes (ex: 80.0 para 80%)

  // Médias que poderiam ser calculadas ou vir de outra fonte (para análise pré-jogo)
  // Estes campos foram adicionados ao TeamFixtureStatsModel como exemplo,
  // mas sua população depende de uma lógica de cálculo ou de outro endpoint da API.
  final double? averageCornersGenerated;
  final double? averageYellowCardsReceived;

  const TeamFixtureStats({
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    this.expectedGoals,
    this.shotsOnGoal,
    this.shotsOffGoal,
    this.shotsTotal,
    this.shotsBlocked,
    this.corners,
    this.fouls,
    this.yellowCards,
    this.redCards,
    this.ballPossessionPercent,
    this.passesTotal,
    this.passesAccurate,
    this.passAccuracyPercent,
    this.averageCornersGenerated,
    this.averageYellowCardsReceived,
  });

  @override
  List<Object?> get props => [
    teamId,
    teamName,
    teamLogoUrl,
    expectedGoals,
    shotsOnGoal,
    shotsOffGoal,
    shotsTotal,
    shotsBlocked,
    corners,
    fouls,
    yellowCards,
    redCards,
    ballPossessionPercent,
    passesTotal,
    passesAccurate,
    passAccuracyPercent,
    averageCornersGenerated,
    averageYellowCardsReceived,
  ];
}

// Entidade principal para as estatísticas de uma partida completa
class FixtureStatsEntity extends Equatable {
  final int fixtureId; // ID da partida à qual estas estatísticas se referem
  final TeamFixtureStats? homeTeam; // Estatísticas do time da casa
  final TeamFixtureStats? awayTeam; // Estatísticas do time visitante

  const FixtureStatsEntity({
    required this.fixtureId,
    this.homeTeam,
    this.awayTeam,
  });

  @override
  List<Object?> get props => [fixtureId, homeTeam, awayTeam];
}
