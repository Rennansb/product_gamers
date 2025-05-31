// lib/presentation/widgets/common/loading_indicator_widget.dart
import 'package:flutter/material.dart';

class LoadingIndicatorWidget extends StatelessWidget {
  final String? message;
  final bool isSliver; // Para uso dentro de CustomScrollView/Slivers

  const LoadingIndicatorWidget({
    super.key,
    this.message,
    this.isSliver = false, // Por padrão, não é um sliver
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      // Adicionado Padding para dar um respiro
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              strokeWidth: 3.0,
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 24), // Aumentado o espaçamento
              Text(
                message!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color, // Cor mais sutil
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );

    if (isSliver) {
      // Se for para ser usado como um Sliver (dentro de CustomScrollView)
      return SliverFillRemaining(
        hasScrollBody:
            false, // Importante para que não tente ter seu próprio scroll
        child: content,
      );
    } else {
      // Se for para ser usado como um widget normal (dentro de Column, Center, etc.)
      return content;
    }
  }
}
