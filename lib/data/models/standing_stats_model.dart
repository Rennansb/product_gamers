// lib/data/models/standing_stats_model.dart
import 'package:equatable/equatable.dart';

// Estatísticas de um time em um segmento da tabela (geral, casa, fora)
class StandingStatsModel extends Equatable {
  final int played; // Jogos jogados
  final int win; // Vitórias
  final int draw; // Empates
  final int lose; // Derrotas
  final int goalsFor; // Gols a favor
  final int goalsAgainst; // Gols contra

  const StandingStatsModel({
    required this.played,
    required this.win,
    required this.draw,
    required this.lose,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  factory StandingStatsModel.fromJson(Map<String, dynamic> json) {
    final goals =
        json['goals'] ?? {}; // Gols a favor e contra estão em um sub-objeto
    return StandingStatsModel(
      played: json['played'] as int? ?? 0,
      win: json['win'] as int? ?? 0,
      draw: json['draw'] as int? ?? 0,
      lose: json['lose'] as int? ?? 0,
      goalsFor: goals['for'] as int? ?? 0,
      goalsAgainst: goals['against'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'played': played,
    'win': win,
    'draw': draw,
    'lose': lose,
    'goals': {'for': goalsFor, 'against': goalsAgainst},
  };

  @override
  List<Object?> get props => [played, win, draw, lose, goalsFor, goalsAgainst];
}
