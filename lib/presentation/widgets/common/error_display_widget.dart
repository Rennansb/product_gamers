// lib/presentation/widgets/common/error_display_widget.dart
import 'package:flutter/material.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final bool isSliver; // Para uso dentro de CustomScrollView/Slivers

  const ErrorDisplayWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.showRetryButton =
        true, // Por padrão, mostra o botão se onRetry for fornecido
    this.isSliver = false, // Por padrão, não é um sliver
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      // Adicionado Padding
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded, // Ícone mais sugestivo de aviso/erro
              color: Theme.of(context).colorScheme.error,
              size: 72, // Aumentado o tamanho
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Algo deu errado...', // Título mais genérico e amigável
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.error.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color, // Cor mais sutil
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null && showRetryButton) ...[
              const SizedBox(height: 32), // Aumentado o espaçamento
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Tentar Novamente'),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.error.withOpacity(0.9),
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14), // Padding maior
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isSliver) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: content,
      );
    } else {
      return content;
    }
  }
}
