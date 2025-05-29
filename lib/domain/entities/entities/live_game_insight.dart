// lib/domain/entities/live_game_insight.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // Para IconData

enum LiveInsightType {
  pressure,
  goal_scored,
  card_issued,
  late_game_potential,
  momentum_shift,
  custom,
}

class LiveGameInsight extends Equatable {
  final LiveInsightType type;
  final String description;
  final DateTime timestamp;
  final int? relatedTeamId;
  final String? relatedTeamName;
  final IconData? icon;
  final Color? iconColor;

  const LiveGameInsight({
    required this.type,
    required this.description,
    required this.timestamp,
    this.relatedTeamId,
    this.relatedTeamName,
    this.icon,
    this.iconColor,
  });

  @override
  List<Object?> get props => [
    type,
    description,
    timestamp,
    relatedTeamId,
    relatedTeamName,
    icon,
    iconColor,
  ]; // Adicionado iconColor
}
