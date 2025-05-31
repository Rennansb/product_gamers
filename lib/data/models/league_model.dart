// lib/data/models/league_model.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/entities/league.dart';

// Importa a entidade de domínio League

// Sub-modelo para informações de temporada dentro da liga
class LeagueSeasonModel extends Equatable {
  final int year;
  final String
      startDate; // Nome do campo corrigido de 'start' para 'startDate' para clareza
  final String
      endDate; // Nome do campo corrigido de 'end' para 'endDate' para clareza
  final bool current;

  const LeagueSeasonModel({
    required this.year,
    required this.startDate, // Usando nome claro
    required this.endDate, // Usando nome claro
    required this.current,
  });

  factory LeagueSeasonModel.fromJson(Map<String, dynamic> json) {
    return LeagueSeasonModel(
      year: json['year'] as int? ?? 0,
      startDate: json['start'] as String? ?? '', // Mapeia do JSON 'start'
      endDate: json['end'] as String? ?? '', // Mapeia do JSON 'end'
      current: json['current'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        // Para consistência se for usado
        'year': year,
        'start': startDate,
        'end': endDate,
        'current': current,
      };

  @override
  List<Object?> get props => [year, startDate, endDate, current];
}

// Modelo Principal da Liga/Competição
class LeagueModel extends Equatable {
  final int id;
  final String name;
  final String? type; // Ex: "League", "Cup"
  final String? logoUrl;

  // Informações do país associado à liga
  final String? countryName;
  final String? countryCode; // Ex: "GB", "BR" (pode ser nulo)
  final String? countryFlagUrl;

  final List<LeagueSeasonModel>
      seasons; // Lista de temporadas disponíveis para esta liga

  // Campo auxiliar para nome amigável (não vem da API, preenchido pelo nosso app)
  final String? friendlyName; // Pode ser nulo inicialmente, preenchido depois

  const LeagueModel({
    required this.id,
    required this.name,
    this.type,
    this.logoUrl,
    this.countryName,
    this.countryCode,
    this.countryFlagUrl,
    required this.seasons,
    this.friendlyName,
  });

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    // O endpoint /leagues da API-Football retorna um objeto principal 'league',
    // um objeto 'country', e uma lista 'seasons'.
    final leagueData = json['league'] ?? json;
    final countryData = json['country'] ?? {};
    final seasonsListJson = json['seasons'] as List<dynamic>? ?? [];

    final List<LeagueSeasonModel> parsedSeasons = seasonsListJson
        .map((sJson) =>
            LeagueSeasonModel.fromJson(sJson as Map<String, dynamic>))
        .toList();

    return LeagueModel(
      id: leagueData['id'] as int? ?? 0,
      name: leagueData['name'] as String? ?? 'Liga Desconhecida',
      type: leagueData['type'] as String?,
      logoUrl: leagueData['logo'] as String?,
      countryName: countryData['name'] as String?,
      countryCode: countryData['code'] as String?, // Pode ser nulo
      countryFlagUrl: countryData['flag'] as String?, // Pode ser nulo
      seasons: parsedSeasons,
      // friendlyName não vem da API, será preenchido externamente se necessário
    );
  }

  Map<String, dynamic> toJson() => {
        'league': {
          'id': id,
          'name': name,
          'type': type,
          'logo': logoUrl,
        },
        'country': {
          'name': countryName,
          'code': countryCode,
          'flag': countryFlagUrl,
        },
        'seasons': seasons.map((s) => s.toJson()).toList(),
        // friendlyName não é parte do JSON da API
      };

  // Converte para a entidade de domínio League
// Em lib/data/models/league_model.dart
// Dentro da classe LeagueModel

  // Dentro de lib/data/models/league_model.dart (método toEntity da classe LeagueModel)
  League toEntity() {
    LeagueSeasonModel? targetSeason;
    if (seasons.isNotEmpty) {
      targetSeason = seasons.firstWhere((s) => s.current, orElse: () {
        List<LeagueSeasonModel> sortedSeasons = List.from(seasons);
        sortedSeasons.sort((a, b) => b.year.compareTo(a.year));
        return sortedSeasons.first;
      });
    }

    // Esta chamada deve corresponder ao construtor da entidade League
    return League(
      id: id, // passando o valor de 'id' do LeagueModel para o parâmetro nomeado 'id' da entidade League
      name: name,
      type: type,
      logoUrl: logoUrl,
      countryName: countryName,
      countryFlagUrl: countryFlagUrl,
      currentSeasonYear: targetSeason?.year,
      friendlyName: friendlyName ?? name,
    );
  }

  // Método para auxiliar na atualização do friendlyName, já que ele não vem da API
  LeagueModel copyWith({
    String? friendlyName,
    // Você pode adicionar outros campos aqui se precisar copiar com mais modificações
  }) {
    return LeagueModel(
      id: id,
      name: name,
      type: type,
      logoUrl: logoUrl,
      countryName: countryName,
      countryCode: countryCode,
      countryFlagUrl: countryFlagUrl,
      seasons: seasons,
      friendlyName: friendlyName ?? this.friendlyName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        logoUrl,
        countryName,
        countryCode,
        countryFlagUrl,
        seasons,
        friendlyName
      ];
}
