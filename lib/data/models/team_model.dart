// lib/data/models/team_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
import 'package:product_gamers/domain/entities/entities/team.dart';

class TeamModel extends Equatable {
  final int id;
  final String name;
  final String?
  code; // Código curto do time (ex: "FLA", "MUN") - API-Football pode ou não fornecer
  final String? country; // País do time
  final int? founded; // Ano de fundação
  final bool? national; // Se é uma seleção nacional
  final String? logoUrl;

  const TeamModel({
    required this.id,
    required this.name,
    this.code,
    this.country,
    this.founded,
    this.national,
    this.logoUrl,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    // A API-Football pode retornar os dados do time diretamente
    // ou aninhados dentro de um objeto 'team' (ex: em /standings)
    // ou em 'home'/'away' (ex: em /fixtures).
    // Esta fábrica tenta ser flexível.
    final teamData =
        json['team'] ?? json; // Se 'team' não existir, usa o json raiz.

    return TeamModel(
      id: teamData['id'] as int? ?? 0, // Default para 0 se nulo ou tipo errado
      name: teamData['name'] as String? ?? 'Desconhecido', // Default
      code: teamData['code'] as String?,
      country: teamData['country'] as String?,
      founded: teamData['founded'] as int?,
      national: teamData['national'] as bool?,
      logoUrl: teamData['logo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    // Útil para debugging ou se você fosse enviar dados para uma API (não é o caso aqui)
    return {
      'id': id,
      'name': name,
      'code': code,
      'country': country,
      'founded': founded,
      'national': national,
      'logo': logoUrl,
    };
  }

  // Converte o Modelo de Dados para uma Entidade de Domínio
  // Usaremos TeamInFixture como a entidade básica para times dentro de jogos.
  // Se você precisar de uma entidade Team mais completa para uma tela de detalhes do time,
  // você criaria uma TeamEntity separada.
  TeamInFixture toEntity() {
    return TeamInFixture(id: id, name: name, logoUrl: logoUrl);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    country,
    founded,
    national,
    logoUrl,
  ];
}
