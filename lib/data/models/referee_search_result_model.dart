// lib/data/models/referee_search_result_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/referee_stats.dart';
// Para a entidade RefereeBasicInfo

class RefereeSearchResultModel extends Equatable {
  final int id;
  final String name;
  final String? type; // A API pode retornar "Main", "VAR", etc.
  final String?
      countryName; // A API pode retornar 'country: {name: "...", ...}'
  final String? photoUrl;

  const RefereeSearchResultModel({
    required this.id,
    required this.name,
    this.type,
    this.countryName,
    this.photoUrl,
  });

  factory RefereeSearchResultModel.fromJson(Map<String, dynamic> json) {
    // A API /referees?search=... retorna uma lista de árbitros.
    // Esta factory é para UM item dessa lista.
    // A API pode retornar o árbitro diretamente ou dentro de um objeto "referee".
    // No caso de /referees?search=, geralmente é direto.
    return RefereeSearchResultModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Árbitro Desconhecido',
      type: json['type'] as String?, // Campo "type" do árbitro, se houver
      countryName:
          json['country']?['name'] as String?, // Se o país estiver aninhado
      photoUrl: json['photo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'country': {
          'name': countryName
        }, // Exemplo se for aninhar na serialização
        'photo': photoUrl,
      };

  // Converte para a entidade de domínio RefereeBasicInfo
  RefereeBasicInfo toEntity() {
    return RefereeBasicInfo(
      id: id,
      name: name,
      countryName: countryName,
      photoUrl: photoUrl,
      // 'type' não está na entidade RefereeBasicInfo, mas poderia ser adicionado se necessário
    );
  }

  @override
  List<Object?> get props => [id, name, type, countryName, photoUrl];
}
