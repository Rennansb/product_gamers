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
  final Fixture fixtureBasicInfo; // Este é o Fixture com a estrutura atualizada

  const LiveFixtureScreen({super.key, required this.fixtureBasicInfo});

  @override
  Widget build(BuildContext context) {
    final liveProvider = context.watch<LiveFixtureProvider>();
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${fixtureBasicInfo.homeTeam.name} vs ${fixtureBasicInfo.awayTeam.name} (Ao Vivo)",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500), // Ajuste de tamanho
              overflow: TextOverflow.ellipsis,
            ),
            // ===== CORREÇÃO AQUI =====
            Text(
              liveProvider.liveData?.leagueName ??
                  fixtureBasicInfo.league
                      .name, // Usar liveData se disponível, senão o baseFixture.league.name
              style: const TextStyle(
                  fontSize: 11, color: Colors.white70), // Ajuste de tamanho
              overflow: TextOverflow.ellipsis,
            ),
            // ===========================
          ],
        ),
        actions: [
          if (liveProvider.status == LiveFixturePollingStatus.activePolling ||
              liveProvider.status == LiveFixturePollingStatus.error ||
              liveProvider.status == LiveFixturePollingStatus.finished)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Atualizar Dados Ao Vivo",
              onPressed: () => liveProvider.forceRefresh(),
            ),
        ],
      ),
      body: _buildLiveContent(context, liveProvider, isDarkMode),
    );
  }

  Widget _buildLiveInsightsSection(
      BuildContext context, List<LiveGameInsight> insights) {
    if (insights.isEmpty) {
      // Você pode optar por não mostrar nada ou uma mensagem sutil
      return const SizedBox.shrink();
      // Ou:
      // return Padding(
      //   padding: const EdgeInsets.symmetric(vertical: 16.0),
      //   child: Center(child: Text("Nenhum insight especial no momento.", style: Theme.of(context).textTheme.bodySmall)),
      // );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          // Ajuste no estilo do título para ser consistente com outros títulos de seção
          child: Text("Insights Ao Vivo 🔥",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: insights
              .length, // Já está ordenado (mais recente primeiro no provider)
          itemBuilder: (ctx, index) {
            final insight = insights[index];
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              color: insight.iconColor?.withOpacity(0.12) ??
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Borda mais suave
                  side: BorderSide(
                      color: insight.iconColor?.withOpacity(0.5) ??
                          Colors.transparent,
                      width: 1)),
              child: ListTile(
                leading: insight.icon != null
                    ? Icon(insight.icon,
                        color: insight.iconColor ??
                            Theme.of(context).colorScheme.primary,
                        size: 30) // Ícone um pouco maior
                    : null,
                title: Text(insight.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  "Detectado: ${DateFormat.Hm('pt_BR').format(insight.timestamp.toLocal())}${insight.relatedTeamName != null ? ' - Ref: ${insight.relatedTeamName}' : ''}",
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontSize: 11),
                ),
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLiveContent(
      BuildContext context, LiveFixtureProvider provider, bool isDarkMode) {
    switch (provider.status) {
      case LiveFixturePollingStatus.initial:
      case LiveFixturePollingStatus.loadingFirst:
        return const LoadingIndicatorWidget(
            message: "Carregando dados ao vivo...");
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
                Text(
                  provider.errorMessage!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
            ],
          ));
        }
        final liveData = provider.liveData!;
        return RefreshIndicator(
          onRefresh: () => provider.forceRefresh(),
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: [
              _buildScoreboard(context, liveData, fixtureBasicInfo,
                  isDarkMode), // Passa fixtureBasicInfo para fallback de logos
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLiveInsightsSection(context,
                    provider.liveInsights), // Mantido da Fase de Insights
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildEventsList(
                    context, liveData), // Passar liveData para nomes de times
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLiveStatsSection(context, liveData),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLiveSuggestionsSection(
                    context,
                    provider.liveSuggestions,
                    liveData), // Para futuras sugestões
              ),
              if (provider.status == LiveFixturePollingStatus.finished)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 24.0, horizontal: 16.0),
                  child: Card(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Jogo Finalizado: ${liveData.homeTeamName} ${liveData.homeScore ?? '-'} - ${liveData.awayScore ?? '-'} ${liveData.awayTeamName} (${liveData.statusShort})",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                                fontWeight: FontWeight.bold),
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
            child: Text("Atualizações ao vivo foram interrompidas."));
    }
  }

  // Helper para logo, similar ao de FixtureCardWidget e FixtureDetailScreen
  Widget _buildTeamLogo(String? logoUrl, BuildContext context,
      {double size = 40}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor =
        Theme.of(context).colorScheme.primary.withOpacity(0.08);
    final iconColor = Theme.of(context).colorScheme.primary.withOpacity(0.7);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: iconColor),
              ),
              errorWidget: (context, url, error) => Icon(Icons.shield_outlined,
                  size: size * 0.6, color: iconColor),
            )
          : Icon(Icons.shield, size: size * 0.6, color: iconColor),
    );
  }

  Widget _buildScoreboard(BuildContext context, LiveFixtureUpdate liveData,
      Fixture fixtureBase, bool isDarkMode) {
    final homeTeamName = liveData.homeTeamName; // Vem do LiveFixtureUpdate
    final awayTeamName = liveData.awayTeamName; // Vem do LiveFixtureUpdate
    final homeTeamLogo = liveData.homeTeamLogoUrl ??
        fixtureBase.homeTeam.logoUrl; // Fallback para o logo do fixture base
    final awayTeamLogo =
        liveData.awayTeamLogoUrl ?? fixtureBase.awayTeam.logoUrl; // Fallback

    final homeScore = liveData.homeScore ?? 0;
    final awayScore = liveData.awayScore ?? 0;
    final elapsed = liveData.elapsedMinutes ?? 0;
    final statusShort = liveData.statusShort ?? fixtureBase.statusShort;
    final statusLong = liveData.statusLong ?? fixtureBase.statusLong;

    Color liveStatusColor = statusShort == "HT"
        ? Colors.orangeAccent.shade700
        : Colors.redAccent.shade400;
    if (["FT", "AET", "PEN"].contains(statusShort)) {
      liveStatusColor =
          isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700;
    }
    if (statusShort == "NS" || statusShort == "TBD") {
      liveStatusColor =
          isDarkMode ? Colors.blueGrey.shade300 : Colors.blueGrey.shade500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: 16.0, horizontal: 16.0), // Reduzido padding vertical
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.2)
            : Theme.of(context).canvasColor, // Cor de fundo sutil
        // border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.8))
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(homeTeamLogo, context,
                        size: 48), // Tamanho ligeiramente menor
                    const SizedBox(height: 6),
                    Text(
                      homeTeamName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    Text(
                      "$homeScore - $awayScore",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: liveStatusColor,
                          borderRadius: BorderRadius.circular(16)),
                      child: Text(
                        (elapsed > 0 &&
                                !["HT", "FT", "AET", "PEN", "NS", "TBD"]
                                    .contains(statusShort))
                            ? "$elapsed'"
                            : statusShort,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(awayTeamLogo, context, size: 48),
                    const SizedBox(height: 6),
                    Text(
                      awayTeamName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
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
                  ["NS", "TBD", "PST", "CANC"].contains(statusShort)))
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(statusLong,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor)),
            )
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, LiveFixtureUpdate liveData) {
    // Modificado para receber liveData
    final events = liveData.events; // Pega os eventos do liveData
    if (events.isEmpty &&
        (liveData.statusShort == "NS" || (liveData.elapsedMinutes ?? 0) < 1)) {
      return Card(
          elevation: 0,
          color: Theme.of(context).cardColor.withOpacity(0.5),
          child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                  child: Text("O jogo ainda não começou ou não há eventos.",
                      textAlign: TextAlign.center))));
    }
    if (events.isEmpty) {
      return Card(
          elevation: 0,
          color: Theme.of(context).cardColor.withOpacity(0.5),
          child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                  child: Text("Sem eventos importantes até o momento.",
                      textAlign: TextAlign.center))));
    }
    final displayedEvents = events.length > 7
        ? events.sublist(events.length - 7)
        : events; // Aumentei para 7

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Linha do Tempo ⏱️",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayedEvents.length,
          itemBuilder: (ctx, index) {
            final event = displayedEvents.reversed.toList()[index];
            IconData iconData;
            Color iconColor = Theme.of(context).colorScheme.primary;
            String eventTitle = "${event.type}: ${event.detail}";

            // ===== CORREÇÃO AQUI para teamNameForEvent =====
            String teamNameForEvent = event.teamName ??
                (event.teamId == liveData.homeTeamId
                    ? liveData.homeTeamName
                    : (event.teamId == liveData.awayTeamId
                        ? liveData.awayTeamName
                        : "Time Desconhecido"));
            // =============================================

            switch (event.type.toLowerCase()) {
              case "goal":
                iconData = Icons.sports_soccer;
                iconColor = Colors.green.shade600;
                eventTitle = "GOL! ${event.playerName ?? ''}";
                break;
              case "card":
                iconData = Icons.style;
                iconColor = event.detail.toLowerCase().contains("yellow")
                    ? Colors.amber.shade700
                    : Colors.red.shade700;
                eventTitle = "${event.detail} para ${event.playerName ?? ''}";
                break;
              case "subst":
                iconData = Icons.swap_horiz;
                iconColor = Colors.blueGrey.shade400;
                eventTitle =
                    "Sub: ${event.playerName ?? '?'} entra, ${event.assistPlayerName ?? '?'} sai";
                break;
              case "var":
                iconData = Icons.videocam_outlined;
                iconColor = Colors.purple.shade300;
                eventTitle = "VAR: ${event.detail}";
                break;
              default:
                iconData = Icons.info_outline;
            }

            String teamOfEventBadge = "";
            // ===== CORREÇÃO AQUI para teamOfEventBadge =====
            if (event.teamId == liveData.homeTeamId) {
              teamOfEventBadge = "(C)";
            } else if (event.teamId == liveData.awayTeamId) {
              teamOfEventBadge = "(F)";
            }
            // =============================================

            return Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.5),
                          width: 0.5))),
              child: Row(
                children: [
                  SizedBox(
                    width: 55,
                    child: Column(
                      children: [
                        Text(
                            "${event.timeElapsed ?? ''}'${event.timeExtra != null ? "+${event.timeExtra}" : ""}",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Icon(iconData, color: iconColor, size: 24),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(eventTitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500)),
                        if (teamNameForEvent.isNotEmpty ||
                            (event.comments?.isNotEmpty ?? false))
                          Text(
                            "${teamNameForEvent.isNotEmpty ? '$teamNameForEvent. ' : ''}${event.comments ?? ''}",
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (teamOfEventBadge
                      .isNotEmpty) // Só mostra o badge se o time foi identificado
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(teamOfEventBadge,
                          style: TextStyle(
                              color: iconColor.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLiveStatsSection(
      BuildContext context, LiveFixtureUpdate liveData) {
    if (liveData.homeTeamLiveStats == null &&
        liveData.awayTeamLiveStats == null) {
      return Card(
          elevation: 0,
          color: Theme.of(context).cardColor.withOpacity(0.5),
          child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                  child: Text(
                      "Estatísticas ao vivo detalhadas não disponíveis.",
                      textAlign: TextAlign.center))));
    }
    // (Reutilizar/Adaptar _buildFixtureStatsComparison da FixtureDetailScreen para TeamLiveStats)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Estatísticas do Jogo 📈",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
            /* ... Implementar exibição das TeamLiveStats ... */
            child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
              "Placeholder para exibir estatísticas ao vivo como posse, chutes, xG ao vivo."),
        )),
      ],
    );
  }

  Widget _buildLiveSuggestionsSection(BuildContext context,
      List<LiveBetSuggestion> suggestions, LiveFixtureUpdate liveData) {
    // (Reutilizar/Adaptar o _buildLiveSuggestionsSection que já fizemos, se tiver sugestões)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Sugestões Ao Vivo 💡",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
            elevation: 0,
            color: Theme.of(context).cardColor.withOpacity(0.5),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                  child: Text("Motor de sugestões ao vivo em desenvolvimento.",
                      textAlign: TextAlign.center)),
            )),
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
              errorWidget: (c, u, e) =>
                  Icon(Icons.shield_outlined, size: logoSize),
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
