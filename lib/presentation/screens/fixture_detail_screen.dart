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
      // Dispara o fetch inicial quando a tela é construída e o provider está disponível
      // O provider é criado na FixturesScreen durante a navegação.
      Provider.of<FixtureDetailProvider>(context, listen: false)
          .fetchFixtureDetails();
    });
  }

  Future<void> _refreshAllDetails() async {
    if (!mounted) return;
    await Provider.of<FixtureDetailProvider>(context, listen: false)
        .fetchFixtureDetails(forceRefresh: true);
  }

  // Funções para refresh individual de seções (exemplo)
  // Future<void> _refreshStatsSection() async {
  //   if (!mounted) return;
  //   await Provider.of<FixtureDetailProvider>(context, listen: false).fetchStats(forceRefresh: true);
  // }
  // Future<void> _refreshOddsSection() async { ... }
  // Future<void> _refreshH2HSection() async { ... }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FixtureDetailProvider>();
    // Usar o baseFixture do provider se disponível (após o primeiro fetch),
    // senão, usar o widget.baseFixture para o cabeçalho inicial.
    final Fixture displayFixture =
        provider.fixtureFullData?.baseFixture ?? widget.baseFixture;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${displayFixture.homeTeam.name} vs ${displayFixture.awayTeam.name}",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              displayFixture.league.name, // Acessa o nome da liga corretamente
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (provider.overallStatus != FixtureDetailOverallStatus.loading ||
              provider.fixtureFullData != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Atualizar Tudo",
              onPressed: _refreshAllDetails,
            )
        ],
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, FixtureDetailProvider provider) {
    final fullData = provider.fixtureFullData;

    // Loading geral inicial (antes que fullData seja populado pela primeira vez)
    if (provider.overallStatus == FixtureDetailOverallStatus.initial ||
        (provider.overallStatus == FixtureDetailOverallStatus.loading &&
            fullData == null)) {
      return const LoadingIndicatorWidget(
          message: 'Carregando detalhes do jogo...');
    }

    // Erro geral catastrófico (nenhum dado pôde ser carregado)
    if (provider.overallStatus == FixtureDetailOverallStatus.error &&
        fullData == null) {
      return ErrorDisplayWidget(
        message: provider.generalErrorMessage ??
            "Falha ao carregar todos os dados do jogo.",
        onRetry: _refreshAllDetails,
      );
    }

    // Se fullData ainda for nulo após as checagens acima (improvável, mas como fallback)
    if (fullData == null) {
      return ErrorDisplayWidget(
          message: "Erro inesperado ao preparar dados.",
          onRetry: _refreshAllDetails);
    }

    return RefreshIndicator(
      onRefresh: _refreshAllDetails,
      child: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: 12.0, vertical: 8.0), // Padding geral para o conteúdo
        children: [
          _buildFixtureHeader(
              context,
              fullData
                  .baseFixture), // Usa o baseFixture para consistência no header
          const SizedBox(height: 20),

          _buildSectionTitle(context, 'Análise Pré-Jogo 📊'),
          _buildSectionContainer(
            context: context,
            status: fullData.statsStatus,
            errorMessage: fullData.statsErrorMessage,
            loadingMessage: "Carregando estatísticas...",
            onRetrySection: () =>
                Provider.of<FixtureDetailProvider>(context, listen: false)
                    .fetchFixtureDetails(
                        forceRefresh: true), // Ou _refreshStatsSection()
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
            loadingMessage: "Carregando odds...",
            onRetrySection: () =>
                Provider.of<FixtureDetailProvider>(context, listen: false)
                    .fetchFixtureDetails(
                        forceRefresh: true), // Ou _refreshOddsSection()
            contentBuilder: () => fullData.odds.isNotEmpty
                ? Column(
                    children: fullData.odds
                        .map((market) => MarketOddsWidget(market: market))
                        .toList())
                : const _NoDataInSectionWidget(
                    message:
                        "Nenhuma odd para os mercados de interesse foi encontrada."),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle(context, 'Confronto Direto (H2H) ⚔️'),
          _buildSectionContainer(
            context: context,
            status: fullData.h2hStatus,
            errorMessage: fullData.h2hErrorMessage,
            loadingMessage: "Carregando H2H...",
            onRetrySection: () =>
                Provider.of<FixtureDetailProvider>(context, listen: false)
                    .fetchFixtureDetails(
                        forceRefresh: true), // Ou _refreshH2HSection()
            contentBuilder: () => (fullData.h2hFixtures?.isNotEmpty ?? false)
                ? _buildH2HSection(
                    context, fullData.h2hFixtures!, fullData.baseFixture)
                : const _NoDataInSectionWidget(
                    message:
                        "Nenhum histórico de confronto direto recente foi encontrado."),
          ),
          const SizedBox(height: 20), // Espaço no final da lista
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: 8.0, top: 12.0), // Adicionado top padding
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontSize: 19, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSectionContainer({
    required BuildContext context,
    required SectionStatus status,
    String? errorMessage,
    required VoidCallback onRetrySection,
    required Widget Function() contentBuilder,
    required String loadingMessage,
  }) {
    Widget content;
    switch (status) {
      case SectionStatus
            .initial: // Trata initial como loading para evitar piscar
      case SectionStatus.loading:
        content = Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: LoadingIndicatorWidget(message: loadingMessage));
        break;
      case SectionStatus.error:
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ErrorDisplayWidget(
              message: errorMessage ?? "Erro ao carregar dados.",
              onRetry: onRetrySection,
              showRetryButton: true),
        );
        break;
      case SectionStatus.noData:
        content = _NoDataInSectionWidget(
            message: errorMessage ?? "Nenhum dado disponível para esta seção.");
        break;
      case SectionStatus.loaded:
        content = contentBuilder();
        break;
    }
    return Card(
        elevation: 1.0, // Sombra sutil
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: content,
        ));
  }

  // --- WIDGETS DE CONTEÚDO DAS SEÇÕES ---
  // (Cole aqui as implementações de _buildFixtureHeader, _teamDisplayInHeader,
  //  _buildFixtureStatsComparison, _buildH2HSection, _buildStatRow,
  //  _teamStatHeaderInCard, e _NoDataInSectionWidget como na resposta anterior)
  // Eles já estavam corretos e usando fixture.league.name onde necessário.

  // Vou colar novamente por completude:
  Widget _buildFixtureHeader(BuildContext context, Fixture fixture) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool showScore = !["NS", "PST", "CANC", "TBD"]
        .contains(fixture.statusShort.toUpperCase());

    return Card(
      elevation: 2, // Um pouco mais de elevação para o header
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12), // Margem inferior
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              fixture.league.name, // Acesso correto
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              DateFormatter.formatFullDate(fixture.date),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
                        : (fixture.statusShort.toUpperCase() == "TBD"
                            ? "TBD"
                            : DateFormatter.formatTimeOnly(fixture.date)),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 26), // Ajuste de tamanho
                  ),
                ),
                _teamDisplayInHeader(context, fixture.awayTeam),
              ],
            ),
            const SizedBox(height: 14),
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
                Icon(Icons.sports_kabaddi_outlined,
                    size: 14,
                    color: Colors.grey[600]), // Ícone diferente para árbitro
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
                  height: 56, width: 56, // Um pouco menor para o header
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(strokeWidth: 1.5)),
                  errorWidget: (context, url, error) => Icon(
                      Icons.shield_outlined,
                      size: 56,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.2)),
                )
              : Icon(Icons.shield,
                  size: 56,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 8),
          Text(
            team.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold, fontSize: 13), // Ajuste de tamanho
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFixtureStatsComparison(
      BuildContext context, FixtureStatsEntity stats, Fixture baseFixture) {
    if (stats.homeTeam == null &&
        stats.awayTeam == null &&
        (stats.homeTeam?.expectedGoals == null &&
            stats.awayTeam?.expectedGoals == null)) {
      // Checagem mais específica
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
                            fontWeight: FontWeight.bold, fontSize: 11)))),
            _teamStatHeaderInCard(context, baseFixture.awayTeam.name,
                baseFixture.awayTeam.logoUrl,
                alignRight: true),
          ],
        ),
        const Divider(height: 16, thickness: 0.5), // Menor altura
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
            "Escanteios", // Escanteios *neste* jogo (geralmente nulo pré-jogo)
            stats.homeTeam?.corners?.toString() ?? "-",
            stats.awayTeam?.corners?.toString() ?? "-",
            highlightStronger: true,
            isLowerBetter: false // Mais escanteios é geralmente melhor
            ),
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
        // Não precisa do if h2hFixtures.isEmpty aqui, pois _NoDataInSectionWidget já é retornado pelo _buildSectionContainer
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
                awayWeightH2H = FontWeight.bold;
            } else {
              scoreDisplay = "$h2hAwayGoals - $h2hHomeGoals";
              if (h2hAwayGoals > h2hHomeGoals)
                homeWeightH2H = FontWeight.bold;
              else if (h2hHomeGoals > h2hAwayGoals)
                awayWeightH2H = FontWeight.bold;
            }

            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 2, vertical: 0), // Ajustado
              title: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centralizar a linha do placar
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(
                        currentFixture.homeTeam.name,
                        style:
                            TextStyle(fontWeight: homeWeightH2H, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      )),
                  Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(scoreDisplay,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center),
                      )),
                  Expanded(
                      flex: 3,
                      child: Text(
                        currentFixture.awayTeam.name,
                        style:
                            TextStyle(fontWeight: awayWeightH2H, fontSize: 12),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                      )),
                ],
              ),
              subtitle: Text(
                "${DateFormatter.formatDayMonth(game.date)} (${game.league.name})", // Acesso correto
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 10), // Menor
              ),
            );
          },
          separatorBuilder: (context, index) =>
              const Divider(height: 6, thickness: 0.3),
        ),
      ],
    );
  }

  Widget _buildStatRow(
      BuildContext context, String statName, String homeValue, String awayValue,
      {bool highlightStronger = false, bool isLowerBetter = false}) {
    FontWeight homeWeight = FontWeight.normal;
    FontWeight awayWeight = FontWeight.normal;
    Color? homeColor = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.color; // Usar bodyMedium para consistência
    Color? awayColor = Theme.of(context).textTheme.bodyMedium?.color;
    final Color highlightColor =
        Theme.of(context).colorScheme.primary; // Usar cor primária do tema

    if (highlightStronger && homeValue != "-" && awayValue != "-") {
      final hValStr = homeValue.replaceAll(RegExp(r'[^0-9.]'), '');
      final aValStr = awayValue.replaceAll(RegExp(r'[^0-9.]'), '');
      if (hValStr.isNotEmpty && aValStr.isNotEmpty) {
        final double? hVal = double.tryParse(hValStr);
        final double? aVal = double.tryParse(aValStr);

        if (hVal != null && aVal != null && (hVal - aVal).abs() > 0.01) {
          // Só destaca se houver diferença real
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
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Leve ajuste
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(homeValue,
                textAlign: TextAlign.start,
                style: TextStyle(
                    fontWeight: homeWeight, color: homeColor, fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Text(statName,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(awayValue,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontWeight: awayWeight, color: awayColor, fontSize: 14)),
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
          if (logoUrl != null && logoUrl.isNotEmpty)
            CachedNetworkImage(
                imageUrl: logoUrl,
                height: logoSize,
                width: logoSize,
                fit: BoxFit.contain,
                errorWidget: (c, u, e) => Icon(Icons.shield_outlined,
                    size: logoSize, color: Theme.of(context).hintColor)),
          const SizedBox(height: 2),
          Text(
            name,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w500), // Ajuste
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
    return Container(
      // Container para dar um padding e talvez um fundo sutil
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      // color: Theme.of(context).cardColor.withOpacity(0.5), // Opcional: fundo sutil
      // decoration: BoxDecoration(
      //   color: Theme.of(context).disabledColor.withOpacity(0.05),
      //   borderRadius: BorderRadius.circular(8)
      // ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 30, color: Theme.of(context).hintColor),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
}
