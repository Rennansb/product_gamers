// lib/data/models/league_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';

// Sub-modelo para informações de temporada dentro da liga
class LeagueSeasonModel extends Equatable {
  final int year;
  final String start; // Data de início (ex: "2023-08-11")
  final String end; // Data de término (ex: "2024-05-19")
  final bool current; // Se é a temporada atual
  // A API-Football pode incluir 'coverage' aqui, detalhando o que é coberto (fixtures, odds, etc.)
  // final Map<String, bool>? coverage; // Ex: {"fixtures": {"events": true, ...}, "odds": true}

  const LeagueSeasonModel({
    required this.year,
    required this.start,
    required this.end,
    required this.current,
    // this.coverage
  });

  factory LeagueSeasonModel.fromJson(Map<String, dynamic> json) {
    return LeagueSeasonModel(
      year: json['year'] as int? ?? 0,
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      current: json['current'] as bool? ?? false,
      // coverage: json['coverage'] != null ? Map<String, bool>.from(json['coverage']) : null, // Exemplo se coverage for simples
    );
  }

  Map<String, dynamic> toJson() => {
    'year': year,
    'start': start,
    'end': end,
    'current': current,
    // 'coverage': coverage,
  };

  @override
  List<Object?> get props => [year, start, end, current /*, coverage*/];
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
  final String? friendlyName;

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
    // A API-Football no endpoint /leagues retorna um objeto principal 'league'
    // e um objeto 'country', e uma lista 'seasons'.
    final leagueData =
        json['league'] ??
        json; // Se 'league' não existir, usa o json raiz (flexibilidade)
    final countryData = json['country'] ?? {};
    final seasonsList =
        (json['seasons'] as List<dynamic>?)
            ?.map((s) => LeagueSeasonModel.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return LeagueModel(
      id: leagueData['id'] as int? ?? 0,
      name: leagueData['name'] as String? ?? 'Liga Desconhecida',
      type: leagueData['type'] as String?,
      logoUrl: leagueData['logo'] as String?,
      countryName: countryData['name'] as String?,
      countryCode: countryData['code'] as String?,
      countryFlagUrl: countryData['flag'] as String?,
      seasons: seasonsList,
      // friendlyName não vem da API, será preenchido externamente se necessário
    );
  }

  Map<String, dynamic> toJson() => {
    'league': {'id': id, 'name': name, 'type': type, 'logo': logoUrl},
    'country': {
      'name': countryName,
      'code': countryCode,
      'flag': countryFlagUrl,
    },
    'seasons': seasons.map((s) => s.toJson()).toList(),
    // friendlyName não é parte do JSON da API
  };

  // Converte para a entidade de domínio League
  League toEntity() {
    // Para a entidade, podemos querer a temporada atual ou a mais recente
    LeagueSeasonModel? currentOrLatestSeason;
    if (seasons.isNotEmpty) {
      currentOrLatestSeason = seasons.firstWhere(
        (s) => s.current,
        orElse: () => seasons.last,
      );
    }

    return League(
      id: id,
      name: name, // Usaremos o friendlyName na UI se disponível
      type: type,
      logoUrl: logoUrl,
      countryName: countryName,
      countryFlagUrl: countryFlagUrl,
      currentSeasonYear:
          currentOrLatestSeason?.year, // Entidade pode querer só o ano
      friendlyName: friendlyName ?? name, // Usa o nome da API como fallback
    );
  }

  // Método para auxiliar na atualização do friendlyName, já que ele não vem da API
  LeagueModel copyWith({
    int? id,
    String? name,
    String? type,
    String? logoUrl,
    String? countryName,
    String? countryCode,
    String? countryFlagUrl,
    List<LeagueSeasonModel>? seasons,
    String? friendlyName, // Permite definir/atualizar o friendlyName
  }) {
    return LeagueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      logoUrl: logoUrl ?? this.logoUrl,
      countryName: countryName ?? this.countryName,
      countryCode: countryCode ?? this.countryCode,
      countryFlagUrl: countryFlagUrl ?? this.countryFlagUrl,
      seasons: seasons ?? this.seasons,
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
    friendlyName,
  ];
}
