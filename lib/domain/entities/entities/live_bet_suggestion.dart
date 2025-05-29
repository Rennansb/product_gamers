// lib/domain/entities/live_bet_suggestion.dart
import 'package:equatable/equatable.dart';
import 'live_game_insight.dart'; // Importar LiveInsightType

enum BetSuggestionStrength { low, medium, high }

class LiveBetSuggestion extends Equatable {
  final String id;
  final int fixtureId;
  final String marketName;
  final String selectionName;
  final String currentOdd;
  final String reasoning;
  final LiveInsightType? basedOnInsight;
  final BetSuggestionStrength strength;
  final DateTime timestamp;
  final int? suggestedAtMinute;
  final String? currentScore;

  const LiveBetSuggestion({
    required this.id,
    required this.fixtureId,
    required this.marketName,
    required this.selectionName,
    required this.currentOdd,
    required this.reasoning,
    this.basedOnInsight,
    required this.strength,
    required this.timestamp,
    this.suggestedAtMinute,
    this.currentScore,
  });

  @override
  List<Object?> get props => [
    id,
    fixtureId,
    marketName,
    selectionName,
    currentOdd,
    reasoning, // Removido basedOnInsight de props por simplicidade, pode adicionar se quiser comparação por ele
    strength, timestamp, suggestedAtMinute, currentScore,
  ];
}
