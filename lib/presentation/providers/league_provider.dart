// lib/presentation/providers/league_provider.dart
import 'package:flutter/foundation.dart'; // Para ChangeNotifier e kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  LeagueProvider(this._getLeaguesUseCase);

  LeagueStatus _status = LeagueStatus.initial;
  List<League> _leagues = [];
  String? _errorMessage;

  LeagueStatus get status => _status;
  List<League> get leagues => _leagues;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false; // Adicionar flag de dispose

  Future<void> fetchLeagues({bool forceRefresh = false}) async {
    if (_isDisposed) return;
    if (_status == LeagueStatus.loading && !forceRefresh) return;
    if ((_status == LeagueStatus.loaded || _status == LeagueStatus.empty) &&
        _leagues.isNotEmpty &&
        !forceRefresh) {
      return;
    }
    if (_status == LeagueStatus.empty && !forceRefresh && _leagues.isEmpty) {
      return;
    }

    // Mudança de estado para loading
    _status = LeagueStatus.loading;
    _errorMessage = null;
    if (forceRefresh) {
      _leagues = [];
    }

    // ===== CORREÇÃO PRINCIPAL AQUI =====
    // Adiar a notificação para depois do frame de build atual se for a primeira chamada que muda para loading.
    // Ou, se a chamada vier de um local que já está "seguro" (como um callback de botão), isso pode não ser necessário.
    // No entanto, para chamadas de initState/didChangeDependencies, é mais seguro.
    bool needsImmediateNotify = true;
    if (WidgetsBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks ||
        WidgetsBinding.instance.schedulerPhase ==
            SchedulerPhase.postFrameCallbacks ||
        WidgetsBinding.instance.schedulerPhase ==
            SchedulerPhase.midFrameMicrotasks) {
      // Se já estamos em uma fase "segura" ou pós-build, podemos notificar.
      // No entanto, para simplificar e garantir, vamos sempre usar Future.microtask para a primeira notificação de loading
      // se o estado anterior não era loading.
    }

    // Notifica que está carregando. Se isso for chamado durante um build, pode causar o erro.
    // Vamos garantir que a notificação de mudança para 'loading' aconteça de forma segura.
    // Se já estava 'loading', não precisa notificar de novo.
    // A notificação para 'loaded' ou 'error' no final é geralmente segura porque acontece após um 'await'.

    // Notificar listeners APÓS a atribuição de status, mas antes do await da operação async.
    // Para evitar o erro "setState() or markNeedsBuild() called during build",
    // podemos envolver a parte que muda o estado e notifica em Future.microtask
    // se for a transição inicial para loading.

    // Se o estado anterior não era loading, ou se é forceRefresh, notificamos.
    // A notificação que muda para 'loading' é a mais crítica.
    if (_status == LeagueStatus.loading) {
      // Verifica se o status realmente mudou para loading
      // Para ser extra seguro, especialmente se chamado de didChangeDependencies:
      Future.microtask(() {
        if (!_isDisposed && _status == LeagueStatus.loading) {
          // Checa de novo antes de notificar
          notifyListeners();
        }
      });
    }

    if (kDebugMode) {
      print("LeagueProvider: Buscando ligas... (forceRefresh: $forceRefresh)");
    }

    final result = await _getLeaguesUseCase();

    if (_isDisposed) return; // Checa novamente após o await

    // Só atualiza o estado se ainda estivermos no processo de loading que esta chamada iniciou.
    // Isso evita problemas se uma nova chamada a fetchLeagues for feita enquanto uma antiga ainda está no await.
    // (Uma trava _isLoading_internally seria mais robusta para chamadas concorrentes, mas _status já ajuda)
    if (_status == LeagueStatus.loading) {
      result.fold(
        (failure) {
          _errorMessage = _mapFailureToMessage(failure);
          _status = LeagueStatus.error;
          _leagues = [];
          if (kDebugMode)
            print("LeagueProvider: Erro ao buscar ligas - $_errorMessage");
        },
        (leaguesData) {
          _leagues = leaguesData;
          if (_leagues.isEmpty) {
            _errorMessage =
                "Nenhuma liga popular foi encontrada ou configurada.";
            _status = LeagueStatus.empty;
            if (kDebugMode) print("LeagueProvider: Nenhuma liga encontrada.");
          } else {
            _status = LeagueStatus.loaded;
            if (kDebugMode)
              print(
                  "LeagueProvider: Ligas carregadas - ${_leagues.length} ligas.");
          }
        },
      );
      notifyListeners(); // Esta notificação (para loaded/error/empty) é segura pois ocorre após o await.
    }
  }

  String _mapFailureToMessage(Failure failure) {
    // ... (implementação como antes)
    if (failure is ServerFailure) return 'Erro no servidor: ${failure.message}';
    if (failure is NetworkFailure)
      return 'Falha de conexão: ${failure.message}';
    if (failure is AuthenticationFailure)
      return 'Erro de autenticação: ${failure.message}';
    if (failure is ApiFailure) return 'Erro da API: ${failure.message}';
    if (failure is NoDataFailure) return failure.message;
    return 'Ocorreu um erro inesperado ao buscar as ligas: ${failure.message}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (kDebugMode) print("LeagueProvider disposed.");
    super.dispose();
  }
}
