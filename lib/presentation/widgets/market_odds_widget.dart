// lib/presentation/widgets/market_odds_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar porcentagem
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';
// Nossa entidade

class MarketOddsWidget extends StatelessWidget {
  final PrognosticMarket market;

  const MarketOddsWidget({super.key, required this.market});

  @override
  Widget build(BuildContext context) {
    final NumberFormat percentFormat = NumberFormat.percentPattern("pt_BR");
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
      ), // Removido horizontal para ocupar largura
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: isDarkMode ? Colors.grey[800]?.withOpacity(0.7) : Colors.white,
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
                    market.marketName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (market.suggestedOption != null &&
                    market.suggestedOption!.probability != null &&
                    market.suggestedOption!.probability! > 0)
                  Tooltip(
                    message:
                        "Sugestão do mercado (maior probabilidade implícita)",
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.amber.shade600,
                      size: 22,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (market.options.isEmpty)
              const Text(
                "Nenhuma odd disponível para este mercado.",
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else if (market.options.length <= 3 &&
                market.options.length > 1 &&
                market.marketId ==
                    1) // Layout horizontal para Match Winner (1X2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    market.options.map((option) {
                      bool isSuggested = market.suggestedOption == option;
                      return Expanded(
                        child: _OddChip(
                          option: option,
                          isSuggested: isSuggested,
                          percentFormat: percentFormat,
                        ),
                      );
                    }).toList(),
              )
            else // Layout vertical para outros mercados ou mais opções
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: market.options.length,
                itemBuilder: (context, index) {
                  final option = market.options[index];
                  bool isSuggested = market.suggestedOption == option;
                  return _OddListItem(
                    option: option,
                    isSuggested: isSuggested,
                    percentFormat: percentFormat,
                  );
                },
                separatorBuilder:
                    (context, index) => const Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 8,
                      endIndent: 8,
                    ),
              ),
            if (market.suggestedOption != null &&
                market.marketName.toLowerCase().contains("match winner"))
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "Sugestão do mercado: ${market.suggestedOption!.label} (Odd: ${market.suggestedOption!.odd})",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.9),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OddChip extends StatelessWidget {
  final OddOption option;
  final bool isSuggested;
  final NumberFormat percentFormat;
  const _OddChip({
    required this.option,
    required this.isSuggested,
    required this.percentFormat,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 6.0,
      ), // Reduzido padding horizontal
      decoration: BoxDecoration(
        color:
            isSuggested
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(
                  isDarkMode ? 0.5 : 0.3,
                )
                : Theme.of(context).colorScheme.surfaceVariant.withOpacity(
                  isDarkMode ? 0.3 : 0.5,
                ),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color:
              isSuggested
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                  : Theme.of(context).dividerColor.withOpacity(0.5),
          width: isSuggested ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            option.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isSuggested ? FontWeight.bold : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            option.odd,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSuggested ? Theme.of(context).colorScheme.primary : null,
            ),
            textAlign: TextAlign.center,
          ),
          if (option.probability != null && option.probability! > 0.01) ...[
            // Só mostra se prob for útil
            const SizedBox(height: 2),
            Text(
              percentFormat.format(option.probability),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: (isSuggested
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).textTheme.labelSmall?.color)
                    ?.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OddListItem extends StatelessWidget {
  final OddOption option;
  final bool isSuggested;
  final NumberFormat percentFormat;
  const _OddListItem({
    required this.option,
    required this.isSuggested,
    required this.percentFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 8.0,
      ), // Ajustado padding
      decoration: BoxDecoration(
        color:
            isSuggested
                ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.2)
                : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isSuggested ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (option.probability != null && option.probability! > 0.01)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      "Prob. Implícita: ${percentFormat.format(option.probability)}",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: (isSuggested
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).textTheme.labelSmall?.color)
                            ?.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              option.odd,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                // Ajustado para bodyMedium
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
