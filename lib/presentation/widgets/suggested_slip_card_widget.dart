// lib/presentation/widgets/suggested_slip_card_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatação de números/data
import 'package:cached_network_image/cached_network_image.dart'; // Para logos dos times
import 'package:product_gamers/domain/entities/entities/suggested_bet_slip.dart';

import '../../core/utils/date_formatter.dart'; // Nosso helper de data
// A entidade do bilhete
// Não precisamos de fixture.dart diretamente aqui se SuggestedBetSlip já tem Fixture

class SuggestedSlipCardWidget extends StatelessWidget {
  final SuggestedBetSlip slip;

  const SuggestedSlipCardWidget({super.key, required this.slip});

  Widget _buildTeamLogo(
    String? logoUrl,
    BuildContext context, {
    double size = 20,
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
                child: const CircularProgressIndicator(strokeWidth: 1.5),
              ),
          errorWidget:
              (context, url, error) => Icon(
                Icons.shield_outlined,
                size: size,
                color: isDarkMode ? Colors.white54 : Colors.black38,
              ),
        )
        : Icon(
          Icons.shield,
          size: size,
          color: isDarkMode ? Colors.white54 : Colors.black38,
        );
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat oddsFormat = NumberFormat(
      "0.00",
      "pt_BR",
    ); // Para formatar odds
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final Color cardBackgroundColor =
        Theme.of(context).cardTheme.color ??
        Theme.of(context).cardColor; // Usa cor do cardTheme se definida
    final Color textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final Color subtleTextColor = Theme.of(context).textTheme.bodySmall!.color!;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // side: BorderSide(color: primaryColor.withOpacity(0.7), width: 1) // Borda opcional
      ),
      child: Container(
        // Usar Container para gradiente ou cor de fundo seletiva
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          // Exemplo de gradiente sutil (opcional):
          // gradient: LinearGradient(
          //   colors: isDarkMode
          //       ? [primaryColor.withOpacity(0.05), cardBackgroundColor.withOpacity(0.9)]
          //       : [primaryColor.withOpacity(0.03), cardBackgroundColor],
          //   stops: const [0.0, 0.3],
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          // ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do Bilhete
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slip.title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        if (slip.overallReasoning != null &&
                            slip.overallReasoning!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            slip.overallReasoning!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: subtleTextColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Chip(
                    label: Text(
                      'Odd: ${oddsFormat.format(slip.totalOddsValue)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: onPrimaryColor, // Cor do texto no chip
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.8),

              // Lista de Seleções
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: slip.selections.length,
                itemBuilder: (context, index) {
                  final selection = slip.selections[index];
                  // Encontrar o fixture correspondente.
                  final fixture =
                      (index < slip.fixturesInvolved.length)
                          ? slip.fixturesInvolved[index]
                          : slip.fixturesInvolved.first;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildTeamLogo(fixture.homeTeam.logoUrl, context),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "${fixture.homeTeam.name} vs ${fixture.awayTeam.name}",
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.formatFixtureDate(
                                fixture.date,
                              ).split(' ').last, // Só a hora
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: subtleTextColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: textColor),
                                      children: [
                                        TextSpan(
                                          text: "${selection.marketName}: ",
                                        ),
                                        TextSpan(
                                          text: selection.selectionName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selection.reasoning != null &&
                                      selection.reasoning!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      selection.reasoning!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium?.copyWith(
                                        color: subtleTextColor.withOpacity(0.8),
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                    .withOpacity(isDarkMode ? 0.6 : 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                selection.odd,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder:
                    (context, index) => const Divider(
                      height: 12,
                      thickness: 0.5,
                      indent: 8,
                      endIndent: 8,
                    ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Gerado: ${DateFormatter.formatFixtureDate(slip.dateGenerated)}",
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: subtleTextColor),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Prognósticos baseados em estatísticas. Sem garantia de acerto. Aposte com responsabilidade.",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
