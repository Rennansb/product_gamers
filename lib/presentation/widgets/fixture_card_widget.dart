// lib/presentation/widgets/fixture_card_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import '../../core/utils/date_formatter.dart';

// A entidade TeamInFixture é usada dentro da entidade Fixture, então não precisa de import direto aqui.

class FixtureCardWidget extends StatelessWidget {
  final Fixture fixture;
  final VoidCallback onTap;

  const FixtureCardWidget({
    super.key,
    required this.fixture,
    required this.onTap,
  });

  // Helper widget para construir o logo do time
  Widget _buildTeamLogo(String? logoUrl, BuildContext context,
      {double size = 38}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Usar cores do tema para consistência
    final placeholderBackgroundColor =
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
    final iconColor =
        Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: placeholderBackgroundColor, // Cor de fundo suave para o círculo
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit
                  .contain, // Usar contain para logos que não são perfeitamente redondos
              placeholder: (context, url) => Padding(
                padding: EdgeInsets.all(
                    size * 0.2), // Placeholder proporcional ao tamanho
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.shield_outlined,
                size: size * 0.6,
                color: iconColor,
              ),
            )
          : Icon(
              Icons.shield, // Ícone padrão para time sem logo
              size: size * 0.6,
              color: iconColor,
            ),
    );
  }

  // Helper para determinar a cor do status do jogo
  Color _getStatusColor(BuildContext context, String? statusShort) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color liveColor = Colors.redAccent.shade400;
    final Color finishedColor = isDarkMode
        ? Theme.of(context).colorScheme.secondaryContainer
        : Theme.of(context).colorScheme.primaryContainer;
    final Color upcomingColor = isDarkMode
        ? Colors.grey.shade600
        : Colors.grey.shade700; // Um pouco mais escuro para contraste
    final Color problematicColor = Colors.orange.shade800;

    switch (statusShort?.toUpperCase()) {
      case 'NS': // Not Started
      case 'TBD': // To Be Defined
        return upcomingColor;
      case 'LIVE':
      case '1H': // First Half
      case 'HT': // Half Time
      case '2H': // Second Half
      case 'ET': // Extra Time
      case 'P': // Penalty Shootout
        return liveColor;
      case 'FT': // Full Time
      case 'AET': // After Extra Time
      case 'PEN': // After Penalty
        return finishedColor;
      case 'PST': // Postponed
      case 'CANC': // Cancelled
      case 'ABD': // Abandoned
      case 'SUSP': // Suspended
      case 'INT': // Interrupted
        return problematicColor;
      default: // Para status desconhecidos ou não mapeados
        return Colors.grey.shade500;
    }
  }

  Color _getStatusTextColor(BuildContext context, String? statusShort) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color liveTextColor =
        Colors.white; // Para contraste com fundo vermelho
    final Color finishedTextColor = isDarkMode
        ? Theme.of(context).colorScheme.onSecondaryContainer
        : Theme.of(context).colorScheme.onPrimaryContainer;
    final Color upcomingTextColor =
        isDarkMode ? Colors.white70 : Colors.black87;
    final Color problematicTextColor = Colors.white;

    switch (statusShort?.toUpperCase()) {
      case 'LIVE':
      case '1H':
      case 'HT':
      case '2H':
      case 'ET':
      case 'P':
        return liveTextColor;
      case 'FT':
      case 'AET':
      case 'PEN':
        return finishedTextColor;
      case 'PST':
      case 'CANC':
      case 'ABD':
      case 'SUSP':
      case 'INT':
        return problematicTextColor;
      default:
        return upcomingTextColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayDateOrTime;
    final bool showScore = !["NS", "PST", "CANC", "TBD"]
        .contains(fixture.statusShort.toUpperCase());

    if (fixture.statusShort.toUpperCase() == "NS" ||
        fixture.statusShort.toUpperCase() == "TBD") {
      displayDateOrTime = DateFormatter.formatTimeOnly(fixture.date);
    } else {
      displayDateOrTime =
          DateFormatter.formatRelativeDateWithTime(fixture.date);
    }

    // Acessando dados da liga CORRETAMENTE através do objeto 'league' da entidade Fixture
    final String leagueNameFromEntity = fixture.league.name;
    final String? leagueLogoUrlFromEntity = fixture.league.logoUrl;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6), // Ajustado para um visual mais limpo
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Padding interno uniforme
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Linha Superior: Data/Hora e Status do Jogo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    displayDateOrTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5), // Padding do chip
                    decoration: BoxDecoration(
                      color: _getStatusColor(context, fixture.statusShort)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      fixture.statusShort.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                _getStatusColor(context, fixture.statusShort),
                            letterSpacing: 0.4, // Espaçamento entre letras
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Linha Central: Times e Placar/Hora
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTeamLogo(fixture.homeTeam.logoUrl, context),
                        const SizedBox(height: 6),
                        Text(
                          fixture.homeTeam.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      showScore
                          ? "${fixture.homeGoals ?? '-'} - ${fixture.awayGoals ?? '-'}"
                          : (fixture.statusShort.toUpperCase() == "TBD"
                              ? "TBD"
                              : DateFormatter.formatTimeOnly(fixture.date)),
                      style: showScore
                          ? Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)
                          : Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTeamLogo(fixture.awayTeam.logoUrl, context),
                        const SizedBox(height: 6),
                        Text(
                          fixture.awayTeam.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Linha Inferior: Nome da Liga (opcional, mas útil)
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leagueLogoUrlFromEntity != null &&
                      leagueLogoUrlFromEntity.isNotEmpty) ...[
                    CachedNetworkImage(
                      imageUrl: leagueLogoUrlFromEntity,
                      height: 16, width: 16, fit: BoxFit.contain,
                      errorWidget: (c, u, e) => const SizedBox
                          .shrink(), // Não mostra nada se o logo da liga falhar
                    ),
                    const SizedBox(width: 6),
                  ] else ...[
                    Icon(Icons.emoji_events_outlined,
                        size: 14,
                        color: Theme.of(context).hintColor.withOpacity(0.7)),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      leagueNameFromEntity, // Usa a variável corrigida
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          // labelMedium para um pouco mais de destaque
                          color: Theme.of(context).hintColor,
                          fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
