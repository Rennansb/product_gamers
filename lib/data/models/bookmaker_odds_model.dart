// lib/data/models/bookmaker_odds_model.dart
import 'package:equatable/equatable.dart';
import 'market_bet_model.dart';
// Não precisa converter para entidade aqui, a conversão ocorre no MarketBetModel

class BookmakerOddsModel extends Equatable {
  final int id; // ID do bookmaker (ex: 8 para Bet365)
  final String name; // Nome do bookmaker
  final List<MarketBetModel>
  bets; // Lista de mercados oferecidos por este bookmaker

  const BookmakerOddsModel({
    required this.id,
    required this.name,
    required this.bets,
  });

  factory BookmakerOddsModel.fromJson(Map<String, dynamic> json) {
    var betsList =
        (json['bets'] as List<dynamic>?)
            ?.map((b) => MarketBetModel.fromJson(b as Map<String, dynamic>))
            .toList() ??
        [];
    return BookmakerOddsModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Bookmaker Desconhecido',
      bets: betsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bets': bets.map((b) => b.toJson()).toList(),
  };

  @override
  List<Object?> get props => [id, name, bets];
}
