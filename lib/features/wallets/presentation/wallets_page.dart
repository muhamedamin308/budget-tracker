import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_format.dart';
import '../domain/wallet_entity.dart';
import 'transfer_form_sheet.dart';
import 'wallet_cubit.dart';
import 'wallet_form_dialog.dart';
import 'wallet_icons.dart';

abstract final class _S {
  static const title = 'Manage wallets';
  static const addWallet = 'Add wallet';
  static const emptyTitle = 'No wallets yet';
  static const emptyBody = 'Create your first wallet to start tracking.';
  static const totalLabel = 'Total across wallets';
  static const active = 'Active';
  static const archived = 'Archived';
  static const edit = 'Edit';
  static const actions = 'Wallet actions';
  static const transferFromHere = 'Transfer from here';
  static const archive = 'Archive';
  static const cancel = 'Cancel';
  static const transfer = 'Transfer';
  static const moveFunds = 'Move money between wallets';
  static const moveFirstTitle = 'Move the balance first';
  static const archiveTitle = 'Archive wallet';
  static const genericError = 'Something went wrong. Please try again.';

  static String walletCount(int count) =>
      count == 1 ? '1 wallet' : '$count wallets';
  static String moveFirstBody(String name, String balance) =>
      '"$name" still holds $balance. Transfer it to another wallet, then archive.';
  static String archiveBody(String name) =>
      'Archive "$name"? Its past transactions stay in your history.';
}

class WalletsPage extends StatelessWidget {
  const WalletsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WalletCubit>(),
      child: const _WalletsView(),
    );
  }
}

class _WalletsView extends StatelessWidget {
  const _WalletsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_S.title)),
      body: BlocConsumer<WalletCubit, WalletState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? _S.genericError)),
            ),
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.wallets.isEmpty) {
            return _EmptyState(onAdd: () => showWalletFormDialog(context));
          }

          final active = state.wallets.where((w) => !w.isArchived).toList();
          final archived = state.wallets.where((w) => w.isArchived).toList();
          final hasMultiple = active.length > 1;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            children: [
              _TotalCard(
                totalMinor: state.totalBalanceMinor,
                walletCount: active.length,
                onTransfer: hasMultiple
                    ? () => showTransferFormSheet(context)
                    : null,
              ),
              const SizedBox(height: 24),
              const _SectionLabel(_S.active),
              for (final wallet in active)
                _WalletCard(
                  wallet: wallet,
                  canArchive: hasMultiple,
                  canTransfer: hasMultiple,
                ),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _SectionLabel(_S.archived),
                for (final wallet in archived)
                  _WalletCard(
                    wallet: wallet,
                    canArchive: false,
                    canTransfer: false,
                  ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWalletFormDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(_S.addWallet),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Total hero card
// ---------------------------------------------------------------------------

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.totalMinor,
    required this.walletCount,
    required this.onTransfer,
  });

  final int totalMinor;
  final int walletCount;
  final VoidCallback? onTransfer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNegative = totalMinor < 0;
    final glow = isNegative ? AppTheme.expenseCoral : AppTheme.primaryEmerald;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.darkCardGradient
            : isNegative
            ? AppTheme.expenseGradient
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : glow.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -44,
            child: _Orb(size: 150, alpha: isDark ? 0.05 : 0.09),
          ),
          Positioned(
            right: 50,
            bottom: -60,
            child: _Orb(size: 110, alpha: isDark ? 0.04 : 0.07),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _S.totalLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _S.walletCount(walletCount),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMinor(totalMinor),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.1,
                      height: 1.05,
                    ),
                  ),
                ),
                if (onTransfer != null) ...[
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onTransfer,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _S.moveFunds,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet card
// ---------------------------------------------------------------------------

enum _WalletAction { edit, transfer, archive }

PopupMenuItem<_WalletAction> _menuItem(
  _WalletAction value,
  IconData icon,
  String label, {
  bool danger = false,
}) {
  final color = danger ? AppTheme.expenseCoral : null;
  return PopupMenuItem<_WalletAction>(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    ),
  );
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.wallet,
    required this.canArchive,
    required this.canTransfer,
  });

  final WalletEntity wallet;
  final bool canArchive;
  final bool canTransfer;

  Future<void> _onAction(BuildContext context, _WalletAction action) async {
    switch (action) {
      case _WalletAction.edit:
        await showWalletFormDialog(context, wallet: wallet);
      case _WalletAction.transfer:
        await showTransferFormSheet(context, fromWalletId: wallet.id);
      case _WalletAction.archive:
        await _archive(context);
    }
  }

  Future<void> _archive(BuildContext context) async {
    final balance = wallet.balanceMinor ?? 0;

    if (balance != 0) {
      final moveNow =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text(_S.moveFirstTitle),
              content: Text(
                _S.moveFirstBody(wallet.name, formatMinor(balance)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(_S.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(_S.transfer),
                ),
              ],
            ),
          ) ??
          false;
      if (moveNow && context.mounted) {
        await showTransferFormSheet(context, fromWalletId: wallet.id);
      }
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(_S.archiveTitle),
            content: Text(_S.archiveBody(wallet.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(_S.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(_S.archive),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      await context.read<WalletCubit>().archiveWallet(wallet.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final balance = wallet.balanceMinor ?? 0;
    final isArchived = wallet.isArchived;
    final accent = WalletIcons.color(wallet.iconKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: isArchived ? 0.6 : 1,
        child: Material(
          color: theme.cardColor,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(
                alpha: isDark ? 0.3 : 0.5,
              ),
            ),
          ),
          child: InkWell(
            onTap: isArchived
                ? null
                : () => showWalletFormDialog(context, wallet: wallet),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 12, isArchived ? 14 : 4, 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      WalletIcons.icon(wallet.iconKey),
                      size: 24,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (isArchived)
                          Text(
                            _S.archived,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          )
                        else
                          Text(
                            formatMinor(balance),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: balance < 0
                                  ? AppTheme.expenseCoral
                                  : scheme.onSurface,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isArchived)
                    PopupMenuButton<_WalletAction>(
                      tooltip: _S.actions,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                      onSelected: (action) => _onAction(context, action),
                      itemBuilder: (_) => [
                        _menuItem(
                          _WalletAction.edit,
                          Icons.edit_rounded,
                          _S.edit,
                        ),
                        if (canTransfer)
                          _menuItem(
                            _WalletAction.transfer,
                            Icons.swap_horiz_rounded,
                            _S.transferFromHere,
                          ),
                        if (canArchive)
                          _menuItem(
                            _WalletAction.archive,
                            Icons.archive_rounded,
                            _S.archive,
                            danger: true,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 34,
                color: AppTheme.primaryEmerald,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _S.emptyTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _S.emptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.add_rounded),
              label: const Text(_S.addWallet),
            ),
          ],
        ),
      ),
    );
  }
}
