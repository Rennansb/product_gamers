// lib/domain/entities/data_for_prediction.dart
import 'package:equatable/equatable.dart';
import 'fixture.dart';
import 'fixture_stats.dart';
import 'prognostic_market.dart';
import 'standing_info.dart';
import 'lineup.dart';
import 'player_stats.dart';
import 'referee_stats.dart';
import 'team_aggregated_stats.dart';

class DataForPrediction extends Equatable {
  final Fixture fixture;
  final FixtureStatsEntity? fixtureStats;
  final List<PrognosticMarket> odds;
  final List<Fixture>? h2hFixtures;
  final List<StandingInfo>? leagueStandings;
  final List<Fixture>? homeTeamRecentFixtures; // Para forma
  final List<Fixture>? awayTeamRecentFixtures; // Para forma
  final RefereeStats? refereeStats;
  final TeamAggregatedStats? homeTeamAggregatedStats;
  final TeamAggregatedStats? awayTeamAggregatedStats;
  final LineupsForFixture? lineups;
  final Map<int, PlayerSeasonStats>? playerSeasonStats; // Map<playerId, Stats>

  const DataForPrediction({
    required this.fixture,
    required this.odds, // Odds são cruciais
    this.fixtureStats,
    this.h2hFixtures,
    this.leagueStandings,
    this.homeTeamRecentFixtures,
    this.awayTeamRecentFixtures,
    this.refereeStats,
    this.homeTeamAggregatedStats,
    this.awayTeamAggregatedStats,
    this.lineups,
    this.playerSeasonStats,
  });

  // Adicionar um copyWith completo aqui se precisar modificar instâncias
  DataForPrediction copyWith({
    Fixture? fixture,
    FixtureStatsEntity? fixtureStats,
    List<PrognosticMarket>? odds,
    List<Fixture>? h2hFixtures,
    List<StandingInfo>? leagueStandings,
    List<Fixture>? homeTeamRecentFixtures,
    List<Fixture>? awayTeamRecentFixtures,
    RefereeStats? refereeStats,
    TeamAggregatedStats? homeTeamAggregatedStats,
    TeamAggregatedStats? awayTeamAggregatedStats,
    LineupsForFixture? lineups,
    Map<int, PlayerSeasonStats>? playerSeasonStats,
  }) {
    return DataForPrediction(
      fixture: fixture ?? this.fixture,
      odds: odds ?? this.odds,
      fixtureStats: fixtureStats ?? this.fixtureStats,
      h2hFixtures: h2hFixtures ?? this.h2hFixtures,
      leagueStandings: leagueStandings ?? this.leagueStandings,
      homeTeamRecentFixtures:
          homeTeamRecentFixtures ?? this.homeTeamRecentFixtures,
      awayTeamRecentFixtures:
          awayTeamRecentFixtures ?? this.awayTeamRecentFixtures,
      refereeStats: refereeStats ?? this.refereeStats,
      homeTeamAggregatedStats:
          homeTeamAggregatedStats ?? this.homeTeamAggregatedStats,
      awayTeamAggregatedStats:
          awayTeamAggregatedStats ?? this.awayTeamAggregatedStats,
      lineups: lineups ?? this.lineups,
      playerSeasonStats: playerSeasonStats ?? this.playerSeasonStats,
    );
  }

  @override
  List<Object?> get props => [
        fixture,
        fixtureStats,
        odds,
        h2hFixtures,
        leagueStandings,
        homeTeamRecentFixtures,
        awayTeamRecentFixtures,
        refereeStats,
        homeTeamAggregatedStats,
        awayTeamAggregatedStats,
        lineups,
        playerSeasonStats
      ];
}
