// lib/presentation/widgets/fixture_card_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:product_gamers/core/theme/app_theme.dart';
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

  // Helper widget para construir o logo do time com círculo dourado
  Widget _buildTeamLogoWithGoldCircle(String? logoUrl, BuildContext context,
      {double circleSize = 40, double logoPadding = 5.0}) {
    final Color circleBackgroundColor =
        AppTheme.darkCardSurface.withOpacity(0.5);
    final Color placeholderIconColor =
        AppTheme.goldAccentLight.withOpacity(0.7);
    final Color progressColor = AppTheme.goldAccent;
    final Color circleBorderColor = AppTheme.goldAccent.withOpacity(0.9);

    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        color: circleBackgroundColor,
        shape: BoxShape.circle,
        border:
            Border.all(color: circleBorderColor, width: 1.5), // Borda dourada
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(logoPadding), // Padding interno para o logo
        child: logoUrl != null && logoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.contain,
                fadeInDuration: const Duration(milliseconds: 300),
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: circleSize * 0.4, // Proporcional
                    height: circleSize * 0.4,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: progressColor),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.shield_outlined,
                  size: circleSize * 0.5, // Proporcional
                  color: placeholderIconColor,
                ),
              )
            : Icon(
                Icons.shield,
                size: circleSize * 0.5,
                color: placeholderIconColor,
              ),
      ),
    );
  }

  // Helper para determinar a cor do texto e do fundo do status do jogo
  Tuple2<Color, Color> _getStatusColors(
      BuildContext context, String? statusShort) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Cores de Fundo do Chip de Status
    Color backgroundColor;
    // Cores do Texto do Chip de Status
    Color textColor;

    switch (statusShort?.toUpperCase()) {
      case 'NS': // Not Started
      case 'TBD': // To Be Defined
        backgroundColor = AppTheme.slightlyLighterDark.withOpacity(0.7);
        textColor = AppTheme.textWhite70;
        break;
      case 'LIVE':
      case '1H':
      case 'HT':
      case '2H':
      case 'ET':
      case 'P':
        backgroundColor = Colors.redAccent.withOpacity(0.25);
        textColor = Colors.redAccent.shade100;
        break;
      case 'FT':
      case 'AET':
      case 'PEN':
        backgroundColor = AppTheme.goldAccent.withOpacity(0.15);
        textColor = AppTheme.goldAccentLight;
        break;
      case 'PST':
      case 'CANC':
      case 'ABD':
      case 'SUSP':
      case 'INT':
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange.shade300;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.15);
        textColor = AppTheme.textWhite54;
    }
    return Tuple2(backgroundColor, textColor);
  }

  @override
  Widget build(BuildContext context) {
    final String displayDateOrTime;
    final bool showScore = !["NS", "PST", "CANC", "TBD"]
        .contains(fixture.statusShort.toUpperCase());
    final bool isLive = ["LIVE", "1H", "HT", "2H", "ET", "P"]
        .contains(fixture.statusShort.toUpperCase());

    if (fixture.statusShort.toUpperCase() == "NS" ||
        fixture.statusShort.toUpperCase() == "TBD") {
      displayDateOrTime = DateFormatter.formatTimeOnly(fixture.date);
    } else {
      displayDateOrTime =
          DateFormatter.formatRelativeDateWithTime(fixture.date);
    }

    final leagueNameFromEntity = fixture.league.name; // Acesso correto
    final leagueLogoUrlFromEntity = fixture.league.logoUrl; // Acesso correto

    final statusColors = _getStatusColors(context, fixture.statusShort);
    final statusBgColor = statusColors.item1;
    final statusTextColor = statusColors.item2;

    return Card(
      // elevation, margin, shape virão do AppTheme.cardTheme
      // Para um card ainda mais escuro, podemos usar um Container com BoxDecoration
      // ou um Card com `color` explícito. O tema já define uma borda dourada sutil.
      // color: AppTheme.darkBackground, // Se quiser mais escuro que o cardTheme
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12.0), // Consistente com o CardTheme
        splashColor: AppTheme.goldAccent.withOpacity(0.1),
        highlightColor: AppTheme.goldAccent.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Aumentar padding geral
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.textWhite70,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      fixture.statusShort.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusTextColor,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Mais espaço

              // Linha Central: Times e Placar/Hora
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround, // Distribui melhor
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Time da Casa
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogoWithGoldCircle(
                            fixture.homeTeam.logoUrl, context,
                            circleSize: 44, logoPadding: 6), // Logo maior
                        const SizedBox(height: 8),
                        Text(
                          fixture.homeTeam.name,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textWhite, // Garante branco
                                    fontSize: 13, // Levemente menor para caber
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Placar ou Hora
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0), // Menos padding horizontal
                    child: Column(
                      // Para alinhar tempo decorrido abaixo do placar se ao vivo
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          showScore
                              ? "${fixture.homeGoals ?? '-'} - ${fixture.awayGoals ?? '-'}"
                              : (fixture.statusShort.toUpperCase() == "TBD"
                                  ? "TBD"
                                  : DateFormatter.formatTimeOnly(fixture.date)),
                          style: showScore
                              ? Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme
                                          .textWhite, // Placar em branco
                                      fontSize: 26 // Placar maior
                                      )
                              : Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme
                                        .goldAccentLight, // Hora em dourado
                                  ),
                        ),
                        if (isLive &&
                            fixture.elapsedMinutes != null &&
                            fixture.elapsedMinutes! > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            "${fixture.elapsedMinutes}'",
                            style: TextStyle(
                                color:
                                    statusTextColor, // Cor do texto do status (ex: vermelho)
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          )
                        ]
                      ],
                    ),
                  ),

                  // Time Visitante
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogoWithGoldCircle(
                            fixture.awayTeam.logoUrl, context,
                            circleSize: 44, logoPadding: 6),
                        const SizedBox(height: 8),
                        Text(
                          fixture.awayTeam.name,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textWhite,
                                    fontSize: 13,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Linha Inferior: Nome da Liga
              const SizedBox(height: 14), // Mais espaço
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leagueLogoUrlFromEntity != null &&
                      leagueLogoUrlFromEntity.isNotEmpty) ...[
                    CachedNetworkImage(
                      imageUrl: leagueLogoUrlFromEntity,
                      height: 18, width: 18,
                      fit: BoxFit.contain, // Logo da liga um pouco maior
                      errorWidget: (c, u, e) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 6),
                  ] else ...[
                    Icon(Icons.emoji_events_outlined,
                        size: 16, color: AppTheme.textWhite54.withOpacity(0.7)),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      leagueNameFromEntity,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          // Usar labelMedium
                          color: AppTheme.textWhite70, // Cor mais sutil
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

// Helper para Tuple2 se não quiser adicionar o pacote 'tuple'
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  const Tuple2(this.item1, this.item2);
}
