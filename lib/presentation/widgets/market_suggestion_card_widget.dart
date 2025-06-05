// lib/presentation/widgets/market_suggestion_card_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar a probabilidade
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import '../../domain/usecases/generate_suggested_slips_usecase.dart'; // Para PotentialBet
// Importar FixtureDetailScreen e LiveFixtureScreen para navegação
import '../screens/fixture_detail_screen.dart';
import '../screens/live_fixture_screen.dart';
// Importar Providers e UseCases necessários para a navegação
import 'package:provider/provider.dart';

import '../providers/fixture_detail_provider.dart';
import '../providers/live_fixture_provider.dart';
import '../../domain/usecases/get_odds_usecase.dart';
import '../../domain/usecases/get_fixture_statistics_usecase.dart';
import '../../domain/usecases/get_h2h_usecase.dart';
import '../../domain/usecases/get_live_fixture_update_usecase.dart';
import '../../domain/usecases/get_live_odds_usecase.dart';

class MarketSuggestionCardWidget extends StatelessWidget {
  final PotentialBet potentialBet;
  final String
      marketCategoryTitle; // Ex: "Vitórias Prováveis", "Alto Potencial de Gols"

  const MarketSuggestionCardWidget({
    super.key,
    required this.potentialBet,
    required this.marketCategoryTitle,
  });

  void _navigateToDetails(BuildContext navContext, Fixture fixture) {
    // Lógica de navegação (copiada/adaptada da FixturesScreen)
    final now = DateTime.now();
    final gameTime = fixture.date.toLocal();
    final difference = gameTime.difference(now);

    final bool isImminentOrLive = (!["NS", "PST", "CANC", "TBD"]
            .contains(fixture.statusShort.toUpperCase())) ||
        (fixture.statusShort.toUpperCase() == "NS" &&
            (difference.isNegative && difference.abs().inMinutes < 120 ||
                !difference.isNegative && difference.inMinutes < 15));

    final bool isTrulyFinished = [
      "FT",
      "AET",
      "PEN",
      "CANC",
      "ABD",
      "PST",
      "WO"
    ].contains(fixture.statusShort.toUpperCase());

    if (isImminentOrLive && !isTrulyFinished) {
      Navigator.push(
        navContext,
        MaterialPageRoute(
          builder: (contextForProvider) => ChangeNotifierProvider(
            create: (_) => LiveFixtureProvider(
              fixtureId: fixture.id,
              homeTeamId: fixture.homeTeam.id,
              homeTeamName: fixture.homeTeam.name,
              awayTeamId: fixture.awayTeam.id,
              awayTeamName: fixture.awayTeam.name,
              getLiveFixtureUpdateUseCase:
                  contextForProvider.read<GetLiveFixtureUpdateUseCase>(),
              getLiveOddsUseCase: contextForProvider.read<GetLiveOddsUseCase>(),
            ),
            child: LiveFixtureScreen(fixtureBasicInfo: fixture),
          ),
        ),
      );
    } else {
      Navigator.push(
        navContext,
        MaterialPageRoute(
          builder: (contextForProvider) => ChangeNotifierProvider(
            create: (_) => FixtureDetailProvider(
              baseFixture: fixture,
              getFixtureStatsUseCase:
                  contextForProvider.read<GetFixtureStatisticsUseCase>(),
              getOddsUseCase: contextForProvider.read<GetOddsUseCase>(),
              getH2HUseCase: contextForProvider.read<GetH2HUseCase>(),
            ),
            child: FixtureDetailScreen(baseFixture: fixture),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = potentialBet.selection;
    final fixture = potentialBet.fixture;
    final NumberFormat percentFormat = NumberFormat.percentPattern("pt_BR");
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 10.5,
      color: Colors.black.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _navigateToDetails(
            context, fixture), // Navega para detalhes do jogo
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações do Jogo
              Text(
                "${fixture.homeTeam.name} vs ${fixture.awayTeam.name}",
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                fixture.league.name, // Acesso correto
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).hintColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(height: 12, thickness: 0.5),

              // Detalhes da Aposta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${selection.marketName}: ${selection.selectionName}",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    label: Text(selection.odd,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.black : Colors.white)),
                    backgroundColor: const Color.fromARGB(255, 71, 255, 80),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    labelStyle: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Probabilidade e Confiança
              Row(
                children: [
                  Icon(Icons.show_chart_rounded,
                      size: 16, color: Colors.green.shade500),
                  const SizedBox(width: 4),
                  Text(
                    "Prob. Calculada: ${percentFormat.format(selection.probability ?? 0.0)}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade500),
                  ),
                  const Spacer(),
                  Text(
                    "Confiança: ${(potentialBet.confidence * 100).toStringAsFixed(0)}%",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                ],
              ),

              if (selection.reasoning != null &&
                  selection.reasoning!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  "Justificativa: ${selection.reasoning}",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).hintColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
