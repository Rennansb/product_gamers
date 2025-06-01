// lib/data/models/fixture_model.dart
import 'package:equatable/equatable.dart';
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
  factory VenueModel.fromJson(Map<String, dynamic> json) => VenueModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      city: json['city'] as String?);
  @override
  List<Object?> get props => [id, name, city];
}

class StatusModel extends Equatable {
  final String? longName;
  final String? shortName;
  final int? elapsedMinutes;
  const StatusModel({this.longName, this.shortName, this.elapsedMinutes});
  factory StatusModel.fromJson(Map<String, dynamic> json) => StatusModel(
      longName: json['long'] as String?,
      shortName: json['short'] as String?,
      elapsedMinutes: json['elapsed'] as int?);
  @override
  List<Object?> get props => [longName, shortName, elapsedMinutes];
}

class FixtureLeagueInfoModel extends Equatable {
  // Este é o MODELO para dados da liga DENTRO do fixture
  final int id;
  final String name;
  final String? country;
  final String? logoUrl;
  final String? flagUrl;
  final int? season;
  final String? round;
  const FixtureLeagueInfoModel(
      {required this.id,
      required this.name,
      this.country,
      this.logoUrl,
      this.flagUrl,
      this.season,
      this.round});
  factory FixtureLeagueInfoModel.fromJson(Map<String, dynamic> json) =>
      FixtureLeagueInfoModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? 'Liga Desconhecida',
        country: json['country'] as String?,
        logoUrl: json['logo'] as String?,
        flagUrl: json['flag'] as String?,
        season: json['season'] as int?,
        round: json['round'] as String?,
      );
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

  @override
  List<Object?> get props =>
      [id, name, country, logoUrl, flagUrl, season, round];
}

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
  factory ScoreInfoModel.fromJson(Map<String, dynamic> json) => ScoreInfoModel(
        halftimeHome: json['halftime']?['home'] as int?,
        halftimeAway: json['halftime']?['away'] as int?,
        fulltimeHome: json['fulltime']?['home'] as int?,
        fulltimeAway: json['fulltime']?['away'] as int?,
        extratimeHome: json['extratime']?['home'] as int?,
        extratimeAway: json['extratime']?['away'] as int?,
        penaltyHome: json['penalty']?['home'] as int?,
        penaltyAway: json['penalty']?['away'] as int?,
      );
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
  final String? refereeNameFromFixture;
  final String timezone;
  final DateTime date;
  final int? timestamp;
  final VenueModel venue;
  final StatusModel status;
  final FixtureLeagueInfoModel league; // Este é o MODELO FixtureLeagueInfoModel
  final TeamModel homeTeam;
  final TeamModel awayTeam;
  final int? homeGoals;
  final int? awayGoals;
  final ScoreInfoModel score;

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
  });

  factory FixtureModel.fromJson(Map<String, dynamic> json) {
    final fixtureData = json['fixture'] ?? {};
    final leagueData = json['league'] ?? {};
    final teamsData = json['teams'] ?? {};
    final goalsData = json['goals'] ?? {};
    final scoreData = json['score'] ?? {};

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
          leagueData as Map<String, dynamic>? ??
              {}), // Cria FixtureLeagueInfoModel
      homeTeam:
          TeamModel.fromJson(teamsData['home'] as Map<String, dynamic>? ?? {}),
      awayTeam:
          TeamModel.fromJson(teamsData['away'] as Map<String, dynamic>? ?? {}),
      homeGoals: goalsData['home'] as int?,
      awayGoals: goalsData['away'] as int?,
      score: ScoreInfoModel.fromJson(scoreData as Map<String, dynamic>? ?? {}),
    );
  }

  // MÉTODO toEntity CORRIGIDO
  Fixture toEntity() {
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
      homeGoals: homeGoals,
      awayGoals: awayGoals,
      league: league
          .toEntity(), // <--- AQUI: this.league (FixtureLeagueInfoModel) chama seu próprio toEntity()
      // que retorna FixtureLeagueInfoEntity.
      refereeName: refereeNameFromFixture,
      venueName: venue.name,
      elapsedMinutes: status.elapsedMinutes,
      halftimeHomeScore: score.halftimeHome,
      halftimeAwayScore: score.halftimeAway,
      fulltimeHomeScore: score.fulltimeHome,
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
      ];
}
