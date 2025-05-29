// lib/data/models/league_standings_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/standing_info.dart';
import 'standing_item_model.dart'; // Importa StandingItemModel

class LeagueStandingsModel extends Equatable {
  // Informações da liga (pode ser um sub-objeto LeagueInfoModel se preferir)
  final int leagueId;
  final String leagueName;
  final String? leagueCountry;
  final String? leagueLogoUrl;
  final String? leagueFlagUrl;
  final int seasonYear;

  // A lista de classificações é uma LISTA DE LISTAS na API-Football.
  // A primeira lista representa "grupos" ou "fases", e a segunda lista contém os times dentro desse grupo.
  // Para ligas de pontos corridos, geralmente há apenas um grupo (a primeira lista tem 1 elemento).
  final List<List<StandingItemModel>> standings;

  const LeagueStandingsModel({
    required this.leagueId,
    required this.leagueName,
    this.leagueCountry,
    this.leagueLogoUrl,
    this.leagueFlagUrl,
    required this.seasonYear,
    required this.standings,
  });

  factory LeagueStandingsModel.fromJson(Map<String, dynamic> json) {
    // A API retorna um objeto 'league' no root e uma lista 'standings' (lista de listas).
    final leagueData = json['league'] as Map<String, dynamic>? ?? {};
    final standingsData = (json['standings'] as List<dynamic>?) ?? [];

    return LeagueStandingsModel(
      leagueId: leagueData['id'] as int? ?? 0,
      leagueName: leagueData['name'] as String? ?? 'Liga Desconhecida',
      leagueCountry: leagueData['country'] as String?,
      leagueLogoUrl: leagueData['logo'] as String?,
      leagueFlagUrl: leagueData['flag'] as String?,
      seasonYear: leagueData['season'] as int? ?? DateTime.now().year,

      // Mapeia a lista externa (grupos) e depois a lista interna (times)
      standings:
          standingsData.map((groupListJson) {
            return (groupListJson
                    as List<
                      dynamic
                    >) // Cada item da lista externa é uma lista interna
                .map(
                  (itemJson) => StandingItemModel.fromJson(
                    itemJson as Map<String, dynamic>,
                  ),
                )
                .toList();
          }).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'league': {
      'id': leagueId,
      'name': leagueName,
      'country': leagueCountry,
      'logo': leagueLogoUrl,
      'flag': leagueFlagUrl,
      'season': seasonYear,
    },
    'standings':
        standings.map((groupList) {
          return groupList.map((item) => item.toJson()).toList();
        }).toList(),
  };

  // Converte a lista de StandingItemModel (do primeiro grupo) para StandingInfo (entidades)
  List<StandingInfo> toEntityList() {
    if (standings.isNotEmpty && standings.first.isNotEmpty) {
      // Geralmente, para ligas de pontos corridos, o primeiro elemento da lista 'standings'
      // contém a lista completa dos times.
      return standings.first.map((itemModel) => itemModel.toEntity()).toList();
    }
    return []; // Retorna lista vazia se não houver dados de classificação
  }

  @override
  List<Object?> get props => [
    leagueId,
    leagueName,
    leagueCountry,
    leagueLogoUrl,
    leagueFlagUrl,
    seasonYear,
    standings,
  ];
}
