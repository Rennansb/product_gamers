// lib/domain/entities/team.dart
import 'package:equatable/equatable.dart';

class TeamInFixture extends Equatable {
  final int id;
  final String name;
  final String? logoUrl;

  const TeamInFixture({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  @override
  List<Object?> get props => [id, name, logoUrl];
}
