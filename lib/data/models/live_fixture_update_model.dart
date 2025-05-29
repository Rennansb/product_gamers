// lib/data/models/live_fixture_update_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/live_fixture_update.dart';
import 'live_game_event_model.dart'; // Certifique-se que este arquivo existe e está correto
import 'team_model.dart'; // Certifique-se que este arquivo existe e está correto
import 'team_live_stats_data_model.dart'; // Certifique-se que este arquivo existe e está correto
// Certifique-se que esta entidade existe e está correta

class LiveFixtureUpdateModel extends Equatable {
  final int fixtureId;
  final DateTime date;
  final String? referee;
  final String? timezone;
  final String? venueName;
  final String? venueCity;

  final String? statusLong;
  final String? statusShort;
  final int? elapsedMinutes;

  final int? leagueId;
  final String? leagueName;
  final String? leagueCountry;
  final String? leagueLogoUrl;
  final String? leagueFlagUrl;
  final String? seasonYear;

  final TeamModel homeTeam;
  final TeamModel awayTeam;

  final int? homeScore;
  final int? awayScore;
  final int? halftimeHomeScore;
  final int? halftimeAwayScore;
  final int? fulltimeHomeScore;
  final int? fulltimeAwayScore;
  final int? extratimeHomeScore;
  final int? extratimeAwayScore;
  final int? penaltyHomeScore;
  final int? penaltyAwayScore;

  final List<LiveGameEventModel> events;
  final List<Map<String, dynamic>>? lineupsRaw;

  final TeamLiveStatsDataModel? homeTeamLiveStats;
  final TeamLiveStatsDataModel? awayTeamLiveStats;

  const LiveFixtureUpdateModel({
    required this.fixtureId,
    required this.date,
    this.referee,
    this.timezone,
    this.venueName,
    this.venueCity,
    this.statusLong,
    this.statusShort,
    this.elapsedMinutes,
    this.leagueId,
    this.leagueName,
    this.leagueCountry,
    this.leagueLogoUrl,
    this.leagueFlagUrl,
    this.seasonYear,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.halftimeHomeScore,
    this.halftimeAwayScore,
    this.fulltimeHomeScore,
    this.fulltimeAwayScore,
    this.extratimeHomeScore,
    this.extratimeAwayScore,
    this.penaltyHomeScore,
    this.penaltyAwayScore,
    required this.events,
    this.lineupsRaw,
    this.homeTeamLiveStats,
    this.awayTeamLiveStats,
  });

  factory LiveFixtureUpdateModel.fromJson(Map<String, dynamic> json) {
    final fixtureData = json['fixture'] as Map<String, dynamic>? ?? {};
    final leagueData = json['league'] as Map<String, dynamic>? ?? {};
    final teamsData = json['teams'] as Map<String, dynamic>? ?? {};
    final goalsData = json['goals'] as Map<String, dynamic>? ?? {};
    final scoreData = json['score'] as Map<String, dynamic>? ?? {};
    final eventsData = json['events'] as List<dynamic>? ?? [];
    final lineupsData = json['lineups'] as List<dynamic>?;

    // Parsear os times primeiro, pois precisaremos dos IDs deles para as estatísticas
    final TeamModel parsedHomeTeam = TeamModel.fromJson(
      teamsData['home'] as Map<String, dynamic>? ?? {},
    );
    final TeamModel parsedAwayTeam = TeamModel.fromJson(
      teamsData['away'] as Map<String, dynamic>? ?? {},
    );

    TeamLiveStatsDataModel? parsedHomeLiveStats;
    TeamLiveStatsDataModel? parsedAwayLiveStats;
    final statsListFromApi = json['statistics'] as List<dynamic>?;

    if (statsListFromApi != null) {
      for (var teamStatsContainer in statsListFromApi) {
        if (teamStatsContainer is Map<String, dynamic>) {
          final teamInfoInStats =
              teamStatsContainer['team'] as Map<String, dynamic>?;
          final teamIdInStats = teamInfoInStats?['id'] as int?;
          final individualTeamStatsList =
              teamStatsContainer['statistics'] as List<dynamic>?;

          if (teamIdInStats != null && individualTeamStatsList != null) {
            if (teamIdInStats == parsedHomeTeam.id) {
              parsedHomeLiveStats = TeamLiveStatsDataModel.fromJson(
                individualTeamStatsList,
              );
            } else if (teamIdInStats == parsedAwayTeam.id) {
              parsedAwayLiveStats = TeamLiveStatsDataModel.fromJson(
                individualTeamStatsList,
              );
            }
          }
        }
      }
    }

    return LiveFixtureUpdateModel(
      fixtureId: fixtureData['id'] as int? ?? 0,
      date:
          DateTime.tryParse(fixtureData['date'] as String? ?? '') ??
          DateTime.now(),
      referee: fixtureData['referee'] as String?,
      timezone: fixtureData['timezone'] as String?,
      venueName: fixtureData['venue']?['name'] as String?,
      venueCity: fixtureData['venue']?['city'] as String?,
      statusLong: fixtureData['status']?['long'] as String?,
      statusShort: fixtureData['status']?['short'] as String?,
      elapsedMinutes: fixtureData['status']?['elapsed'] as int?,
      leagueId: leagueData['id'] as int?,
      leagueName: leagueData['name'] as String?,
      leagueCountry: leagueData['country'] as String?,
      leagueLogoUrl: leagueData['logo'] as String?,
      leagueFlagUrl: leagueData['flag'] as String?,
      seasonYear: leagueData['season']?.toString(),
      homeTeam: parsedHomeTeam,
      awayTeam: parsedAwayTeam,
      homeScore: goalsData['home'] as int?,
      awayScore: goalsData['away'] as int?,
      halftimeHomeScore: scoreData['halftime']?['home'] as int?,
      halftimeAwayScore: scoreData['halftime']?['away'] as int?,
      fulltimeHomeScore: scoreData['fulltime']?['home'] as int?,
      fulltimeAwayScore: scoreData['fulltime']?['away'] as int?,
      extratimeHomeScore: scoreData['extratime']?['home'] as int?,
      extratimeAwayScore: scoreData['extratime']?['away'] as int?,
      penaltyHomeScore: scoreData['penalty']?['home'] as int?,
      penaltyAwayScore: scoreData['penalty']?['away'] as int?,
      events:
          eventsData
              .map(
                (e) => LiveGameEventModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      lineupsRaw: lineupsData?.map((l) => l as Map<String, dynamic>).toList(),
      homeTeamLiveStats: parsedHomeLiveStats,
      awayTeamLiveStats: parsedAwayLiveStats,
    );
  }

  LiveFixtureUpdate toEntity() {
    List<LiveGameEvent> enrichedEvents =
        events.map((eventModel) {
          final baseEventEntity =
              eventModel.toEntity(); // Cria a entidade base do evento
          String? resolvedTeamName = baseEventEntity.teamName;

          // Se o evento não tem nome de time mas tem ID, tenta resolver usando os nomes dos times principais
          if (resolvedTeamName == null && baseEventEntity.teamId != null) {
            if (baseEventEntity.teamId == homeTeam.id) {
              // homeTeam aqui é o TeamModel desta classe
              resolvedTeamName = homeTeam.name;
            } else if (baseEventEntity.teamId == awayTeam.id) {
              // awayTeam aqui é o TeamModel desta classe
              resolvedTeamName = awayTeam.name;
            }
          }
          // Usa o método copyWith da entidade LiveGameEvent (que deve existir)
          return baseEventEntity.copyWith(teamName: resolvedTeamName);
        }).toList();

    return LiveFixtureUpdate(
      fixtureId: fixtureId,
      date: date,
      referee: referee,
      statusLong: statusLong,
      statusShort: statusShort,
      elapsedMinutes: elapsedMinutes,
      leagueName: leagueName,
      homeTeam: homeTeam.toEntity(), // Converte TeamModel para TeamInFixture
      awayTeam: awayTeam.toEntity(), // Converte TeamModel para TeamInFixture
      homeScore: homeScore,
      awayScore: awayScore,
      events: enrichedEvents,
      homeTeamLiveStats:
          homeTeamLiveStats
              ?.toEntity(), // Converte TeamLiveStatsDataModel para TeamLiveStats
      awayTeamLiveStats:
          awayTeamLiveStats
              ?.toEntity(), // Converte TeamLiveStatsDataModel para TeamLiveStats
    );
  }

  @override
  List<Object?> get props => [
    fixtureId, date, referee, timezone, venueName, venueCity,
    statusLong, statusShort, elapsedMinutes,
    leagueId,
    leagueName,
    leagueCountry,
    leagueLogoUrl,
    leagueFlagUrl,
    seasonYear,
    homeTeam, awayTeam, // TeamModel objects
    homeScore, awayScore, halftimeHomeScore, halftimeAwayScore,
    fulltimeHomeScore,
    fulltimeAwayScore,
    extratimeHomeScore,
    extratimeAwayScore,
    penaltyHomeScore, penaltyAwayScore,
    events, lineupsRaw,
    homeTeamLiveStats, awayTeamLiveStats,
  ];
}
