// lib/domain/entities/data_for_prediction.dart
// ... (imports existentes)
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
import 'package:product_gamers/domain/entities/entities/standing_info.dart';

class DataForPrediction extends Equatable {
  final Fixture fixture;
  final FixtureStatsEntity? fixtureStats;
  final List<PrognosticMarket> odds;
  final List<Fixture>? h2hFixtures;
  final List<StandingInfo>? leagueStandings; // NOVO CAMPO
  // final List<PlayerSeasonStats>? probableStartersPlayerStats; // Se for usar para análise
  // final RefereeStats? refereeStats; // Se for usar para análise

  const DataForPrediction({
    required this.fixture,
    this.fixtureStats,
    required this.odds,
    this.h2hFixtures,
    this.leagueStandings, // NOVO
    // this.probableStartersPlayerStats,
    // this.refereeStats,
  });

  // Adicionar leagueStandings ao copyWith e props
  DataForPrediction copyWith({
    Fixture? fixture,
    FixtureStatsEntity? fixtureStats,
    List<PrognosticMarket>? odds,
    List<Fixture>? h2hFixtures,
    List<StandingInfo>? leagueStandings,
  }) {
    return DataForPrediction(
      fixture: fixture ?? this.fixture,
      fixtureStats: fixtureStats ?? this.fixtureStats,
      odds: odds ?? this.odds,
      h2hFixtures: h2hFixtures ?? this.h2hFixtures,
      leagueStandings: leagueStandings ?? this.leagueStandings,
    );
  }

  @override
  List<Object?> get props => [
    fixture,
    fixtureStats,
    odds,
    h2hFixtures,
    leagueStandings,
  ];
}
