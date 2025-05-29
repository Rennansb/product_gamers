// lib/domain/entities/referee_stats.dart
import 'package:equatable/equatable.dart';

class RefereeStats extends Equatable {
  final int refereeId;
  final String refereeName;
  final String? nationality;
  final String? photoUrl;
  final double averageYellowCardsPerGame; // Média calculada
  final double averageRedCardsPerGame; // Média calculada
  final int
  gamesOfficiatedInCalculation; // Jogos usados para o cálculo da média

  const RefereeStats({
    required this.refereeId,
    required this.refereeName,
    this.nationality,
    this.photoUrl,
    required this.averageYellowCardsPerGame,
    required this.averageRedCardsPerGame,
    required this.gamesOfficiatedInCalculation,
  });

  @override
  List<Object?> get props => [
    refereeId,
    refereeName,
    nationality,
    photoUrl,
    averageYellowCardsPerGame,
    averageRedCardsPerGame,
    gamesOfficiatedInCalculation,
  ];
}
