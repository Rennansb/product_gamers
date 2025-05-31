// lib/presentation/widgets/league_tile_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    final placeholderColor =
        Theme.of(context).colorScheme.primary.withOpacity(0.1);
    final iconColor = Theme.of(context).colorScheme.primary;

    if (league.logoUrl != null && league.logoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: league.logoUrl!,
        imageBuilder: (context, imageProvider) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape
                .circle, // Logos de ligas geralmente ficam bem em círculos
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.contain, // Usar contain para não cortar o logo
            ),
          ),
        ),
        placeholder: (context, url) => Container(
          width: 40,
          height: 40,
          decoration:
              BoxDecoration(color: placeholderColor, shape: BoxShape.circle),
          padding: const EdgeInsets.all(10.0), // Espaço para o indicador
          child: CircularProgressIndicator(strokeWidth: 1.5, color: iconColor),
        ),
        errorWidget: (context, url, error) => Container(
          width: 40,
          height: 40,
          decoration:
              BoxDecoration(color: placeholderColor, shape: BoxShape.circle),
          child: Icon(Icons.shield_outlined,
              size: 24, color: iconColor.withOpacity(0.7)),
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration:
            BoxDecoration(color: placeholderColor, shape: BoxShape.circle),
        child: Icon(Icons.shield_outlined,
            size: 24, color: iconColor.withOpacity(0.7)),
      );
    }
  }

  Widget _buildCountryFlag(BuildContext context) {
    if (league.countryFlagUrl != null && league.countryFlagUrl!.isNotEmpty) {
      return SizedBox(
        width: 18, // Tamanho pequeno para bandeira
        height: 12,
        child: CachedNetworkImage(
          imageUrl: league.countryFlagUrl!,
          fit: BoxFit.cover,
          // Placeholder e error para bandeiras podem ser mais simples ou até omitidos
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),
      );
    } else if (league.countryName != null && league.countryName!.isNotEmpty) {
      // Fallback se não houver URL da bandeira mas houver nome do país
      return Icon(Icons.flag_circle_outlined,
          size: 14, color: Theme.of(context).hintColor.withOpacity(0.7));
    }
    return const SizedBox
        .shrink(); // Não mostra nada se não houver nem URL nem nome
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 7), // Ajuste de margem
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 14.0), // Ajuste de padding
          child: Row(
            children: [
              _buildLeagueLogo(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      league.friendlyName, // Usar friendlyName para exibição
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            // color: Theme.of(context).colorScheme.onSurface, // Cor padrão do tema para texto em superfície
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
                            // Para evitar overflow do nome do país
                            child: Text(
                              league.countryName!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .hintColor, // Cor mais sutil
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
                size: 16, // Tamanho um pouco menor
                color: Theme.of(context).hintColor.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
