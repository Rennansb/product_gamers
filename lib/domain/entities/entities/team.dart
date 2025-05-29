// lib/domain/entities/team.dart
import 'package:equatable/equatable.dart';

// Entidade para representar um time dentro do contexto de um jogo (Fixture)
// Usada pela entidade Fixture.
class TeamInFixture extends Equatable {
  final int id;
  final String name;
  final String? logoUrl;

  const TeamInFixture({required this.id, required this.name, this.logoUrl});

  @override
  List<Object?> get props => [id, name, logoUrl];
}

// Você pode adicionar outras entidades de Team aqui se precisar de representações diferentes
// para outros contextos, por exemplo, TeamDetailsEntity para uma tela de detalhes do time.
