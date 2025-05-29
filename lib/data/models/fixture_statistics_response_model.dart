// lib/data/models/fixture_statistics_response_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'team_fixture_stats_model.dart'; // Importa o modelo de estatísticas do time
// Para a entidade FixtureStatsEntity

class FixtureStatisticsResponseModel extends Equatable {
  // A API /fixtures/statistics retorna uma lista com dois elementos, um para cada time.
  // Estes campos armazenarão os dados parseados para o time da casa e visitante.
  final TeamFixtureStatsModel? homeTeamStats;
  final TeamFixtureStatsModel? awayTeamStats;

  const FixtureStatisticsResponseModel({
    this.homeTeamStats,
    this.awayTeamStats,
  });

  factory FixtureStatisticsResponseModel.fromJson(
    List<dynamic> jsonList, {
    required int homeTeamId,
    required int awayTeamId,
  }) {
    TeamFixtureStatsModel? tempHomeStats;
    TeamFixtureStatsModel? tempAwayStats;

    if (jsonList.length == 2) {
      // Geralmente a API retorna 2 times
      final team1Data = jsonList[0] as Map<String, dynamic>?;
      final team2Data = jsonList[1] as Map<String, dynamic>?;

      if (team1Data != null && team2Data != null) {
        final team1StatsModel = TeamFixtureStatsModel.fromJson(team1Data);
        final team2StatsModel = TeamFixtureStatsModel.fromJson(team2Data);

        // Identifica qual é o time da casa e qual é o visitante pelo ID
        if (team1StatsModel.team.id == homeTeamId) {
          tempHomeStats = team1StatsModel;
          tempAwayStats =
              (team2StatsModel.team.id == awayTeamId) ? team2StatsModel : null;
        } else if (team1StatsModel.team.id == awayTeamId) {
          tempAwayStats = team1StatsModel;
          tempHomeStats =
              (team2StatsModel.team.id == homeTeamId) ? team2StatsModel : null;
        } else if (team2StatsModel.team.id == homeTeamId) {
          // Caso a ordem esteja invertida e o primeiro não era nem home nem away
          tempHomeStats = team2StatsModel;
          tempAwayStats =
              (team1StatsModel.team.id == awayTeamId) ? team1StatsModel : null;
        } else if (team2StatsModel.team.id == awayTeamId) {
          tempAwayStats = team2StatsModel;
          tempHomeStats =
              (team1StatsModel.team.id == homeTeamId) ? team1StatsModel : null;
        }

        // Se, após a tentativa de match por ID, um deles ainda for nulo,
        // e o outro não, e os IDs não bateram (ex: ID de um time era 0 ou errado),
        // podemos tentar atribuir pela ordem (primeiro = home, segundo = away) como último recurso.
        // Esta parte é mais um fallback e depende da API ser consistente na ordem.
        if (jsonList.length == 2) {
          if (tempHomeStats == null &&
              tempAwayStats != null &&
              tempAwayStats.team.id != homeTeamId) {
            final potentialHome = TeamFixtureStatsModel.fromJson(
              jsonList[0] as Map<String, dynamic>,
            );
            if (potentialHome.team.id != tempAwayStats.team.id) {
              // Garante que não é o mesmo time
              tempHomeStats = potentialHome;
            }
          } else if (tempAwayStats == null &&
              tempHomeStats != null &&
              tempHomeStats.team.id != awayTeamId) {
            final potentialAway = TeamFixtureStatsModel.fromJson(
              jsonList[1] as Map<String, dynamic>,
            );
            if (potentialAway.team.id != tempHomeStats.team.id) {
              tempAwayStats = potentialAway;
            }
          } else if (tempHomeStats == null && tempAwayStats == null) {
            // Nenhum foi identificado por ID
            tempHomeStats = TeamFixtureStatsModel.fromJson(
              jsonList[0] as Map<String, dynamic>,
            );
            tempAwayStats = TeamFixtureStatsModel.fromJson(
              jsonList[1] as Map<String, dynamic>,
            );
            // Validação posterior pode ser necessária para garantir que home é home e away é away.
          }
        }
      }
    } else if (jsonList.isNotEmpty && jsonList.length == 1) {
      // A API pode retornar estatísticas de apenas um time em alguns casos (raro para /statistics)
      final singleTeamData = jsonList[0] as Map<String, dynamic>?;
      if (singleTeamData != null) {
        final singleTeamStatsModel = TeamFixtureStatsModel.fromJson(
          singleTeamData,
        );
        if (singleTeamStatsModel.team.id == homeTeamId) {
          tempHomeStats = singleTeamStatsModel;
        } else if (singleTeamStatsModel.team.id == awayTeamId) {
          tempAwayStats = singleTeamStatsModel;
        }
      }
    }
    // Se jsonList for vazia, tempHomeStats e tempAwayStats permanecerão nulos.

    return FixtureStatisticsResponseModel(
      homeTeamStats: tempHomeStats,
      awayTeamStats: tempAwayStats,
    );
  }

  FixtureStatsEntity toEntity(int fixtureId) {
    return FixtureStatsEntity(
      fixtureId:
          fixtureId, // O ID do fixture vem do contexto da chamada, não da resposta de /statistics
      homeTeam: homeTeamStats?.toEntity(),
      awayTeam: awayTeamStats?.toEntity(),
    );
  }

  @override
  List<Object?> get props => [homeTeamStats, awayTeamStats];
}
