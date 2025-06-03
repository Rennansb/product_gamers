// lib/data/models/fixture_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/data/models/live_game_event_model.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_league_info_entity.dart';
import 'team_model.dart';
// Import da entidade Fixture e da nova FixtureLeagueInfoEntity
// Garanta este import

// --- SUB-MODELOS (VenueModel, StatusModel, FixtureLeagueInfoModel, ScoreInfoModel) ---
// Cole aqui as definições de VenueModel, StatusModel, FixtureLeagueInfoModel, ScoreInfoModel
// como fornecidas na resposta "Ok, vamos para o FixtureModel. Este modelo é central..."
// Eles não devem ter mudado. Vou colocar apenas a estrutura deles para referência:

class VenueModel extends Equatable {
  final int? id;
  final String? name;
  final String? city;

  const VenueModel({this.id, this.name, this.city});

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      city: json['city'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'city': city};
  @override
  List<Object?> get props => [id, name, city];
}

// Sub-modelo para o status da partida
class StatusModel extends Equatable {
  final String? longName; // Ex: "Match Finished", "Not Started", "Halftime"
  final String? shortName; // Ex: "FT", "NS", "HT", "LIVE"
  final int? elapsedMinutes; // Minutos decorridos (para jogos ao vivo)

  const StatusModel({this.longName, this.shortName, this.elapsedMinutes});

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      longName: json['long'] as String?,
      shortName: json['short'] as String?,
      elapsedMinutes: json['elapsed'] as int?,
    );
  }
  Map<String, dynamic> toJson() =>
      {'long': longName, 'short': shortName, 'elapsed': elapsedMinutes};
  @override
  List<Object?> get props => [longName, shortName, elapsedMinutes];
}

// Sub-modelo para informações da liga DENTRO do fixture (MODELO DE DADOS)
class FixtureLeagueInfoModel extends Equatable {
  final int id;
  final String name;
  final String? country;
  final String? logoUrl;
  final String? flagUrl;
  final int? season; // Ano da temporada
  final String? round;

  const FixtureLeagueInfoModel({
    required this.id,
    required this.name,
    this.country,
    this.logoUrl,
    this.flagUrl,
    this.season,
    this.round,
  });

  factory FixtureLeagueInfoModel.fromJson(Map<String, dynamic> json) {
    return FixtureLeagueInfoModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Liga Desconhecida',
      country: json['country'] as String?,
      logoUrl: json['logo'] as String?,
      flagUrl: json['flag'] as String?,
      season: json['season'] as int?,
      round: json['round'] as String?,
    );
  }

  // Método para converter este MODELO para a ENTIDADE FixtureLeagueInfoEntity
  FixtureLeagueInfoEntity toEntity() {
    return FixtureLeagueInfoEntity(
        id: id,
        name: name,
        country: country,
        logoUrl: logoUrl,
        flagUrl: flagUrl,
        season: season,
        round: round);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'logo': logoUrl,
        'flag': flagUrl,
        'season': season,
        'round': round
      };
  @override
  List<Object?> get props =>
      [id, name, country, logoUrl, flagUrl, season, round];
}

// Sub-modelo para placares
class ScoreInfoModel extends Equatable {
  final int? halftimeHome;
  final int? halftimeAway;
  final int? fulltimeHome;
  final int? fulltimeAway;
  final int? extratimeHome;
  final int? extratimeAway;
  final int? penaltyHome;
  final int? penaltyAway;

  const ScoreInfoModel(
      {this.halftimeHome,
      this.halftimeAway,
      this.fulltimeHome,
      this.fulltimeAway,
      this.extratimeHome,
      this.extratimeAway,
      this.penaltyHome,
      this.penaltyAway});

  factory ScoreInfoModel.fromJson(Map<String, dynamic> json) {
    return ScoreInfoModel(
      halftimeHome: json['halftime']?['home'] as int?,
      halftimeAway: json['halftime']?['away'] as int?,
      fulltimeHome: json['fulltime']?['home'] as int?,
      fulltimeAway: json['fulltime']?['away'] as int?,
      extratimeHome: json['extratime']?['home'] as int?,
      extratimeAway: json['extratime']?['away'] as int?,
      penaltyHome: json['penalty']?['home'] as int?,
      penaltyAway: json['penalty']?['away'] as int?,
    );
  }
  Map<String, dynamic> toJson() => {/* ... se necessário ... */};
  @override
  List<Object?> get props => [
        halftimeHome,
        halftimeAway,
        fulltimeHome,
        fulltimeAway,
        extratimeHome,
        extratimeAway,
        penaltyHome,
        penaltyAway
      ];
}
// --- FIM DOS SUB-MODELOS ---

// Modelo Principal da Partida
class FixtureModel extends Equatable {
  final int id;
  final String?
      refereeNameFromFixture; // Nome do árbitro como string da API (json['fixture']['referee'])
  final String timezone;
  final DateTime date;
  final int? timestamp; // Unix timestamp
  final VenueModel venue;
  final StatusModel status;
  final FixtureLeagueInfoModel league; // Este é o MODELO FixtureLeagueInfoModel
  final TeamModel homeTeam;
  final TeamModel awayTeam;
  final int? homeGoals; // Gols atuais/finais do placar principal
  final int? awayGoals; // Gols atuais/finais do placar principal
  final ScoreInfoModel
      score; // Placar detalhado (intervalo, tempo normal, etc.)
  final List<LiveGameEventModel>
      events; // Eventos do jogo (para cartões, gols, etc.)

  // Estes campos são para armazenar os totais calculados a partir dos 'events'
  // Eles não vêm diretamente da API no nó principal do fixture para jogos futuros.
  final int? totalYellowCardsInFixture;
  final int? totalRedCardsInFixture;

  const FixtureModel({
    required this.id,
    this.refereeNameFromFixture,
    required this.timezone,
    required this.date,
    this.timestamp,
    required this.venue,
    required this.status,
    required this.league, // Recebe FixtureLeagueInfoModel
    required this.homeTeam,
    required this.awayTeam,
    this.homeGoals,
    this.awayGoals,
    required this.score,
    required this.events,
    this.totalYellowCardsInFixture, // Calculado a partir de events
    this.totalRedCardsInFixture, // Calculado a partir de events
  });

  factory FixtureModel.fromJson(Map<String, dynamic> json) {
    final fixtureData = json['fixture'] ?? {};
    final leagueData = json['league'] ?? {};
    final teamsData = json['teams'] ?? {};
    final goalsData = json['goals'] ?? {}; // Gols atuais (home/away)
    final scoreData = json['score'] ?? {}; // Placar (halftime, fulltime, etc.)
    final eventsData = json['events'] as List<dynamic>? ?? [];

    List<LiveGameEventModel> parsedEvents = eventsData
        .map((e) => LiveGameEventModel.fromJson(e as Map<String, dynamic>))
        .toList();

    int yellowCount = 0;
    int redCount = 0;
    for (var event in parsedEvents) {
      if (event.type.toLowerCase() == "card") {
        if (event.detail.toLowerCase() == "yellow card") yellowCount++;
        if (event.detail.toLowerCase() == "red card") redCount++;
      }
    }

    return FixtureModel(
      id: fixtureData['id'] as int? ?? 0,
      refereeNameFromFixture: fixtureData['referee'] as String?,
      timezone: fixtureData['timezone'] as String? ?? 'UTC',
      date: DateTime.tryParse(fixtureData['date'] as String? ?? '') ??
          DateTime.now(),
      timestamp: fixtureData['timestamp'] as int?,
      venue: VenueModel.fromJson(
          fixtureData['venue'] as Map<String, dynamic>? ?? {}),
      status: StatusModel.fromJson(
          fixtureData['status'] as Map<String, dynamic>? ?? {}),
      league: FixtureLeagueInfoModel.fromJson(
          leagueData as Map<String, dynamic>? ?? {}),
      homeTeam:
          TeamModel.fromJson(teamsData['home'] as Map<String, dynamic>? ?? {}),
      awayTeam:
          TeamModel.fromJson(teamsData['away'] as Map<String, dynamic>? ?? {}),
      homeGoals: goalsData['home'] as int?,
      awayGoals: goalsData['away'] as int?,
      score: ScoreInfoModel.fromJson(scoreData as Map<String, dynamic>? ?? {}),
      events: parsedEvents,
      totalYellowCardsInFixture: yellowCount > 0 ? yellowCount : null,
      totalRedCardsInFixture: redCount > 0 ? redCount : null,
    );
  }

  // ===== MÉTODO toEntity() CORRIGIDO =====
  Fixture toEntity() {
    // O campo 'this.league' é do tipo FixtureLeagueInfoModel.
    // Chamamos o método 'toEntity()' DELE para obter um FixtureLeagueInfoEntity.
    final FixtureLeagueInfoEntity leagueEntity = this.league.toEntity();

    return Fixture(
      // Chamando o construtor da ENTIDADE Fixture
      id: id,
      date: date,
      statusShort: status.shortName ?? 'N/A',
      statusLong: status.longName ?? 'Status Desconhecido',
      homeTeam:
          homeTeam.toEntity(), // TeamModel.toEntity() retorna TeamInFixture
      awayTeam:
          awayTeam.toEntity(), // TeamModel.toEntity() retorna TeamInFixture
      homeGoals:
          homeGoals, // Gols principais (podem ser os atuais se ao vivo, ou finais)
      awayGoals: awayGoals,
      league:
          leagueEntity, // Passa o objeto FixtureLeagueInfoEntity para a entidade Fixture
      refereeName: refereeNameFromFixture,
      venueName: venue.name,
      elapsedMinutes: status.elapsedMinutes,
      halftimeHomeScore: score.halftimeHome,
      halftimeAwayScore: score.halftimeAway,
      fulltimeHomeScore: score.fulltimeHome, // Placar do tempo normal
      fulltimeAwayScore: score.fulltimeAway,
      // A entidade Fixture não armazena a lista de eventos ou os cartões totais do jogo diretamente,
      // mas o FixtureModel os tem se forem necessários para outras lógicas (como agregação de árbitro).
    );
  }
  // =====================================

  @override
  List<Object?> get props => [
        id,
        refereeNameFromFixture,
        timezone,
        date,
        timestamp,
        venue,
        status,
        league,
        homeTeam,
        awayTeam,
        homeGoals,
        awayGoals,
        score,
        events,
        totalYellowCardsInFixture,
        totalRedCardsInFixture,
      ];
}
