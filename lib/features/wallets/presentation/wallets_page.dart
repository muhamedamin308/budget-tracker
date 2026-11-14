import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_format.dart';
import '../domain/wallet_entity.dart';
import 'transfer_form_sheet.dart';
import 'wallet_cubit.dart';
import 'wallet_form_dialog.dart';

abstract final class _S {
  static const title = 'Manage wallets';
  static const addWallet = 'Add wallet';
  static const noWallets = 'No wallets found.';
  static const totalLabel = 'Total across wallets';
  static const active = 'Active';
  static const archived = 'Archived';
  static const edit = 'Edit';
  static const transferFromHere = 'Transfer from here';
  static const archive = 'Archive';
  static const cancel = 'Cancel';
  static const transfer = 'Transfer';
  static const moveFirstTitle = 'Move the balance first';
  static const archiveTitle = 'Archive wallet';
  static const genericError = 'Something went wrong. Please try again.';

  static String walletCount(int count) => count == 1 ? '1 wallet' : '$count wallets';
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
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage ?? _S.genericError)),
        ),
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.wallets.isEmpty) {
            return const Center(child: Text(_S.noWallets));
          }

          final active = state.wallets.where((w) => !w.isArchived).toList();
          final archived = state.wallets.where((w) => w.isArchived).toList();
          final hasMultiple = active.length > 1;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _TotalCard(
                totalMinor: state.totalBalanceMinor,
                walletCount: active.length,
              ),
              const SizedBox(height: 20),
              const _SectionLabel(_S.active),
              for (final wallet in active)
                _WalletCard(
                  wallet: wallet,
                  canArchive: hasMultiple,
                  canTransfer: hasMultiple,
                ),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 12),
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

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalMinor, required this.walletCount});

  final int totalMinor;
  final int walletCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNegative = totalMinor < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.darkCardGradient
            : isNegative
            ? AppTheme.expenseGradient
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _S.totalLabel,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Text(
                _S.walletCount(walletCount),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMinor(totalMinor),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
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

enum _WalletAction { edit, transfer, archive }

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
      final moveNow = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(_S.moveFirstTitle),
          content: Text(_S.moveFirstBody(wallet.name, formatMinor(balance))),
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

    final confirmed = await showDialog<bool>(
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
              color: scheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
            ),
          ),
          child: InkWell(
            onTap: () => showWalletFormDialog(context, wallet: wallet),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 12, isArchived ? 14 : 4, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      CategoryIcons.getIcon(wallet.iconKey),
                      color: AppTheme.primaryEmerald,
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
                        const SizedBox(height: 2),
                        Text(
                          isArchived ? _S.archived : formatMinor(balance),
                          style: TextStyle(
                            fontSize: isArchived ? 12 : 16,
                            fontWeight: isArchived ? FontWeight.w600 : FontWeight.w800,
                            color: isArchived
                                ? scheme.onSurfaceVariant
                                : (balance < 0 ? AppTheme.expenseCoral : scheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isArchived)
                    PopupMenuButton<_WalletAction>(
                      onSelected: (action) => _onAction(context, action),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: _WalletAction.edit,
                          child: Text(_S.edit),
                        ),
                        if (canTransfer)
                          const PopupMenuItem(
                            value: _WalletAction.transfer,
                            child: Text(_S.transferFromHere),
                          ),
                        if (canArchive)
                          const PopupMenuItem(
                            value: _WalletAction.archive,
                            child: Text(_S.archive),
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