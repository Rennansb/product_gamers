// lib/data/models/market_bet_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
import 'odd_value_model.dart';
// Para a entidade PrognosticMarket

class MarketBetModel extends Equatable {
  final int id; // ID do mercado (ex: 1 para "Match Winner")
  final String name; // Nome do mercado (ex: "Match Winner")
  final List<OddValueModel> values; // Lista de opções de aposta com suas odds

  const MarketBetModel({
    required this.id,
    required this.name,
    required this.values,
  });

  factory MarketBetModel.fromJson(Map<String, dynamic> json) {
    var valuesList =
        (json['values'] as List<dynamic>?)
            ?.map((v) => OddValueModel.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];
    return MarketBetModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Mercado Desconhecido',
      values: valuesList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'values': values.map((v) => v.toJson()).toList(),
  };

  PrognosticMarket toEntity() {
    final List<OddOption> entityOptions =
        values.map((v) => v.toEntity()).toList();
    OddOption? suggested;

    if (entityOptions.isNotEmpty) {
      // Encontra a opção com a maior probabilidade (menor odd)
      // (Lógica de ordenação e seleção da sugestão como implementamos antes)
      List<OddOption> sortedOptions = List.from(entityOptions);
      sortedOptions.sort((a, b) {
        final probA = a.probability ?? 0.0;
        final probB = b.probability ?? 0.0;
        if (probA == 0.0 && probB == 0.0) {
          // Se probs são 0, ordena pela menor odd (maior prob implícita)
          return (double.tryParse(a.odd) ?? 1000.0).compareTo(
            double.tryParse(b.odd) ?? 1000.0,
          );
        }
        return probB.compareTo(probA); // Descendente por probabilidade
      });
      if ((sortedOptions.first.probability ?? 0.0) > 0.0 ||
          (double.tryParse(sortedOptions.first.odd) ?? 0.0) > 0.0) {
        suggested = sortedOptions.first;
      }
    }

    return PrognosticMarket(
      marketId: id,
      marketName: name,
      options:
          entityOptions, // Passa as opções originais, não necessariamente ordenadas
      suggestedOption: suggested,
    );
  }

  @override
  List<Object?> get props => [id, name, values];
}
