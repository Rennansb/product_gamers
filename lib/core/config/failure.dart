// lib/core/error/failure.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

// Falhas Gerais
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message});
}

class ApiFailure extends Failure {
  const ApiFailure({required super.message});
}

class NoDataFailure extends Failure {
  const NoDataFailure({
    super.message = "Nenhum dado encontrado para sua solicitação.",
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Ocorreu um erro inesperado durante a operação.',
  });
}
