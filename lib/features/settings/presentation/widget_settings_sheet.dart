// lib/features/settings/presentation/widget_settings_sheet.dart

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/widget_sync_service.dart';
import '../../../core/theme/app_theme.dart';

abstract final class _S {
  static const title = 'Home screen widget';
  static const subtitle = 'Shows your balance and budget at a glance';
  static const previewLabel = 'Preview with sample numbers';
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_S.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            _S.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _Preview(hidden: _hidden),
          const SizedBox(height: 6),
          Text(
            _S.previewLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              _S.hideTitle,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
            ),
            subtitle: const Text(
              _S.hideSubtitle,
              style: TextStyle(fontSize: 12.5),
            ),
            value: _hidden,
            activeTrackColor: AppTheme.primaryEmerald,
            onChanged: _toggleHidden,
          ),
          const SizedBox(height: 8),
          if (widget.isPinSupported)
            FilledButton.icon(
              onPressed: _busy ? null : _pinOrSync,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
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
                minimumSize: const Size.fromHeight(52),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  _S.addExpense,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hidden ? _S.hiddenBalance : _S.sampleBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
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
    );
  }
}
