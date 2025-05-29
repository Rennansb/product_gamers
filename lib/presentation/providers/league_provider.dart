// lib/presentation/providers/league_provider.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';

import '../../domain/usecases/get_leagues_usecase.dart';

// Enum para representar os diferentes estados do provider
enum LeagueStatus { initial, loading, loaded, error }

class LeagueProvider with ChangeNotifier {
  final GetLeaguesUseCase _getLeaguesUseCase;

  LeagueProvider(this._getLeaguesUseCase) {
    // Poderíamos chamar fetchLeagues() aqui, mas geralmente é melhor
    // que a UI (ex: initState da tela) dispare a primeira busca de dados.
  }

  // Estado interno do provider
  LeagueStatus _status = LeagueStatus.initial;
  List<League> _leagues = [];
  String? _errorMessage;

  // Getters públicos para a UI consumir o estado
  LeagueStatus get status => _status;
  List<League> get leagues => _leagues;
  String? get errorMessage => _errorMessage;

  // Ação para buscar as ligas
  Future<void> fetchLeagues({bool forceRefresh = false}) async {
    // Evita múltiplas chamadas se já estiver carregando ou se os dados já foram carregados (a menos que seja um forceRefresh)
    if (_status == LeagueStatus.loading && !forceRefresh) return;
    if (_status == LeagueStatus.loaded &&
        _leagues.isNotEmpty &&
        !forceRefresh) {
      // Se já carregou e não é refresh, não faz nada.
      // Ou, você pode decidir sempre permitir o refresh se forceRefresh = true.
      // A lógica atual já permite isso.
    }

    _status = LeagueStatus.loading;
    _errorMessage = null; // Limpa erro anterior
    if (forceRefresh)
      _leagues = []; // Limpa ligas atuais para mostrar o loading em refresh
    notifyListeners(); // Notifica a UI que o estado mudou para loading

    final result = await _getLeaguesUseCase(); // Chama o UseCase

    // Processa o resultado (Either<Failure, List<League>>)
    result.fold(
      (failure) {
        // Caso de falha
        _errorMessage = _mapFailureToMessage(failure);
        _status = LeagueStatus.error;
        _leagues =
            []; // Garante que a lista de ligas esteja vazia em caso de erro
      },
      (leaguesData) {
        // Caso de sucesso
        _leagues = leaguesData;
        if (_leagues.isEmpty) {
          // Mesmo que a chamada à API seja bem-sucedida, a lista pode vir vazia
          // (ex: se AppConstants.popularLeagues estiver vazio ou todas as buscas individuais falharem no DataSource)
          _errorMessage = "Nenhuma liga popular foi encontrada ou configurada.";
          _status =
              LeagueStatus
                  .error; // Considerar como um erro se esperávamos ligas
        } else {
          _status = LeagueStatus.loaded;
        }
      },
    );
    notifyListeners(); // Notifica a UI sobre o novo estado (loaded ou error)
  }

  // Helper para converter diferentes tipos de Failure em mensagens amigáveis
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Erro no servidor da API: ${failure.message}';
      case NetworkFailure:
        return 'Falha de conexão: ${failure.message}. Verifique sua internet.';
      case AuthenticationFailure:
        return 'Erro de autenticação com a API: ${failure.message}. Verifique sua chave.';
      case ApiFailure:
        return 'Erro da API: ${failure.message}. Tente novamente mais tarde.';
      case NoDataFailure:
        return failure
            .message; // Mensagem já é específica (ex: "Nenhuma das ligas populares pôde ser carregada.")
      default:
        return 'Ocorreu um erro inesperado: ${failure.message}';
    }
  }
}
