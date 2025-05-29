// lib/domain/entities/player_stats.dart
import 'package:equatable/equatable.dart';

class PlayerSeasonStats extends Equatable {
  final int playerId;
  final String playerName;
  final String? playerPhotoUrl;

  // Informações do time principal e liga para estas estatísticas
  final int? teamId;
  final String? teamName;
  final String? teamLogoUrl;
  final int? leagueId;
  final String?
  leagueName; // Nome da liga principal onde estas stats foram obtidas

  // Estatísticas de Jogo
  final String? position; // Posição mais frequente
  final int? appearances; // Aparições (jogos jogados)
  final int? lineups; // Quantas vezes foi titular
  final int? minutesPlayed;
  final double? rating; // Nota média do jogador (se fornecida)

  // Estatísticas Ofensivas
  final int? goals;
  final int? assists;
  final double?
  expectedGoalsIndividualPer90; // xGi/90 - Gols Esperados Individuais por 90 minutos
  final int? shotsTotal; // Total de finalizações
  final int? shotsOnGoal; // Finalizações no gol

  // Estatísticas Defensivas/Disciplinares (Exemplos)
  final int? yellowCards;
  final int? redCards;
  // Poderia adicionar tackles, interceptações, etc., se relevante e disponível

  const PlayerSeasonStats({
    required this.playerId,
    required this.playerName,
    this.playerPhotoUrl,
    this.teamId,
    this.teamName,
    this.teamLogoUrl,
    this.leagueId,
    this.leagueName,
    this.position,
    this.appearances,
    this.lineups,
    this.minutesPlayed,
    this.rating,
    this.goals,
    this.assists,
    this.expectedGoalsIndividualPer90,
    this.shotsTotal,
    this.shotsOnGoal,
    this.yellowCards,
    this.redCards,
  });

  // Calculadora simples de gols por 90 minutos
  double get goalsPer90 {
    if ((goals ?? 0) > 0 && (minutesPlayed ?? 0) > 0) {
      return (goals! / minutesPlayed!) * 90.0;
    }
    return 0.0;
  }

  @override
  List<Object?> get props => [
    playerId,
    playerName,
    playerPhotoUrl,
    teamId,
    teamName,
    teamLogoUrl,
    leagueId,
    leagueName,
    position,
    appearances,
    lineups,
    minutesPlayed,
    rating,
    goals,
    assists,
    expectedGoalsIndividualPer90,
    shotsTotal,
    shotsOnGoal,
    yellowCards,
    redCards,
  ];
}
