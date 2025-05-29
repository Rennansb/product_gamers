// lib/presentation/widgets/common/loading_indicator_widget.dart
import 'package:flutter/material.dart';

class LoadingIndicatorWidget extends StatelessWidget {
  final String? message;
  final bool isSliver; // Adicionado para uso em CustomScrollView

  const LoadingIndicatorWidget({
    super.key,
    this.message,
    this.isSliver = false, // Padrão para não ser sliver
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
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
            const SizedBox(height: 20),
            Text(
              message!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (isSliver) {
      return SliverFillRemaining(
        // Ocupa o espaço restante em uma CustomScrollView
        hasScrollBody: false, // Importante se for apenas um indicador
        child: content,
      );
    } else {
      return content;
    }
  }
}
