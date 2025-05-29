// lib/data/models/statistic_item_model.dart
import 'package:equatable/equatable.dart';

class StatisticItemModel extends Equatable {
  final String type; // Ex: "Shots on Goal", "Ball Possession", "Expected Goals"
  final dynamic
  value; // Pode ser String (ex: "55%"), int (ex: 5), double (ex: "1.23" para xG)

  const StatisticItemModel({required this.type, this.value});

  factory StatisticItemModel.fromJson(Map<String, dynamic> json) {
    return StatisticItemModel(
      type: json['type'] as String? ?? 'Unknown Type',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'value': value};

  @override
  List<Object?> get props => [type, value];
}
