// lib/presentation/providers/fixture_detail_provider.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_full_data.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
// Importar PrognosticMarket
import '../../domain/usecases/get_fixture_statistics_usecase.dart';
import '../../domain/usecases/get_odds_usecase.dart'; // Importar GetOddsUseCase
import '../../domain/usecases/get_h2h_usecase.dart';
import 'package:collection/collection.dart'; // Para firstWhereOrNull, se usado em outro lugar

enum FixtureDetailOverallStatus {
  initial,
  loading,
  partiallyLoaded,
  fullyLoaded,
  error,
}

class FixtureDetailProvider with ChangeNotifier {
  final GetFixtureStatisticsUseCase _getFixtureStatsUseCase;
  final GetOddsUseCase _getOddsUseCase; // Usar o nome correto
  final GetH2HUseCase _getH2HUseCase;

  final Fixture baseFixture;

  FixtureDetailProvider({
    required this.baseFixture,
    required GetFixtureStatisticsUseCase getFixtureStatsUseCase,
    required GetOddsUseCase getOddsUseCase, // Nome correto
    required GetH2HUseCase getH2HUseCase,
  }) : _getFixtureStatsUseCase = getFixtureStatsUseCase,
       _getOddsUseCase = getOddsUseCase, // Nome correto
       _getH2HUseCase = getH2HUseCase {
    _fixtureFullData = FixtureFullData(baseFixture: baseFixture, odds: []);
  }

  FixtureDetailOverallStatus _overallStatus =
      FixtureDetailOverallStatus.initial;
  FixtureFullData? _fixtureFullData;
  String? _generalErrorMessage;

  FixtureDetailOverallStatus get overallStatus => _overallStatus;
  FixtureFullData? get fixtureFullData => _fixtureFullData;
  String? get generalErrorMessage => _generalErrorMessage;

  bool _hasFetchedOnce = false;

  Future<void> fetchFixtureDetails({bool forceRefresh = false}) async {
    if (_overallStatus == FixtureDetailOverallStatus.loading && !forceRefresh)
      return;
    if (_hasFetchedOnce &&
        !forceRefresh &&
        _overallStatus != FixtureDetailOverallStatus.error)
      return;

    _overallStatus = FixtureDetailOverallStatus.loading;
    if (forceRefresh ||
        _fixtureFullData == null ||
        _fixtureFullData!.baseFixture.id != baseFixture.id) {
      // Reseta se for fixture diferente
      _fixtureFullData = FixtureFullData(baseFixture: baseFixture, odds: []);
      _hasFetchedOnce = false; // Força recarga de tudo se o fixture mudou
    }
    _generalErrorMessage = null;
    notifyListeners();

    final List<Future> futures = [
      _fetchStats(forceRefresh: forceRefresh || !_hasFetchedOnce),
      _fetchOdds(forceRefresh: forceRefresh || !_hasFetchedOnce),
      _fetchH2H(forceRefresh: forceRefresh || !_hasFetchedOnce),
    ];

    try {
      await Future.wait(futures);
      _hasFetchedOnce = true;

      // Reavaliar status geral
      bool anyError =
          _fixtureFullData!.statsStatus == SectionStatus.error ||
          _fixtureFullData!.oddsStatus == SectionStatus.error ||
          _fixtureFullData!.h2hStatus == SectionStatus.error;
      bool anyLoading =
          _fixtureFullData!.statsStatus == SectionStatus.loading ||
          _fixtureFullData!.oddsStatus == SectionStatus.loading ||
          _fixtureFullData!.h2hStatus == SectionStatus.loading;
      bool allNoData =
          _fixtureFullData!.statsStatus == SectionStatus.noData &&
          _fixtureFullData!.oddsStatus == SectionStatus.noData &&
          _fixtureFullData!.h2hStatus == SectionStatus.noData;

      if (anyError && !anyLoading) {
        // Se há erros e nada mais carregando
        _overallStatus = FixtureDetailOverallStatus.error;
        // Montar uma mensagem de erro geral mais específica se possível
        List<String> errorMessages = [];
        if (_fixtureFullData!.statsStatus == SectionStatus.error)
          errorMessages.add("estatísticas");
        if (_fixtureFullData!.oddsStatus == SectionStatus.error)
          errorMessages.add("odds");
        if (_fixtureFullData!.h2hStatus == SectionStatus.error)
          errorMessages.add("H2H");
        _generalErrorMessage =
            "Falha ao carregar: ${errorMessages.join(', ')}.";
        if (errorMessages.isEmpty)
          _generalErrorMessage = "Falha ao carregar alguns dados do jogo.";
      } else if (anyLoading) {
        _overallStatus =
            FixtureDetailOverallStatus.partiallyLoaded; // ou manter loading
      } else if (allNoData) {
        _overallStatus =
            FixtureDetailOverallStatus
                .fullyLoaded; // Carregado, mas sem dados específicos
        _generalErrorMessage =
            "Nenhum dado detalhado (stats, odds, H2H) encontrado para este jogo.";
      } else {
        _overallStatus = FixtureDetailOverallStatus.fullyLoaded;
      }
    } catch (e) {
      _generalErrorMessage =
          "Erro inesperado ao buscar detalhes: ${e.toString()}";
      _overallStatus = FixtureDetailOverallStatus.error;
    }

    notifyListeners();
  }

  Future<void> _fetchStats({bool forceRefresh = false}) async {
    // Condições para evitar refetch desnecessário
    if (_fixtureFullData?.statsStatus == SectionStatus.loading && !forceRefresh)
      return;
    if (_fixtureFullData?.statsStatus == SectionStatus.loaded &&
        !forceRefresh &&
        _fixtureFullData?.fixtureStats != null)
      return;
    if (_fixtureFullData?.statsStatus == SectionStatus.noData && !forceRefresh)
      return;

    _fixtureFullData = _fixtureFullData?.copyWith(
      statsStatus: SectionStatus.loading,
      clearStatsError: true,
    );
    if (!forceRefresh && _overallStatus != FixtureDetailOverallStatus.loading)
      notifyListeners();

    final result = await _getFixtureStatsUseCase(
      fixtureId: baseFixture.id,
      homeTeamId: baseFixture.homeTeam.id,
      awayTeamId: baseFixture.awayTeam.id,
    );

    if (!mounted && _overallStatus == FixtureDetailOverallStatus.initial)
      return; // Checagem se o provider ainda existe

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
          statsStatus:
              (stats.homeTeam == null &&
                      stats.awayTeam == null &&
                      (stats.homeTeam?.expectedGoals ==
                          null)) // Checagem mais robusta para noData
                  ? SectionStatus.noData
                  : SectionStatus.loaded,
          statsErrorMessage:
              (stats.homeTeam == null &&
                      stats.awayTeam == null &&
                      (stats.homeTeam?.expectedGoals == null))
                  ? "Estatísticas pré-jogo não disponíveis."
                  : null,
        );
      },
    );
    if (forceRefresh || _overallStatus == FixtureDetailOverallStatus.loading)
      return; // Notificação será feita pelo fetchFixtureDetails ou no final dele
    notifyListeners();
  }

  Future<void> _fetchOdds({bool forceRefresh = false}) async {
    if (_fixtureFullData?.oddsStatus == SectionStatus.loading && !forceRefresh)
      return;
    if (_fixtureFullData?.oddsStatus == SectionStatus.loaded &&
        !forceRefresh &&
        (_fixtureFullData?.odds.isNotEmpty ?? false))
      return;
    if (_fixtureFullData?.oddsStatus == SectionStatus.noData && !forceRefresh)
      return;

    _fixtureFullData = _fixtureFullData?.copyWith(
      oddsStatus: SectionStatus.loading,
      clearOddsError: true,
      odds: [],
    ); // Limpa odds antigas ao recarregar
    if (!forceRefresh && _overallStatus != FixtureDetailOverallStatus.loading)
      notifyListeners();

    final result = await _getOddsUseCase(fixtureId: baseFixture.id);

    if (!mounted && _overallStatus == FixtureDetailOverallStatus.initial)
      return;

    result.fold(
      (failure) {
        _fixtureFullData = _fixtureFullData?.copyWith(
          oddsStatus: SectionStatus.error,
          oddsErrorMessage: _mapFailureToMessage(failure),
          odds: [],
        );
      },
      (oddsList) {
        final filteredOdds = _filterAndSortOddsMarkets(oddsList);
        _fixtureFullData = _fixtureFullData?.copyWith(
          odds: filteredOdds,
          oddsStatus:
              filteredOdds.isEmpty
                  ? SectionStatus.noData
                  : SectionStatus.loaded,
          oddsErrorMessage:
              filteredOdds.isEmpty
                  ? "Nenhuma odd encontrada para os mercados principais."
                  : null,
        );
      },
    );
    if (forceRefresh || _overallStatus == FixtureDetailOverallStatus.loading)
      return;
    notifyListeners();
  }

  Future<void> _fetchH2H({bool forceRefresh = false}) async {
    if (_fixtureFullData?.h2hStatus == SectionStatus.loading && !forceRefresh)
      return;
    if (_fixtureFullData?.h2hStatus == SectionStatus.loaded &&
        !forceRefresh &&
        (_fixtureFullData?.h2hFixtures?.isNotEmpty ?? false))
      return;
    if (_fixtureFullData?.h2hStatus == SectionStatus.noData && !forceRefresh)
      return;

    _fixtureFullData = _fixtureFullData?.copyWith(
      h2hStatus: SectionStatus.loading,
      clearH2HError: true,
      h2hFixtures: [],
    );
    if (!forceRefresh && _overallStatus != FixtureDetailOverallStatus.loading)
      notifyListeners();

    final result = await _getH2HUseCase(
      team1Id: baseFixture.homeTeam.id,
      team2Id: baseFixture.awayTeam.id,
      lastN: 5,
    );

    if (!mounted && _overallStatus == FixtureDetailOverallStatus.initial)
      return;

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
          h2hErrorMessage:
              h2hList.isEmpty
                  ? "Nenhum histórico de confronto direto encontrado."
                  : null,
        );
      },
    );
    if (forceRefresh || _overallStatus == FixtureDetailOverallStatus.loading)
      return;
    notifyListeners();
  }

  List<PrognosticMarket> _filterAndSortOddsMarkets(
    List<PrognosticMarket> allMarkets,
  ) {
    // CORREÇÃO AQUI: Definir a lista de IDs de mercado de interesse
    const List<int> desiredMarketIds = [
      1, // Match Winner
      12, // Both Teams to Score
      // Adicione outros IDs de mercado que você considera principais, ex:
      // 5, // Goals Over/Under (API-Football pode usar ID 5 ou outros para linhas específicas)
      // Para Over/Under é melhor filtrar pelo nome do mercado E pela linha (ex: "2.5")
    ];

    List<PrognosticMarket> filtered =
        allMarkets.where((market) {
          if (desiredMarketIds.contains(market.marketId)) return true;
          // Lógica específica para Over/Under 2.5
          if (market.marketName.toLowerCase().contains("goals over/under") &&
              market.options.any((o) => o.label.toLowerCase().contains("2.5")))
            return true;
          // Adicione aqui outros filtros baseados em market.marketName se necessário
          return false;
        }).toList();

    // Ordenar para consistência na UI (Ex: Match Winner primeiro)
    filtered.sort((a, b) {
      int getOrderScore(PrognosticMarket m) {
        if (m.marketId == 1) return 0; // Match Winner
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
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Erro no servidor: ${failure.message}';
      case NetworkFailure:
        return 'Falha de conexão: ${failure.message}';
      case AuthenticationFailure:
        return 'Erro de autenticação: ${failure.message}';
      case ApiFailure:
        return 'Erro da API: ${failure.message}';
      case NoDataFailure:
        return failure.message; // Já é uma mensagem específica
      default:
        return 'Erro inesperado: ${failure.message}';
    }
  }

  // Helper para verificar se o provider ainda está montado antes de chamar notifyListeners
  // Isso é mais uma precaução, pois a lógica de status já tenta cobrir.
  // No entanto, com múltiplas chamadas async, é uma boa prática.
  bool get mounted =>
      _overallStatus != FixtureDetailOverallStatus.initial ||
      _hasFetchedOnce; // Simplificação
  // Uma checagem real de "mounted" não existe em ChangeNotifier
  // A melhor prática é cancelar subscriptions em dispose().
  // A lógica de status tenta evitar chamadas após dispose.
}
