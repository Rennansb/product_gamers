// lib/data/models/lineup_player_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/lineup.dart';
// Para PlayerInLineup

class LineupPlayerModel extends Equatable {
  final int? id; // ID do jogador
  final String? name;
  final int? number; // Número da camisa
  final String? pos; // Posição (ex: "G", "D", "M", "F")
  final String?
      grid; // Posição no grid tático (ex: "4:2:3:1" -> "1:1", "2:1", etc.) - pode ser complexo

  const LineupPlayerModel(
      {this.id, this.name, this.number, this.pos, this.grid});

  factory LineupPlayerModel.fromJson(Map<String, dynamic> jsonPlayer) {
    // O objeto 'player' dentro de startXI ou substitutes
    final player = jsonPlayer['player'] ?? jsonPlayer;
    return LineupPlayerModel(
      id: player['id'] as int?,
      name: player['name'] as String?,
      number: player['number'] as int?,
      pos: player['pos'] as String?,
      grid: player['grid'] as String?,
    );
  }

  PlayerInLineup toEntity() {
    return PlayerInLineup(
      playerId: id ?? 0,
      playerName: name ?? "Desconhecido",
      playerNumber: number,
      position: pos,
      gridPosition: grid,
    );
  }

  @override
  List<Object?> get props => [id, name, number, pos, grid];
}
