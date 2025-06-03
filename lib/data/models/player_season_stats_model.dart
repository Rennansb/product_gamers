// lib/data/models/player_season_stats_model.dart
import 'package:collection/collection.dart';
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
  // A API para /players?id=X&season=Y ou /players/topscorers retorna uma lista de "statistics",
  // cada uma sendo um PlayerCompetitionStatsModel (estatísticas para uma liga/competição diferente).
  final List<PlayerCompetitionStatsModel> statisticsPerCompetition;

  const PlayerSeasonStatsModel({
    required this.player,
    required this.statisticsPerCompetition,
  });

  factory PlayerSeasonStatsModel.fromJson(Map<String, dynamic> json) {
    // Esta factory espera um objeto JSON que já contenha as chaves 'player' e 'statistics'.
    // Para /players?id=X&season=Y, a API retorna uma LISTA com UM objeto assim.
    // Para /players/topscorers, a API retorna uma LISTA de objetos assim (um por jogador).
    // O FootballRemoteDataSourceImpl já lida com a extração do objeto correto da lista da API.
    return PlayerSeasonStatsModel(
      player: PlayerInfoModel.fromJson(
          json['player'] as Map<String, dynamic>? ??
              json), // Tenta 'player', senão o root (para /players/squads)
      statisticsPerCompetition: (json['statistics'] as List<dynamic>?)
              ?.map((statJson) => PlayerCompetitionStatsModel.fromJson(
                  statJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'player': player.toJson(), // Assumindo que PlayerInfoModel tem toJson()
        'statistics': statisticsPerCompetition
            .map((s) => {
                  /* Lógica para serializar PlayerCompetitionStatsModel se necessário */
                })
            .toList(),
      };

  // Converte para a Entidade de Domínio PlayerSeasonStats
  // Tenta encontrar as estatísticas da competição principal ou a mais relevante.
  PlayerSeasonStats toEntity(
      {int? filterByLeagueId, String? filterByLeagueName}) {
    PlayerCompetitionStatsModel? relevantStats;

    if (statisticsPerCompetition.isNotEmpty) {
      if (filterByLeagueId != null) {
        relevantStats = statisticsPerCompetition.firstWhereOrNull(
          (s) => s.leagueId == filterByLeagueId,
        );
      }
      if (relevantStats == null && filterByLeagueName != null) {
        relevantStats = statisticsPerCompetition.firstWhereOrNull(
          (s) =>
              s.leagueName?.toLowerCase() == filterByLeagueName.toLowerCase(),
        );
      }
      // Fallback: Pega a competição com mais aparições, ou a primeira se todas tiverem 0 ou nulo.
      relevantStats ??= statisticsPerCompetition
              .sorted(
                  (a, b) => (b.appearances ?? 0).compareTo(a.appearances ?? 0))
              .firstOrNull ??
          statisticsPerCompetition.first;
    }

    return PlayerSeasonStats(
      playerId: player.id,
      playerName: player.name,
      playerPhotoUrl: player.photoUrl,

      // Informações do time e liga são extraídas de relevantStats (se disponíveis)
      teamId: relevantStats?.team?.id,
      teamName: relevantStats?.team?.name,
      teamLogoUrl: relevantStats?.team?.logoUrl,
      leagueId: relevantStats?.leagueId,
      leagueName: relevantStats?.leagueName,

      position: relevantStats?.position,
      appearances: relevantStats?.appearances,
      lineups: relevantStats?.lineups,
      minutesPlayed: relevantStats?.minutesPlayed,
      rating: double.tryParse(relevantStats?.rating?.toString() ??
          ""), // Converte rating para double

      goals: relevantStats?.goalsTotal,
      assists: relevantStats?.goalsAssists,

      // Mapeando xG e xA totais da competição relevante para a entidade
      xgTotalSeason: relevantStats?.expectedGoals,
      xaTotalSeason: relevantStats?.expectedAssists,

      shotsTotal: relevantStats?.shotsTotal,
      shotsOnGoal: relevantStats?.shotsOnGoal,

      yellowCards: relevantStats?.cardsYellow,
      redCards: relevantStats?.cardsRed,
      // Adicione outros campos da entidade PlayerSeasonStats que você queira popular
    );
  }

  @override
  List<Object?> get props => [player, statisticsPerCompetition];
}
