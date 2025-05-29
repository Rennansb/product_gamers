// lib/data/models/player_season_stats_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/player_stats.dart'
    show PlayerSeasonStats;
import 'player_info_model.dart';
import 'player_competition_stats_model.dart'; // O modelo que acabamos de definir
import 'team_model.dart'; // Para o time do jogador, se aplicável
// Para a entidade PlayerSeasonStats

// Modelo principal para as estatísticas de um jogador em uma temporada,
// potencialmente agregando dados de múltiplas competições ou focando em uma.
// Este modelo encapsula a resposta do endpoint /players?id=X&season=Y ou /players/topscorers
class PlayerSeasonStatsModel extends Equatable {
  final PlayerInfoModel player; // Informações básicas do jogador
  // A API para /players?id=X&season=Y retorna uma lista de 'statistics',
  // cada uma sendo um PlayerCompetitionStatsModel.
  // Para /players/topscorers, cada item da lista já é um jogador com suas estatísticas (geralmente 1).
  final List<PlayerCompetitionStatsModel> statisticsPerCompetition;

  const PlayerSeasonStatsModel({
    required this.player,
    required this.statisticsPerCompetition,
  });

  factory PlayerSeasonStatsModel.fromJson(Map<String, dynamic> json) {
    // O endpoint /players?id=X&season=Y tem 'player' e 'statistics' no root do primeiro item da lista de resposta.
    // O endpoint /players/topscorers tem 'player' e 'statistics' para cada item da lista de resposta.
    // Esta factory espera um objeto que já contenha 'player' e 'statistics'.
    return PlayerSeasonStatsModel(
      player: PlayerInfoModel.fromJson(
        json['player'] as Map<String, dynamic>? ?? json,
      ), // Tenta 'player', senão o root
      statisticsPerCompetition:
          (json['statistics'] as List<dynamic>?)
              ?.map(
                (statJson) => PlayerCompetitionStatsModel.fromJson(
                  statJson as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  // Método para converter para a Entidade de Domínio
  PlayerSeasonStats toEntity({int? filterByLeagueId}) {
    PlayerCompetitionStatsModel? relevantStats;

    if (statisticsPerCompetition.isNotEmpty) {
      if (filterByLeagueId != null) {
        relevantStats = statisticsPerCompetition.firstWhere(
          (s) => (s.leagueRaw?['id'] as int?) == filterByLeagueId,
          orElse:
              () =>
                  statisticsPerCompetition
                      .first, // Fallback para a primeira se a liga não for encontrada
        );
      } else {
        // Lógica para escolher a "principal" competição ou agregar.
        // Por simplicidade, pegamos a primeira ou a com mais jogos.
        relevantStats = statisticsPerCompetition.reduce(
          (curr, next) =>
              (curr.appearances ?? 0) >= (next.appearances ?? 0) ? curr : next,
        );
      }
    }

    return PlayerSeasonStats(
      playerId: player.id,
      playerName: player.name,
      playerPhotoUrl: player.photoUrl,
      // Informações do time e liga são extraídas de relevantStats (se disponíveis)
      teamId: relevantStats?.team?.id,
      teamName: relevantStats?.team?.name,
      teamLogoUrl: relevantStats?.team?.logoUrl,
      leagueId:
          relevantStats?.leagueRaw?['id'] as int?, // Adicionado à entidade
      leagueName: relevantStats?.leagueName, // Adicionado à entidade

      position: relevantStats?.position,
      appearances: relevantStats?.appearances,
      lineups: relevantStats?.lineups,
      minutesPlayed: relevantStats?.minutesPlayed,
      goals: relevantStats?.goalsTotal,
      assists: relevantStats?.goalsAssists,
      rating: double.tryParse(relevantStats?.rating ?? ""),
      expectedGoalsIndividualPer90:
          relevantStats
              ?.expectedGoalsIndividual, // Supondo que já é por 90min ou precisa de cálculo
      // Outras estatísticas da entidade
      yellowCards:
          relevantStats?.cardsRaw?['yellow'] as int?, // Exemplo de como extrair
      redCards: relevantStats?.cardsRaw?['red'] as int?,
    );
  }

  @override
  List<Object?> get props => [player, statisticsPerCompetition];
}
