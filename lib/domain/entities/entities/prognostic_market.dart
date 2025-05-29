// lib/domain/entities/prognostic_market.dart
import 'package:equatable/equatable.dart';

// Representa uma única opção de aposta dentro de um mercado, com sua odd e probabilidade implícita
class OddOption extends Equatable {
  final String label; // Nome da opção (ex: "Home", "Over 2.5", "Yes")
  final String odd; // A cotação como string (ex: "1.85")
  final double?
  probability; // Probabilidade implícita calculada (0.0 a 1.0), opcional

  const OddOption({required this.label, required this.odd, this.probability});

  // Helper para obter a odd como double, útil para cálculos
  double get oddValue {
    return double.tryParse(odd) ??
        0.0; // Retorna 0.0 se não puder parsear, para evitar erros
  }

  @override
  List<Object?> get props => [label, odd, probability];
}

// Representa um mercado de apostas (ex: "Match Winner", "Goals Over/Under")
class PrognosticMarket extends Equatable {
  final int marketId; // ID do mercado fornecido pela API
  final String marketName; // Nome do mercado
  final List<OddOption> options; // Lista de opções de aposta para este mercado
  final OddOption?
  suggestedOption; // A opção com a maior probabilidade implícita (menor odd), opcional

  const PrognosticMarket({
    required this.marketId,
    required this.marketName,
    required this.options,
    this.suggestedOption,
  });

  @override
  List<Object?> get props => [marketId, marketName, options, suggestedOption];
}
