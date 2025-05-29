// lib/data/models/odd_value_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';

class OddValueModel extends Equatable {
  final String valueName; // Nome da opção/valor (ex: "Home", "Over 2.5", "Yes")
  final String odd; // A cotação como string (ex: "1.85")

  const OddValueModel({required this.valueName, required this.odd});

  factory OddValueModel.fromJson(Map<String, dynamic> json) {
    return OddValueModel(
      valueName: json['value'] as String? ?? 'N/A', // 'value' é a chave na API
      odd: json['odd'] as String? ?? '0.00', // 'odd' é a chave na API
    );
  }

  Map<String, dynamic> toJson() => {'value': valueName, 'odd': odd};

  OddOption toEntity() {
    double? prob;
    final double? oddValue = double.tryParse(odd);
    if (oddValue != null && oddValue > 0) {
      // Cálculo simples da probabilidade implícita (sem remover a margem da casa)
      prob = 1 / oddValue;
    }
    return OddOption(
      label: valueName,
      odd: odd,
      probability: prob, // A entidade OddOption tem o campo probabilidade
    );
  }

  @override
  List<Object?> get props => [valueName, odd];
}
