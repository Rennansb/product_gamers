// lib/domain/entities/fixture_full_data.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'fixture.dart';

import 'prognostic_market.dart';

// Enum para controlar o status de carregamento de cada parte dos dados
enum SectionStatus { initial, loading, loaded, error, noData }

class FixtureFullData extends Equatable {
  final Fixture
  baseFixture; // Informações básicas do fixture passadas inicialmente

  // Seções de dados carregadas dinamicamente
  final FixtureStatsEntity? fixtureStats;
  final SectionStatus statsStatus;
  final String? statsErrorMessage;

  final List<PrognosticMarket> odds;
  final SectionStatus oddsStatus;
  final String? oddsErrorMessage;

  final List<Fixture>? h2hFixtures;
  final SectionStatus h2hStatus;
  final String? h2hErrorMessage;

  const FixtureFullData({
    required this.baseFixture,
    this.fixtureStats,
    this.statsStatus = SectionStatus.initial,
    this.statsErrorMessage,
    required this.odds,
    this.oddsStatus = SectionStatus.initial,
    this.oddsErrorMessage,
    this.h2hFixtures,
    this.h2hStatus = SectionStatus.initial,
    this.h2hErrorMessage,
  });

  // Helper para verificar se alguma seção principal está carregando
  bool get isLoading =>
      statsStatus == SectionStatus.loading ||
      oddsStatus == SectionStatus.loading ||
      h2hStatus == SectionStatus.loading;

  FixtureFullData copyWith({
    Fixture? baseFixture,
    FixtureStatsEntity? fixtureStats,
    SectionStatus? statsStatus,
    String? statsErrorMessage,
    bool clearStatsError = false,
    List<PrognosticMarket>? odds,
    SectionStatus? oddsStatus,
    String? oddsErrorMessage,
    bool clearOddsError = false,
    List<Fixture>? h2hFixtures,
    SectionStatus? h2hStatus,
    String? h2hErrorMessage,
    bool clearH2HError = false,
  }) {
    return FixtureFullData(
      baseFixture: baseFixture ?? this.baseFixture,
      fixtureStats: fixtureStats ?? this.fixtureStats,
      statsStatus: statsStatus ?? this.statsStatus,
      statsErrorMessage:
          clearStatsError
              ? null
              : (statsErrorMessage ?? this.statsErrorMessage),
      odds: odds ?? this.odds,
      oddsStatus: oddsStatus ?? this.oddsStatus,
      oddsErrorMessage:
          clearOddsError ? null : (oddsErrorMessage ?? this.oddsErrorMessage),
      h2hFixtures: h2hFixtures ?? this.h2hFixtures,
      h2hStatus: h2hStatus ?? this.h2hStatus,
      h2hErrorMessage:
          clearH2HError ? null : (h2hErrorMessage ?? this.h2hErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
    baseFixture,
    fixtureStats,
    statsStatus,
    odds,
    oddsStatus,
    h2hFixtures,
    h2hStatus,
    statsErrorMessage,
    oddsErrorMessage,
    h2hErrorMessage,
  ];
}
