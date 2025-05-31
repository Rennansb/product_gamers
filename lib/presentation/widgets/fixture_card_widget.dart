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

  Widget _buildTeamLogo(String? logoUrl, BuildContext context,
      {double size = 38}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor =
        Theme.of(context).colorScheme.primary.withOpacity(0.08);
    final iconColor = Theme.of(context).colorScheme.primary.withOpacity(0.7);

    return Container(
      // Adicionado container para garantir tamanho consistente e borda se desejado
      width: size,
      height: size,
      decoration: BoxDecoration(
        // color: placeholderColor, // Opcional: cor de fundo para o círculo
        shape: BoxShape.circle,
        // border: Border.all(color: Colors.grey.shade300, width: 0.5) // Borda opcional
      ),
      clipBehavior:
          Clip.antiAlias, // Garante que a imagem respeite o shape circular
      child: logoUrl != null && logoUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => Padding(
                padding: const EdgeInsets.all(
                    8.0), // Espaço para o indicador dentro do círculo
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: iconColor),
              ),
              errorWidget: (context, url, error) => Icon(Icons.shield_outlined,
                  size: size * 0.6, color: iconColor),
            )
          : Icon(Icons.shield, size: size * 0.6, color: iconColor),
    );
  }

  Color _getStatusColor(BuildContext context, String? statusShort) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Usar cores do tema para melhor consistência
    final Color liveColor = Colors.redAccent.shade400;
    final Color finishedColor = isDarkMode
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;
    final Color upcomingColor =
        isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    final Color problematicColor = Colors.orange.shade700;

    switch (statusShort?.toUpperCase()) {
      case 'NS': // Not Started
        return upcomingColor;
      case 'LIVE':
      case '1H':
      case 'HT':
      case '2H':
      case 'ET':
      case 'P':
        return liveColor;
      case 'FT':
      case 'AET':
      case 'PEN':
        return finishedColor;
      case 'PST': // Postponed
      case 'CANC': // Cancelled
      case 'ABD': // Abandoned
      case 'SUSP': // Suspended
      case 'INT': // Interrupted
        return problematicColor;
      default:
        return upcomingColor; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final String displayDate =
        DateFormatter.formatRelativeDateWithTime(fixture.date);

    // Determinar se o placar deve ser mostrado
    final bool showScore = !["NS", "PST", "CANC", "TBD"]
        .contains(fixture.statusShort.toUpperCase());
    // TBD = To Be Defined (Hora a ser definida)

    return Card(
      elevation: 2.5,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Para o card se ajustar ao conteúdo
            children: [
              // Linha Superior: Data e Status do Jogo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context, fixture.statusShort)
                          .withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(16), // Mais arredondado
                    ),
                    child: Text(
                      fixture.statusShort.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                _getStatusColor(context, fixture.statusShort),
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Linha Central: Times e Placar
              Row(
                children: [
                  // Time da Casa
                  Expanded(
                    child: Column(
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

                  // Placar ou "vs" ou Hora
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      showScore
                          ? "${fixture.homeGoals ?? '-'} - ${fixture.awayGoals ?? '-'}"
                          : DateFormatter.formatTimeOnly(
                              fixture.date), // Mostra a hora se não começou
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

                  // Time Visitante
                  Expanded(
                    child: Column(
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

              // Linha Inferior Opcional: Nome da Liga (pode ser útil se os cards forem misturados)
              if (fixture.leagueName.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (fixture.leagueLogoUrl != null &&
                        fixture.leagueLogoUrl!.isNotEmpty) ...[
                      CachedNetworkImage(
                        imageUrl: fixture.leagueLogoUrl!,
                        height: 16,
                        width: 16,
                        fit: BoxFit.contain,
                        errorWidget: (c, u, e) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      // Para evitar overflow do nome da liga
                      child: Text(
                        fixture.leagueName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).hintColor.withOpacity(0.8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
