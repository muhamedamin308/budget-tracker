import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class InlineErrorBanner extends StatelessWidget {
  const InlineErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.retryTooltip = 'Retry',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryTooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 12, onRetry == null ? 14 : 6, 12),
      decoration: BoxDecoration(
        color: AppTheme.expenseCoral.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.expenseCoral,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.expenseCoral,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              tooltip: retryTooltip,
              onPressed: onRetry,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.expenseCoral,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
