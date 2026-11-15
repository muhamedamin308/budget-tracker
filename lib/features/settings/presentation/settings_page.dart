// lib/features/settings/presentation/settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../budget/domain/budget_status.dart';
import '../../budget/presentation/budget_bloc.dart';
import '../../budget/presentation/monthly_limit_dialog.dart';
import '../../recurring/presentation/recurring_rules_page.dart';
import 'categories_page.dart';
import 'widget_settings_sheet.dart';

abstract final class _S {
  static const title = 'Settings';
  static const subtitle = 'Make the app work your way';
  static const manage = 'Manage';
  static const automation = 'Automation';
  static const appearance = 'Appearance';
  static const wallets = 'Wallets';
  static const walletsSubtitle = 'Balances & transfers';
  static const categories = 'Categories';
  static const categoriesSubtitle = 'Income & spending tags';
  static const monthlyLimit = 'Monthly limit';
  static const limitNotSet = 'Not set';
  static const limitHint = 'Tap to set a spending cap';
  static const recurring = 'Recurring rules';
  static const recurringSubtitle = 'Salary, subscriptions and other repeats';
  static const widget = 'Widget';
  static const widgetSubtitle = 'Balance and budget on your home screen';
  static const auto = 'Auto';
  static const light = 'Light';
  static const dark = 'Dark';
  static const footer = 'All your data is stored on this device.';
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _openCategories(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: (_) => const CategoriesPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          EntranceAnimation(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _S.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _S.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const EntranceAnimation(
            delay: Duration(milliseconds: 40),
            child: _LimitCard(),
          ),
          const SizedBox(height: 24),
          EntranceAnimation(
            delay: const Duration(milliseconds: 80),
            child: _Section(
              title: _S.manage,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.account_balance_wallet_rounded,
                        title: _S.wallets,
                        subtitle: _S.walletsSubtitle,
                        onTap: () => context.push('/wallets'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.category_rounded,
                        title: _S.categories,
                        subtitle: _S.categoriesSubtitle,
                        onTap: () => _openCategories(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          EntranceAnimation(
            delay: const Duration(milliseconds: 120),
            child: _SettingsGroup(
              title: _S.automation,
              children: [
                _SettingsTile(
                  icon: Icons.event_repeat_rounded,
                  title: _S.recurring,
                  subtitle: _S.recurringSubtitle,
                  onTap: () => showRecurringRules(context),
                ),
                _SettingsTile(
                  icon: Icons.widgets_rounded,
                  title: _S.widget,
                  subtitle: _S.widgetSubtitle,
                  onTap: () => showWidgetSettingsSheet(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const EntranceAnimation(
            delay: Duration(milliseconds: 160),
            child: _Section(title: _S.appearance, child: _ThemePicker()),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _S.footer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Limit hero card
// ---------------------------------------------------------------------------

class _LimitCard extends StatelessWidget {
  const _LimitCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        final status = state is BudgetLoaded ? state.status : null;
        final limit = status?.limitMinor;
        final exceeded = status?.level == BudgetLevel.exceeded;

        final gradient = isDark
            ? AppTheme.darkCardGradient
            : exceeded
            ? AppTheme.expenseGradient
            : AppTheme.primaryGradient;
        final glow = exceeded ? AppTheme.expenseCoral : AppTheme.primaryEmerald;

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: gradient,
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
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => showMonthlyLimitDialog(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            Icons.speed_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _S.monthlyLimit,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        limit == null ? _S.limitNotSet : formatMinor(limit),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (limit == null || status == null)
                      Text(
                        _S.limitHint,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      )
                    else ...[
                      Text(
                        'Spent ${formatMinor(status.spentMinor)} · '
                        '${(status.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: status.progress.clamp(0.0, 1.0).toDouble(),
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Layout building blocks
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline = theme.colorScheme.outlineVariant;

    return Material(
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: outline.withValues(alpha: isDark ? 0.3 : 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: AppTheme.primaryEmerald),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline = theme.colorScheme.outlineVariant;

    return _Section(
      title: title,
      child: Material(
        color: theme.cardColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: outline.withValues(alpha: isDark ? 0.3 : 0.5),
          ),
        ),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 70,
                  color: outline.withValues(alpha: 0.4),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppTheme.primaryEmerald),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme picker
// ---------------------------------------------------------------------------

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        Widget option(ThemeMode value, IconData icon, String label) {
          return Expanded(
            child: _ThemeOption(
              icon: icon,
              label: label,
              selected: mode == value,
              onTap: () => context.read<ThemeCubit>().setThemeMode(value),
            ),
          );
        }

        return Row(
          children: [
            option(ThemeMode.system, Icons.brightness_auto_rounded, _S.auto),
            const SizedBox(width: 10),
            option(ThemeMode.light, Icons.light_mode_rounded, _S.light),
            const SizedBox(width: 10),
            option(ThemeMode.dark, Icons.dark_mode_rounded, _S.dark),
          ],
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outlineVariant;
    final color = selected
        ? AppTheme.primaryEmerald
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppTheme.primaryEmerald.withValues(alpha: 0.12)
            : theme.cardColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected
                ? AppTheme.primaryEmerald
                : outline.withValues(alpha: 0.5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
