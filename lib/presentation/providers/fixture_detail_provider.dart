// lib/presentation/providers/fixture_detail_provider.dart
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart'; // Para mockar Either
import 'package:collection/collection.dart'; // Para firstWhereOrNull
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_full_data.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';

import '../../domain/usecases/get_fixture_statistics_usecase.dart';
import '../../domain/usecases/get_odds_usecase.dart';
import '../../domain/usecases/get_h2h_usecase.dart';

enum FixtureDetailOverallStatus {
  initial,
  loading,
  partiallyLoaded,
  fullyLoaded,
  error
}

class FixtureDetailProvider with ChangeNotifier {
  final GetFixtureStatisticsUseCase _getFixtureStatsUseCase;
  final GetOddsUseCase _getOddsUseCase;
  final GetH2HUseCase _getH2HUseCase;
  final Fixture baseFixture;
  bool _isDisposed = false;

  FixtureDetailProvider({
    required this.baseFixture,
    required GetFixtureStatisticsUseCase getFixtureStatsUseCase,
    required GetOddsUseCase getOddsUseCase,
    required GetH2HUseCase getH2HUseCase,
  })  : _getFixtureStatsUseCase = getFixtureStatsUseCase,
        _getOddsUseCase = getOddsUseCase,
        _getH2HUseCase = getH2HUseCase {
    _fixtureFullData = FixtureFullData(
      baseFixture: baseFixture,
      odds: [],
      statsStatus: SectionStatus.initial,
      oddsStatus: SectionStatus.initial,
      h2hStatus: SectionStatus.initial,
    );
  }

  FixtureDetailOverallStatus _overallStatus =
      FixtureDetailOverallStatus.initial;
  FixtureFullData? _fixtureFullData;
  String? _generalErrorMessage;
  bool _hasFetchedOnce = false;

  FixtureDetailOverallStatus get overallStatus => _overallStatus;
  FixtureFullData? get fixtureFullData => _fixtureFullData;
  String? get generalErrorMessage => _generalErrorMessage;

  final bool _useMockData = true; // Mude para false para usar a API real

  Future<void> fetchFixtureDetails({bool forceRefresh = false}) async {
    if (_isDisposed) return;
    // ... (lógica de prevenção de fetch como antes) ...
    if (_overallStatus == FixtureDetailOverallStatus.loading && !forceRefresh)
      return;
    if (!forceRefresh &&
        _hasFetchedOnce &&
        _overallStatus == FixtureDetailOverallStatus.fullyLoaded) return;

    _overallStatus = FixtureDetailOverallStatus.loading;
    if (forceRefresh || !_hasFetchedOnce) {
      _fixtureFullData = FixtureFullData(
        baseFixture: baseFixture,
        odds: [],
        statsStatus: SectionStatus.loading,
        oddsStatus: SectionStatus.loading,
        h2hStatus: SectionStatus.loading,
      );
    } else {/* ... lógica para atualizar status de seções individuais ... */}
    _generalErrorMessage = null;

    Future.microtask(() {
      if (!_isDisposed && _overallStatus == FixtureDetailOverallStatus.loading)
        notifyListeners();
    });

    if (kDebugMode)
      print(
          "FixtureDetailProvider: Buscando detalhes para ${baseFixture.id} (mock: $_useMockData)...");

    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (_isDisposed) return;

      // Mock FixtureStatsEntity
      final mockHomeStats = TeamFixtureStats(
        teamId: baseFixture.homeTeam.id, teamName: baseFixture.homeTeam.name,
        teamLogoUrl: baseFixture.homeTeam.logoUrl,
        expectedGoals:
            1.5 + (baseFixture.homeTeam.id % 10 * 0.1), // Alguma variação
        shotsTotal: 12, shotsOnGoal: 5, corners: 6, ballPossessionPercent: 55.0,
        averageCornersGenerated: 5.8, // Média da competição
      );
      final mockAwayStats = TeamFixtureStats(
        teamId: baseFixture.awayTeam.id,
        teamName: baseFixture.awayTeam.name,
        teamLogoUrl: baseFixture.awayTeam.logoUrl,
        expectedGoals: 1.2 + (baseFixture.awayTeam.id % 10 * 0.1),
        shotsTotal: 9,
        shotsOnGoal: 3,
        corners: 4,
        ballPossessionPercent: 45.0,
        averageCornersGenerated: 4.7,
      );
      final mockFixtureStats = FixtureStatsEntity(
          fixtureId: baseFixture.id,
          homeTeam: mockHomeStats,
          awayTeam: mockAwayStats);

      // Mock Odds
      final mockOdds = [
        PrognosticMarket(
            marketId: 1,
            marketName: "Resultado Final (Mock)",
            options: [
              OddOption(
                  label: "Casa",
                  odd: (1.8 + Random().nextDouble()).toStringAsFixed(2),
                  probability: 0.50),
              OddOption(
                  label: "Empate",
                  odd: (3.2 + Random().nextDouble()).toStringAsFixed(2),
                  probability: 0.28),
              OddOption(
                  label: "Fora",
                  odd: (4.0 + Random().nextDouble()).toStringAsFixed(2),
                  probability: 0.22),
            ],
            suggestedOption:
                const OddOption(label: "Casa", odd: "1.85", probability: 0.50)),
        PrognosticMarket(
            marketId: 5,
            marketName: "Gols Acima/Abaixo (Mock)",
            options: [
              OddOption(label: "Mais de 2.5", odd: "1.90", probability: 0.52),
              OddOption(label: "Menos de 2.5", odd: "1.90", probability: 0.48),
            ],
            suggestedOption: const OddOption(
                label: "Mais de 2.5", odd: "1.90", probability: 0.52)),
      ];

      // Mock H2H
      final mockH2H = List.generate(
          3,
          (i) => Fixture(
              id: baseFixture.id - 1000 - i,
              date: baseFixture.date.subtract(Duration(days: 100 + i * 50)),
              statusShort: "FT",
              statusLong: "Match Finished",
              homeTeam: baseFixture.homeTeam,
              awayTeam:
                  baseFixture.awayTeam, // Simplificado, poderia inverter times
              homeGoals: Random().nextInt(3),
              awayGoals: Random().nextInt(3),
              league: baseFixture.league // Reusa a liga do fixture base
              ));

      _fixtureFullData = _fixtureFullData?.copyWith(
        fixtureStats: mockFixtureStats,
        statsStatus: SectionStatus.loaded,
        odds: mockOdds,
        oddsStatus: SectionStatus.loaded,
        h2hFixtures: mockH2H,
        h2hStatus: SectionStatus.loaded,
      );
      _hasFetchedOnce = true;
      _determineOverallStatusAfterFetch();
    } else {
      // ===== CÓDIGO REAL DA API (COMENTADO) =====
      // final List<Future> futures = [];
      // if (shouldFetchStats || forceRefresh) futures.add(_fetchStats());
      // ... (como na implementação anterior de fetchFixtureDetails)
      // try {
      //   if (futures.isNotEmpty) await Future.wait(futures);
      //   if (!_isDisposed) _hasFetchedOnce = true;
      // } catch (e) { /* ... */ }
      // finally { if (!_isDisposed) _determineOverallStatusAfterFetch(); }
      // ============================================
      await Future.delayed(const Duration(milliseconds: 300));
      _fixtureFullData = _fixtureFullData?.copyWith(
          statsStatus: SectionStatus.error,
          oddsStatus: SectionStatus.error,
          h2hStatus: SectionStatus.error,
          statsErrorMessage: "API real desativada",
          oddsErrorMessage: "API real desativada",
          h2hErrorMessage: "API real desativada");
      _determineOverallStatusAfterFetch();
    }
    if (!_isDisposed) notifyListeners();
  }

  // _determineOverallStatusAfterFetch, _fetchStats, _fetchOdds, _fetchH2H,
  // _filterAndSortOddsMarkets, _mapFailureToMessage, dispose
  // DEVEM SER MANTIDOS COMO NA ÚLTIMA VERSÃO COMPLETA QUE VOCÊ TEM.
  // A mudança principal é no fetchFixtureDetails para usar _useMockData.
  // Vou colar stubs para eles, mas você deve usar as implementações completas anteriores.
  void _determineOverallStatusAfterFetch() {
    if (_isDisposed || _fixtureFullData == null) return;
    bool anyError = _fixtureFullData!.statsStatus == SectionStatus.error ||
        _fixtureFullData!.oddsStatus == SectionStatus.error ||
        _fixtureFullData!.h2hStatus == SectionStatus.error;
    bool anyLoading = _fixtureFullData!.statsStatus == SectionStatus.loading ||
        _fixtureFullData!.oddsStatus == SectionStatus.loading ||
        _fixtureFullData!.h2hStatus == SectionStatus.loading;
    bool anyInitial = _fixtureFullData!.statsStatus == SectionStatus.initial ||
        _fixtureFullData!.oddsStatus == SectionStatus.initial ||
        _fixtureFullData!.h2hStatus == SectionStatus.initial;
    bool allSectionsAttemptedOrDone = !anyLoading && !anyInitial;
    if (allSectionsAttemptedOrDone) {
      if (!anyError) {
        _overallStatus = FixtureDetailOverallStatus.fullyLoaded;
        _generalErrorMessage = null;
      } else {
        _overallStatus = FixtureDetailOverallStatus
            .partiallyLoaded; /* ... set generalErrorMessage ... */
      }
    } else {
      _overallStatus = FixtureDetailOverallStatus.loading;
    }
  }

  Future<void> _fetchStats() async {
    /* ... implementação real comentada, ou simular erro/noData se _useMockData for false ... */
  }
  Future<void> _fetchOdds() async {/* ... implementação real comentada ... */}
  Future<void> _fetchH2H() async {/* ... implementação real comentada ... */}
  List<PrognosticMarket> _filterAndSortOddsMarkets(
      List<PrognosticMarket> allMarkets) {
    /* ... como antes ... */ return allMarkets;
  }

  String _mapFailureToMessage(Failure failure) {
    /* ... como antes ... */ return failure.message;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}


// lib/presentation/providers/fixture_detail_provider.dart
/*
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Para ChangeNotifier
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_full_data.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';

// Core

import '../../core/config/app_constants.dart'; // Para preferredBookmakerId

// Domain

import '../../domain/usecases/get_fixture_statistics_usecase.dart';
import '../../domain/usecases/get_odds_usecase.dart';
import '../../domain/usecases/get_h2h_usecase.dart';
import 'package:collection/collection.dart'; // Para firstWhereOrNull

enum FixtureDetailOverallStatus {
  initial,
  loading,
  partiallyLoaded,
  fullyLoaded,
  error
}

class FixtureDetailProvider with ChangeNotifier {
  final GetFixtureStatisticsUseCase _getFixtureStatsUseCase;
  final GetOddsUseCase _getOddsUseCase;
  final GetH2HUseCase _getH2HUseCase;

  final Fixture baseFixture;

  FixtureDetailProvider({
    required this.baseFixture,
    required GetFixtureStatisticsUseCase getFixtureStatsUseCase,
    required GetOddsUseCase getOddsUseCase,
    required GetH2HUseCase getH2HUseCase,
  })  : _getFixtureStatsUseCase = getFixtureStatsUseCase,
        _getOddsUseCase = getOddsUseCase,
        _getH2HUseCase = getH2HUseCase {
    _fixtureFullData = FixtureFullData(
      baseFixture: baseFixture,
      odds: [],
      statsStatus: SectionStatus.initial,
      oddsStatus: SectionStatus.initial,
      h2hStatus: SectionStatus.initial,
    );
  }

  FixtureDetailOverallStatus _overallStatus =
      FixtureDetailOverallStatus.initial;
  FixtureFullData? _fixtureFullData;
  String? _generalErrorMessage;

  FixtureDetailOverallStatus get overallStatus => _overallStatus;
  FixtureFullData? get fixtureFullData => _fixtureFullData;
  String? get generalErrorMessage => _generalErrorMessage;

  bool _isDisposed = false;
  bool _hasFetchedOnce = false;

  Future<void> fetchFixtureDetails({bool forceRefresh = false}) async {
    if (_isDisposed) return;
    if (_overallStatus == FixtureDetailOverallStatus.loading && !forceRefresh)
      return;

    bool initialFetch = !_hasFetchedOnce;

    // Se não for refresh forçado e já tivermos carregado tudo uma vez, não faz nada.
    if (!forceRefresh &&
        _hasFetchedOnce &&
        _overallStatus == FixtureDetailOverallStatus.fullyLoaded) {
      if (kDebugMode)
        print(
            "FixtureDetailProvider: Dados já totalmente carregados para ${baseFixture.id}, sem forceRefresh.");
      return;
    }
    // Se não for refresh forçado e já tentamos carregar (mesmo que parcialmente ou com erro),
    // e não há seções em 'initial', não refaz automaticamente.
    if (!forceRefresh &&
        _hasFetchedOnce &&
        _fixtureFullData?.statsStatus != SectionStatus.initial &&
        _fixtureFullData?.oddsStatus != SectionStatus.initial &&
        _fixtureFullData?.h2hStatus != SectionStatus.initial) {
      // print("FixtureDetailProvider: Seções já tentadas, sem forceRefresh.");
      return;
    }

    _overallStatus = FixtureDetailOverallStatus.loading;
    if (forceRefresh || initialFetch) {
      _fixtureFullData = FixtureFullData(
        // Reseta para o estado inicial de carregamento
        baseFixture: baseFixture,
        odds: [],
        statsStatus: SectionStatus.loading,
        oddsStatus: SectionStatus.loading,
        h2hStatus: SectionStatus.loading,
        statsErrorMessage: null,
        oddsErrorMessage: null,
        h2hErrorMessage: null,
      );
    } else {
      // Se não for forceRefresh e não for initialFetch, só atualiza o status geral
      // e os status das seções que ainda estão 'initial' ou 'error'.
      _fixtureFullData = _fixtureFullData?.copyWith(
          statsStatus: _fixtureFullData?.statsStatus == SectionStatus.initial ||
                  _fixtureFullData?.statsStatus == SectionStatus.error
              ? SectionStatus.loading
              : _fixtureFullData?.statsStatus,
          oddsStatus: _fixtureFullData?.oddsStatus == SectionStatus.initial ||
                  _fixtureFullData?.oddsStatus == SectionStatus.error
              ? SectionStatus.loading
              : _fixtureFullData?.oddsStatus,
          h2hStatus: _fixtureFullData?.h2hStatus == SectionStatus.initial ||
                  _fixtureFullData?.h2hStatus == SectionStatus.error
              ? SectionStatus.loading
              : _fixtureFullData?.h2hStatus,
          clearStatsError: true,
          clearOddsError: true,
          clearH2HError: true);
    }
    _generalErrorMessage = null;
    if (!_isDisposed) notifyListeners();

    final List<Future> futures = [];
    if (_fixtureFullData?.statsStatus == SectionStatus.loading)
      futures.add(_fetchStats());
    if (_fixtureFullData?.oddsStatus == SectionStatus.loading)
      futures.add(_fetchOdds());
    if (_fixtureFullData?.h2hStatus == SectionStatus.loading)
      futures.add(_fetchH2H());

    if (futures.isEmpty) {
      // Nada a buscar (ex: tudo já carregado ou em erro e não é forceRefresh)
      _determineOverallStatusAfterFetch();
      if (!_isDisposed) notifyListeners();
      return;
    }

    try {
      await Future.wait(futures);
      if (!_isDisposed) _hasFetchedOnce = true;
    } catch (e) {
      // Future.wait pode lançar erro se um dos futures lançar erro não tratado internamente.
      // Nossas funções _fetch... já convertem para Either, então não deveriam lançar aqui.
      // Mas como precaução:
      if (_isDisposed) return;
      _generalErrorMessage = "Erro inesperado durante buscas: ${e.toString()}";
      // Marca todas as seções que ainda estavam carregando como erro
      _fixtureFullData = _fixtureFullData?.copyWith(
        statsStatus: _fixtureFullData?.statsStatus == SectionStatus.loading
            ? SectionStatus.error
            : _fixtureFullData?.statsStatus,
        oddsStatus: _fixtureFullData?.oddsStatus == SectionStatus.loading
            ? SectionStatus.error
            : _fixtureFullData?.oddsStatus,
        h2hStatus: _fixtureFullData?.h2hStatus == SectionStatus.loading
            ? SectionStatus.error
            : _fixtureFullData?.h2hStatus,
        statsErrorMessage: _fixtureFullData?.statsStatus == SectionStatus.error
            ? (_fixtureFullData?.statsErrorMessage ?? e.toString())
            : null,
        oddsErrorMessage: _fixtureFullData?.oddsStatus == SectionStatus.error
            ? (_fixtureFullData?.oddsErrorMessage ?? e.toString())
            : null,
        h2hErrorMessage: _fixtureFullData?.h2hStatus == SectionStatus.error
            ? (_fixtureFullData?.h2hErrorMessage ?? e.toString())
            : null,
      );
    } finally {
      if (!_isDisposed) {
        _determineOverallStatusAfterFetch();
        notifyListeners();
      }
    }
  }

  void _determineOverallStatusAfterFetch() {
    if (_isDisposed || _fixtureFullData == null) return;

    bool anyError = _fixtureFullData!.statsStatus == SectionStatus.error ||
        _fixtureFullData!.oddsStatus == SectionStatus.error ||
        _fixtureFullData!.h2hStatus == SectionStatus.error;
    bool anyLoading = _fixtureFullData!.statsStatus == SectionStatus.loading ||
        _fixtureFullData!.oddsStatus == SectionStatus.loading ||
        _fixtureFullData!.h2hStatus == SectionStatus.loading;
    bool anyInitial = _fixtureFullData!.statsStatus == SectionStatus.initial ||
        _fixtureFullData!.oddsStatus == SectionStatus.initial ||
        _fixtureFullData!.h2hStatus == SectionStatus.initial;

    bool allSectionsAttemptedOrDone = !anyLoading && !anyInitial;

    if (allSectionsAttemptedOrDone) {
      if (!anyError) {
        // Nenhuma seção com erro
        _overallStatus = FixtureDetailOverallStatus.fullyLoaded;
        _generalErrorMessage = null;
      } else {
        // Pelo menos uma seção com erro
        _overallStatus = FixtureDetailOverallStatus.partiallyLoaded;
        List<String> errorSections = [];
        if (_fixtureFullData!.statsStatus == SectionStatus.error)
          errorSections.add("estatísticas");
        if (_fixtureFullData!.oddsStatus == SectionStatus.error)
          errorSections.add("odds");
        if (_fixtureFullData!.h2hStatus == SectionStatus.error)
          errorSections.add("H2H");
        _generalErrorMessage = errorSections.isNotEmpty
            ? "Falha ao carregar: ${errorSections.join(', ')}."
            : "Alguns dados não puderam ser carregados.";
      }
    } else {
      // Ainda carregando ou alguma seção nem tentou
      _overallStatus = FixtureDetailOverallStatus
          .loading; // ou partiallyLoaded se algumas já terminaram
    }
  }

  Future<void> _fetchStats() async {
    if (_isDisposed) return;
    // Não precisa de notifyListeners aqui, será feito pelo fetchFixtureDetails

    final result = await _getFixtureStatsUseCase(
      fixtureId: baseFixture.id,
      homeTeamId: baseFixture.homeTeam.id,
      awayTeamId: baseFixture.awayTeam.id,
    );

    if (_isDisposed) return;
    result.fold(
      (failure) {
        _fixtureFullData = _fixtureFullData?.copyWith(
          statsStatus: SectionStatus.error,
          statsErrorMessage: _mapFailureToMessage(failure),
        );
      },
      (stats) {
        _fixtureFullData = _fixtureFullData?.copyWith(
          fixtureStats: stats,
          statsStatus: (stats == null ||
                  (stats.homeTeam == null && stats.awayTeam == null))
              ? SectionStatus.noData
              : SectionStatus.loaded,
          statsErrorMessage: (stats == null ||
                  (stats.homeTeam == null && stats.awayTeam == null))
              ? "Estatísticas pré-jogo não disponíveis."
              : null,
        );
      },
    );
  }

  Future<void> _fetchOdds() async {
    if (_isDisposed) return;

    final result = await _getOddsUseCase(
        fixtureId: baseFixture.id,
        bookmakerId:
            AppConstants.preferredBookmakerId // Usar o bookmaker preferido
        );

    if (_isDisposed) return;
    result.fold(
      (failure) {
        _fixtureFullData = _fixtureFullData?.copyWith(
            oddsStatus: SectionStatus.error,
            oddsErrorMessage: _mapFailureToMessage(failure),
            odds: []);
      },
      (oddsList) {
        final filteredOdds = _filterAndSortOddsMarkets(oddsList);
        _fixtureFullData = _fixtureFullData?.copyWith(
          odds: filteredOdds,
          oddsStatus: filteredOdds.isEmpty
              ? SectionStatus.noData
              : SectionStatus.loaded,
          oddsErrorMessage: filteredOdds.isEmpty
              ? "Nenhuma odd encontrada para os mercados de interesse."
              : null,
        );
      },
    );
  }

  Future<void> _fetchH2H() async {
    if (_isDisposed) return;

    final result = await _getH2HUseCase(
      team1Id: baseFixture.homeTeam.id,
      team2Id: baseFixture.awayTeam.id,
      lastN: 5, // Últimos 5 confrontos
      status: 'FT', // Apenas jogos finalizados
    );

    if (_isDisposed) return;
    result.fold(
      (failure) {
        _fixtureFullData = _fixtureFullData?.copyWith(
          h2hStatus: SectionStatus.error,
          h2hErrorMessage: _mapFailureToMessage(failure),
        );
      },
      (h2hList) {
        _fixtureFullData = _fixtureFullData?.copyWith(
          h2hFixtures: h2hList,
          h2hStatus:
              h2hList.isEmpty ? SectionStatus.noData : SectionStatus.loaded,
          h2hErrorMessage: h2hList.isEmpty
              ? "Nenhum histórico de confronto direto recente encontrado."
              : null,
        );
      },
    );
  }

  List<PrognosticMarket> _filterAndSortOddsMarkets(
      List<PrognosticMarket> allMarkets) {
    const List<int> desiredMarketIds = [1, 12]; // Match Winner, BTTS
    List<PrognosticMarket> filtered = allMarkets.where((market) {
      if (desiredMarketIds.contains(market.marketId)) return true;
      // Para Over/Under, checar nome e se tem a linha "2.5"
      if (market.marketName.toLowerCase().contains("goals over/under") &&
          market.options.any((o) => o.label.toLowerCase().contains("2.5")))
        return true;
      return false;
    }).toList();

    filtered.sort((a, b) {
      int getOrderScore(PrognosticMarket m) {
        if (m.marketId == 1) return 0; // Match Winner primeiro
        if (m.marketName.toLowerCase().contains("goals over/under") &&
            m.options.any((o) => o.label.toLowerCase().contains("2.5")))
          return 1; // Over/Under 2.5
        if (m.marketId == 12) return 2; // BTTS
        return 3; // Outros
      }

      return getOrderScore(a).compareTo(getOrderScore(b));
    });
    return filtered;
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) return 'Erro no servidor: ${failure.message}';
    if (failure is NetworkFailure)
      return 'Falha de conexão: ${failure.message}';
    if (failure is AuthenticationFailure)
      return 'Erro de autenticação: ${failure.message}';
    if (failure is ApiFailure) return 'Erro da API: ${failure.message}';
    if (failure is NoDataFailure)
      return failure.message; // Já é uma mensagem específica
    return 'Erro inesperado ao carregar dados: ${failure.message}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (kDebugMode)
      print("FixtureDetailProvider para ${baseFixture.id} foi disposed.");
    super.dispose();
  }
}


*/