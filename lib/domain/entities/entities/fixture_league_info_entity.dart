// lib/domain/entities/fixture_league_info_entity.dart
import 'package:equatable/equatable.dart';

class FixtureLeagueInfoEntity extends Equatable {
  final int id;
  final String name;
  final String? country;
  final String? logoUrl;
  final String? flagUrl;
  final int? season; // Ano da temporada
  final String? round;

  const FixtureLeagueInfoEntity({
    required this.id,
    required this.name,
    this.country,
    this.logoUrl,
    this.flagUrl,
    this.season,
    this.round,
  });

  @override
  List<Object?> get props =>
      [id, name, country, logoUrl, flagUrl, season, round];
}
