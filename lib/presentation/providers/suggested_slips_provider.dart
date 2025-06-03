// lib/presentation/providers/suggested_slips_provider.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/core/error/exceptions.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/suggested_bet_slip.dart';
// <<< IMPORT CORRETO
import '../../domain/usecases/get_fixtures_usecase.dart';
import '../../domain/usecases/generate_suggested_slips_usecase.dart'; // <<< IMPORT CORRETO
import '../../core/config/app_constants.dart'; // Para AppConstants.popularLeagues

// lib/presentation/providers/suggested_slips_provider.dart
import 'package:flutter/foundation.dart'; // Para kDebugMode e ChangeNotifier
import 'package:collection/collection.dart'; // Para firstWhereOrNull, etc.

import '../../core/config/app_constants.dart'; // Para IDs de ligas populares
import '../../core/utils/date_formatter.dart'; // Para a temporada atual

// Domain

// Importar PotentialBet e SlipGenerationResult do GenerateSuggestedSlipsUseCase
import '../../domain/usecases/generate_suggested_slips_usecase.dart';
// Para SuggestedBetSlip
import '../../domain/usecases/get_fixtures_usecase.dart';

enum SuggestionsStatus { initial, loading, loaded, error, empty }

class SuggestedSlipsProvider with ChangeNotifier {
  final GetFixturesUseCase _getFixturesUseCase;
  final GenerateSuggestedSlipsUseCase _generateSlipsUseCase;

  SuggestedSlipsProvider(this._getFixturesUseCase, this._generateSlipsUseCase);

  SuggestionsStatus _status = SuggestionsStatus.initial;
  String? _errorMessage;
  Map<String, List<PotentialBet>> _marketSuggestions = {};
  List<SuggestedBetSlip> _accumulatedSlips = [];
  bool _isDisposed = false;
  bool _isCurrentlyFetching = false;

  SuggestionsStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, List<PotentialBet>> get marketSuggestions => _marketSuggestions;
  List<SuggestedBetSlip> get accumulatedSlips => _accumulatedSlips;
  bool get isLoadingData => _isCurrentlyFetching;

  Future<void> fetchAndGeneratePotentialBets(
      {bool forceRefresh = false}) async {
    if (_isDisposed) return;
    if (_isCurrentlyFetching && !forceRefresh) {
      if (kDebugMode)
        print(
            "SuggestedSlipsProvider: Fetch já em progresso, skipando (forceRefresh: $forceRefresh).");
      return;
    }
    if (!forceRefresh &&
        (_status == SuggestionsStatus.loaded ||
            _status == SuggestionsStatus.empty) &&
        (_marketSuggestions.isNotEmpty || _accumulatedSlips.isNotEmpty)) {
      if (kDebugMode)
        print(
            "SuggestedSlipsProvider: Sugestões já processadas e não é forceRefresh.");
      return;
    }

    _isCurrentlyFetching = true;
    _status = SuggestionsStatus.loading; // Define o status como loading
    _errorMessage = null;
    if (forceRefresh) {
      _marketSuggestions = {};
      _accumulatedSlips = [];
    }

    // Notifica sobre o estado de loading APÓS o frame atual
    Future.microtask(() {
      if (!_isDisposed && _status == SuggestionsStatus.loading) {
        notifyListeners();
      }
    });

    if (kDebugMode)
      print(
          "SuggestedSlipsProvider: Iniciando busca (forceRefresh: $forceRefresh)...");

    List<Fixture> fixturesForAnalysis = [];
    bool fetchFixturesError = false; // Flag para erro na busca de fixtures

    try {
      List<int> leaguesToAnalyze =
          AppConstants.popularLeagues.values.take(1).toList();
      String currentSeason = DateFormatter.getYear(DateTime.now());
      int totalGamesFetched = 0;
      const int maxGamesToAnalyze = 1;

      // A busca de fixtures é async, então o try/catch principal pegará erros dela.
      for (int leagueId in leaguesToAnalyze) {
        if (totalGamesFetched >= maxGamesToAnalyze || _isDisposed) break;
        final result = await _getFixturesUseCase(
          leagueId: leagueId,
          season: currentSeason,
          nextGames: 1,
        );
        if (_isDisposed) {
          _isCurrentlyFetching = false;
          return;
        }
        result.fold((failure) {
          if (kDebugMode)
            print(
                "SuggestedSlipsProvider: Falha ao buscar jogos da liga $leagueId: ${failure.message}");
          // Adicione aqui para ver se o erro é de API esgotada:
          if (failure is ApiException &&
              failure.message.toLowerCase().contains("quota")) {
            print(
                "!!!! COTA DA API ESGOTADA AO BUSCAR JOGOS DA LIGA $leagueId !!!!");
          }
        }, (fixtures) {
          if (kDebugMode)
            print(
                "SuggestedSlipsProvider: Liga $leagueId - ${fixtures.length} jogos encontrados.");
          // ... resto da lógica ...
        });
        ;
      }
      fixturesForAnalysis.sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      // Este catch é para erros inesperados DURANTE a busca de fixtures
      if (_isDisposed) {
        _isCurrentlyFetching = false;
        return;
      }
      if (kDebugMode)
        print(
            "SuggestedSlipsProvider: Erro crítico ao buscar jogos para análise: $e");
      _errorMessage = "Erro ao selecionar jogos para análise: ${e.toString()}";
      _status = SuggestionsStatus.error;
      _isCurrentlyFetching = false;
      // Adiar notificação de erro
      Future.microtask(() {
        if (!_isDisposed) notifyListeners();
      });
      return;
    }

    if (fixturesForAnalysis.isEmpty && !_isDisposed) {
      _errorMessage =
          "Nenhum jogo encontrado para análise hoje nas ligas selecionadas.";
      _status = SuggestionsStatus.empty;
      _isCurrentlyFetching = false;
      // Adiar notificação
      Future.microtask(() {
        if (!_isDisposed) notifyListeners();
      });
      return;
    }

    if (_isDisposed) {
      _isCurrentlyFetching = false;
      return;
    }
    if (kDebugMode)
      print(
          "SuggestedSlipsProvider: ${fixturesForAnalysis.length} jogos selecionados para análise.");

    // A chamada a _generateSlipsUseCase é a operação longa principal
    final generationResult = await _generateSlipsUseCase(
      fixturesForToday: fixturesForAnalysis,
      targetTotalOdd: 7.0,
      maxSelectionsPerSlip: 3,
    );

    if (_isDisposed) {
      _isCurrentlyFetching = false;
      return;
    }

    // O estado só deve ser atualizado aqui se ainda estivermos no processo de loading iniciado por esta chamada.
    // Se o status mudou para error/disposed enquanto _generateSlipsUseCase rodava, não atualizamos.
    if (_status == SuggestionsStatus.loading) {
      generationResult.fold((failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _status = SuggestionsStatus.error;
        // _marketSuggestions e _accumulatedSlips já foram limpos se era forceRefresh
      }, (slipGenResult) {
        _accumulatedSlips = slipGenResult.suggestedSlips;
        _groupAndFilterMarketSuggestions(slipGenResult.allPotentialBets);

        if (_marketSuggestions.isEmpty && _accumulatedSlips.isEmpty) {
          _status = SuggestionsStatus.empty;
          _errorMessage = "Nenhuma sugestão ou bilhete pôde ser gerado.";
        } else {
          _status = SuggestionsStatus.loaded;
        }
      });
      notifyListeners(); // Esta notificação é segura pois vem depois do await principal
    }
    _isCurrentlyFetching = false;
  }

  void _groupAndFilterMarketSuggestions(List<PotentialBet> allBets) {
    // ... (implementação como antes)
    _marketSuggestions = {
      "1X2": [],
      "GolsOverUnder": [],
      "BTTS": [],
      "Escanteios": [],
      "Cartoes": [],
      "JogadorAMarcar": []
    };
    if (allBets.isEmpty) return;
    allBets.sort((a, b) {
      int confidenceCompare = b.confidence.compareTo(a.confidence);
      if (confidenceCompare != 0) return confidenceCompare;
      return (b.selection.probability ?? 0.0)
          .compareTo(a.selection.probability ?? 0.0);
    });
    for (var bet in allBets) {
      const int maxPerCategory = 3;
      String? targetCategoryKey;
      String marketNameLower = bet.selection.marketName.toLowerCase();
      if (marketNameLower.contains("match winner") ||
          marketNameLower.contains("resultado final") ||
          marketNameLower == "1x2")
        targetCategoryKey = "1X2";
      else if (marketNameLower.contains("goals over/under") ||
          marketNameLower.contains("total de gols") ||
          marketNameLower.contains("golos mais/menos"))
        targetCategoryKey = "GolsOverUnder";
      else if (marketNameLower.contains("both teams to score") ||
          marketNameLower.contains("ambas equipes marcam"))
        targetCategoryKey = "BTTS";
      else if (marketNameLower.contains("corners") ||
          marketNameLower.contains("escanteios"))
        targetCategoryKey = "Escanteios";
      else if (marketNameLower.contains("card") ||
          marketNameLower.contains("cartões") ||
          marketNameLower.contains("booking points"))
        targetCategoryKey = "Cartoes";
      else if (marketNameLower.contains("goalscorer") ||
          marketNameLower.contains("jogador para marcar") ||
          marketNameLower.contains("jogador marca"))
        targetCategoryKey = "JogadorAMarcar";
      if (targetCategoryKey != null &&
          (_marketSuggestions[targetCategoryKey]?.length ?? 0) <
              maxPerCategory) {
        if ((bet.selection.probability ?? 0.0) >= 0.38 &&
            bet.confidence >= 0.58) {
          _marketSuggestions[targetCategoryKey]!.add(bet);
        }
      }
    }
    _marketSuggestions.removeWhere((key, value) => value.isEmpty);
  }

  String _mapFailureToMessage(Failure failure) {
    /* ... como antes ... */ return failure.message;
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (kDebugMode) print("SuggestedSlipsProvider disposed.");
    super.dispose();
  }
}
