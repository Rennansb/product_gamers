// lib/presentation/widgets/league_tile_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:product_gamers/domain/entities/entities/league.dart';

class LeagueTileWidget extends StatelessWidget {
  final League league;
  final VoidCallback onTap;

  const LeagueTileWidget({
    super.key,
    required this.league,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color tileColor =
        isDarkMode
            ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
            : Theme.of(context).colorScheme.surface;

    return Card(
      elevation: 2.5, // Um pouco mais de elevação para destaque
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ), // Para o InkWell ter o mesmo shape
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Logo da Liga
              if (league.logoUrl != null && league.logoUrl!.isNotEmpty)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CachedNetworkImage(
                    imageUrl: league.logoUrl!,
                    imageBuilder:
                        (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            shape:
                                BoxShape
                                    .circle, // Ou BoxShape.rectangle se os logos forem quadrados
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    placeholder:
                        (context, url) => Container(
                          padding: const EdgeInsets.all(
                            8.0,
                          ), // Espaço para o indicador
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sports_soccer,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ),
                  ),
                )
              else
                Container(
                  // Fallback se não houver logo
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              const SizedBox(width: 16),

              // Nome e País da Liga
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      league.friendlyName, // Usar friendlyName
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (league.countryName != null &&
                        league.countryName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (league.countryFlagUrl != null &&
                              league.countryFlagUrl!.isNotEmpty)
                            SizedBox(
                              width: 16,
                              height: 12, // Tamanho pequeno para bandeira
                              child: CachedNetworkImage(
                                imageUrl: league.countryFlagUrl!,
                                fit: BoxFit.cover,
                                errorWidget:
                                    (context, url, error) =>
                                        const SizedBox.shrink(), // Não mostra nada se a bandeira falhar
                              ),
                            )
                          else
                            Icon(
                              Icons.flag_outlined,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                          const SizedBox(width: 4),
                          Text(
                            league.countryName!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Ícone de Seta
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
