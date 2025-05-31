// lib/domain/entities/league.dart
import 'package:equatable/equatable.dart';

class League extends Equatable {
  final int id;
  final String name;
  final String? type;
  final String? logoUrl;
  final String? countryName;
  final String? countryFlagUrl;
  final int? currentSeasonYear;
  final String friendlyName;

  // ===== ESTE É O CONSTRUTOR CRÍTICO =====
  // VERIFIQUE SE AS CHAVES '{' E '}' ESTÃO PRESENTES E CORRETAS
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
  // ========================================

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        logoUrl,
        countryName,
        countryFlagUrl,
        currentSeasonYear,
        friendlyName
      ];
}
