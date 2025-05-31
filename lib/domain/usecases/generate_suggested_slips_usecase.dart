// lib/domain/usecases/generate_suggested_slips_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:collection/collection.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/data_for_prediction.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
import 'package:product_gamers/domain/entities/entities/standing_info.dart';
import 'package:product_gamers/domain/entities/entities/suggested_bet_slip.dart';
import 'dart:math';

import '../../core/utils/date_formatter.dart';

import '../repositories/football_repository.dart';
// import '../../core/config/app_constants.dart'; // Não é usado diretamente aqui mais

// GetLeagueStandingsUseCase precisa ser importado se for usado aqui,
// ou assumimos que o repositório tem um método para isso.
// Para manter simples, vamos assumir que o repositório já tem getLeagueStandings
// (o que já fizemos).
import 'get_league_standings_usecase.dart'; // Já criamos este

// Classe auxiliar para guardar uma aposta potencial com sua confiança
class PotentialBet {
  final Fixture fixture;
  final BetSelection selection;
  final double confidence; // 0.0 a 1.0

  PotentialBet({
    required this.fixture,
    required this.selection,
    required this.confidence,
  });
}

class GenerateSuggestedSlipsUseCase {
  final FootballRepository _footballRepository;
  // O GetLeagueStandingsUseCase será usado dentro de _gatherDataForFixture
  // Ele é instanciado no construtor usando o _footballRepository.
  final GetLeagueStandingsUseCase _getLeagueStandingsUseCase;

  GenerateSuggestedSlipsUseCase(this._footballRepository,
      GetLeagueStandingsUseCase getLeagueStandingsUseCase)
      : _getLeagueStandingsUseCase = GetLeagueStandingsUseCase(
          _footballRepository,
        );

  Future<Either<Failure, List<SuggestedBetSlip>>> call({
    required List<Fixture> fixturesForToday,
    double targetTotalOdd = 10.0,
    int maxSelectionsPerSlip = 3,
  }) async {
    try {
      List<PotentialBet> allPotentialBetsGenerated =
          []; // Renomeado para clareza e evitar conflito de escopo

      for (var fixture in fixturesForToday) {
        final Either<Failure, DataForPrediction> dataResult =
            await _gatherDataForFixture(fixture);

        await dataResult.fold(
          (failure) {
            print(
              "Falha ao obter dados para o jogo ${fixture.id} no GenerateSuggestedSlipsUseCase: ${failure.message}",
            );
          },
          (predictionData) async {
            // _analyzeMarketsForFixture retorna List<PotentialBet>
            allPotentialBetsGenerated.addAll(
              _analyzeMarketsForFixture(predictionData),
            );
          },
        );
      }

      if (allPotentialBetsGenerated.isEmpty) {
        print("Nenhuma aposta potencial gerada para os jogos de hoje.");
        return Right([]);
      }

      // Passa a lista gerada para o método de construção
      List<SuggestedBetSlip> slips = _buildSlipsFromPotentialBets(
        allPotentialBetsGenerated,
        targetTotalOdd,
        maxSelectionsPerSlip,
      );

      return Right(slips);
    } catch (e, s) {
      print("Erro inesperado em GenerateSuggestedSlipsUseCase: $e\n$s");
      return Left(
        UnknownFailure(message: "Erro ao gerar bilhetes: ${e.toString()}"),
      );
    }
  }

  Future<Either<Failure, DataForPrediction>> _gatherDataForFixture(
    Fixture fixture,
  ) async {
    try {
      // CORREÇÃO 1: Obter a temporada da data do fixture, não de fixture.league.season
      final String currentSeason = DateFormatter.getYear(fixture.date);

      final results = await Future.wait([
        _footballRepository.getFixtureStatistics(
          fixtureId: fixture.id,
          homeTeamId: fixture.homeTeam.id,
          awayTeamId: fixture.awayTeam.id,
        ),
        // CORREÇÃO 2: Chamada correta para getOddsForFixture
        _footballRepository.getOddsForFixture(
          fixture.id, // Passado como argumento posicional
          // bookmakerId: AppConstants.preferredBookmakerId, // Opcional, o repositório pode usar o default
        ),
        _footballRepository.getHeadToHead(
          team1Id: fixture.homeTeam.id,
          team2Id: fixture.awayTeam.id,
          lastN: 5,
          status: 'FT',
        ),
        _getLeagueStandingsUseCase(
          leagueId: fixture.leagueId,
          season: currentSeason,
        ),
      ]);

      final fixtureStatsResult =
          results[0] as Either<Failure, FixtureStatsEntity?>;
      final oddsResult = results[1] as Either<Failure, List<PrognosticMarket>>;
      final h2hResult = results[2] as Either<Failure, List<Fixture>>;
      final standingsResult = results[3] as Either<Failure, List<StandingInfo>>;

      // CORREÇÃO 3: Usar fold para acessar os valores de Left/Right de forma segura
      Failure? firstCriticalFailure;
      fixtureStatsResult.fold((l) => firstCriticalFailure ??= l, (r) => null);
      oddsResult.fold((l) => firstCriticalFailure ??= l, (r) => null);
      // Logar falhas não críticas, mas não necessariamente impedir a criação de DataForPrediction
      h2hResult.fold(
        (l) => print("Falha ao buscar H2H para ${fixture.id}: ${l.message}"),
        (r) => null,
      );
      standingsResult.fold(
        (l) => print(
          "Falha ao buscar standings para liga ${fixture.leagueId}: ${l.message}",
        ),
        (r) => null,
      );

      // Mesmo que haja falhas não críticas, tentamos construir DataForPrediction com o que temos.
      // Se oddsResult falhou, passamos lista vazia.
      return Right(
        DataForPrediction(
          fixture: fixture,
          fixtureStats: fixtureStatsResult.fold((l) => null, (r) => r),
          odds: oddsResult.fold((l) {
            print(
              "Usando lista de odds vazia para ${fixture.id} devido a erro: ${l.message}",
            );
            return [];
          }, (r) => r),
          h2hFixtures: h2hResult.fold((l) => null, (r) => r),
          leagueStandings: standingsResult.fold((l) => null, (r) => r),
        ),
      );
    } catch (e) {
      print("Erro em _gatherDataForFixture (UseCase) para ${fixture.id}: $e");
      return Left(
        UnknownFailure(
          message:
              "Erro ao coletar dados para análise do jogo: ${e.toString()}",
        ),
      );
    }
  }

  // --- O restante dos métodos (_analyzeMarketsForFixture, sub-análises, Poisson, _buildSlipsFromPotentialBets) ---
  // --- permanecem como definidos anteriormente. Cole-os aqui. ---
  // Para economizar espaço, não vou repetir todos eles, mas você deve tê-los.
  // Vou colar apenas os stubs para referência de onde eles entram.

  List<PotentialBet> _analyzeMarketsForFixture(DataForPrediction data) {
    List<PotentialBet> potentialBets = [];
    _analyzeMatchWinnerMarket(data, potentialBets);
    _analyzeGoalsOverUnderMarket(data, potentialBets);
    _analyzeBothTeamsToScoreMarket(data, potentialBets);
    // _analyzeCornersMarket(data, potentialBets);
    // _analyzeCardsMarket(data, potentialBets);
    return potentialBets;
  }

  void _analyzeMatchWinnerMarket(
    DataForPrediction data,
    List<PotentialBet> bets,
  ) {
    // (Implementação completa de _analyzeMatchWinnerMarket como na Etapa "Integrar Classificações...")
    final fixture = data.fixture;
    final odds1X2 = data.odds.firstWhereOrNull(
      (o) =>
          o.marketId == 1 &&
          o.marketName.toLowerCase().contains("match winner"),
    );
    if (odds1X2 == null) return;

    double? xgHome = data.fixtureStats?.homeTeam?.expectedGoals;
    double? xgAway = data.fixtureStats?.awayTeam?.expectedGoals;

    Map<String, double> scoreProbabilities = {};
    double probHomeWinPoisson = 0, probDrawPoisson = 0, probAwayWinPoisson = 0;

    if (xgHome != null && xgAway != null) {
      scoreProbabilities = _calculatePoissonScoreProbabilities(xgHome, xgAway);
      scoreProbabilities.forEach((score, prob) {
        final scores = score.split('-').map(int.parse).toList();
        if (scores[0] > scores[1])
          probHomeWinPoisson += prob;
        else if (scores[0] == scores[1])
          probDrawPoisson += prob;
        else
          probAwayWinPoisson += prob;
      });
    }

    int? homeRank, awayRank;
    int totalTeamsInLeague = data.leagueStandings?.length ?? 20;
    if (data.leagueStandings != null && data.leagueStandings!.isNotEmpty) {
      homeRank = data.leagueStandings!
          .firstWhereOrNull((s) => s.teamId == fixture.homeTeam.id)
          ?.rank;
      awayRank = data.leagueStandings!
          .firstWhereOrNull((s) => s.teamId == fixture.awayTeam.id)
          ?.rank;
    }

    double standingFactorHome = 0.0;
    if (homeRank != null && awayRank != null) {
      int rankDiff = awayRank - homeRank;
      if (totalTeamsInLeague > 1) {
        standingFactorHome = (rankDiff / (totalTeamsInLeague - 1)) * 0.15;
        standingFactorHome = standingFactorHome.clamp(-0.15, 0.15);
      }
    }

    final homeOpt = odds1X2.options.firstWhereOrNull(
      (o) => o.label.toLowerCase() == "home",
    );
    final awayOpt = odds1X2.options.firstWhereOrNull(
      (o) => o.label.toLowerCase() == "away",
    );

    if (homeOpt != null) {
      double impliedProbHome = 1 / (double.tryParse(homeOpt.odd) ?? 100.0);
      double baseProb = (probHomeWinPoisson > 0.05)
          ? probHomeWinPoisson
          : (impliedProbHome * 0.95);
      double adjustedProbHomeWin = (baseProb + standingFactorHome).clamp(
        0.01,
        0.99,
      );

      String reasoning = "";
      if (probHomeWinPoisson > 0.05)
        reasoning +=
            "Poisson (xG ${xgHome?.toStringAsFixed(1)}-${xgAway?.toStringAsFixed(1)})";
      if (homeRank != null && awayRank != null)
        reasoning +=
            "${reasoning.isNotEmpty ? ' + ' : ''}Class.(${homeRank}º vs ${awayRank}º)";
      if (reasoning.isEmpty) reasoning = "Análise de mercado";
      reasoning +=
          ". Prob.Calc.: ${(adjustedProbHomeWin * 100).toStringAsFixed(0)}%";

      if (adjustedProbHomeWin > (impliedProbHome * 1.10) &&
          (double.tryParse(homeOpt.odd) ?? 0) > 1.25) {
        bets.add(
          PotentialBet(
            fixture: fixture,
            selection: BetSelection(
              marketName: odds1X2.marketName,
              selectionName: homeOpt.label,
              odd: homeOpt.odd,
              reasoning: reasoning,
              probability: adjustedProbHomeWin,
            ),
            confidence: 0.60 +
                ((adjustedProbHomeWin - impliedProbHome).abs() * 0.8).clamp(
                  0,
                  0.35,
                ),
          ),
        );
      }
    }
    if (awayOpt != null) {
      double impliedProbAway = 1 / (double.tryParse(awayOpt.odd) ?? 100.0);
      double baseProb = (probAwayWinPoisson > 0.05)
          ? probAwayWinPoisson
          : (impliedProbAway * 0.95);
      double adjustedProbAwayWin = (baseProb - standingFactorHome).clamp(
        0.01,
        0.99,
      );

      String reasoning = "";
      if (probAwayWinPoisson > 0.05)
        reasoning +=
            "Poisson (xG ${xgHome?.toStringAsFixed(1)}-${xgAway?.toStringAsFixed(1)})";
      if (homeRank != null && awayRank != null)
        reasoning +=
            "${reasoning.isNotEmpty ? ' + ' : ''}Class.(${homeRank}º vs ${awayRank}º)";
      if (reasoning.isEmpty) reasoning = "Análise de mercado";
      reasoning +=
          ". Prob.Calc.: ${(adjustedProbAwayWin * 100).toStringAsFixed(0)}%";

      if (adjustedProbAwayWin > (impliedProbAway * 1.10) &&
          (double.tryParse(awayOpt.odd) ?? 0) > 1.25) {
        bets.add(
          PotentialBet(
            fixture: fixture,
            selection: BetSelection(
              marketName: odds1X2.marketName,
              selectionName: awayOpt.label,
              odd: awayOpt.odd,
              reasoning: reasoning,
              probability: adjustedProbAwayWin,
            ),
            confidence: 0.60 +
                ((adjustedProbAwayWin - impliedProbAway).abs() * 0.8).clamp(
                  0,
                  0.35,
                ),
          ),
        );
      }
    }
    // Não esquecer de implementar para o Empate (Draw) se desejar.
  }

  void _analyzeGoalsOverUnderMarket(
    DataForPrediction data,
    List<PotentialBet> bets,
  ) {
    // (Implementação como na Etapa 3.2.2 da resposta "Ok, excelente! Seguindo a progressão lógica...")
    final fixture = data.fixture;
    final oddsOverUnder = data.odds
        .where(
          (o) => o.marketName.toLowerCase().contains("goals over/under"),
        )
        .toList();
    if (oddsOverUnder.isEmpty) return;

    double? xgHome = data.fixtureStats?.homeTeam?.expectedGoals;
    double? xgAway = data.fixtureStats?.awayTeam?.expectedGoals;

    if (xgHome == null || xgAway == null) return;
    double totalExpectedGoals = xgHome + xgAway;

    final marketOverUnder25 = oddsOverUnder.firstWhereOrNull(
      (m) => m.options.any((opt) => opt.label.toLowerCase() == "over 2.5"),
    );
    if (marketOverUnder25 != null) {
      final over25Opt = marketOverUnder25.options.firstWhereOrNull(
        (o) => o.label.toLowerCase() == "over 2.5",
      );
      final under25Opt = marketOverUnder25.options.firstWhereOrNull(
        (o) => o.label.toLowerCase() == "under 2.5",
      );

      Map<String, double> scoreProbabilities =
          _calculatePoissonScoreProbabilities(xgHome, xgAway);
      double probOver25 = 0;
      scoreProbabilities.forEach((score, prob) {
        final s = score.split('-').map(int.parse).toList();
        if ((s[0] + s[1]) > 2.5) probOver25 += prob;
      });
      double probUnder25 = 1 - probOver25;

      if (over25Opt != null) {
        double impliedProbOver25 =
            1 / (double.tryParse(over25Opt.odd) ?? 100.0);
        if (probOver25 > (impliedProbOver25 * 1.08) &&
            (double.tryParse(over25Opt.odd) ?? 0) > 1.45) {
          bets.add(
            PotentialBet(
              fixture: fixture,
              selection: BetSelection(
                marketName: marketOverUnder25.marketName,
                selectionName: over25Opt.label,
                odd: over25Opt.odd,
                reasoning:
                    "xG total (${totalExpectedGoals.toStringAsFixed(1)}) e Poisson: ${(probOver25 * 100).toStringAsFixed(0)}% Over 2.5.",
                probability: probOver25,
              ),
              confidence: 0.60 +
                  ((probOver25 - impliedProbOver25).abs() * 0.7).clamp(0, 0.30),
            ),
          );
        }
      }
      if (under25Opt != null) {
        double impliedProbUnder25 =
            1 / (double.tryParse(under25Opt.odd) ?? 100.0);
        if (probUnder25 > (impliedProbUnder25 * 1.08) &&
            (double.tryParse(under25Opt.odd) ?? 0) > 1.45) {
          bets.add(
            PotentialBet(
              fixture: fixture,
              selection: BetSelection(
                marketName: marketOverUnder25.marketName,
                selectionName: under25Opt.label,
                odd: under25Opt.odd,
                reasoning:
                    "xG total (${totalExpectedGoals.toStringAsFixed(1)}) e Poisson: ${(probUnder25 * 100).toStringAsFixed(0)}% Under 2.5.",
                probability: probUnder25,
              ),
              confidence: 0.60 +
                  ((probUnder25 - impliedProbUnder25).abs() * 0.7).clamp(
                    0,
                    0.30,
                  ),
            ),
          );
        }
      }
    }
  }

  void _analyzeBothTeamsToScoreMarket(
    DataForPrediction data,
    List<PotentialBet> bets,
  ) {
    // (Implementação como na Etapa 3.2.3 da resposta "Ok, excelente! Seguindo a progressão lógica...")
    final fixture = data.fixture;
    final oddsBTTS = data.odds.firstWhereOrNull(
      (o) =>
          o.marketId == 12 &&
          o.marketName.toLowerCase().contains("both teams to score"),
    );
    if (oddsBTTS == null) return;

    double? xgHome = data.fixtureStats?.homeTeam?.expectedGoals;
    double? xgAway = data.fixtureStats?.awayTeam?.expectedGoals;

    if (xgHome == null || xgAway == null) return;

    double probHomeScores = 1 - _poissonProbability(xgHome, 0);
    double probAwayScores = 1 - _poissonProbability(xgAway, 0);
    double probBTTS_Yes_Calculated = probHomeScores * probAwayScores;
    // double probBTTS_No_Calculated = 1 - probBTTS_Yes_Calculated; // Não usado diretamente aqui para adicionar a aposta "Não"

    final bttsYesOpt = oddsBTTS.options.firstWhereOrNull(
      (o) => o.label.toLowerCase() == "yes",
    );

    if (bttsYesOpt != null) {
      double impliedProbBTTSYes =
          1 / (double.tryParse(bttsYesOpt.odd) ?? 100.0);
      if (xgHome > 0.65 &&
          xgAway > 0.65 &&
          probBTTS_Yes_Calculated > (impliedProbBTTSYes * 1.05) &&
          (double.tryParse(bttsYesOpt.odd) ?? 0) > 1.45) {
        bets.add(
          PotentialBet(
            fixture: fixture,
            selection: BetSelection(
              marketName: oddsBTTS.marketName,
              selectionName: bttsYesOpt.label,
              odd: bttsYesOpt.odd,
              reasoning:
                  "xG (${xgHome.toStringAsFixed(1)} vs ${xgAway.toStringAsFixed(1)}). Poisson (Sim): ${(probBTTS_Yes_Calculated * 100).toStringAsFixed(0)}%",
              probability: probBTTS_Yes_Calculated,
            ),
            confidence: 0.58 +
                ((probBTTS_Yes_Calculated - impliedProbBTTSYes).abs() * 0.7)
                    .clamp(0, 0.32),
          ),
        );
      }
    }
    // Lógica para BTTS "Não" pode ser adicionada se desejado.
  }

  int _factorial(int n) {
    if (n < 0)
      throw ArgumentError("Factorial not defined for negative numbers.");
    if (n == 0) return 1;
    int result = 1;
    for (int i = 1; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  double _poissonProbability(double lambda, int k) {
    if (lambda <= 0)
      return (k == 0) ? 1.0 : 0.0; /* Se lambda é 0, P(0)=1, P(k>0)=0 */
    return (pow(lambda, k) * exp(-lambda)) / _factorial(k);
  }

  Map<String, double> _calculatePoissonScoreProbabilities(
    double lambdaHome,
    double lambdaAway, {
    int maxGoals = 4,
  }) {
    Map<String, double> probabilities = {};
    for (int i = 0; i <= maxGoals; i++) {
      for (int j = 0; j <= maxGoals; j++) {
        double probHomeGoals = _poissonProbability(lambdaHome, i);
        double probAwayGoals = _poissonProbability(lambdaAway, j);
        probabilities["$i-$j"] = probHomeGoals * probAwayGoals;
      }
    }
    return probabilities;
  }

  List<SuggestedBetSlip> _buildSlipsFromPotentialBets(
    List<PotentialBet> allPotentialBetsInput, // Renomeado para evitar conflito
    double targetTotalOdd,
    int maxSelectionsPerSlip,
  ) {
    // (Implementação completa de _buildSlipsFromPotentialBets como na Etapa 4 da resposta "Ok, vamos para a Etapa 4...")
    // Certifique-se de que está usando 'allPotentialBetsInput' como parâmetro.
    List<SuggestedBetSlip> builtSlips = [];
    if (allPotentialBetsInput.isEmpty) return builtSlips;

    List<PotentialBet> sortedPotentialBets = List.from(
      allPotentialBetsInput,
    ); // Cria cópia para ordenar
    sortedPotentialBets.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Bilhete de Alta Confiança
    List<PotentialBet> highConfidenceSelections = [];
    Set<int> usedFixtureIdsHighConfidence = {};
    double currentOddHc = 1.0;
    for (var bet in sortedPotentialBets) {
      // Usa a lista ordenada
      if (highConfidenceSelections.length < maxSelectionsPerSlip &&
          highConfidenceSelections.length <
              2 && // Forçar apenas duplas para este tipo de bilhete
          !usedFixtureIdsHighConfidence.contains(bet.fixture.id)) {
        highConfidenceSelections.add(bet);
        usedFixtureIdsHighConfidence.add(bet.fixture.id);
        currentOddHc *= bet.selection.oddValue;
      }
      if (highConfidenceSelections.length >= 2) break; // Parar se já temos 2
    }
    if (highConfidenceSelections.length == 2 && currentOddHc >= 1.5) {
      // Mínimo de 2 seleções e odd total mínima
      builtSlips.add(
        SuggestedBetSlip(
          title: "Dupla de Confiança 🛡️",
          fixturesInvolved:
              highConfidenceSelections.map((e) => e.fixture).toList(),
          selections: highConfidenceSelections.map((e) => e.selection).toList(),
          totalOdds: currentOddHc.toStringAsFixed(2),
          dateGenerated: DateTime.now(),
          overallReasoning:
              "Seleções com alta confiança individual baseada em análise.",
          totalOddsDisplay: '',
        ),
      );
    }

    // Bilhete Odd Alvo
    List<PotentialBet> targetOddSelections = [];
    Set<int> usedFixtureIdsTarget = {};
    double currentOddTarget = 1.0;
    int selectionsCountTarget = 0;
    List<PotentialBet> candidatesForTargetOdd =
        sortedPotentialBets // Usa a lista já ordenada por confiança
            .where(
              (b) => b.selection.oddValue >= 1.40 && b.confidence >= 0.55,
            ) // Filtros um pouco mais rígidos
            .toList();

    for (var bet in candidatesForTargetOdd) {
      if (selectionsCountTarget < maxSelectionsPerSlip &&
          !usedFixtureIdsTarget.contains(bet.fixture.id)) {
        if ((currentOddTarget * bet.selection.oddValue) <
            (targetTotalOdd * 1.7)) {
          // Limite de estouro da odd
          targetOddSelections.add(bet);
          usedFixtureIdsTarget.add(bet.fixture.id);
          currentOddTarget *= bet.selection.oddValue;
          selectionsCountTarget++;
        }
      }
      if (selectionsCountTarget >= 2 &&
          currentOddTarget >= (targetTotalOdd * 0.80) &&
          selectionsCountTarget <= maxSelectionsPerSlip) break;
      if (selectionsCountTarget == maxSelectionsPerSlip &&
          currentOddTarget < (targetTotalOdd * 0.7)) {
        // Se atingiu max seleções mas odd muito baixa, reseta e tenta com as próximas
        targetOddSelections = [];
        usedFixtureIdsTarget = {};
        currentOddTarget = 1.0;
        selectionsCountTarget = 0;
      } else if (selectionsCountTarget == maxSelectionsPerSlip) {
        break;
      }
    }
    if (targetOddSelections.length >= 2 &&
        targetOddSelections.length <= maxSelectionsPerSlip &&
        currentOddTarget >= (targetTotalOdd * 0.70)) {
      builtSlips.add(
        SuggestedBetSlip(
          title: "Múltipla Alvo (Odd ~${targetTotalOdd.toStringAsFixed(0)}) 🎯",
          fixturesInvolved: targetOddSelections.map((e) => e.fixture).toList(),
          selections: targetOddSelections.map((e) => e.selection).toList(),
          totalOdds: currentOddTarget.toStringAsFixed(2),
          dateGenerated: DateTime.now(),
          overallReasoning:
              "Combinação buscando odd alvo com base em análise e valor percebido.",
          totalOddsDisplay: '',
        ),
      );
    }

    builtSlips.removeWhere((slip) {
      if (slip!.title.contains("Confiança"))
        return slip.selections.length < 2 || slip.totalOddsValue < 1.5;
      return slip!.selections.length < 2 || slip.totalOddsValue < 2.5;
    });

    // Garantir que não haja bilhetes com o mesmo conjunto de fixture IDs
    List<SuggestedBetSlip> finalUniqueSlips = [];
    Set<String> usedFixtureSets = {};

    for (var slip in builtSlips) {
      var fixtureIdSet = slip.fixturesInvolved.map((f) => f.id).toSet().toList()
        ..sort();
      String fixtureKey = fixtureIdSet.join(',');
      if (!usedFixtureSets.contains(fixtureKey)) {
        finalUniqueSlips.add(slip);
        usedFixtureSets.add(fixtureKey);
      }
    }

    if (finalUniqueSlips.length > 2)
      return finalUniqueSlips
          .take(2)
          .toList(); // Retorna no máximo 2 bilhetes por dia
    return finalUniqueSlips;
  }
}
