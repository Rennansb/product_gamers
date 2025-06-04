// lib/presentation/widgets/league_tile_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:product_gamers/core/theme/app_theme.dart';

import '../../domain/entities/entities/league.dart';

// Nossa entidade League

class LeagueTileWidget extends StatelessWidget {
  final League league;
  final VoidCallback onTap;

  const LeagueTileWidget({
    super.key,
    required this.league,
    required this.onTap,
  });

  Widget _buildLeagueLogo(BuildContext context) {
    // Cores do tema "Dark Gold"
    final Color circleBackgroundColor =
        AppTheme.darkCardSurface.withOpacity(0.6); // Fundo sutil para o círculo
    final Color placeholderIconColor =
        AppTheme.goldAccentLight.withOpacity(0.7);
    final Color progressColor = AppTheme.goldAccent;
    final Color circleBorderColor =
        AppTheme.goldAccent.withOpacity(0.8); // Borda dourada

    return Container(
      width: 42, // Tamanho do círculo
      height: 42,
      decoration: BoxDecoration(
        color: circleBackgroundColor,
        shape: BoxShape.circle,
        border:
            Border.all(color: circleBorderColor, width: 1.5), // Borda dourada
      ),
      clipBehavior:
          Clip.antiAlias, // Garante que a imagem respeite a forma circular
      child: Padding(
        // Padding interno para o logo não colar na borda
        padding: const EdgeInsets.all(4.0), // Ajuste conforme o visual desejado
        child: league.logoUrl != null && league.logoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: league.logoUrl!,
                fit: BoxFit.contain,
                fadeInDuration: const Duration(milliseconds: 300),
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 20, // Tamanho do progress indicator
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: progressColor),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.shield_outlined, // Ícone de fallback
                  size: 24, // Tamanho do ícone de fallback
                  color: placeholderIconColor,
                ),
              )
            : Icon(
                Icons.shield, // Ícone padrão para liga sem logo
                size: 24,
                color: placeholderIconColor,
              ),
      ),
    );
  }

  Widget _buildCountryFlag(BuildContext context) {
    if (league.countryFlagUrl != null && league.countryFlagUrl!.isNotEmpty) {
      return SizedBox(
        width: 18,
        height: 12,
        child: CachedNetworkImage(
          imageUrl: league.countryFlagUrl!,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),
      );
    } else if (league.countryName != null && league.countryName!.isNotEmpty) {
      return Icon(Icons.flag_circle_outlined,
          size: 14, color: AppTheme.textWhite54.withOpacity(0.8));
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    // O CardTheme do AppTheme.darkGoldTheme já define a cor de fundo do card
    // e uma borda dourada sutil. Podemos ajustar ou complementar aqui se necessário.

    return Card(
      // elevation e margin virão do tema, mas podem ser sobrescritos
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(12),
      //   side: BorderSide(color: AppTheme.subtleBorder, width: 1.0) // Borda já definida no tema
      // ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12), // Consistente com o shape do Card
        splashColor:
            AppTheme.goldAccent.withOpacity(0.1), // Efeito de clique dourado
        highlightColor: AppTheme.goldAccent.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 12.0), // Padding interno do tile
          child: Row(
            children: [
              _buildLeagueLogo(context), // Logo da Liga com círculo dourado
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      league.friendlyName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textWhite, // Garante texto branco
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (league.countryName != null &&
                        league.countryName!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildCountryFlag(context),
                          if (league.countryFlagUrl != null &&
                                  league.countryFlagUrl!.isNotEmpty ||
                              (league.countryName != null &&
                                  league.countryName!.isNotEmpty))
                            const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              league.countryName!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme
                                        .textWhite70, // Cor sutil para o país
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.textWhite54
                    .withOpacity(0.8), // Cor sutil para a seta
              ),
            ],
          ),
        ),
      ),
    );
  }
}
