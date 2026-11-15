// lib/features/settings/presentation/widget_settings_sheet.dart

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/widget_sync_service.dart';
import '../../../core/theme/app_theme.dart';

abstract final class _S {
  static const title = 'Home screen widget';
  static const subtitle = 'Shows your balance and budget at a glance';
  static const previewLabel = 'PREVIEW · SAMPLE NUMBERS';
  static const appName = 'BUDGET TRACKER';
  static const addExpense = '+ Expense';
  static const sampleBalance = '1,250.00 EGP';
  static const hiddenBalance = '••••••';
  static const sampleBudget = 'Spent 800.00 of 1,000.00 EGP';
  static const hideTitle = 'Hide balance on widget';
  static const hideSubtitle = 'Shows •••••• instead of your balance.';
  static const addToHome = 'Add widget to home screen';
  static const syncNow = 'Refresh widget data';
  static const pinSent = 'Check your home screen to place the widget.';
  static const pinFailed =
      'Could not add the widget. Try from your launcher instead.';
  static const synced = 'Widget refreshed.';
  static const actionFailed = 'Something went wrong. Please try again.';
}

Future<void> showWidgetSettingsSheet(BuildContext context) async {
  final service = getIt<WidgetSyncService>();
  final isPinSupported = await service.isPinWidgetSupported();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) =>
        _WidgetSettingsSheet(service: service, isPinSupported: isPinSupported),
  );
}

class _WidgetSettingsSheet extends StatefulWidget {
  const _WidgetSettingsSheet({
    required this.service,
    required this.isPinSupported,
  });

  final WidgetSyncService service;
  final bool isPinSupported;

  @override
  State<_WidgetSettingsSheet> createState() => _WidgetSettingsSheetState();
}

class _WidgetSettingsSheetState extends State<_WidgetSettingsSheet> {
  late bool _hidden = widget.service.isBalanceHidden;
  bool _busy = false;

  Future<void> _toggleHidden(bool value) async {
    setState(() => _hidden = value);
    await widget.service.setBalanceHidden(value);
  }

  Future<void> _pinOrSync() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);

    String message;
    try {
      if (widget.isPinSupported) {
        final success = await widget.service.requestPinWidget();
        message = success ? _S.pinSent : _S.pinFailed;
      } else {
        await widget.service.syncNow();
        message = _S.synced;
      }
    } catch (_) {
      message = _S.actionFailed;
    }

    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline = theme.colorScheme.outlineVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.widgets_rounded,
                  size: 22,
                  color: AppTheme.primaryEmerald,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _S.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _S.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Preview(hidden: _hidden),
          const SizedBox(height: 10),
          Text(
            _S.previewLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: theme.cardColor,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: outline.withValues(alpha: isDark ? 0.3 : 0.5),
              ),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
              secondary: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _hidden
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: AppTheme.primaryEmerald,
                ),
              ),
              title: const Text(
                _S.hideTitle,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
              subtitle: const Text(
                _S.hideSubtitle,
                style: TextStyle(fontSize: 12.5),
              ),
              value: _hidden,
              activeTrackColor: AppTheme.primaryEmerald,
              onChanged: _toggleHidden,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.isPinSupported)
            FilledButton.icon(
              onPressed: _busy ? null : _pinOrSync,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_to_home_screen_rounded),
              label: const Text(_S.addToHome),
            )
          else
            OutlinedButton.icon(
              onPressed: _busy ? null : _pinOrSync,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.sync_rounded),
              label: const Text(_S.syncNow),
            ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.hidden});

  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryEmerald.withValues(alpha: 0.14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      _S.appName,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        _S.addExpense,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    hidden ? _S.hiddenBalance : _S.sampleBalance,
                    key: ValueKey(hidden),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  _S.sampleBudget,
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.8,
                    minHeight: 6,
                    backgroundColor: Color(0xFF334155),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryEmerald,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
