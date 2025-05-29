// lib/data/models/standing_item_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/standing_info.dart';
import 'team_model.dart'; // Importa TeamModel
import 'standing_stats_model.dart'; // Importa StandingStatsModel

class StandingItemModel extends Equatable {
  final int rank; // Posição na tabela
  final int teamId; // ID do time
  final String teamName; // Nome do time
  final String? teamLogoUrl; // Logo do time
  final int points; // Pontos
  final int goalsDiff; // Saldo de gols
  final String
  groupName; // Nome do grupo/fase (ex: "Premier League", "Group A")
  final String form; // Sequência de resultados (ex: "WWLDW")
  final String? status; // Mudança de posição (ex: "same", "up", "down")
  final String? description; // Ex: "Promotion - Champions League (Group Stage)"

  final StandingStatsModel allStats; // Estatísticas totais (casa + fora)
  final StandingStatsModel? homeStats; // Estatísticas apenas em casa
  final StandingStatsModel? awayStats; // Estatísticas apenas fora

  final DateTime?
  update; // Data da última atualização (nem sempre presente/útil)

  const StandingItemModel({
    required this.rank,
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    required this.points,
    required this.goalsDiff,
    required this.groupName,
    required this.form,
    this.status,
    this.description,
    required this.allStats,
    this.homeStats,
    this.awayStats,
    this.update,
  });

  factory StandingItemModel.fromJson(Map<String, dynamic> json) {
    // API-Football retorna a informação do time aninhada
    final teamData = json['team'] as Map<String, dynamic>? ?? {};
    final teamModel = TeamModel.fromJson(
      teamData,
    ); // Usar nosso TeamModel para parsear

    final allStatsData = json['all'] as Map<String, dynamic>? ?? {};
    final homeStatsData =
        json['home'] as Map<String, dynamic>?; // Pode ser nulo
    final awayStatsData =
        json['away'] as Map<String, dynamic>?; // Pode ser nulo

    return StandingItemModel(
      rank: json['rank'] as int? ?? 0,
      teamId: teamModel.id,
      teamName: teamModel.name,
      teamLogoUrl: teamModel.logoUrl,
      points: json['points'] as int? ?? 0,
      goalsDiff: json['goalsDiff'] as int? ?? 0,
      groupName: json['group'] as String? ?? 'N/A',
      form: json['form'] as String? ?? '',
      status: json['status'] as String?,
      description: json['description'] as String?,

      allStats: StandingStatsModel.fromJson(allStatsData),
      homeStats:
          homeStatsData != null
              ? StandingStatsModel.fromJson(homeStatsData)
              : null,
      awayStats:
          awayStatsData != null
              ? StandingStatsModel.fromJson(awayStatsData)
              : null,
      update:
          json['update'] != null
              ? DateTime.tryParse(json['update'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'team': {
      'id': teamId,
      'name': teamName,
      'logo': teamLogoUrl,
    }, // Simplificado
    'points': points,
    'goalsDiff': goalsDiff,
    'group': groupName,
    'form': form,
    'status': status,
    'description': description,
    'all': allStats.toJson(),
    'home': homeStats?.toJson(),
    'away': awayStats?.toJson(),
    'update': update?.toIso8601String(),
  };

  StandingInfo toEntity() {
    return StandingInfo(
      rank: rank,
      teamId: teamId,
      teamName: teamName,
      teamLogoUrl: teamLogoUrl,
      points: points,
      goalsDiff: goalsDiff,
      groupName: groupName,
      formStreak: form,
      played: allStats.played,
      wins: allStats.win,
      draws: allStats.draw,
      losses: allStats.lose,
      goalsFor: allStats.goalsFor,
      goalsAgainst: allStats.goalsAgainst,
      description: description,
    );
  }

  @override
  List<Object?> get props => [
    rank,
    teamId,
    teamName,
    teamLogoUrl,
    points,
    goalsDiff,
    groupName,
    form,
    status,
    description,
    allStats,
    homeStats,
    awayStats,
    update,
  ];
}
