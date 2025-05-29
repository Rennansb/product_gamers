// lib/data/models/referee_stats_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/referee_stats.dart';
// Para o método toEntity

// Modelo para uma temporada específica das estatísticas do árbitro
// Colocando aqui para garantir que está acessível
class RefereeSeasonGamesModel extends Equatable {
  final int? leagueId;
  final String? leagueName;
  final int gamesOfficiated;
  final int totalYellowCards;
  final int totalRedCards;

  const RefereeSeasonGamesModel({
    this.leagueId,
    this.leagueName,
    required this.gamesOfficiated,
    required this.totalYellowCards,
    required this.totalRedCards,
  });

  factory RefereeSeasonGamesModel.fromJson(Map<String, dynamic> json) {
    return RefereeSeasonGamesModel(
      leagueId: json['league']?['id'] as int?,
      leagueName: json['league']?['name'] as String?,
      gamesOfficiated: json['matches'] as int? ?? json['games'] as int? ?? 0,
      totalYellowCards: json['cards']?['yellow'] as int? ?? 0,
      totalRedCards: json['cards']?['red'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'league': {'id': leagueId, 'name': leagueName},
    'matches': gamesOfficiated,
    'cards': {'yellow': totalYellowCards, 'red': totalRedCards},
  };

  @override
  List<Object?> get props => [
    leagueId,
    leagueName,
    gamesOfficiated,
    totalYellowCards,
    totalRedCards,
  ];
}

class RefereeStatsModel extends Equatable {
  final int id;
  final String name;
  final String? nationality;
  final String? photoUrl;
  final List<RefereeSeasonGamesModel> seasonStats;

  const RefereeStatsModel({
    required this.id,
    required this.name,
    this.nationality,
    this.photoUrl,
    required this.seasonStats,
  });

  factory RefereeStatsModel.fromJson(Map<String, dynamic> json) {
    final refereeData = json['referee'] ?? json;
    // A lógica para preencher 'seasonStats' a partir da agregação de jogos
    // ocorre no DataSource, não diretamente aqui no fromJson do RefereeStatsModel base.
    // O DataSource construirá a lista de RefereeSeasonGamesModel e a passará.
    return RefereeStatsModel(
      id: refereeData['id'] as int? ?? 0,
      name: refereeData['name'] as String? ?? 'Árbitro Desconhecido',
      nationality: refereeData['nationality'] as String?,
      photoUrl: refereeData['photo'] as String?,
      seasonStats:
          (json['parsed_season_stats'] as List<dynamic>?) // Chave hipotética
              ?.map(
                (s) =>
                    RefereeSeasonGamesModel.fromJson(s as Map<String, dynamic>),
              )
              .toList() ??
          [], // Inicializa vazio, será preenchido pelo copyWithAggregatedStats
    );
  }

  RefereeStats toEntity(String currentSeasonOrContext) {
    double avgYellowCards = 0;
    double avgRedCards = 0;
    int totalGamesInCalc = 0;

    if (seasonStats.isNotEmpty) {
      final relevantAggregatedData = seasonStats.firstWhere(
        (s) => s.gamesOfficiated > 0, // Pega o primeiro agregado com jogos
        orElse:
            () => const RefereeSeasonGamesModel(
              gamesOfficiated: 0,
              totalYellowCards: 0,
              totalRedCards: 0,
            ), // Fallback
      );

      totalGamesInCalc = relevantAggregatedData.gamesOfficiated;
      if (totalGamesInCalc > 0) {
        avgYellowCards =
            relevantAggregatedData.totalYellowCards / totalGamesInCalc;
        avgRedCards = relevantAggregatedData.totalRedCards / totalGamesInCalc;
      }
    }

    return RefereeStats(
      refereeId: id,
      refereeName: name,
      nationality: nationality,
      photoUrl: photoUrl,
      averageYellowCardsPerGame: avgYellowCards,
      averageRedCardsPerGame: avgRedCards,
      gamesOfficiatedInCalculation: totalGamesInCalc,
    );
  }

  RefereeStatsModel copyWithAggregatedStats(
    List<RefereeSeasonGamesModel> aggregated,
  ) {
    return RefereeStatsModel(
      id: id,
      name: name,
      nationality: nationality,
      photoUrl: photoUrl,
      seasonStats: aggregated,
    );
  }

  @override
  List<Object?> get props => [id, name, nationality, photoUrl, seasonStats];
}
