// lib/data/models/fixture_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'team_model.dart'; // Importa o TeamModel
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';

// Sub-modelo para o árbitro dentro do fixture (se a API fornecer)
class FixtureRefereeModel extends Equatable {
  final int? id;
  final String? name;
  final String? type; // Ex: "Main referee"
  final String? nationality;

  const FixtureRefereeModel({this.id, this.name, this.type, this.nationality});

  factory FixtureRefereeModel.fromJson(Map<String, dynamic> json) {
    return FixtureRefereeModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      nationality: json['nationality'] as String?,
    );
  }
  @override
  List<Object?> get props => [id, name, type, nationality];
}

// Sub-modelo para o local da partida
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
  @override
  List<Object?> get props => [id, name, city];
}

// Sub-modelo para o status da partida
class StatusModel extends Equatable {
  final String? longName; // Ex: "Match Finished", "Not Started", "Halftime"
  final String?
  shortName; // Ex: "FT", "NS", "HT", "LIVE" (API-Football usa '1H', 'HT', '2H', 'ET', 'P', 'FT', 'AET', 'PEN', 'BT', 'SUSP', 'INT', 'PST', 'CANC', 'ABD', 'AWD', 'WO', 'LIVE')
  final int? elapsedMinutes; // Minutos decorridos (para jogos ao vivo)

  const StatusModel({this.longName, this.shortName, this.elapsedMinutes});

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      longName: json['long'] as String?,
      shortName: json['short'] as String?,
      elapsedMinutes: json['elapsed'] as int?,
    );
  }
  @override
  List<Object?> get props => [longName, shortName, elapsedMinutes];
}

// Sub-modelo para informações da liga dentro do fixture
class FixtureLeagueInfoModel extends Equatable {
  final int id;
  final String name;
  final String? country;
  final String? logoUrl;
  final String? flagUrl;
  final int? season; // Ano da temporada
  final String? round; // Rodada

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
  @override
  List<Object?> get props => [
    id,
    name,
    country,
    logoUrl,
    flagUrl,
    season,
    round,
  ];
}

// Sub-modelo para placares
class ScoreInfoModel extends Equatable {
  final int? halftimeHome;
  final int? halftimeAway;
  final int? fulltimeHome;
  final int? fulltimeAway;
  final int? extratimeHome; // Gols na prorrogação
  final int? extratimeAway;
  final int? penaltyHome; // Gols nos pênaltis
  final int? penaltyAway;

  const ScoreInfoModel({
    this.halftimeHome,
    this.halftimeAway,
    this.fulltimeHome,
    this.fulltimeAway,
    this.extratimeHome,
    this.extratimeAway,
    this.penaltyHome,
    this.penaltyAway,
  });

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
  @override
  List<Object?> get props => [
    halftimeHome,
    halftimeAway,
    fulltimeHome,
    fulltimeAway,
    extratimeHome,
    extratimeAway,
    penaltyHome,
    penaltyAway,
  ];
}

// Modelo Principal da Partida
class FixtureModel extends Equatable {
  final int id;
  final FixtureRefereeModel?
  referee; // API-Football retorna nome do árbitro como string, não objeto detalhado aqui.
  // O nome do árbitro é `json['fixture']['referee']`
  final String? refereeNameFromFixture; // Para o nome do árbitro como string
  final String timezone;
  final DateTime date;
  final int? timestamp; // Unix timestamp
  final VenueModel venue;
  final StatusModel status;

  final FixtureLeagueInfoModel league;
  final TeamModel homeTeam;
  final TeamModel awayTeam;
  final int? homeGoals; // Gols atuais do time da casa
  final int? awayGoals; // Gols atuais do time visitante
  final ScoreInfoModel
  score; // Placar detalhado (intervalo, tempo normal, etc.)

  // Campos simulados para cartões totais que podem ser usados na agregação do árbitro.
  // Verifique se a API os fornece diretamente no objeto fixture.
  // Se não, eles seriam calculados a partir do endpoint /fixtures/statistics.
  final int? totalYellowCardsInFixture;
  final int? totalRedCardsInFixture;

  const FixtureModel({
    required this.id,
    this.referee,
    this.refereeNameFromFixture,
    required this.timezone,
    required this.date,
    this.timestamp,
    required this.venue,
    required this.status,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    this.homeGoals,
    this.awayGoals,
    required this.score,
    this.totalYellowCardsInFixture,
    this.totalRedCardsInFixture,
  });

  factory FixtureModel.fromJson(Map<String, dynamic> json) {
    final fixtureData = json['fixture'] ?? {};
    final leagueData = json['league'] ?? {};
    final teamsData = json['teams'] ?? {}; // Contém 'home' e 'away'
    final goalsData = json['goals'] ?? {}; // Contém gols atuais 'home' e 'away'
    final scoreData =
        json['score'] ?? {}; // Contém 'halftime', 'fulltime', etc.

    return FixtureModel(
      id: fixtureData['id'] as int? ?? 0,
      refereeNameFromFixture: fixtureData['referee'] as String?,
      // referee: fixtureData['referee'] != null ? FixtureRefereeModel.fromJson(fixtureData['referee']) : null, // Se fosse um objeto
      timezone: fixtureData['timezone'] as String? ?? 'UTC',
      date:
          DateTime.tryParse(fixtureData['date'] as String? ?? '') ??
          DateTime.now(),
      timestamp: fixtureData['timestamp'] as int?,
      venue: VenueModel.fromJson(
        fixtureData['venue'] as Map<String, dynamic>? ?? {},
      ),
      status: StatusModel.fromJson(
        fixtureData['status'] as Map<String, dynamic>? ?? {},
      ),
      league: FixtureLeagueInfoModel.fromJson(
        leagueData as Map<String, dynamic>? ?? {},
      ),
      homeTeam: TeamModel.fromJson(
        teamsData['home'] as Map<String, dynamic>? ?? {},
      ),
      awayTeam: TeamModel.fromJson(
        teamsData['away'] as Map<String, dynamic>? ?? {},
      ),
      homeGoals: goalsData['home'] as int?, // Gols atuais
      awayGoals: goalsData['away'] as int?, // Gols atuais
      score: ScoreInfoModel.fromJson(scoreData as Map<String, dynamic>? ?? {}),
      // Os campos de cartões totais não vêm diretamente aqui, seriam de /fixtures/statistics.
      // Deixaremos nulos por padrão.
    );
  }

  Fixture toEntity() {
    return Fixture(
      id: id,
      date: date,
      statusShort: status.shortName ?? 'N/A',
      statusLong: status.longName ?? 'Status Desconhecido',
      homeTeam: homeTeam.toEntity(), // Converte TeamModel para TeamInFixture
      awayTeam: awayTeam.toEntity(), // Converte TeamModel para TeamInFixture
      homeGoals: homeGoals, // Gols atuais
      awayGoals: awayGoals, // Gols atuais
      leagueId: league.id,
      leagueName: league.name,
      leagueLogoUrl: league.logoUrl,
      // Adicionar mais campos da entidade se necessário (ex: refereeName, venueName)
      refereeName: refereeNameFromFixture,
      venueName: venue.name,
      elapsedMinutes: status.elapsedMinutes,
      // Informações do placar (halftime, fulltime) podem ser adicionadas à entidade Fixture se necessário
      halftimeHomeScore: score.halftimeHome,
      halftimeAwayScore: score.halftimeAway,
      fulltimeHomeScore: score.fulltimeHome, // Se FT, este é o placar final
      fulltimeAwayScore: score.fulltimeAway,
    );
  }

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
    totalYellowCardsInFixture,
    totalRedCardsInFixture,
  ];
}
