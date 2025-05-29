// lib/presentation/providers/live_fixture_provider.dart
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/live_bet_suggestion.dart';
import 'package:product_gamers/domain/entities/entities/live_fixture_update.dart';
import 'package:product_gamers/domain/entities/entities/live_game_insight.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart'; // Para firstWhereOrNull e DeepCollectionEquality

// Core
// <<< IMPORT CORRETO

// Domain - UseCases
import '../../domain/usecases/get_live_fixture_update_usecase.dart';
import '../../domain/usecases/get_live_odds_usecase.dart';

enum LiveFixturePollingStatus {
  initial,
  loadingFirst,
  activePolling,
  error,
  finished,
  disposed,
}

class LiveFixtureProvider with ChangeNotifier {
  final GetLiveFixtureUpdateUseCase _getLiveFixtureUpdateUseCase;
  final GetLiveOddsUseCase _getLiveOddsUseCase;
  final int fixtureId;
  final String _homeTeamName;
  final String _awayTeamName;
  final int _homeTeamId;
  final int _awayTeamId;

  LiveFixtureProvider({
    required this.fixtureId,
    required String homeTeamName,
    required String awayTeamName,
    required int homeTeamId,
    required int awayTeamId,
    required GetLiveFixtureUpdateUseCase getLiveFixtureUpdateUseCase,
    required GetLiveOddsUseCase getLiveOddsUseCase,
  }) : _homeTeamName = homeTeamName,
       _awayTeamName = awayTeamName,
       _homeTeamId = homeTeamId,
       _awayTeamId = awayTeamId,
       _getLiveFixtureUpdateUseCase = getLiveFixtureUpdateUseCase,
       _getLiveOddsUseCase = getLiveOddsUseCase {
    _startPolling();
  }

  LiveFixturePollingStatus _status = LiveFixturePollingStatus.initial;
  LiveFixtureUpdate? _liveData;
  LiveFixtureUpdate? _previousLiveData;
  String? _errorMessage;
  Timer? _pollingTimer;
  int _errorCount = 0;

  List<PrognosticMarket> _liveOdds = [];
  String? _oddsErrorMessage;

  List<LiveGameInsight> _liveInsights = [];
  List<LiveBetSuggestion> _liveSuggestions = [];

  final Uuid _uuid = const Uuid();

  LiveFixturePollingStatus get status => _status;
  LiveFixtureUpdate? get liveData => _liveData;
  String? get errorMessage => _errorMessage;
  List<PrognosticMarket> get liveOdds => _liveOdds;
  String? get oddsErrorMessage => _oddsErrorMessage;
  List<LiveGameInsight> get liveInsights => _liveInsights;
  List<LiveBetSuggestion> get liveSuggestions => _liveSuggestions;

  static const Duration _pollingInterval = Duration(seconds: 25);
  static const int _maxErrorRetries = 3;

  void _startPolling() {
    if ((_pollingTimer != null && _pollingTimer!.isActive) ||
        _status == LiveFixturePollingStatus.disposed) {
      return;
    }
    print("Iniciando polling completo para fixture $fixtureId");
    _fetchAllLiveInfo(isInitialLoad: true);

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      if (_status != LiveFixturePollingStatus.finished &&
          _status != LiveFixturePollingStatus.disposed) {
        _fetchAllLiveInfo();
      } else {
        print("Parando polling completo ($fixtureId) pois status é $_status");
        timer.cancel();
      }
    });
  }

  Future<void> _fetchAllLiveInfo({bool isInitialLoad = false}) async {
    if (_status == LiveFixturePollingStatus.disposed) return;

    bool previousHadError = _status == LiveFixturePollingStatus.error;

    if (isInitialLoad) {
      _status = LiveFixturePollingStatus.loadingFirst;
      // Só notifica aqui se for a primeira vez, o notifyListeners no final do try/catch cuidará das outras
      if (!previousHadError) notifyListeners();
    } else if (previousHadError && _errorCount < _maxErrorRetries) {
      print("Tentando recuperar de erro para fixture $fixtureId...");
      _errorMessage = null;
      _oddsErrorMessage = null;
      // Não notifica imediatamente para evitar piscar a UI, espera o resultado da chamada
    }

    final fixtureUpdateFuture = _getLiveFixtureUpdateUseCase(fixtureId);
    final liveOddsFuture = _getLiveOddsUseCase(fixtureId: fixtureId);

    try {
      final results = await Future.wait([fixtureUpdateFuture, liveOddsFuture]);
      if (_status == LiveFixturePollingStatus.disposed) return;

      final fixtureResult = results[0] as Either<Failure, LiveFixtureUpdate>;
      final oddsResult = results[1] as Either<Failure, List<PrognosticMarket>>;

      bool dataChanged = isInitialLoad; // Considera mudança na carga inicial

      // Processar resultado do estado do jogo
      fixtureResult.fold(
        (failure) {
          _errorMessage = _mapFailureToMessage(failure);
          _errorCount++;
          print(
            "Erro ao buscar atualização ao vivo para $fixtureId (tentativa $_errorCount): $_errorMessage",
          );
          if (_errorCount >= _maxErrorRetries ||
              _isUnrecoverableError(failure)) {
            _status = LiveFixturePollingStatus.error;
            _pollingTimer?.cancel();
          } else if (_liveData == null) {
            _status = LiveFixturePollingStatus.error;
          }
          dataChanged = true; // Houve uma mudança (para estado de erro)
        },
        (update) {
          if (!const DeepCollectionEquality().equals(_liveData, update)) {
            _previousLiveData = _liveData;
            _liveData = update;
            dataChanged = true;
          }
          if (_errorMessage != null) {
            // Limpa erro do jogo se sucesso
            _errorMessage = null;
            dataChanged = true;
          }
          _errorCount = 0;

          if ([
            "FT",
            "AET",
            "PEN",
            "PST",
            "CANC",
            "ABD",
            "SUSP",
            "INT",
          ].contains(update.statusShort?.toUpperCase())) {
            if (_status != LiveFixturePollingStatus.finished)
              dataChanged = true;
            _status = LiveFixturePollingStatus.finished;
            _pollingTimer?.cancel();
            _generateGameFinishedInsight(update);
            print(
              "Jogo $fixtureId finalizado (${update.statusShort}). Polling parado.",
            );
          } else if (_status == LiveFixturePollingStatus.loadingFirst ||
              _status == LiveFixturePollingStatus.initial) {
            _status = LiveFixturePollingStatus.activePolling;
            dataChanged = true;
          } else if (_status != LiveFixturePollingStatus.activePolling) {
            _status =
                LiveFixturePollingStatus
                    .activePolling; // Garante que está ativo se não finalizado
            // dataChanged já pode ser true aqui
          }
        },
      );

      // Processar resultado das odds
      oddsResult.fold(
        (failure) {
          final newOddsErrorMessage = _mapFailureToMessage(failure);
          if (_oddsErrorMessage != newOddsErrorMessage) {
            _oddsErrorMessage = newOddsErrorMessage;
            dataChanged = true;
          }
          print(
            "Erro ao buscar odds ao vivo para $fixtureId: $_oddsErrorMessage",
          );
        },
        (odds) {
          final filteredOdds = _filterAndSortOddsMarkets(odds);
          if (!const DeepCollectionEquality().equals(_liveOdds, filteredOdds)) {
            _liveOdds = filteredOdds;
            dataChanged = true;
          }
          if (_oddsErrorMessage != null) {
            _oddsErrorMessage = null;
            dataChanged = true;
          }
          if (_liveOdds.isEmpty && odds.isNotEmpty && !dataChanged) {
            // Se o filtro resultou em lista vazia mas antes não era
            dataChanged = true;
          }
        },
      );

      // Se o jogo está ativo e temos dados, analisar insights e sugestões
      if (_status == LiveFixturePollingStatus.activePolling &&
          _liveData != null) {
        // A função de análise pode retornar true se algo mudou nos insights/sugestões
        bool analysisChanged = _analyzeAndUpdateLiveInsightsAndSuggestions(
          _liveData!,
          _previousLiveData,
          _liveOdds,
        );
        if (analysisChanged) dataChanged = true;
      }

      if (dataChanged) {
        notifyListeners();
      }
    } catch (e) {
      if (_status == LiveFixturePollingStatus.disposed) return;
      _errorMessage = "Erro geral no polling: ${e.toString()}";
      _status = LiveFixturePollingStatus.error;
      _pollingTimer?.cancel();
      notifyListeners();
    }
  }

  bool _isUnrecoverableError(Failure failure) {
    return failure is AuthenticationFailure ||
        (failure is ApiFailure &&
            (failure.message.toLowerCase().contains("fixture not found") ||
                failure.message.toLowerCase().contains(
                  "not found for this id",
                )));
  }

  List<PrognosticMarket> _filterAndSortOddsMarkets(
    List<PrognosticMarket> allMarkets,
  ) {
    const List<int> desiredMarketIds = [1, 12];
    List<PrognosticMarket> filtered =
        allMarkets.where((market) {
          if (desiredMarketIds.contains(market.marketId)) return true;
          if (market.marketName.toLowerCase().contains("goals over/under") &&
              market.options.any((o) => o.label.toLowerCase().contains("2.5")))
            return true;
          if (market.marketName.toLowerCase().contains("next goal"))
            return true;
          return false;
        }).toList();

    filtered.sort((a, b) {
      int getOrderScore(PrognosticMarket m) {
        if (m.marketId == 1) return 0;
        if (m.marketName.toLowerCase().contains("next goal")) return 1;
        if (m.marketName.toLowerCase().contains("goals over/under") &&
            m.options.any((o) => o.label.toLowerCase().contains("2.5")))
          return 2;
        if (m.marketId == 12) return 3;
        return 4;
      }

      return getOrderScore(a).compareTo(getOrderScore(b));
    });
    return filtered;
  }

  // Retorna true se insights ou sugestões foram realmente modificados
  bool _analyzeAndUpdateLiveInsightsAndSuggestions(
    LiveFixtureUpdate currentData,
    LiveFixtureUpdate? previousData,
    List<PrognosticMarket> currentOdds,
  ) {
    List<LiveGameInsight> newGeneratedInsights = [];
    List<LiveBetSuggestion> newGeneratedSuggestions = [];

    _detectRecentGoals(currentData, previousData, newGeneratedInsights);
    _detectRecentRedCards(currentData, previousData, newGeneratedInsights);
    _analyzeTeamPressure(currentData, newGeneratedInsights, currentOdds);
    _analyzeLateGamePotential(currentData, newGeneratedInsights, currentOdds);
    _generateLiveBetSuggestions(
      currentData,
      currentOdds,
      newGeneratedInsights,
      newGeneratedSuggestions,
    );

    bool insightsActuallyChanged = false;
    if (newGeneratedInsights.isNotEmpty) {
      for (var newInsight in newGeneratedInsights) {
        // Lógica para evitar spam de insights idênticos ou muito próximos
        if (!_liveInsights.any(
          (existing) =>
              existing.type == newInsight.type &&
              existing.relatedTeamId ==
                  newInsight.relatedTeamId && // Considera o time
              existing.description.substring(
                    0,
                    (existing.description.length * 0.8).round(),
                  ) ==
                  newInsight.description.substring(
                    0,
                    (newInsight.description.length * 0.8).round(),
                  ) && // Descrição similar
              DateTime.now().difference(existing.timestamp).inMinutes <
                  2, // Não o mesmo tipo de insight para o mesmo time em 2 min
        )) {
          _liveInsights.add(newInsight);
          insightsActuallyChanged = true;
        }
      }
      if (insightsActuallyChanged) {
        if (_liveInsights.length > 5) {
          _liveInsights = _liveInsights.sublist(_liveInsights.length - 5);
        }
        _liveInsights.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    }

    bool suggestionsActuallyChanged = false;
    if (newGeneratedSuggestions.isNotEmpty) {
      for (var newSug in newGeneratedSuggestions) {
        if (!_liveSuggestions.any(
          (s) =>
              s.marketName == newSug.marketName &&
              s.selectionName == newSug.selectionName &&
              DateTime.now().difference(s.timestamp).inMinutes <
                  5, // Não a mesma sugestão nos últimos 5 min
        )) {
          _liveSuggestions.add(newSug);
          suggestionsActuallyChanged = true;
        }
      }
      if (suggestionsActuallyChanged) {
        if (_liveSuggestions.length > 3) {
          _liveSuggestions = _liveSuggestions.sublist(
            _liveSuggestions.length - 3,
          );
        }
        _liveSuggestions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    }
    return insightsActuallyChanged || suggestionsActuallyChanged;
  }

  void _generateGameFinishedInsight(LiveFixtureUpdate data) {
    final insight = LiveGameInsight(
      type: LiveInsightType.custom,
      description:
          "Jogo finalizado: $_homeTeamName ${data.homeScore ?? '-'} - ${data.awayScore ?? '-'} $_awayTeamName",
      timestamp: DateTime.now(),
      icon: Icons.check_circle_outline,
      iconColor: Colors.grey,
    );
    if (!_liveInsights.any(
      (i) => i.type == insight.type && i.description == insight.description,
    )) {
      _liveInsights.insert(0, insight); // Adiciona no início
      if (_liveInsights.length > 5) {
        _liveInsights = _liveInsights.sublist(0, 5);
      }
    }
  }

  void _detectRecentGoals(
    LiveFixtureUpdate current,
    LiveFixtureUpdate? previous,
    List<LiveGameInsight> insights,
  ) {
    if (previous == null) return;
    final prevHomeScore = previous.homeScore ?? 0;
    final prevAwayScore = previous.awayScore ?? 0;
    final currHomeScore = current.homeScore ?? 0;
    final currAwayScore = current.awayScore ?? 0;

    LiveGameEvent? findGoalEvent(int teamId, List<LiveGameEvent> events) {
      return events.lastWhereOrNull(
        (e) => e.type.toLowerCase() == "goal" && e.teamId == teamId,
      );
    }

    if (currHomeScore > prevHomeScore) {
      final goalEvent = findGoalEvent(_homeTeamId, current.events);
      insights.add(
        LiveGameInsight(
          type: LiveInsightType.goal_scored,
          description:
              "GOL! ${_homeTeamName} marca${goalEvent?.playerName != null ? ' por ${goalEvent!.playerName}' : ''}! Placar: $currHomeScore-$currAwayScore",
          timestamp: DateTime.now(),
          relatedTeamId: _homeTeamId,
          relatedTeamName: _homeTeamName,
          icon: Icons.sports_soccer,
          iconColor: Colors.green.shade700,
        ),
      );
    }
    if (currAwayScore > prevAwayScore) {
      final goalEvent = findGoalEvent(_awayTeamId, current.events);
      insights.add(
        LiveGameInsight(
          type: LiveInsightType.goal_scored,
          description:
              "GOL! ${_awayTeamName} marca${goalEvent?.playerName != null ? ' por ${goalEvent!.playerName}' : ''}! Placar: $currHomeScore-$currAwayScore",
          timestamp: DateTime.now(),
          relatedTeamId: _awayTeamId,
          relatedTeamName: _awayTeamName,
          icon: Icons.sports_soccer,
          iconColor: Colors.green.shade700,
        ),
      );
    }
  }

  void _detectRecentRedCards(
    LiveFixtureUpdate current,
    LiveFixtureUpdate? previous,
    List<LiveGameInsight> insights,
  ) {
    if (previous == null) return;
    final newRedCardEvent = current.events.firstWhereOrNull(
      (event) =>
          event.type.toLowerCase() == "card" &&
          event.detail.toLowerCase().contains("red card") &&
          previous.events.firstWhereOrNull(
                (prevEvent) =>
                    prevEvent.type == event.type &&
                    prevEvent.detail == event.detail &&
                    prevEvent.playerId == event.playerId &&
                    prevEvent.timeElapsed == event.timeElapsed,
              ) ==
              null,
    );

    if (newRedCardEvent != null) {
      String teamName =
          newRedCardEvent.teamName ??
          (newRedCardEvent.teamId == _homeTeamId
              ? _homeTeamName
              : _awayTeamName);
      insights.add(
        LiveGameInsight(
          type: LiveInsightType.card_issued,
          description:
              "CARTÃO VERMELHO para ${newRedCardEvent.playerName ?? 'jogador'} do ${teamName}!",
          timestamp: DateTime.now(),
          relatedTeamId: newRedCardEvent.teamId,
          relatedTeamName: teamName,
          icon: Icons.style,
          iconColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _analyzeTeamPressure(
    LiveFixtureUpdate current,
    List<LiveGameInsight> insights,
    List<PrognosticMarket> currentOdds,
  ) {
    final homeStats = current.homeTeamLiveStats;
    final awayStats = current.awayTeamLiveStats;
    final elapsed = current.elapsedMinutes ?? 0;

    if (homeStats == null || awayStats == null || elapsed < 15 || elapsed > 80)
      return; // Analisar em momentos chave

    double homeXG = homeStats.expectedGoalsLive ?? 0;
    double awayXG = awayStats.expectedGoalsLive ?? 0;
    int homeShotsTotal = homeStats.totalShots ?? 0;
    int awayShotsTotal = awayStats.totalShots ?? 0;

    // Time da casa pressionando
    if (homeXG > (awayXG + 0.5) &&
        homeShotsTotal > (awayShotsTotal + 3) &&
        (current.homeScore ?? 0) <= (current.awayScore ?? 0)) {
      if (!_liveInsights.any(
        (i) =>
            i.type == LiveInsightType.pressure &&
            i.relatedTeamId == _homeTeamId &&
            DateTime.now().difference(i.timestamp).inMinutes < 7,
      )) {
        insights.add(
          LiveGameInsight(
            type: LiveInsightType.pressure,
            description:
                "$_homeTeamName aumenta a pressão! (xG: ${homeXG.toStringAsFixed(2)}, Finalizações: $homeShotsTotal)",
            timestamp: DateTime.now(),
            relatedTeamId: _homeTeamId,
            relatedTeamName: _homeTeamName,
            icon: Icons.trending_up,
            iconColor: Colors.blue.shade600,
          ),
        );
      }
    }
    // Time visitante pressionando
    else if (awayXG > (homeXG + 0.5) &&
        awayShotsTotal > (homeShotsTotal + 3) &&
        (current.awayScore ?? 0) <= (current.homeScore ?? 0)) {
      if (!_liveInsights.any(
        (i) =>
            i.type == LiveInsightType.pressure &&
            i.relatedTeamId == _awayTeamId &&
            DateTime.now().difference(i.timestamp).inMinutes < 7,
      )) {
        insights.add(
          LiveGameInsight(
            type: LiveInsightType.pressure,
            description:
                "$_awayTeamName aumenta a pressão! (xG: ${awayXG.toStringAsFixed(2)}, Finalizações: $awayShotsTotal)",
            timestamp: DateTime.now(),
            relatedTeamId: _awayTeamId,
            relatedTeamName: _awayTeamName,
            icon: Icons.trending_up,
            iconColor: Colors.blue.shade600,
          ),
        );
      }
    }
  }

  void _analyzeLateGamePotential(
    LiveFixtureUpdate current,
    List<LiveGameInsight> insights,
    List<PrognosticMarket> currentOdds,
  ) {
    final elapsed = current.elapsedMinutes ?? 0;
    final homeScore = current.homeScore ?? 0;
    final awayScore = current.awayScore ?? 0;

    if (elapsed >= 78 && elapsed <= 90) {
      if ((homeScore - awayScore).abs() <= 1) {
        if (!_liveInsights.any(
          (i) =>
              i.type == LiveInsightType.late_game_potential &&
              DateTime.now().difference(i.timestamp).inMinutes < 10,
        )) {
          insights.add(
            LiveGameInsight(
              type: LiveInsightType.late_game_potential,
              description:
                  "Minutos finais! Placar ${homeScore}-${awayScore}. Jogo aberto!",
              timestamp: DateTime.now(),
              icon: Icons.hourglass_bottom,
              iconColor: Colors.deepOrange,
            ),
          );
        }
      }
    }
  }

  void _generateLiveBetSuggestions(
    LiveFixtureUpdate gameData,
    List<PrognosticMarket> liveOdds,
    List<LiveGameInsight> currentInsights,
    List<LiveBetSuggestion> suggestionsOutput,
  ) {
    final currentMinute = gameData.elapsedMinutes ?? 0;
    final currentScore =
        "${gameData.homeScore ?? '-'}-${gameData.awayScore ?? '-'}";

    // Cenário 1: Time da Casa Pressionando para Virar/Marcar
    final homePressureInsight = currentInsights.firstWhereOrNull(
      (i) =>
          i.type == LiveInsightType.pressure && i.relatedTeamId == _homeTeamId,
    );

    if (homePressureInsight != null &&
        (gameData.homeScore ?? 0) <= (gameData.awayScore ?? 0)) {
      final nextGoalMarket = liveOdds.firstWhereOrNull(
        (o) => o.marketName.toLowerCase().contains("next goal"),
      );
      if (nextGoalMarket != null) {
        final homeToScoreNextOpt = nextGoalMarket.options.firstWhereOrNull(
          (opt) =>
              opt.label.toLowerCase() == _homeTeamName.toLowerCase() ||
              opt.label.toLowerCase() == "home",
        );

        if (homeToScoreNextOpt != null) {
          double oddVal = double.tryParse(homeToScoreNextOpt.odd) ?? 0.0;
          if (oddVal >= 1.9 && oddVal <= 4.0) {
            // Odds interessantes
            suggestionsOutput.add(
              LiveBetSuggestion(
                id: _uuid.v4(),
                fixtureId: gameData.fixtureId,
                marketName: "Próximo Gol",
                selectionName: _homeTeamName,
                currentOdd: homeToScoreNextOpt.odd,
                reasoning:
                    "$_homeTeamName pressionando intensamente (baseado em xG/chutes) e buscando o resultado.",
                basedOnInsight: homePressureInsight.type,
                strength: BetSuggestionStrength.medium,
                timestamp: DateTime.now(),
                suggestedAtMinute: currentMinute,
                currentScore: currentScore,
              ),
            );
          }
        }
      }
    }
    // Adicionar mais cenários de sugestão aqui...
  }

  Future<void> forceRefresh() async {
    _errorCount = 0;
    bool needsPollingRestart = false;
    if (_status == LiveFixturePollingStatus.finished) {
      print("Jogo $fixtureId já finalizado, buscando última atualização...");
    } else if (_pollingTimer == null || !_pollingTimer!.isActive) {
      needsPollingRestart = true;
    }

    await _fetchAllLiveInfo(isInitialLoad: true);

    if (needsPollingRestart && _status != LiveFixturePollingStatus.finished) {
      print("Reiniciando polling para fixture $fixtureId após forceRefresh.");
      _pollingTimer?.cancel();
      _startPolling();
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Servidor API: ${failure.message}';
      case NetworkFailure:
        return 'Rede: ${failure.message}';
      case AuthenticationFailure:
        return 'Autenticação API: ${failure.message}';
      case ApiFailure:
        return 'API: ${failure.message}';
      case NoDataFailure:
        return failure.message;
      default:
        return 'Erro ao vivo: ${failure.message}';
    }
  }

  @override
  void dispose() {
    print(
      "LiveFixtureProvider para fixture $fixtureId sendo disposed. Parando timers.",
    );
    _status = LiveFixturePollingStatus.disposed;
    _pollingTimer?.cancel();
    super.dispose();
  }
}
