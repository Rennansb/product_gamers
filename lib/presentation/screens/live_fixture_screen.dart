// lib/presentation/screens/live_fixture_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/live_bet_suggestion.dart';
import 'package:product_gamers/domain/entities/entities/live_fixture_update.dart';
import 'package:product_gamers/domain/entities/entities/live_game_insight.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_formatter.dart';
import '../providers/live_fixture_provider.dart';

import '../widgets/common/loading_indicator_widget.dart';
import '../widgets/common/error_display_widget.dart';
// import '../widgets/market_odds_widget.dart'; // Descomente se for exibir odds ao vivo com este widget

class LiveFixtureScreen extends StatelessWidget {
  final Fixture fixtureBasicInfo;

  const LiveFixtureScreen({super.key, required this.fixtureBasicInfo});

  @override
  Widget build(BuildContext context) {
    final liveProvider = context.watch<LiveFixtureProvider>();
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Nomes dos times com fallback para fixtureBasicInfo se liveData ainda for nulo
    String appBarHomeName =
        liveProvider.liveData?.homeTeam.name ?? fixtureBasicInfo.homeTeam.name;
    String appBarAwayName =
        liveProvider.liveData?.awayTeam.name ?? fixtureBasicInfo.awayTeam.name;
    String appBarLeagueName =
        liveProvider.liveData?.leagueName ?? fixtureBasicInfo.leagueName;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$appBarHomeName vs $appBarAwayName",
              style: const TextStyle(fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              appBarLeagueName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (liveProvider.status == LiveFixturePollingStatus.activePolling ||
              liveProvider.status == LiveFixturePollingStatus.error ||
              liveProvider.status == LiveFixturePollingStatus.finished)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Atualizar dados",
              onPressed: () => liveProvider.forceRefresh(),
            ),
        ],
      ),
      body: _buildLiveContent(context, liveProvider, isDarkMode),
    );
  }

  Widget _buildLiveContent(
    BuildContext context,
    LiveFixtureProvider provider,
    bool isDarkMode,
  ) {
    switch (provider.status) {
      case LiveFixturePollingStatus.initial:
      case LiveFixturePollingStatus.loadingFirst:
        return const LoadingIndicatorWidget(
          message: "Carregando dados ao vivo...",
        );
      case LiveFixturePollingStatus.error:
        return ErrorDisplayWidget(
          message: provider.errorMessage ?? "Falha ao carregar dados ao vivo.",
          onRetry: () => provider.forceRefresh(),
        );
      case LiveFixturePollingStatus.activePolling:
      case LiveFixturePollingStatus.finished:
        if (provider.liveData == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Aguardando dados do jogo..."),
                const SizedBox(height: 10),
                if (provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      provider.errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        }
        final liveData = provider.liveData!;
        return RefreshIndicator(
          onRefresh: () => provider.forceRefresh(),
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: [
              _buildScoreboard(context, liveData, isDarkMode),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLiveInsightsSection(
                  context,
                  provider.liveInsights,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLiveSuggestionsSection(
                  context,
                  provider.liveSuggestions,
                  liveData,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildEventsList(context, liveData, isDarkMode),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLiveStatsSection(context, liveData),
              ),
              if (provider.status == LiveFixturePollingStatus.finished)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Card(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Jogo Finalizado: ${liveData.homeTeam.name} ${liveData.homeScore ?? '-'} - ${liveData.awayScore ?? '-'} ${liveData.awayTeam.name} (${liveData.statusShort})",
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      case LiveFixturePollingStatus.disposed:
        return const Center(
          child: Text("Atualizações ao vivo foram interrompidas."),
        );
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTeamLogo(
    String? logoUrl,
    BuildContext context, {
    double size = 40,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return logoUrl != null && logoUrl.isNotEmpty
        ? CachedNetworkImage(
          imageUrl: logoUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholder:
              (context, url) => SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).primaryColor,
                ),
              ),
          errorWidget:
              (context, url, error) => Icon(
                Icons.shield_outlined,
                size: size,
                color: isDarkMode ? Colors.white54 : Colors.black54,
              ),
        )
        : Icon(
          Icons.shield,
          size: size,
          color: isDarkMode ? Colors.white54 : Colors.black54,
        );
  }

  Widget _buildScoreboard(
    BuildContext context,
    LiveFixtureUpdate liveData,
    bool isDarkMode,
  ) {
    final homeTeamName = liveData.homeTeam.name;
    final awayTeamName = liveData.awayTeam.name;
    final homeTeamLogo = liveData.homeTeam.logoUrl;
    final awayTeamLogo = liveData.awayTeam.logoUrl;
    final homeScore = liveData.homeScore ?? 0;
    final awayScore = liveData.awayScore ?? 0;
    final elapsed = liveData.elapsedMinutes ?? 0;
    final statusShort = liveData.statusShort ?? "NS";
    final statusLong = liveData.statusLong ?? "Não Iniciado";

    Color liveStatusColor =
        statusShort == "HT"
            ? Colors.orangeAccent.shade700
            : Theme.of(context).colorScheme.error; // Vermelho padrão para LIVE
    if (["FT", "AET", "PEN"].contains(statusShort)) {
      liveStatusColor =
          Theme.of(
            context,
          ).colorScheme.secondary; // Cor secundária para finalizado
    } else if (statusShort == "NS" || statusShort == "PST") {
      liveStatusColor = Colors.grey.shade500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Theme.of(context).cardTheme.color?.withOpacity(0.5)
                : Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(homeTeamLogo, context, size: 50),
                    const SizedBox(height: 8),
                    Text(
                      homeTeamName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      "$homeScore - $awayScore",
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold), // Aumentado
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: liveStatusColor,
                        borderRadius: BorderRadius.circular(
                          20,
                        ), // Mais arredondado
                      ),
                      child: Text(
                        (elapsed > 0 &&
                                ![
                                  "HT",
                                  "FT",
                                  "AET",
                                  "PEN",
                                  "NS",
                                  "PST",
                                ].contains(statusShort))
                            ? "$elapsed'"
                            : statusShort,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ), // Ajustado
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(awayTeamLogo, context, size: 50),
                    const SizedBox(height: 8),
                    Text(
                      awayTeamName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (statusLong != statusShort &&
              (elapsed == 0 ||
                  ["NS", "PST", "CANC", "ABD"].contains(statusShort)) &&
              !["HT", "FT", "AET", "PEN"].contains(statusShort))
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                statusLong,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsList(
    BuildContext context,
    LiveFixtureUpdate liveData,
    bool isDarkMode,
  ) {
    final events = liveData.events;
    if (events.isEmpty &&
        (liveData.statusShort == "NS" || (liveData.elapsedMinutes ?? 0) < 1)) {
      return Card(
        elevation: 0,
        color:
            isDarkMode
                ? Theme.of(context).cardTheme.color?.withOpacity(0.3)
                : Colors.grey[100],
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "O jogo ainda não começou ou não há eventos registrados.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (events.isEmpty) {
      return Card(
        elevation: 0,
        color:
            isDarkMode
                ? Theme.of(context).cardTheme.color?.withOpacity(0.3)
                : Colors.grey[100],
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "Sem eventos importantes até o momento.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    // Mostrar os eventos em ordem cronológica (API já costuma retornar assim)
    // Ou podemos inverter para mostrar os mais recentes no topo se desejado: `events.reversed.toList()`
    final displayedEvents =
        events.length > 7
            ? events.reversed.toList().sublist(0, 7)
            : events.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "Linha do Tempo ⏱️"),
        Card(
          elevation: 1.5,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedEvents.length,
            itemBuilder: (ctx, index) {
              final event = displayedEvents[index];
              IconData iconData;
              Color iconColor = Theme.of(context).colorScheme.primary;
              String eventTitle = "${event.type}: ${event.detail}";
              String eventSubtitleDetails = "Time: ${event.teamName ?? 'N/A'}";
              if (event.comments != null && event.comments!.isNotEmpty) {
                eventSubtitleDetails += " - ${event.comments}";
              }

              switch (event.type.toLowerCase()) {
                case "goal":
                  iconData = Icons.sports_soccer;
                  iconColor = Colors.green.shade600;
                  eventTitle =
                      "GOL! ${event.playerName ?? event.teamName ?? ''}";
                  if (event.assistPlayerName != null)
                    eventTitle += " (Ass: ${event.assistPlayerName})";
                  break;
                case "card":
                  iconData = Icons.sticky_note_2_outlined;
                  iconColor =
                      event.detail.toLowerCase().contains("yellow card")
                          ? Colors.amber.shade700
                          : Colors.red.shade700;
                  eventTitle = "${event.detail} para ${event.playerName ?? ''}";
                  break;
                case "subst":
                  iconData = Icons.swap_horiz_rounded;
                  iconColor = Colors.blueGrey.shade400;
                  eventTitle = "Substituição";
                  eventSubtitleDetails =
                      "Sai: ${event.assistPlayerName ?? 'N/A'}\nEntra: ${event.playerName ?? 'N/A'} (${event.teamName ?? 'N/A'})";
                  break;
                case "var":
                  iconData = Icons.switch_video_outlined;
                  iconColor = Colors.purple.shade400;
                  eventTitle = "VAR: ${event.detail}";
                  break;
                default:
                  iconData = Icons.info_outline_rounded;
              }

              return ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${event.timeElapsed ?? ''}'${event.timeExtra != null ? "+${event.timeExtra}" : ""}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(iconData, color: iconColor, size: 28),
                  ],
                ),
                title: Text(
                  eventTitle,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  eventSubtitleDetails,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                dense: true,
              );
            },
            separatorBuilder:
                (_, __) => const Divider(
                  height: 1,
                  indent: 70,
                  endIndent: 16,
                ), // Ajustado indent
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStatsSection(
    BuildContext context,
    LiveFixtureUpdate liveData,
  ) {
    if (liveData.homeTeamLiveStats == null &&
        liveData.awayTeamLiveStats == null) {
      return Card(/* ... como antes ... */);
    }

    final homeStats = liveData.homeTeamLiveStats;
    final awayStats = liveData.awayTeamLiveStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "Estatísticas Ao Vivo 📈"),
        Card(
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    _teamStatHeader(
                      context,
                      liveData.homeTeam.name,
                      liveData.homeTeam.logoUrl,
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
                      liveData.awayTeam.name,
                      liveData.awayTeam.logoUrl,
                      alignRight: true,
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (homeStats?.expectedGoalsLive != null ||
                    awayStats?.expectedGoalsLive != null)
                  _buildStatRow(
                    context,
                    "Gols Esperados (xG)",
                    homeStats?.expectedGoalsLive?.toStringAsFixed(2) ?? "-",
                    awayStats?.expectedGoalsLive?.toStringAsFixed(2) ?? "-",
                    highlightStronger: true,
                    isLowerBetter: false,
                  ),
                _buildStatRow(
                  context,
                  "Finalizações (No Gol)",
                  "${homeStats?.totalShots ?? '-'}(${homeStats?.shotsOnGoal ?? '-'})",
                  "${awayStats?.totalShots ?? '-'}(${awayStats?.shotsOnGoal ?? '-'})",
                ),
                _buildStatRow(
                  context,
                  "Posse de Bola",
                  homeStats?.ballPossession ?? "-",
                  awayStats?.ballPossession ?? "-",
                  highlightStronger: true,
                  isLowerBetter: false,
                ),
                _buildStatRow(
                  context,
                  "Escanteios",
                  homeStats?.corners?.toString() ?? "-",
                  awayStats?.corners?.toString() ?? "-",
                  highlightStronger: true,
                  isLowerBetter: false,
                ),
                _buildStatRow(
                  context,
                  "Cartões Amarelos",
                  homeStats?.yellowCards?.toString() ?? "-",
                  awayStats?.yellowCards?.toString() ?? "-",
                  isLowerBetter: true,
                ),
                _buildStatRow(
                  context,
                  "Cartões Vermelhos",
                  homeStats?.redCards?.toString() ?? "-",
                  awayStats?.redCards?.toString() ?? "-",
                  isLowerBetter: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveSuggestionsSection(
    BuildContext context,
    List<LiveBetSuggestion> suggestions,
    LiveFixtureUpdate liveData,
  ) {
    if (suggestions.isEmpty) {
      return Card(/* ... como antes ... */);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "Sugestões Ao Vivo 💡"),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          itemBuilder: (ctx, index) {
            final suggestion = suggestions[index];
            Color strengthColor;
            String strengthText;
            IconData strengthIcon;

            switch (suggestion.strength) {
              case BetSuggestionStrength.low:
                strengthColor = Colors.orange.shade400;
                strengthText = "Baixa";
                strengthIcon = Icons.arrow_downward_rounded;
                break;
              case BetSuggestionStrength.medium:
                strengthColor = Colors.amber.shade700;
                strengthText = "Média";
                strengthIcon = Icons.arrow_forward_rounded;
                break;
              case BetSuggestionStrength.high:
                strengthColor = Colors.green.shade600;
                strengthText = "Alta";
                strengthIcon = Icons.arrow_upward_rounded;
                break;
            }

            return Card(
              elevation: 1.5,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: strengthColor.withOpacity(0.6),
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            "${suggestion.marketName}: ${suggestion.selectionName}",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            "Odd: ${suggestion.currentOdd}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      suggestion.reasoning,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 13.5),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          avatar: Icon(
                            strengthIcon,
                            size: 16,
                            color: strengthColor,
                          ),
                          label: Text(
                            "Confiança: $strengthText",
                            style: TextStyle(
                              fontSize: 12,
                              color: strengthColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // ignore: deprecated_member_use
                          backgroundColor: strengthColor.withOpacity(0.1),
                          // ignore: deprecated_member_use
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: strengthColor.withOpacity(0.3),
                            ),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 0,
                          ),
                        ),
                        Text(
                          "${suggestion.currentScore} (${suggestion.suggestedAtMinute ?? liveData.elapsedMinutes ?? ''}')",
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLiveInsightsSection(
    BuildContext context,
    List<LiveGameInsight> insights,
  ) {
    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "Insights Ao Vivo 🔥"),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: insights.length,
          itemBuilder: (ctx, index) {
            final insight = insights[index];
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              color:
                  insight.iconColor?.withOpacity(0.08) ??
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color:
                      insight.iconColor?.withOpacity(0.4) ?? Colors.transparent,
                  width: 0.7,
                ),
              ),
              child: ListTile(
                leading:
                    insight.icon != null
                        ? CircleAvatar(
                          backgroundColor:
                              insight.iconColor?.withOpacity(0.2) ??
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            insight.icon,
                            color:
                                insight.iconColor ??
                                Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                        )
                        : null,
                title: Text(
                  insight.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
                subtitle: Text(
                  "Às ${DateFormat.Hm('pt_BR').format(insight.timestamp.toLocal())}${insight.relatedTeamName != null ? ' - ${insight.relatedTeamName}' : ''}",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                dense: true,
              ),
            );
          },
        ),
      ],
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
      final hValStr = homeValue.replaceAll(RegExp(r'[^0-9.]'), '');
      final aValStr = awayValue.replaceAll(RegExp(r'[^0-9.]'), '');
      if (hValStr.isNotEmpty && aValStr.isNotEmpty) {
        final double? hVal = double.tryParse(hValStr);
        final double? aVal = double.tryParse(aValStr);

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
          if (logoUrl != null && logoUrl.isNotEmpty)
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ), // Ajustado para titleMedium
            textAlign: alignRight ? TextAlign.end : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
