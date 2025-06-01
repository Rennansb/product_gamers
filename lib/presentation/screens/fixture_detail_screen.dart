// lib/presentation/screens/fixture_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/fixture_full_data.dart';
import 'package:product_gamers/domain/entities/entities/fixture_stats.dart';
import 'package:product_gamers/domain/entities/entities/team.dart';
import 'package:provider/provider.dart';

// Core
import '../../core/utils/date_formatter.dart';

// Domain

// import '../../domain/entities/fixture_league_info_entity.dart'; // Não precisa importar aqui diretamente se Fixture já o contém

// Presentation
import '../providers/fixture_detail_provider.dart';
import '../widgets/common/loading_indicator_widget.dart';
import '../widgets/common/error_display_widget.dart';
import '../widgets/market_odds_widget.dart';

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
      Provider.of<FixtureDetailProvider>(context, listen: false)
          .fetchFixtureDetails();
    });
  }

  Future<void> _refreshDetails() async {
    if (!mounted) return;
    await Provider.of<FixtureDetailProvider>(context, listen: false)
        .fetchFixtureDetails(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FixtureDetailProvider>();
    final fullData = provider.fixtureFullData;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.baseFixture.homeTeam.name} vs ${widget.baseFixture.awayTeam.name}",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            // ===== CORREÇÃO AQUI =====
            Text(
              widget.baseFixture.league
                  .name, // Acessar através do objeto 'league'
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
            // ===========================
          ],
        ),
        actions: [
          if (provider.overallStatus != FixtureDetailOverallStatus.loading ||
              fullData != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Atualizar Detalhes",
              onPressed: _refreshDetails,
            )
        ],
      ),
      body: _buildBody(context, provider, fullData),
    );
  }

  Widget _buildBody(BuildContext context, FixtureDetailProvider provider,
      FixtureFullData? fullData) {
    if (fullData == null &&
        (provider.overallStatus == FixtureDetailOverallStatus.initial ||
            provider.overallStatus == FixtureDetailOverallStatus.loading)) {
      return const LoadingIndicatorWidget(
          message: 'Carregando detalhes do jogo...');
    }
    if (provider.overallStatus == FixtureDetailOverallStatus.error &&
        fullData == null) {
      return ErrorDisplayWidget(
        message:
            provider.generalErrorMessage ?? "Falha ao carregar dados do jogo.",
        onRetry: _refreshDetails,
      );
    }
    if (fullData == null) {
      return ErrorDisplayWidget(
          message: "Erro inesperado ao carregar dados.",
          onRetry: _refreshDetails);
    }

    return RefreshIndicator(
      onRefresh: _refreshDetails,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 16, left: 8, right: 8),
        children: [
          _buildFixtureHeader(context, fullData.baseFixture),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Análise Pré-Jogo 📊'),
          _buildSectionContainer(
            context: context,
            status: fullData.statsStatus,
            errorMessage: fullData.statsErrorMessage,
            onRetrySection: () =>
                provider.fetchFixtureDetails(forceRefresh: true),
            contentBuilder: () => (fullData.fixtureStats != null &&
                    (fullData.fixtureStats?.homeTeam != null ||
                        fullData.fixtureStats?.awayTeam != null))
                ? _buildFixtureStatsComparison(
                    context, fullData.fixtureStats!, fullData.baseFixture)
                : const _NoDataInSectionWidget(
                    message: "Estatísticas pré-jogo não disponíveis."),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Odds Pré-Jogo 🎲'),
          _buildSectionContainer(
            context: context,
            status: fullData.oddsStatus,
            errorMessage: fullData.oddsErrorMessage,
            onRetrySection: () =>
                provider.fetchFixtureDetails(forceRefresh: true),
            contentBuilder: () => fullData.odds.isNotEmpty
                ? Column(
                    children: fullData.odds
                        .map((market) => MarketOddsWidget(market: market))
                        .toList())
                : const _NoDataInSectionWidget(
                    message:
                        "Odds não disponíveis para os mercados de interesse."),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Confronto Direto (H2H) ⚔️'),
          _buildSectionContainer(
            context: context,
            status: fullData.h2hStatus,
            errorMessage: fullData.h2hErrorMessage,
            onRetrySection: () =>
                provider.fetchFixtureDetails(forceRefresh: true),
            contentBuilder: () => (fullData.h2hFixtures?.isNotEmpty ?? false)
                ? _buildH2HSection(
                    context, fullData.h2hFixtures!, fullData.baseFixture)
                : const _NoDataInSectionWidget(
                    message: "Nenhum histórico de confronto direto recente."),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 8, right: 8),
      child: Text(
        title,
        style:
            Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20),
      ),
    );
  }

  Widget _buildSectionContainer({
    required BuildContext context,
    required SectionStatus status,
    String? errorMessage,
    required VoidCallback onRetrySection,
    required Widget Function() contentBuilder,
    String loadingMessage = "Carregando...",
  }) {
    Widget content;
    switch (status) {
      case SectionStatus.initial:
      case SectionStatus.loading:
        content = Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: LoadingIndicatorWidget(message: loadingMessage));
        break;
      case SectionStatus.error:
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ErrorDisplayWidget(
              message: errorMessage ?? "Erro ao carregar dados.",
              onRetry: onRetrySection,
              showRetryButton: true),
        );
        break;
      case SectionStatus.noData:
        content = _NoDataInSectionWidget(
            message: errorMessage ?? "Nenhum dado disponível.");
        break;
      case SectionStatus.loaded:
        content = contentBuilder();
        break;
    }
    return Card(
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: content,
        ));
  }

  Widget _buildFixtureHeader(BuildContext context, Fixture fixture) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool showScore = !["NS", "PST", "CANC", "TBD"]
        .contains(fixture.statusShort.toUpperCase());

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ===== CORREÇÃO AQUI =====
            Text(
              fixture.league.name, // Acessar através do objeto 'league'
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.black87),
              textAlign: TextAlign.center,
            ),
            // ===========================
            const SizedBox(height: 8),
            Text(
              DateFormatter.formatFullDate(fixture.date),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _teamDisplayInHeader(context, fixture.homeTeam),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    showScore
                        ? '${fixture.homeGoals ?? (fixture.fulltimeHomeScore ?? '-')} - ${fixture.awayGoals ?? (fixture.fulltimeAwayScore ?? '-')}'
                        : 'vs',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _teamDisplayInHeader(context, fixture.awayTeam),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              fixture.statusLong,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (fixture.refereeName != null &&
                fixture.refereeName!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.sports, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text("Árbitro: ${fixture.refereeName}",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[700])),
              ]),
            ],
            if (fixture.venueName != null && fixture.venueName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text("Local: ${fixture.venueName}",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[700])),
              ]),
            ]
          ],
        ),
      ),
    );
  }

  Widget _teamDisplayInHeader(BuildContext context, TeamInFixture team) {
    return Expanded(
      child: Column(
        children: [
          team.logoUrl != null
              ? CachedNetworkImage(
                  imageUrl: team.logoUrl!,
                  height: 64,
                  width: 64,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (context, url, error) => Icon(
                      Icons.shield_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.2)),
                )
              : Icon(Icons.shield,
                  size: 64,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 8),
          Text(
            team.name,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFixtureStatsComparison(
      BuildContext context, FixtureStatsEntity stats, Fixture baseFixture) {
    if (stats.homeTeam == null && stats.awayTeam == null) {
      return const _NoDataInSectionWidget(
          message: "Estatísticas pré-jogo detalhadas não disponíveis.");
    }
    return Column(
      children: [
        Row(
          children: [
            _teamStatHeaderInCard(context, baseFixture.homeTeam.name,
                baseFixture.homeTeam.logoUrl),
            const SizedBox(
                width: 8,
                child: Center(
                    child: Text("vs",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)))),
            _teamStatHeaderInCard(context, baseFixture.awayTeam.name,
                baseFixture.awayTeam.logoUrl,
                alignRight: true),
          ],
        ),
        const Divider(height: 20, thickness: 0.5),
        if (stats.homeTeam?.expectedGoals != null ||
            stats.awayTeam?.expectedGoals != null)
          _buildStatRow(
              context,
              "Gols Esperados (xG)",
              stats.homeTeam?.expectedGoals?.toStringAsFixed(2) ?? "-",
              stats.awayTeam?.expectedGoals?.toStringAsFixed(2) ?? "-",
              highlightStronger: true,
              isLowerBetter: false),
        _buildStatRow(
            context,
            "Finalizações (No Gol)",
            "${stats.homeTeam?.shotsTotal ?? '-'}(${stats.homeTeam?.shotsOnGoal ?? '-'})",
            "${stats.awayTeam?.shotsTotal ?? '-'}(${stats.awayTeam?.shotsOnGoal ?? '-'})"),
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
            isLowerBetter: false),
        _buildStatRow(
            context,
            "Escanteios",
            stats.homeTeam?.corners?.toString() ?? "-",
            stats.awayTeam?.corners?.toString() ?? "-",
            highlightStronger: true,
            isLowerBetter: false),
        _buildStatRow(
            context,
            "Faltas Cometidas",
            stats.homeTeam?.fouls?.toString() ?? "-",
            stats.awayTeam?.fouls?.toString() ?? "-",
            highlightStronger: true,
            isLowerBetter: true),
        _buildStatRow(
            context,
            "Cartões Amarelos",
            stats.homeTeam?.yellowCards?.toString() ?? "-",
            stats.awayTeam?.yellowCards?.toString() ?? "-",
            isLowerBetter: true),
      ],
    );
  }

  Widget _buildH2HSection(
      BuildContext context, List<Fixture> h2hFixtures, Fixture currentFixture) {
    return Column(
      children: [
        if (h2hFixtures.isEmpty)
          const _NoDataInSectionWidget(
              message: "Nenhum confronto direto recente encontrado.")
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
              FontWeight homeWeightH2H = FontWeight.normal,
                  awayWeightH2H = FontWeight.normal;

              final h2hHomeGoals = game.homeGoals ?? 0;
              final h2hAwayGoals = game.awayGoals ?? 0;

              if (currentHomeWasHomeInH2H) {
                scoreDisplay = "$h2hHomeGoals - $h2hAwayGoals";
                if (h2hHomeGoals > h2hAwayGoals)
                  homeWeightH2H = FontWeight.bold;
                else if (h2hAwayGoals > h2hHomeGoals)
                  awayWeightH2H = FontWeight.bold; // Corrigido else if
              } else {
                scoreDisplay = "$h2hAwayGoals - $h2hHomeGoals";
                if (h2hAwayGoals > h2hHomeGoals)
                  homeWeightH2H = FontWeight.bold;
                else if (h2hHomeGoals > h2hAwayGoals)
                  awayWeightH2H = FontWeight.bold; // Corrigido else if
              }

              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Row(
                  children: [
                    // ===== CORREÇÃO AQUI (se houver) =====
                    Expanded(
                        child: Text(
                      currentFixture.homeTeam.name,
                      style: TextStyle(fontWeight: homeWeightH2H, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(scoreDisplay,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    Expanded(
                        child: Text(
                      currentFixture.awayTeam.name,
                      style: TextStyle(fontWeight: awayWeightH2H, fontSize: 13),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    )),
                    // =====================================
                  ],
                ),
                // ===== CORREÇÃO AQUI =====
                subtitle: Text(
                  "${DateFormatter.formatDayMonth(game.date)} (${game.league.name})", // Acessar nome da liga do H2H
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontSize: 11),
                ),
                // ===========================
              );
            },
            separatorBuilder: (context, index) =>
                const Divider(height: 8, thickness: 0.3),
          ),
      ],
    );
  }

  Widget _buildStatRow(
      BuildContext context, String statName, String homeValue, String awayValue,
      {bool highlightStronger = false, bool isLowerBetter = false}) {
    FontWeight homeWeight = FontWeight.normal;
    FontWeight awayWeight = FontWeight.normal;
    Color? homeColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? awayColor = Theme.of(context).textTheme.bodyLarge?.color;
    final Color highlightColor = Colors.green.shade700;

    if (highlightStronger && homeValue != "-" && awayValue != "-") {
      final double? hVal =
          double.tryParse(homeValue.replaceAll(RegExp(r'[^0-9.]'), ''));
      final double? aVal =
          double.tryParse(awayValue.replaceAll(RegExp(r'[^0-9.]'), ''));

      if (hVal != null && aVal != null && hVal != aVal) {
        if (isLowerBetter) {
          if (hVal < aVal) {
            homeWeight = FontWeight.bold;
            homeColor = highlightColor;
          } else {
            awayWeight = FontWeight.bold;
            awayColor = highlightColor;
          }
        } else {
          if (hVal > aVal) {
            homeWeight = FontWeight.bold;
            homeColor = highlightColor;
          } else {
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
            child: Text(homeValue,
                textAlign: TextAlign.start,
                style: TextStyle(
                    fontWeight: homeWeight, color: homeColor, fontSize: 15)),
          ),
          Expanded(
            flex: 3,
            child: Text(statName,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(awayValue,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontWeight: awayWeight, color: awayColor, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _teamStatHeaderInCard(
      BuildContext context, String? name, String? logoUrl,
      {bool alignRight = false, double logoSize = 20}) {
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
                errorWidget: (c, u, e) =>
                    Icon(Icons.shield_outlined, size: logoSize)),
          const SizedBox(height: 3),
          Text(
            name,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            textAlign: alignRight ? TextAlign.end : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NoDataInSectionWidget extends StatelessWidget {
  final String message;
  const _NoDataInSectionWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 32, color: Theme.of(context).hintColor),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
