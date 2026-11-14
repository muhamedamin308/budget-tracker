import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_format.dart';
import 'wallet_cubit.dart';
import 'wallet_form_dialog.dart';

abstract final class _S {
  static const allWallets = 'All wallets';
  static const addWallet = 'Add wallet';
}

class WalletSelectorBar extends StatelessWidget {
  const WalletSelectorBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        if (state.isLoading) return const _SelectorSkeleton();

        final wallets = state.wallets.where((w) => !w.isArchived).toList();
        final cubit = context.read<WalletCubit>();

        return SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: wallets.length + 2,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _WalletPill(
                  icon: Icons.account_balance_wallet_rounded,
                  name: _S.allWallets,
                  balanceMinor: state.totalBalanceMinor,
                  selected: state.selectedWalletId == null,
                  onTap: () => cubit.selectWallet(null),
                );
              }
              if (index == wallets.length + 1) {
                return Center(
                  child: IconButton.outlined(
                    tooltip: _S.addWallet,
                    onPressed: () => showWalletFormDialog(context),
                    icon: const Icon(Icons.add_rounded),
                  ),
                );
              }

              final wallet = wallets[index - 1];
              return _WalletPill(
                icon: CategoryIcons.getIcon(wallet.iconKey),
                name: wallet.name,
                balanceMinor: wallet.balanceMinor ?? 0,
                selected: state.selectedWalletId == wallet.id,
                onTap: () => cubit.selectWallet(wallet.id),
                onLongPress: () => showWalletFormDialog(context, wallet: wallet),
              );
            },
          ),
        );
      },
    );
  }
}

class _WalletPill extends StatelessWidget {
  const _WalletPill({
    required this.icon,
    required this.name,
    required this.balanceMinor,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String name;
  final int balanceMinor;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isNegative = balanceMinor < 0;

    final nameColor = selected ? Colors.white : scheme.onSurface;
    final balanceColor = selected
        ? Colors.white.withValues(alpha: 0.85)
        : (isNegative ? AppTheme.expenseCoral : scheme.onSurfaceVariant);
    final bubbleColor = selected
        ? Colors.white.withValues(alpha: 0.22)
        : AppTheme.primaryEmerald.withValues(alpha: 0.12);
    final iconColor = selected ? Colors.white : AppTheme.primaryEmerald;

    return Semantics(
      button: true,
      selected: selected,
      label: '$name, ${formatMinor(balanceMinor)}',
      onTap: onTap,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppTheme.primaryEmerald : theme.cardColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? AppTheme.primaryEmerald
                : scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: nameColor,
                          ),
                        ),
                        Text(
                          formatMinor(balanceMinor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: balanceColor,
                          ),
                        ),
                      ],
                    ),
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

class _SelectorSkeleton extends StatelessWidget {
  const _SelectorSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              width: 112,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}