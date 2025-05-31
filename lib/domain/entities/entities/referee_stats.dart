// lib/domain/entities/referee_stats.dart
import 'package:equatable/equatable.dart';

// Entidade para estatísticas detalhadas e médias do árbitro
class RefereeStats extends Equatable {
  final int refereeId;
  final String refereeName;
  // ... (outros campos e construtor como definido antes) ...
  final String? nationality;
  final String? photoUrl;
  final double averageYellowCardsPerGame;
  final double averageRedCardsPerGame;
  final int gamesOfficiatedInCalculation;

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
        gamesOfficiatedInCalculation
      ];
}

// Entidade para informações básicas do árbitro (resultado da busca por nome)
// ESTA CLASSE DEVE ESTAR AQUI
class RefereeBasicInfo extends Equatable {
  final int id;
  final String name;
  final String? countryName;
  final String? photoUrl;
  // Poderia adicionar 'type' aqui se fosse relevante para a entidade básica

  const RefereeBasicInfo({
    required this.id,
    required this.name,
    this.countryName,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, name, countryName, photoUrl];
}
