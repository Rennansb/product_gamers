import '../entities/entities/fixture_full_data.dart';
import '../entities/entities/suggested_bet_slip.dart';
import '../entities/entities/prognostic_market.dart';

import '../entities/entities/fixture.dart';

class PrognosticEngine {
  /// Helper para criar SuggestedBetSlip
  SuggestedBetSlip _buildSlip({
    required String title,
    required List<Fixture> fixturesInvolved,
    required List<BetSelection> selections,
    required double confidence,
    required List<String> reasons,
  }) {
    return SuggestedBetSlip(
      title: title,
      fixturesInvolved: fixturesInvolved,
      selections: selections,
      totalOddsDisplay:
          '1.80', // Placeholder, você pode implementar cálculo real
      totalOdds: '1.80', // Placeholder
      overallReasoning: reasons.join('\n'),
      dateGenerated: DateTime.now(),
      confidence: confidence,
    );
  }

  /// Sugere prognóstico para Over/Under 2.5 Goals
  SuggestedBetSlip suggestOverUnderGoals(FixtureFullData data) {
    final avgHomeGoals = data.homeTeamStats.avgGoalsFor;
    final avgAwayGoals = data.awayTeamStats.avgGoalsFor;
    final combinedAvgGoals = (avgHomeGoals + avgAwayGoals) / 2.0;

    final recentHighScoringMatches =
        data.recentFixtures.where((f) => f.totalGoals >= 3).length;

    double confidence = 0.0;
    List<String> reasons = [];

    if (combinedAvgGoals > 1.5) {
      confidence += 0.4;
      reasons.add(
          "Alta média de gols combinada (${combinedAvgGoals.toStringAsFixed(2)})");
    }

    if (recentHighScoringMatches >= 2) {
      confidence += 0.3;
      reasons.add(
          "Padrão recente de jogos com 3+ gols (${recentHighScoringMatches} partidas)");
    }

    if (data.h2hFixtures?.any((f) => f.totalGoals >= 3) ?? false) {
      confidence += 0.3;
      reasons.add("Histórico H2H favorável a jogos com muitos gols");
    }

    confidence = confidence.clamp(0.0, 1.0);

    return _buildSlip(
      title: 'Over 2.5 Goals',
      fixturesInvolved: [data.fixture],
      selections: [
        const BetSelection(
          marketName: 'Over/Under Goals',
          selectionName: 'Over 2.5',
          odd: '1.80', // Placeholder
        ),
      ],
      confidence: confidence,
      reasons: reasons,
    );
  }

  /// Sugere prognóstico para BTTS (Both Teams To Score)
  SuggestedBetSlip suggestBTTS(FixtureFullData data) {
    final avgHomeGoalsFor = data.homeTeamStats.avgGoalsFor;
    final avgHomeGoalsAgainst = data.homeTeamStats.avgGoalsAgainst;
    final avgAwayGoalsFor = data.awayTeamStats.avgGoalsFor;
    final avgAwayGoalsAgainst = data.awayTeamStats.avgGoalsAgainst;

    double confidence = 0.0;
    List<String> reasons = [];

    if (avgHomeGoalsFor > 1.0 && avgAwayGoalsFor > 1.0) {
      confidence += 0.4;
      reasons.add("Ambos os ataques têm boa média de gols");
    }

    if (avgHomeGoalsAgainst > 1.0 || avgAwayGoalsAgainst > 1.0) {
      confidence += 0.3;
      reasons.add("Defesas vulneráveis (alta média de gols sofridos)");
    }

    if (data.h2hFixtures.any((f) => f.homeGoals > 0 && f.awayGoals > 0)) {
      confidence += 0.3;
      reasons.add("Histórico H2H com ambos os times marcando gols");
    }

    confidence = confidence.clamp(0.0, 1.0);

    return _buildSlip(
      title: 'Both Teams To Score - YES',
      fixturesInvolved: [data.fixture],
      selections: [
        BetSelection(
          marketName: 'Both Teams To Score',
          selectionName: 'Yes',
          odds: 1.75, // Placeholder
        ),
      ],
      confidence: confidence,
      reasons: reasons,
    );
  }

  /// Sugere prognóstico para cartões (Over 4.5 cartões por exemplo)
  SuggestedBetSlip suggestCards(FixtureFullData data) {
    final avgHomeCards = data.homeTeamStats.avgCards;
    final avgAwayCards = data.awayTeamStats.avgCards;
    final avgRefCards = data.refereeStats?.avgCardsPerMatch ?? 0.0;

    final combinedAvgCards = avgHomeCards + avgAwayCards + avgRefCards;

    double confidence = 0.0;
    List<String> reasons = [];

    if (combinedAvgCards >= 5.0) {
      confidence += 0.6;
      reasons.add(
          "Alta média de cartões combinados (${combinedAvgCards.toStringAsFixed(2)})");
    }

    if (avgRefCards >= 4.5) {
      confidence += 0.4;
      reasons.add("Árbitro com tendência a distribuir muitos cartões");
    }

    confidence = confidence.clamp(0.0, 1.0);

    return _buildSlip(
      title: 'Over 4.5 Cards',
      fixturesInvolved: [data.fixture],
      selections: [
        BetSelection(
          marketName: 'Cards',
          selectionName: 'Over 4.5',
          odds: 1.85, // Placeholder
        ),
      ],
      confidence: confidence,
      reasons: reasons,
    );
  }

  /// Sugere prognóstico para escanteios (Over 8.5 escanteios por exemplo)
  SuggestedBetSlip suggestCorners(FixtureFullData data) {
    final avgHomeCorners = data.homeTeamStats.avgCorners;
    final avgAwayCorners = data.awayTeamStats.avgCorners;

    final combinedAvgCorners = avgHomeCorners + avgAwayCorners;

    double confidence = 0.0;
    List<String> reasons = [];

    if (combinedAvgCorners >= 9.0) {
      confidence += 0.5;
      reasons.add(
          "Alta média combinada de escanteios (${combinedAvgCorners.toStringAsFixed(2)})");
    }

    if (data.recentFixtures.where((f) => f.totalCorners >= 9).length >= 2) {
      confidence += 0.5;
      reasons.add("Padrão recente de jogos com 9+ escanteios");
    }

    confidence = confidence.clamp(0.0, 1.0);

    return _buildSlip(
      title: 'Over 8.5 Corners',
      fixturesInvolved: [data.fixture],
      selections: [
        BetSelection(
          marketName: 'Corners',
          selectionName: 'Over 8.5',
          odds: 1.70, // Placeholder
        ),
      ],
      confidence: confidence,
      reasons: reasons,
    );
  }
}
