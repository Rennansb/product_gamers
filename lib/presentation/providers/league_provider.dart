// lib/presentation/providers/league_provider.dart
import 'package:flutter/foundation.dart'; // Para ChangeNotifier e kDebugMode
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';
import 'package:product_gamers/main.dart' as main_pkg;
// Removido import de 'package:flutter/material.dart;' pois não é usado diretamente aqui,
// mas ChangeNotifier vem de foundation.

// Core

import '../../domain/usecases/get_leagues_usecase.dart';

// Enum para representar os diferentes estados do provider
enum LeagueStatus { initial, loading, loaded, error, empty }

class LeagueProvider with ChangeNotifier {
  final GetLeaguesUseCase _getLeaguesUseCase;

  LeagueProvider(this._getLeaguesUseCase) {
    // A busca inicial de dados (fetchLeagues) será disparada pela UI (ex: initState da HomeScreen)
    // para garantir que o 'context' esteja disponível se o provider precisar dele,
    // ou para melhor controle do ciclo de vida da UI.
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
    // Evita múltiplas chamadas se já estiver carregando
    if (_status == LeagueStatus.loading && !forceRefresh) return;

    // Se já carregou e não é um refresh forçado, não faz nada,
    // a menos que a lista esteja vazia (indicando um erro anterior ou nenhum dado).
    if (_status == LeagueStatus.loaded &&
        _leagues.isNotEmpty &&
        !forceRefresh) {
      // print("LeagueProvider: Dados de ligas já carregados e não é forceRefresh.");
      return;
    }
    if (_status == LeagueStatus.empty && !forceRefresh) {
      // print("LeagueProvider: Status é empty, não é forceRefresh, não buscando novamente.");
      return;
    }

    _status = LeagueStatus.loading;
    _errorMessage = null; // Limpa erro anterior
    if (forceRefresh) {
      _leagues = []; // Limpa ligas atuais para indicar visualmente o refresh
    }
    notifyListeners(); // Notifica a UI que o estado mudou para loading

    if (kDebugMode) {
      print("LeagueProvider: Buscando ligas... (forceRefresh: $forceRefresh)");
    }

    final result = await _getLeaguesUseCase(); // Chama o UseCase

    // Após a chamada async, verificar se o provider ainda está "vivo"
    // Embora para ChangeNotifier, o dispose é o principal.
    // Esta verificação é mais uma precaução se o estado mudar muito rápido.
    if (_status == LeagueStatus.loading) {
      // Só atualiza se ainda estiver no estado de loading
      result.fold(
        (failure) {
          // Caso de falha
          _errorMessage = _mapFailureToMessage(failure);
          _status = LeagueStatus.error;
          _leagues =
              []; // Garante que a lista de ligas esteja vazia em caso de erro
          if (kDebugMode) {
            print("LeagueProvider: Erro ao buscar ligas - $_errorMessage");
          }
        },
        (leaguesData) {
          // Caso de sucesso
          _leagues = leaguesData.cast<League>();
          if (_leagues.isEmpty) {
            // Mesmo que a chamada à API seja bem-sucedida, a lista pode vir vazia
            _errorMessage =
                "Nenhuma liga popular foi encontrada ou configurada.";
            _status = LeagueStatus.empty; // Estado específico para lista vazia
            if (kDebugMode) {
              print("LeagueProvider: Nenhuma liga encontrada.");
            }
          } else {
            _status = LeagueStatus.loaded;
            if (kDebugMode) {
              print(
                  "LeagueProvider: Ligas carregadas - ${_leagues.length} ligas.");
            }
          }
        },
      );
      notifyListeners(); // Notifica a UI sobre o novo estado (loaded, error, ou empty)
    }
  }

  // Helper para converter diferentes tipos de Failure em mensagens amigáveis
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Erro no servidor da API: ${failure.message}';
    } else if (failure is NetworkFailure) {
      return 'Falha de conexão: ${failure.message}. Verifique sua internet.';
    } else if (failure is AuthenticationFailure) {
      return 'Erro de autenticação com a API: ${failure.message}. Verifique sua chave.';
    } else if (failure is ApiFailure) {
      return 'Erro da API: ${failure.message}. Tente novamente mais tarde.';
    } else if (failure is NoDataFailure) {
      return failure.message; // Mensagem já é específica
    }
    // Fallback para outros tipos de Failure
    return 'Ocorreu um erro inesperado ao buscar as ligas: ${failure.message}';
  }
}
