import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_format.dart';
import 'wallet_cubit.dart';
import 'wallet_form_dialog.dart';
import 'wallet_icons.dart';

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
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: wallets.length + 2,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _WalletPill(
                  icon: Icons.layers_rounded,
                  accent: AppTheme.primaryEmerald,
                  name: _S.allWallets,
                  balanceMinor: state.totalBalanceMinor,
                  selected: state.selectedWalletId == null,
                  onTap: () => cubit.selectWallet(null),
                );
              }
              if (index == wallets.length + 1) {
                return const _AddButton();
              }

              final wallet = wallets[index - 1];
              return _WalletPill(
                icon: WalletIcons.icon(wallet.iconKey),
                accent: WalletIcons.color(wallet.iconKey),
                name: wallet.name,
                balanceMinor: wallet.balanceMinor ?? 0,
                selected: state.selectedWalletId == wallet.id,
                onTap: () => cubit.selectWallet(wallet.id),
                onLongPress: () =>
                    showWalletFormDialog(context, wallet: wallet),
              );
            },
          ),
        );
      },
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Tooltip(
        message: _S.addWallet,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: InkWell(
            onTap: () => showWalletFormDialog(context),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.add_rounded, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletPill extends StatelessWidget {
  const _WalletPill({
    required this.icon,
    required this.accent,
    required this.name,
    required this.balanceMinor,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final Color accent;
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
    final radius = BorderRadius.circular(18);

    final nameColor = selected ? Colors.white : scheme.onSurface;
    final balanceColor = selected
        ? Colors.white.withValues(alpha: 0.85)
        : (isNegative ? AppTheme.expenseCoral : scheme.onSurfaceVariant);
    final bubbleColor = selected
        ? Colors.white.withValues(alpha: 0.22)
        : accent.withValues(alpha: 0.14);
    final iconColor = selected ? Colors.white : accent;

    return Semantics(
      button: true,
      selected: selected,
      label: '$name, ${formatMinor(balanceMinor)}',
      onTap: onTap,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.primaryGradient : null,
            color: selected ? null : theme.cardColor,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                    const SizedBox(width: 10),
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
      height: 58,
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              width: 120,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
