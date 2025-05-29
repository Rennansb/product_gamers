// lib/domain/entities/suggested_bet_slip.dart
import 'package:equatable/equatable.dart';
import 'fixture.dart'; // Importa a entidade Fixture

// Representa uma seleção individual dentro de um bilhete
class BetSelection extends Equatable {
  final String
  marketName; // Ex: "Resultado Final", "Time da Casa - Mais de 1.5 Gols"
  final String selectionName; // Ex: "Time da Casa", "Mais de 1.5"
  final String odd; // Ex: "1.85"
  final String?
  reasoning; // Breve justificativa baseada em estatísticas (opcional)
  final double?
  probability; // Probabilidade implícita da seleção individual (opcional)

  const BetSelection({
    required this.marketName,
    required this.selectionName,
    required this.odd,
    this.reasoning,
    this.probability,
  });

  // Helper para obter a odd como double
  double get oddValue {
    return double.tryParse(odd) ??
        1.0; // Retorna 1.0 se não puder parsear (para não quebrar cálculo de produto)
  }

  @override
  List<Object?> get props => [
    marketName,
    selectionName,
    odd,
    reasoning,
    probability,
  ];
}

// Representa um bilhete sugerido
class SuggestedBetSlip extends Equatable {
  final String title; // Ex: "Acumulada Ousada do Dia", "Dupla de Favoritos"
  final List<Fixture> fixturesInvolved; // Lista de jogos incluídos
  final List<BetSelection> selections; // Lista de seleções para esses jogos
  final String totalOdds; // Odd total calculada (como string formatada)
  final String? overallReasoning; // Justificativa geral para o bilhete
  final DateTime dateGenerated;

  const SuggestedBetSlip({
    required this.title,
    required this.fixturesInvolved,
    required this.selections,
    required this.totalOdds, // A odd total já virá calculada do UseCase
    this.overallReasoning,
    required this.dateGenerated,
  });

  // Helper para obter a odd total como double
  double get totalOddsValue {
    return double.tryParse(totalOdds) ?? 1.0;
  }

  @override
  List<Object?> get props => [
    title,
    fixturesInvolved,
    selections,
    totalOdds,
    overallReasoning,
    dateGenerated,
  ];
}
