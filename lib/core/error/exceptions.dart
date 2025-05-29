// lib/core/error/exceptions.dart

// Exceções que podem ser lançadas pela camada de dados ou outras camadas.
class ServerException implements Exception {
  final String? message;
  final int? statusCode; // Opcional: código de status HTTP do erro
  ServerException({this.message, this.statusCode});

  @override
  String toString() {
    return 'ServerException: ${message ?? "Erro desconhecido no servidor"}${statusCode != null ? " (Status: $statusCode)" : ""}.';
  }
}

class CacheException implements Exception {
  final String? message;
  CacheException({this.message});

  @override
  String toString() {
    return 'CacheException: ${message ?? "Erro de cache"}.';
  }
}

class NetworkException implements Exception {
  final String? message;
  NetworkException({this.message});

  @override
  String toString() {
    return 'NetworkException: ${message ?? "Erro de rede"}.';
  }
}

class AuthenticationException implements Exception {
  final String? message;
  AuthenticationException({this.message});

  @override
  String toString() {
    return 'AuthenticationException: ${message ?? "Falha na autenticação. Verifique sua API Key."}.';
  }
}

// Para erros específicos da API (ex: rate limit, parâmetros inválidos, conta suspensa)
class ApiException implements Exception {
  final String? message;
  final dynamic apiErrorData; // Pode conter mais detalhes do erro da API
  ApiException({this.message, this.apiErrorData});

  @override
  String toString() {
    return 'ApiException: ${message ?? "Erro retornado pela API"}${apiErrorData != null ? ". Detalhes: $apiErrorData" : ""}.';
  }
}

class NoDataException implements Exception {
  final String? message;
  NoDataException({this.message});

  @override
  String toString() {
    return 'NoDataException: ${message ?? "Nenhum dado encontrado."}.';
  }
}
