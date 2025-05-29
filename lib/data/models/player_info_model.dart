// lib/data/models/player_info_model.dart
import 'package:equatable/equatable.dart';
// Não há entidade de domínio separada apenas para PlayerInfo neste exemplo,
// pois ele é geralmente usado dentro de PlayerSeasonStats. Se necessário, poderia ser criada.

class PlayerInfoModel extends Equatable {
  final int id;
  final String name;
  final String? firstname;
  final String? lastname;
  final int? age;
  final String? nationality;
  final String? height; // ex: "180 cm"
  final String? weight; // ex: "75 kg"
  final String? photoUrl;
  final bool? injured; // Adicionado, pois a API pode fornecer

  const PlayerInfoModel({
    required this.id,
    required this.name,
    this.firstname,
    this.lastname,
    this.age,
    this.nationality,
    this.height,
    this.weight,
    this.photoUrl,
    this.injured,
  });

  factory PlayerInfoModel.fromJson(Map<String, dynamic> jsonPlayerObject) {
    // A API pode aninhar 'player' dentro de outra estrutura (ex: em /players/topscorers)
    // ou retornar os dados do jogador diretamente (ex: no array 'players' de /players/squads).
    // A chave 'player' também é usada em /players?id=X&season=Y
    final player = jsonPlayerObject['player'] ?? jsonPlayerObject;

    return PlayerInfoModel(
      id: player['id'] as int? ?? 0,
      name: player['name'] as String? ?? 'Jogador Desconhecido',
      firstname: player['firstname'] as String?,
      lastname: player['lastname'] as String?,
      age: player['age'] as int?,
      // 'birth' é um objeto com 'date', 'place', 'country' - não estamos usando por ora
      nationality: player['nationality'] as String?,
      height: player['height'] as String?,
      weight: player['weight'] as String?,
      injured: player['injured'] as bool?,
      photoUrl: player['photo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'firstname': firstname,
    'lastname': lastname,
    'age': age,
    'nationality': nationality,
    'height': height,
    'weight': weight,
    'injured': injured,
    'photo': photoUrl,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    firstname,
    lastname,
    age,
    nationality,
    height,
    weight,
    photoUrl,
    injured,
  ];
}
