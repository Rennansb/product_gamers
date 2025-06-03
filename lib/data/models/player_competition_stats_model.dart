// lib/data/models/player_competition_stats_model.dart
import 'package:equatable/equatable.dart';
import 'team_model.dart'; // Para informações do time dentro das estatísticas

// Este modelo representa as estatísticas de um jogador DENTRO DE UMA COMPETIÇÃO ESPECÍFICA
// na resposta do endpoint /players?id=X&season=Y (que retorna uma lista de 'statistics')
// ou no endpoint /players/topscorers (onde cada item da lista é um jogador com suas stats)
class PlayerCompetitionStatsModel extends Equatable {
  // Informações do Time e Liga (conforme retornado pela API neste contexto)
  final TeamModel? team; // O time do jogador nesta competição/estatística
  final int? leagueId;
  final String? leagueName;
  final int? leagueSeason;
  final String? leagueCountry;
  final String? leagueLogoUrl;

  // Estatísticas de Jogos
  final int? appearances;
  final int? lineups;
  final int? minutesPlayed;
  final int? jerseyNumber;
  final String? position;
  final String? rating; // API retorna como string, ex: "7.80"
  final bool? captain;

  // Substituições
  final int? substitutesIn;
  final int? substitutesOut;
  final int? substitutesOnBench;

  // Finalizações
  final int? shotsTotal;
  final int? shotsOnGoal;

  // Gols e Assistências
  final int? goalsTotal;
  final int? goalsConceded; // Para goleiros
  final int? goalsAssists;
  final int? saves; // Para goleiros
  final double? expectedGoals; // xG (goals.expected)

  // Passes
  final int? passesTotal;
  final int? passesKey;
  final int?
      passesAccuracyPercentage; // passes.accuracy (API retorna int, ex: 85 para 85%)
  final double? expectedAssists; // xA (passes.expectedAssists)

  // Tackles
  final int? tacklesTotal;
  final int? tacklesBlocks;
  final int? tacklesInterceptions;

  // Duelos
  final int? duelsTotal;
  final int? duelsWon;

  // Dribles
  final int? dribblesAttempts;
  final int? dribblesSuccess;
  final int? dribblesPast;

  // Faltas
  final int? foulsDrawn;
  final int? foulsCommitted;

  // Cartões
  final int? cardsYellow;
  final int? cardsYellowRed; // Segundo amarelo resultando em vermelho
  final int? cardsRed;

  // Pênaltis
  final int? penaltyWon;
  final int? penaltyCommitted;
  final int? penaltyScored;
  final int? penaltyMissed;
  final int? penaltySaved;

  const PlayerCompetitionStatsModel({
    this.team,
    this.leagueId,
    this.leagueName,
    this.leagueSeason,
    this.leagueCountry,
    this.leagueLogoUrl,
    this.appearances,
    this.lineups,
    this.minutesPlayed,
    this.jerseyNumber,
    this.position,
    this.rating,
    this.captain,
    this.substitutesIn,
    this.substitutesOut,
    this.substitutesOnBench,
    this.shotsTotal,
    this.shotsOnGoal,
    this.goalsTotal,
    this.goalsConceded,
    this.goalsAssists,
    this.saves,
    this.expectedGoals,
    this.passesTotal,
    this.passesKey,
    this.passesAccuracyPercentage,
    this.expectedAssists,
    this.tacklesTotal,
    this.tacklesBlocks,
    this.tacklesInterceptions,
    this.duelsTotal,
    this.duelsWon,
    this.dribblesAttempts,
    this.dribblesSuccess,
    this.dribblesPast,
    this.foulsDrawn,
    this.foulsCommitted,
    this.cardsYellow,
    this.cardsYellowRed,
    this.cardsRed,
    this.penaltyWon,
    this.penaltyCommitted,
    this.penaltyScored,
    this.penaltyMissed,
    this.penaltySaved,
  });

  factory PlayerCompetitionStatsModel.fromJson(Map<String, dynamic> json) {
    // 'json' aqui é um objeto da lista "statistics" da resposta da API
    final teamData = json['team'] as Map<String, dynamic>?;
    final leagueData = json['league'] as Map<String, dynamic>? ?? {};
    final gamesData = json['games'] as Map<String, dynamic>? ?? {};
    final substitutesData = json['substitutes'] as Map<String, dynamic>? ?? {};
    final shotsData = json['shots'] as Map<String, dynamic>? ?? {};
    final goalsData = json['goals'] as Map<String, dynamic>? ?? {};
    final passesData = json['passes'] as Map<String, dynamic>? ?? {};
    final tacklesData = json['tackles'] as Map<String, dynamic>? ?? {};
    final duelsData = json['duels'] as Map<String, dynamic>? ?? {};
    final dribblesData = json['dribbles'] as Map<String, dynamic>? ?? {};
    final foulsData = json['fouls'] as Map<String, dynamic>? ?? {};
    final cardsData = json['cards'] as Map<String, dynamic>? ?? {};
    final penaltyData = json['penalty'] as Map<String, dynamic>? ?? {};

    // Helper para parsear 'num' para double de forma segura
    double? parseNumToDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return PlayerCompetitionStatsModel(
      team: teamData != null ? TeamModel.fromJson(teamData) : null,
      leagueId: leagueData['id'] as int?,
      leagueName: leagueData['name'] as String?,
      leagueSeason: leagueData['season'] as int?,
      leagueCountry: leagueData['country'] as String?,
      leagueLogoUrl: leagueData['logo'] as String?,

      appearances: gamesData['appearences'] as int?,
      lineups: gamesData['lineups'] as int?,
      minutesPlayed: gamesData['minutes'] as int?,
      jerseyNumber: gamesData['number'] as int?,
      position: gamesData['position'] as String?,
      rating: gamesData['rating']
          ?.toString(), // Manter como string, converter na entidade ou UI
      captain: gamesData['captain'] as bool?,

      substitutesIn: substitutesData['in'] as int?,
      substitutesOut: substitutesData['out'] as int?,
      substitutesOnBench: substitutesData['bench'] as int?,

      shotsTotal: shotsData['total'] as int?,
      shotsOnGoal: shotsData['on'] as int?,

      goalsTotal: goalsData['total'] as int?,
      goalsConceded: goalsData['conceded'] as int?,
      goalsAssists: goalsData['assists'] as int?,
      saves: goalsData['saves'] as int?,
      expectedGoals: parseNumToDouble(goalsData['expected']), // xG

      passesTotal: passesData['total'] as int?,
      passesKey: passesData['key'] as int?,
      passesAccuracyPercentage:
          passesData['accuracy'] as int?, // API retorna int (ex: 82 para 82%)
      expectedAssists: parseNumToDouble(passesData['expectedAssists']), // xA

      tacklesTotal: tacklesData['total'] as int?,
      tacklesBlocks: tacklesData['blocks'] as int?,
      tacklesInterceptions: tacklesData['interceptions'] as int?,

      duelsTotal: duelsData['total'] as int?,
      duelsWon: duelsData['won'] as int?,

      dribblesAttempts: dribblesData['attempts'] as int?,
      dribblesSuccess: dribblesData['success'] as int?,
      dribblesPast: dribblesData['past'] as int?,

      foulsDrawn: foulsData['drawn'] as int?,
      foulsCommitted: foulsData['committed'] as int?,

      cardsYellow: cardsData['yellow'] as int?,
      cardsYellowRed: cardsData['yellowred'] as int?,
      cardsRed: cardsData['red'] as int?,

      penaltyWon: penaltyData['won'] as int?,
      penaltyCommitted: penaltyData['commited'] as int?, // API usa "commited"
      penaltyScored: penaltyData['scored'] as int?,
      penaltyMissed: penaltyData['missed'] as int?,
      penaltySaved: penaltyData['saved'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        // Adicionar mais campos se precisar de comparações mais finas
        team, leagueId, leagueName, leagueSeason,
        appearances, lineups, minutesPlayed, jerseyNumber, position, rating,
        captain,
        substitutesIn, substitutesOut, substitutesOnBench,
        shotsTotal, shotsOnGoal,
        goalsTotal, goalsConceded, goalsAssists, saves, expectedGoals,
        passesTotal, passesKey, passesAccuracyPercentage, expectedAssists,
        tacklesTotal, tacklesBlocks, tacklesInterceptions,
        duelsTotal, duelsWon,
        dribblesAttempts, dribblesSuccess, dribblesPast,
        foulsDrawn, foulsCommitted,
        cardsYellow, cardsYellowRed, cardsRed,
        penaltyWon, penaltyCommitted, penaltyScored, penaltyMissed,
        penaltySaved,
      ];
}
