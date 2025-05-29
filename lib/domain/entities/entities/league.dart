// lib/domain/entities/league.dart
import 'package:equatable/equatable.dart';

class League extends Equatable {
  final int id;
  final String name; // Este será o nome original da API
  final String? type;
  final String? logoUrl;
  final String? countryName;
  final String? countryFlagUrl;
  final int? currentSeasonYear; // Ano da temporada atual/mais recente
  final String
  friendlyName; // Nome amigável para exibição (pode ser igual a 'name')

  const League({
    required this.id,
    required this.name,
    this.type,
    this.logoUrl,
    this.countryName,
    this.countryFlagUrl,
    this.currentSeasonYear,
    required this.friendlyName,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    logoUrl,
    countryName,
    countryFlagUrl,
    currentSeasonYear,
    friendlyName,
  ];
}
