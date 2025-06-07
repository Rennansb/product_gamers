// lib/domain/entities/suggested_bet_slip.dart
import 'package:equatable/equatable.dart';
import 'fixture.dart'; // Importa a entidade Fixture

// Representa uma seleção individual dentro de um bilhete sugerido (pré-jogo)
class BetSelection extends Equatable {
  final String
      marketName; // Ex: "Resultado Final", "Time da Casa - Mais de 1.5 Gols"
  final String selectionName; // Ex: "Time da Casa", "Mais de 1.5"
  final String odd; // Ex: "1.85" - A odd no momento da análise/sugestão
  final String? reasoning; // Justificativa para esta seleção específica
  final double?
      probability; // Probabilidade calculada/ajustada para esta seleção (0.0 a 1.0)

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
        1.0; // Retorna 1.0 se não puder parsear para não quebrar cálculos de odd total
  }

  // Método copyWith para criar uma nova instância com campos modificados
  BetSelection copyWith({
    String? marketName,
    String? selectionName,
    String? odd,
    String? reasoning, // Permite definir ou limpar o reasoning
    bool clearReasoning = false,
    double? probability, // Permite definir ou limpar a probability
    bool clearProbability = false,
  }) {
    return BetSelection(
      marketName: marketName ?? this.marketName,
      selectionName: selectionName ?? this.selectionName,
      odd: odd ?? this.odd,
      reasoning: clearReasoning ? null : (reasoning ?? this.reasoning),
      probability: clearProbability ? null : (probability ?? this.probability),
    );
  }

  @override
  List<Object?> get props =>
      [marketName, selectionName, odd, reasoning, probability];
}

// Representa um bilhete de apostas pré-jogo sugerido
class SuggestedBetSlip extends Equatable {
  final String title;
  final double
      confidence; // Ex: "Acumulada Ousada do Dia", "Dupla de Favoritos"
  final List<Fixture>
      fixturesInvolved; // Lista de jogos incluídos neste bilhete
  // A ordem pode corresponder à ordem das seleções.
  final List<BetSelection> selections; // Lista de seleções para esses jogos
  final String
      totalOddsDisplay; // Odd total formatada para exibição (ex: "10.53")
  final String?
      overallReasoning; // Justificativa geral para o bilhete como um todo
  final DateTime dateGenerated; // Quando o bilhete foi gerado

  const SuggestedBetSlip({
    required this.title,
    required this.fixturesInvolved,
    required this.selections,
    required this.totalOddsDisplay,
    this.overallReasoning,
    required this.dateGenerated,
    required String totalOdds,
    required this.confidence,
  });

  // Calcula a odd total multiplicando as odds individuais
  double get totalOddsValue {
    if (selections.isEmpty) return 1.0;
    double product = 1.0;
    for (var selection in selections) {
      product *= selection.oddValue;
    }
    return product;
  }

  @override
  List<Object?> get props => [
        title,
        fixturesInvolved,
        selections,
        totalOddsDisplay,
        overallReasoning,
        dateGenerated
      ];
}
