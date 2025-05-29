// lib/presentation/widgets/fixture_card_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import '../../core/utils/date_formatter.dart'; // Nosso helper de data

class FixtureCardWidget extends StatelessWidget {
  final Fixture fixture;
  final VoidCallback onTap;

  const FixtureCardWidget({
    super.key,
    required this.fixture,
    required this.onTap,
  });

  Widget _buildTeamLogo(
    String? logoUrl,
    BuildContext context, {
    double size = 36,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return logoUrl != null
        ? CachedNetworkImage(
          imageUrl: logoUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholder:
              (context, url) => SizedBox(
                width: size,
                height: size,
                child: const CircularProgressIndicator(strokeWidth: 1.5),
              ),
          errorWidget:
              (context, url, error) => Icon(
                Icons.shield_outlined,
                size: size,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
        )
        : Icon(
          Icons.shield,
          size: size,
          color: isDarkMode ? Colors.white38 : Colors.black38,
        );
  }

  Color _getStatusColor(BuildContext context, String? statusShort) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (statusShort?.toUpperCase()) {
      case 'NS': // Not Started
        return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
      case 'LIVE':
      case '1H': // First Half
      case 'HT': // Half Time
      case '2H': // Second Half
      case 'ET': // Extra Time
      case 'P': // Penalty Shootout
        return Colors.redAccent.shade400;
      case 'FT': // Full Time
      case 'AET': // After Extra Time
      case 'PEN': // After Penalty
        return isDarkMode ? Colors.blueAccent.shade100 : Colors.blue.shade700;
      case 'PST': // Postponed
      case 'CANC': // Cancelled
      case 'ABD': // Abandoned
      case 'SUSP': // Suspended
      case 'INT': // Interrupted
        return Colors.orange.shade700;
      default:
        return isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Formata a data para "Hoje HH:mm", "Amanhã HH:mm" ou "dd/MM HH:mm"
    final String displayDate = DateFormatter.formatRelativeDateWithTime(
      fixture.date,
    );
    final bool isLiveOrFinished =
        !["NS", "PST", "CANC"].contains(fixture.statusShort.toUpperCase());

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Linha Superior: Data e Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayDate,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        context,
                        fixture.statusShort,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      fixture
                          .statusShort, // Ou fixture.statusLong para mais detalhes
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(context, fixture.statusShort),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Linha Central: Times e Placar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Time da Casa
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTeamLogo(fixture.homeTeam.logoUrl, context),
                        const SizedBox(height: 6),
                        Text(
                          fixture.homeTeam.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Placar ou "vs"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child:
                        isLiveOrFinished
                            ? Text(
                              "${fixture.homeGoals ?? '-'} - ${fixture.awayGoals ?? '-'}",
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            )
                            : Text(
                              "vs",
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                              ),
                            ),
                  ),

                  // Time Visitante
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTeamLogo(fixture.awayTeam.logoUrl, context),
                        const SizedBox(height: 6),
                        Text(
                          fixture.awayTeam.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Linha Inferior: Nome da Liga (opcional, pode ser repetitivo se todos os cards são da mesma liga)
              if (fixture.leagueName.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (fixture.leagueLogoUrl != null &&
                        fixture.leagueLogoUrl!.isNotEmpty) ...[
                      CachedNetworkImage(
                        imageUrl: fixture.leagueLogoUrl!,
                        height: 14,
                        width: 14,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      fixture.leagueName,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
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
