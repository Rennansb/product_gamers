// lib/presentation/screens/fixture_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_full_data.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'package:product_gamers/domain/entities/entities/team.dart';
import 'package:product_gamers/presentation/widgets/market_odds_widget.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_formatter.dart';

import '../providers/fixture_detail_provider.dart';
import '../widgets/common/loading_indicator_widget.dart';
import '../widgets/common/error_display_widget.dart';

class FixtureDetailScreen extends StatefulWidget {
  final Fixture baseFixture;

  const FixtureDetailScreen({super.key, required this.baseFixture});

  @override
  State<FixtureDetailScreen> createState() => _FixtureDetailScreenState();
}

class _FixtureDetailScreenState extends State<FixtureDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FixtureDetailProvider>(
        context,
        listen: false,
      ).fetchFixtureDetails();
    });
  }

  Future<void> _refreshDetails() async {
    if (!mounted) return;
    await Provider.of<FixtureDetailProvider>(
      context,
      listen: false,
    ).fetchFixtureDetails(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    // Obtém o provider e os dados AQUI, no escopo do build
    final provider = context.watch<FixtureDetailProvider>();
    final fullData = provider.fixtureFullData; // Pode ser nulo inicialmente

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.baseFixture.homeTeam.name} vs ${widget.baseFixture.awayTeam.name}",
              style: const TextStyle(fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.baseFixture.leagueName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDetails,
          ),
        ],
      ),
      // CHAMA _buildBody PASSANDO provider e fullData
      body: _buildBody(context, provider, fullData),
    );
  }

  // _buildBody AGORA RECEBE provider e fullData como parâmetros
  Widget _buildBody(
    BuildContext context,
    FixtureDetailProvider provider,
    FixtureFullData? fullData,
  ) {
    // O resto do método _buildBody continua como na resposta anterior,
    // usando os parâmetros 'provider' e 'fullData' recebidos.
    if (provider.overallStatus == FixtureDetailOverallStatus.loading &&
        fullData == null) {
      return const LoadingIndicatorWidget(
        message: 'Carregando detalhes do jogo...',
      );
    }
    if (provider.overallStatus == FixtureDetailOverallStatus.error &&
        (fullData == null ||
            (fullData.statsStatus == SectionStatus.error &&
                fullData.oddsStatus == SectionStatus.error &&
                fullData.h2hStatus == SectionStatus.error))) {
      return ErrorDisplayWidget(
        message:
            provider.generalErrorMessage ?? "Falha ao carregar todos os dados.",
        onRetry: _refreshDetails,
      );
    }

    if (fullData == null) {
      // Isso pode acontecer se o provider for resetado ou se houver um estado inesperado
      // após a carga inicial não ter sido bem sucedida e o status não for 'error'.
      if (provider.overallStatus == FixtureDetailOverallStatus.initial ||
          provider.overallStatus == FixtureDetailOverallStatus.loading) {
        return const LoadingIndicatorWidget(message: 'Inicializando...');
      }
      // Se não estiver carregando e fullData for nulo, pode ser um erro não capturado ou estado inconsistente.
      return ErrorDisplayWidget(
        message:
            provider.generalErrorMessage ??
            "Dados do jogo não disponíveis. Tente atualizar.",
        onRetry: _refreshDetails,
      );
    }

    // Mesmo que haja erros parciais, tentamos mostrar o que temos.
    return RefreshIndicator(
      onRefresh: _refreshDetails,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFixtureHeader(context, fullData.baseFixture),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Análise Pré-Jogo 📊'),
          _buildSectionContent(
            context,
            status: fullData.statsStatus,
            errorMessage: fullData.statsErrorMessage,
            onRetry: () => provider.fetchFixtureDetails(forceRefresh: true),
            contentBuilder:
                () =>
                    fullData.fixtureStats != null
                        ? _buildFixtureStatsComparison(
                          context,
                          fullData.fixtureStats!,
                          fullData.baseFixture,
                        )
                        : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Estatísticas não disponíveis."),
                          ),
                        ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Odds Pré-Jogo 🎲'),
          _buildSectionContent(
            context,
            status: fullData.oddsStatus,
            errorMessage: fullData.oddsErrorMessage,
            onRetry: () => provider.fetchFixtureDetails(forceRefresh: true),
            contentBuilder: () {
              if (fullData.odds.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text("Nenhuma odd principal disponível."),
                  ),
                );
              }
              return Column(
                children:
                    fullData.odds.map((market) {
                      return MarketOddsWidget(market: market);
                    }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Confronto Direto (H2H) ⚔️'),
          _buildSectionContent(
            context,
            status: fullData.h2hStatus,
            errorMessage: fullData.h2hErrorMessage,
            onRetry: () => provider.fetchFixtureDetails(forceRefresh: true),
            contentBuilder:
                () =>
                    (fullData.h2hFixtures?.isNotEmpty ?? false)
                        ? _buildH2HSection(
                          context,
                          fullData.h2hFixtures!,
                          fullData.baseFixture,
                        )
                        : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Sem histórico de confrontos."),
                          ),
                        ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ... (Restante dos métodos _buildSectionTitle, _buildSectionContent, _buildFixtureHeader,
  //      _teamDisplay, _buildFixtureStatsComparison, _buildH2HSection, _buildStatRow, _teamStatHeader
  //      permanecem os mesmos da resposta anterior)

  // COPIE E COLE OS MÉTODOS HELPER QUE ESTAVAM AQUI DA RESPOSTA ANTERIOR
  // Exemplo de um deles:
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }

  Widget _buildSectionContent(
    BuildContext context, {
    required SectionStatus status,
    String? errorMessage,
    required VoidCallback onRetry,
    required Widget Function() contentBuilder,
  }) {
    switch (status) {
      case SectionStatus.initial:
      case SectionStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      case SectionStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ErrorDisplayWidget(
            message: errorMessage ?? "Erro ao carregar dados.",
            onRetry: onRetry,
            showRetryButton: true,
          ),
        );
      case SectionStatus.noData:
        return Card(
          elevation: 0,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                errorMessage ?? "Nenhum dado disponível para esta seção.",
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      case SectionStatus.loaded:
        return contentBuilder();
    }
  }

  Widget _buildFixtureHeader(BuildContext context, Fixture fixture) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              fixture.leagueName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              DateFormatter.formatFullDate(fixture.date),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _teamDisplay(context, fixture.homeTeam),
                Text(
                  (fixture.statusShort.toUpperCase() == "NS" ||
                          fixture.statusShort.toUpperCase() == "PST")
                      ? 'vs'
                      : '${fixture.homeGoals ?? '-'} - ${fixture.awayGoals ?? '-'}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _teamDisplay(context, fixture.awayTeam),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              fixture.statusLong,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (fixture.refereeName != null &&
                fixture.refereeName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Árbitro: ${fixture.refereeName}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (fixture.venueName != null && fixture.venueName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                "Local: ${fixture.venueName}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _teamDisplay(BuildContext context, TeamInFixture team) {
    return Expanded(
      child: Column(
        children: [
          team.logoUrl != null
              ? CachedNetworkImage(
                imageUrl: team.logoUrl!,
                height: 60,
                width: 60,
                fit: BoxFit.contain,
                placeholder:
                    (context, url) => const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                errorWidget:
                    (context, url, error) => Icon(
                      Icons.shield_outlined,
                      size: 60,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.3),
                    ),
              )
              : Icon(
                Icons.shield,
                size: 60,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
          const SizedBox(height: 8),
          Text(
            team.name,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFixtureStatsComparison(
    BuildContext context,
    FixtureStatsEntity stats,
    Fixture baseFixture,
  ) {
    if (stats.homeTeam == null && stats.awayTeam == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text("Estatísticas pré-jogo não disponíveis.")),
        ),
      );
    }
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                _teamStatHeader(
                  context,
                  baseFixture.homeTeam.name,
                  baseFixture.homeTeam.logoUrl,
                ),
                const SizedBox(
                  width: 8,
                  child: Center(
                    child: Text(
                      "vs",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                _teamStatHeader(
                  context,
                  baseFixture.awayTeam.name,
                  baseFixture.awayTeam.logoUrl,
                  alignRight: true,
                ),
              ],
            ),
            const Divider(height: 20),
            if (stats.homeTeam?.expectedGoals != null ||
                stats.awayTeam?.expectedGoals != null)
              _buildStatRow(
                context,
                "Gols Esperados (xG)",
                stats.homeTeam?.expectedGoals?.toStringAsFixed(2) ?? "-",
                stats.awayTeam?.expectedGoals?.toStringAsFixed(2) ?? "-",
                highlightStronger: true,
                isLowerBetter: false,
              ),
            _buildStatRow(
              context,
              "Finalizações (No Gol)",
              "${stats.homeTeam?.shotsTotal ?? '-'}(${stats.homeTeam?.shotsOnGoal ?? '-'})",
              "${stats.awayTeam?.shotsTotal ?? '-'}(${stats.awayTeam?.shotsOnGoal ?? '-'})",
            ),
            _buildStatRow(
              context,
              "Posse de Bola",
              stats.homeTeam?.ballPossessionPercent != null
                  ? "${stats.homeTeam!.ballPossessionPercent!.toStringAsFixed(0)}%"
                  : "-",
              stats.awayTeam?.ballPossessionPercent != null
                  ? "${stats.awayTeam!.ballPossessionPercent!.toStringAsFixed(0)}%"
                  : "-",
              highlightStronger: true,
              isLowerBetter: false,
            ),
            _buildStatRow(
              context,
              "Escanteios",
              stats.homeTeam?.corners?.toString() ?? "-",
              stats.awayTeam?.corners?.toString() ?? "-",
              highlightStronger: true,
              isLowerBetter: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildH2HSection(
    BuildContext context,
    List<Fixture> h2hFixtures,
    Fixture currentFixture,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (h2hFixtures.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Nenhum confronto direto recente encontrado."),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: h2hFixtures.length,
                itemBuilder: (context, index) {
                  final game = h2hFixtures[index];
                  bool currentHomeWasHomeInH2H =
                      game.homeTeam.id == currentFixture.homeTeam.id;
                  String scoreDisplay;
                  FontWeight homeWeight = FontWeight.normal,
                      awayWeight = FontWeight.normal;

                  if (currentHomeWasHomeInH2H) {
                    scoreDisplay =
                        "${game.homeGoals ?? '-'} - ${game.awayGoals ?? '-'}";
                    if ((game.homeGoals ?? -1) > (game.awayGoals ?? -1))
                      homeWeight = FontWeight.bold;
                    else if ((game.awayGoals ?? -1) > (game.homeGoals ?? -1))
                      awayWeight = FontWeight.bold;
                  } else {
                    scoreDisplay =
                        "${game.awayGoals ?? '-'} - ${game.homeGoals ?? '-'}";
                    if ((game.awayGoals ?? -1) > (game.homeGoals ?? -1))
                      homeWeight = FontWeight.bold;
                    else if ((game.homeGoals ?? -1) > (game.awayGoals ?? -1))
                      awayWeight = FontWeight.bold;
                  }

                  return ListTile(
                    dense: true,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            currentFixture.homeTeam.name,
                            style: TextStyle(fontWeight: homeWeight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            scoreDisplay,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            currentFixture.awayTeam.name,
                            style: TextStyle(fontWeight: awayWeight),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      "${DateFormatter.formatDayMonth(game.date)} (${game.leagueName})",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String statName,
    String homeValue,
    String awayValue, {
    bool highlightStronger = false,
    bool isLowerBetter = false,
  }) {
    FontWeight homeWeight = FontWeight.normal;
    FontWeight awayWeight = FontWeight.normal;
    Color? homeColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? awayColor = Theme.of(context).textTheme.bodyLarge?.color;
    final Color highlightColor = Theme.of(context).colorScheme.primary;

    if (highlightStronger && homeValue != "-" && awayValue != "-") {
      final double? hVal = double.tryParse(
        homeValue.replaceAll(RegExp(r'[^0-9.]'), ''),
      );
      final double? aVal = double.tryParse(
        awayValue.replaceAll(RegExp(r'[^0-9.]'), ''),
      );

      if (hVal != null && aVal != null) {
        if (isLowerBetter) {
          if (hVal < aVal) {
            homeWeight = FontWeight.bold;
            homeColor = highlightColor;
          } else if (aVal < hVal) {
            awayWeight = FontWeight.bold;
            awayColor = highlightColor;
          }
        } else {
          if (hVal > aVal) {
            homeWeight = FontWeight.bold;
            homeColor = highlightColor;
          } else if (aVal > hVal) {
            awayWeight = FontWeight.bold;
            awayColor = highlightColor;
          }
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              homeValue,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontWeight: homeWeight,
                color: homeColor,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              statName,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              awayValue,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: awayWeight,
                color: awayColor,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamStatHeader(
    BuildContext context,
    String? name,
    String? logoUrl, {
    bool alignRight = false,
    double logoSize = 24,
  }) {
    if (name == null) return const Expanded(child: SizedBox.shrink());
    return Expanded(
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (logoUrl != null)
            CachedNetworkImage(
              imageUrl: logoUrl,
              height: logoSize,
              width: logoSize,
              fit: BoxFit.contain,
              errorWidget:
                  (c, u, e) => Icon(Icons.shield_outlined, size: logoSize),
            ),
          const SizedBox(height: 4),
          Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: alignRight ? TextAlign.end : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
