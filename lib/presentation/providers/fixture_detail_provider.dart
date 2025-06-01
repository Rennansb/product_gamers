// lib/presentation/providers/fixture_detail_provider.dart
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
