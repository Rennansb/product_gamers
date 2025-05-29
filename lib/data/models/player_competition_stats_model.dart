// lib/data/models/player_competition_stats_model.dart
import 'package:equatable/equatable.dart';
import 'team_model.dart'; // Para informações do time dentro das estatísticas

// Este modelo representa as estatísticas de um jogador DENTRO DE UMA COMPETIÇÃO ESPECÍFICA
// na resposta do endpoint /players?id=X&season=Y (que retorna uma lista de 'statistics')
// ou no endpoint /players/topscorers (onde cada item da lista é um jogador com suas stats)
class PlayerCompetitionStatsModel extends Equatable {
  // Informações da Competição/Time (podem variar dependendo do endpoint)
  final TeamModel? team; // O time do jogador nesta competição/estatística
  final Map<String, dynamic>? leagueRaw; // Dados brutos da liga
  final Map<String, dynamic>? gamesRaw;
  final Map<String, dynamic>? substitutesRaw;
  final Map<String, dynamic>? shotsRaw;
  final Map<String, dynamic>? goalsRaw;
  final Map<String, dynamic>? passesRaw;
  final Map<String, dynamic>? tacklesRaw;
  final Map<String, dynamic>? duelsRaw;
  final Map<String, dynamic>? dribblesRaw;
  final Map<String, dynamic>? foulsRaw;
  final Map<String, dynamic>? cardsRaw;
  final Map<String, dynamic>? penaltyRaw;

  // Campos extraídos para facilitar o acesso (exemplos)
  final String? leagueName;
  final int? appearances;
  final int? lineups;
  final int? minutesPlayed;
  final String? position;
  final String? rating;
  final int? goalsTotal;
  final int? goalsAssists;
  final double? expectedGoalsIndividual; // xGi (se a API fornecer)

  const PlayerCompetitionStatsModel({
    this.team,
    this.leagueRaw,
    this.gamesRaw,
    this.substitutesRaw,
    this.shotsRaw,
    this.goalsRaw,
    this.passesRaw,
    this.tacklesRaw,
    this.duelsRaw,
    this.dribblesRaw,
    this.foulsRaw,
    this.cardsRaw,
    this.penaltyRaw,
    // Campos extraídos
    this.leagueName,
    this.appearances,
    this.lineups,
    this.minutesPlayed,
    this.position,
    this.rating,
    this.goalsTotal,
    this.goalsAssists,
    this.expectedGoalsIndividual,
  });

  factory PlayerCompetitionStatsModel.fromJson(Map<String, dynamic> json) {
    // O objeto 'statistics' da API-Football é uma lista, e cada item dessa lista
    // é o que este factory espera como 'json'.
    final teamData = json['team'] as Map<String, dynamic>?;
    final leagueData = json['league'] as Map<String, dynamic>? ?? {};
    final gamesData = json['games'] as Map<String, dynamic>? ?? {};
    final goalsData = json['goals'] as Map<String, dynamic>? ?? {};
    // Adicione outros conforme necessário (shots, passes, etc.)

    // Exemplo de como xG individual PODE vir (precisa verificar a API):
    // Alguns provedores de dados colocam xG em "expected" ou "xg" dentro de "goals" ou "shots".
    // A API-Football não tem um campo padronizado fácil para xG individual em todos os endpoints.
    // Se você obtiver xG de outra fonte ou um endpoint específico, precisará mapeá-lo.
    double? xgIndividual;
    // if (json['xg']?['total'] != null) {
    //   xgIndividual = double.tryParse(json['xg']['total'].toString());
    // }

    return PlayerCompetitionStatsModel(
      team: teamData != null ? TeamModel.fromJson(teamData) : null,
      leagueRaw: leagueData,
      gamesRaw: gamesData,
      substitutesRaw: json['substitutes'] as Map<String, dynamic>? ?? {},
      shotsRaw: json['shots'] as Map<String, dynamic>? ?? {},
      goalsRaw: goalsData,
      passesRaw: json['passes'] as Map<String, dynamic>? ?? {},
      tacklesRaw: json['tackles'] as Map<String, dynamic>? ?? {},
      duelsRaw: json['duels'] as Map<String, dynamic>? ?? {},
      dribblesRaw: json['dribbles'] as Map<String, dynamic>? ?? {},
      foulsRaw: json['fouls'] as Map<String, dynamic>? ?? {},
      cardsRaw: json['cards'] as Map<String, dynamic>? ?? {},
      penaltyRaw: json['penalty'] as Map<String, dynamic>? ?? {},

      // Campos extraídos para conveniência
      leagueName: leagueData['name'] as String?,
      appearances:
          gamesData['appearences'] as int?, // Atenção ao typo "appearences"
      lineups: gamesData['lineups'] as int?,
      minutesPlayed: gamesData['minutes'] as int?,
      position: gamesData['position'] as String?,
      rating: gamesData['rating']?.toString(), // Pode ser double ou string
      goalsTotal: goalsData['total'] as int?,
      goalsAssists: goalsData['assists'] as int?,
      expectedGoalsIndividual: xgIndividual, // Preencher se conseguir obter
    );
  }

  @override
  List<Object?> get props => [
    team,
    leagueRaw,
    gamesRaw,
    goalsRaw, // Compare os objetos raw ou os extraídos
    leagueName,
    appearances,
    minutesPlayed,
    goalsTotal,
    goalsAssists,
    expectedGoalsIndividual,
  ];
}
