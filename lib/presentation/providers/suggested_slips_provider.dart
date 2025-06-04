// lib/presentation/providers/suggested_slips_provider.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/core/error/exceptions.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_league_info_entity.dart';
import 'package:product_gamers/domain/entities/entities/suggested_bet_slip.dart';
import 'package:product_gamers/domain/entities/entities/team.dart';
import 'package:uuid/uuid.dart';
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
  final GetFixturesUseCase
      _getFixturesUseCase; // Para buscar os jogos do dia no caminho real
  final GenerateSuggestedSlipsUseCase
      _generateSlipsUseCase; // Para obter as PotentialBet e Slips no caminho real

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

  // ========== CONTROLE DE MOCK ==========
  final bool _useMockData =
      true; // <<<< Defina como true para usar mocks, false para API real
  // =====================================

  Future<void> fetchAndGeneratePotentialBets(
      {bool forceRefresh = false}) async {
    if (_isDisposed) return;
    if (_isCurrentlyFetching && !forceRefresh) {
      if (kDebugMode)
        print("SuggestedSlipsProvider: Fetch já em progresso, skipando.");
      return;
    }
    if (!forceRefresh &&
        (_status == SuggestionsStatus.loaded ||
            _status == SuggestionsStatus.empty) &&
        (_marketSuggestions.isNotEmpty || _accumulatedSlips.isNotEmpty)) {
      if (kDebugMode)
        print(
            "SuggestedSlipsProvider: Sugestões já processadas, sem forceRefresh.");
      return;
    }

    _isCurrentlyFetching = true;
    SuggestionsStatus previousStatus = _status;
    _status = SuggestionsStatus.loading;
    _errorMessage = null;
    if (forceRefresh) {
      _marketSuggestions = {};
      _accumulatedSlips = [];
    }

    if (previousStatus != SuggestionsStatus.loading || forceRefresh) {
      Future.microtask(() {
        if (!_isDisposed && _status == SuggestionsStatus.loading)
          notifyListeners();
      });
    }

    if (kDebugMode)
      print(
          "SuggestedSlipsProvider: Iniciando (mock: $_useMockData, forceRefresh: $forceRefresh)...");

    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 1200)); // Simula delay
      if (_isDisposed) {
        _isCurrentlyFetching = false;
        return;
      }

      _generateMockSuggestions(); // Chama o método que gera os mocks

      if (_marketSuggestions.isEmpty && _accumulatedSlips.isEmpty) {
        _status = SuggestionsStatus.empty;
        _errorMessage = "Nenhuma sugestão mockada configurada ou gerada.";
      } else {
        _status = SuggestionsStatus.loaded;
      }
    } else {
      // --- LÓGICA REAL DA API ---
      List<Fixture> fixturesForAnalysis = [];
      bool fetchFixturesError =
          false; // Definido para sinalizar erro na busca de fixtures
      try {
        // Lógica para buscar jogos reais (exemplo simplificado)
        // TODO: Implementar uma lógica mais robusta para selecionar "jogos do dia"
        const int mockLeagueId = 39; // Ex: Premier League
        final String currentSeason = DateFormatter.getYear(DateTime.now());
        final fixturesResult = await _getFixturesUseCase(
            leagueId: mockLeagueId, season: currentSeason, nextGames: 5);

        if (_isDisposed) {
          _isCurrentlyFetching = false;
          return;
        }

        fixturesResult.fold((failure) {
          _errorMessage = _mapFailureToMessage(failure);
          _status = SuggestionsStatus.error;
          // Não precisa de notifyListeners() aqui se o catch abaixo o fizer
          fetchFixturesError = true; // Sinalizar erro
        }, (fixtures) {
          fixturesForAnalysis = fixtures;
        });
        if (fetchFixturesError) {
          // Se houve erro na busca de fixtures, parar aqui
          _isCurrentlyFetching = false;
          if (!_isDisposed) notifyListeners();
          return;
        }
      } catch (e) {
        if (_isDisposed) {
          _isCurrentlyFetching = false;
          return;
        }
        _errorMessage =
            "Erro ao selecionar jogos para análise: ${e.toString()}";
        _status = SuggestionsStatus.error;
        _isCurrentlyFetching = false;
        if (!_isDisposed) notifyListeners();
        return;
      }

      if (fixturesForAnalysis.isEmpty && !_isDisposed) {
        _errorMessage = "Nenhum jogo real encontrado para análise.";
        _status = SuggestionsStatus.empty;
        _isCurrentlyFetching = false;
        if (!_isDisposed) notifyListeners();
        return;
      }

      final generationResult = await _generateSlipsUseCase(
        fixturesForToday: fixturesForAnalysis,
        targetTotalOdd: 7.0,
        maxSelectionsPerSlip: 3,
      );

      if (_isDisposed) {
        _isCurrentlyFetching = false;
        return;
      }

      if (_status == SuggestionsStatus.loading) {
        // Só processa se ainda estiver no estado de loading desta chamada
        generationResult.fold((failure) {
          _errorMessage = _mapFailureToMessage(failure);
          _status = SuggestionsStatus.error;
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
      }
      // --- FIM DA LÓGICA REAL DA API ---
    }

    _isCurrentlyFetching = false;
    if (!_isDisposed) notifyListeners();
  }

  void _generateMockSuggestions() {
    final Uuid uuid = Uuid(); // Para IDs dos bilhetes
    // Limpa sugestões e bilhetes anteriores
    _marketSuggestions = {
      "1X2": [],
      "GolsOverUnder": [],
      "BTTS": [],
      "JogadorAMarcar": []
    };
    _accumulatedSlips = [];

    // Mock Fixtures
    final fixture1 = Fixture(
        id: 1001,
        date: DateTime.now().add(const Duration(hours: 3)),
        statusShort: "NS",
        statusLong: "Not Started",
        homeTeam: const TeamInFixture(
            id: 1,
            name: "Time Forte Casa",
            logoUrl:
                "https://media.api-sports.io/football/teams/40.png"), // Liverpool
        awayTeam: const TeamInFixture(
            id: 2,
            name: "Time Fraco Fora",
            logoUrl:
                "https://media.api-sports.io/football/teams/33.png"), // Man Utd
        league: const FixtureLeagueInfoEntity(
            id: 39, name: "Liga Mock", season: 2024),
        refereeName: "Arbitro Justo");
    final fixture2 = Fixture(
        id: 1002,
        date: DateTime.now().add(const Duration(hours: 5)),
        statusShort: "NS",
        statusLong: "Not Started",
        homeTeam: const TeamInFixture(
            id: 3,
            name: "Atacantes Bons FC",
            logoUrl:
                "https://media.api-sports.io/football/teams/42.png"), // Arsenal
        awayTeam: const TeamInFixture(
            id: 4,
            name: "Goleadores SA",
            logoUrl:
                "https://media.api-sports.io/football/teams/50.png"), // Tottenham
        league: const FixtureLeagueInfoEntity(
            id: 39, name: "Liga Mock", season: 2024),
        refereeName: "Arbitro Caseiro");
    final fixture3 = Fixture(
        id: 1003,
        date: DateTime.now().add(const Duration(hours: 7)),
        statusShort: "NS",
        statusLong: "Not Started",
        homeTeam: const TeamInFixture(
            id: 5,
            name: "Defesa Ruim CF",
            logoUrl:
                "https://media.api-sports.io/football/teams/49.png"), // Chelsea
        awayTeam: const TeamInFixture(
            id: 6,
            name: "Ataque Tímido",
            logoUrl:
                "https://media.api-sports.io/football/teams/66.png"), // Everton
        league: const FixtureLeagueInfoEntity(
            id: 140, name: "Outra Liga Mock", season: 2024),
        refereeName: "Arbitro de Poucos Cartões");

    // Mock PotentialBets
    _marketSuggestions["1X2"]!.addAll([
      PotentialBet(
          fixture: fixture1,
          selection: BetSelection(
              marketName: "Resultado Final",
              selectionName: fixture1.homeTeam.name,
              odd: "1.50",
              probability: 0.65,
              reasoning: "Forte em casa, xG alto."),
          confidence: 0.82),
      PotentialBet(
          fixture: fixture2,
          selection: BetSelection(
              marketName: "Resultado Final",
              selectionName: "Empate",
              odd: "3.80",
              probability: 0.28,
              reasoning: "Equilíbrio de forças, H2H com empates."),
          confidence: 0.65),
    ]);
    _marketSuggestions["GolsOverUnder"]!.addAll([
      PotentialBet(
          fixture: fixture2,
          selection: BetSelection(
              marketName: "Gols Acima/Abaixo",
              selectionName: "Mais de 2.5",
              odd: "1.75",
              probability: 0.60,
              reasoning: "Ambos times com ataque forte, xG total > 3.0."),
          confidence: 0.75),
      PotentialBet(
          fixture: fixture3,
          selection: BetSelection(
              marketName: "Gols Acima/Abaixo",
              selectionName: "Menos de 2.5",
              odd: "2.05",
              probability: 0.55,
              reasoning: "Ataques pouco produtivos, xG total < 2.2."),
          confidence: 0.68),
    ]);
    _marketSuggestions["BTTS"]!.add(
      PotentialBet(
          fixture: fixture2,
          selection: BetSelection(
              marketName: "Ambas Equipes Marcam?",
              selectionName: "Sim",
              odd: "1.60",
              probability: 0.62,
              reasoning: "Defesas inconsistentes, ataques bons."),
          confidence: 0.78),
    );
    _marketSuggestions["JogadorAMarcar"]!.add(
      PotentialBet(
          fixture: fixture1,
          selection: BetSelection(
              marketName: "Jogador para Marcar",
              selectionName: "Artilheiro Casa",
              odd: "2.10",
              probability: 0.45,
              reasoning: "Principal atacante, boa forma."),
          confidence: 0.70),
    );

    // Mock Accumulated Slips (opcional, mas para consistência)
    if (_marketSuggestions["1X2"]!.isNotEmpty &&
        _marketSuggestions["GolsOverUnder"]!.isNotEmpty) {
      _accumulatedSlips.add(SuggestedBetSlip(
          title: "Dupla Mock Top 🛡️",
          fixturesInvolved: [fixture1, fixture2],
          selections: [
            _marketSuggestions["1X2"]![0].selection,
            _marketSuggestions["GolsOverUnder"]![0].selection,
          ],
          totalOddsDisplay: (_marketSuggestions["1X2"]![0].selection.oddValue *
                  _marketSuggestions["GolsOverUnder"]![0].selection.oddValue)
              .toStringAsFixed(2),
          dateGenerated: DateTime.now(),
          overallReasoning:
              "Combinação de uma vitória provável com um jogo de gols.",
          totalOdds: ''));
    }
    _marketSuggestions
        .removeWhere((key, value) => value.isEmpty); // Limpa categorias vazias
  }

  void _groupAndFilterMarketSuggestions(List<PotentialBet> allBets) {
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
        // Aplicar um filtro mais rigoroso para o que entra no marketSuggestions, mesmo que o motor tenha gerado
        if ((bet.selection.probability ?? 0.0) >= 0.40 &&
            bet.confidence >= 0.60) {
          // Limiares para exibir
          _marketSuggestions[targetCategoryKey]!.add(bet);
        }
      }
    }
    _marketSuggestions.removeWhere((key, value) => value.isEmpty);
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) return 'Erro no servidor: ${failure.message}';
    if (failure is NetworkFailure)
      return 'Falha de conexão: ${failure.message}';
    if (failure is AuthenticationFailure)
      return 'Erro de autenticação: ${failure.message}';
    if (failure is ApiFailure) return 'Erro da API: ${failure.message}';
    if (failure is NoDataFailure) return failure.message;
    return 'Erro inesperado ao gerar sugestões: ${failure.message}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (kDebugMode) print("SuggestedSlipsProvider disposed.");
    super.dispose();
  }
}




/*
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


*/