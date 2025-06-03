// lib/domain/entities/player_stats.dart
import 'package:equatable/equatable.dart';

class PlayerSeasonStats extends Equatable {
  final int playerId;
  final String playerName;
  final String? playerPhotoUrl;

  // Informações do time e liga principal para estas estatísticas
  final int? teamId;
  final String? teamName;
  final String? teamLogoUrl;
  final int? leagueId;
  final String? leagueName;

  // Estatísticas de Jogo
  final String? position; // Posição mais frequente
  final int? appearances; // Aparições (jogos jogados)
  final int? lineups; // Quantas vezes foi titular
  final int? minutesPlayed; // Total de minutos jogados na competição/temporada
  final double?
      rating; // Nota média do jogador (se fornecida e parseada como double)

  // Estatísticas Ofensivas
  final int? goals; // Total de gols
  final int? assists; // Total de assistências
  final double?
      xgTotalSeason; // xG (Expected Goals) total do jogador na temporada/competição
  final double?
      xaTotalSeason; // xA (Expected Assists) total do jogador na temporada/competição
  final int? shotsTotal;
  final int? shotsOnGoal;

  // Estatísticas Disciplinares
  final int? yellowCards;
  final int? redCards;

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
    this.xgTotalSeason,
    this.xaTotalSeason,
    this.shotsTotal,
    this.shotsOnGoal,
    this.yellowCards,
    this.redCards,
  });

  // Getters para métricas calculadas por 90 minutos
  double get goalsPer90 {
    if ((goals ?? 0) > 0 && (minutesPlayed ?? 0) >= 90) {
      // Considerar apenas se jogou pelo menos 90 min
      return (goals! / minutesPlayed!) * 90.0;
    }
    return 0.0;
  }

  double get assistsPer90 {
    if ((assists ?? 0) > 0 && (minutesPlayed ?? 0) >= 90) {
      return (assists! / minutesPlayed!) * 90.0;
    }
    return 0.0;
  }

  double get xgIndividualPer90 {
    // xGi/90
    if ((xgTotalSeason ?? 0.0) > 0.0 && (minutesPlayed ?? 0) >= 90) {
      return (xgTotalSeason! / minutesPlayed!) * 90.0;
    }
    // Se xgTotalSeason não estiver disponível, pode-se usar um proxy com goalsPer90,
    // mas é melhor retornar 0.0 e deixar a lógica de análise lidar com a ausência de xG.
    // Exemplo de proxy (menos ideal): return goalsPer90 * 0.8;
    return 0.0;
  }

  double get xaIndividualPer90 {
    // xAi/90
    if ((xaTotalSeason ?? 0.0) > 0.0 && (minutesPlayed ?? 0) >= 90) {
      return (xaTotalSeason! / minutesPlayed!) * 90.0;
    }
    // Exemplo de proxy (menos ideal): return assistsPer90 * 0.8;
    return 0.0;
  }

  // Contribuição de Gol Esperada por 90 minutos (xGi + xAi / 90)
  double get xgiPlusXaiPer90 {
    return xgIndividualPer90 + xaIndividualPer90;
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
        xgTotalSeason,
        xaTotalSeason,
        shotsTotal,
        shotsOnGoal,
        yellowCards,
        redCards,
      ];
}
