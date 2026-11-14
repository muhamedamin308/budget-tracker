// lib/features/settings/presentation/settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../budget/presentation/budget_bloc.dart';
import '../../budget/presentation/monthly_limit_dialog.dart';
import '../../recurring/presentation/recurring_rules_page.dart';
import 'categories_page.dart';
import 'widget_settings_sheet.dart';

abstract final class _S {
  static const title = 'Settings';
  static const money = 'Money';
  static const appearance = 'Appearance';
  static const homeScreen = 'Home screen';
  static const wallets = 'Wallets';
  static const walletsSubtitle = 'Balances, transfers and icons';
  static const categories = 'Categories';
  static const categoriesSubtitle = 'Tags for income and spending';
  static const monthlyLimit = 'Monthly limit';
  static const limitNotSet = 'Not set';
  static const recurring = 'Recurring rules';
  static const recurringSubtitle = 'Salary, subscriptions and other repeats';
  static const widget = 'Widget';
  static const widgetSubtitle = 'Balance and budget on your home screen';
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
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(_S.title, style: theme.textTheme.headlineMedium),
            ),
          ),
          EntranceAnimation(
            delay: const Duration(milliseconds: 40),
            child: _SettingsGroup(
              title: _S.appearance,
              children: [
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    return Padding(
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
                            child: const Icon(
                              Icons.brightness_6_rounded,
                              size: 20,
                              color: AppTheme.primaryEmerald,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Theme Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Switch between light, dark or auto',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(Icons.brightness_auto_rounded, size: 15),
                                label: Text('Auto'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_rounded, size: 15),
                                label: Text('Light'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_rounded, size: 15),
                                label: Text('Dark'),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: (Set<ThemeMode> newSelection) {
                              context.read<ThemeCubit>().setThemeMode(newSelection.first);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          EntranceAnimation(
            delay: const Duration(milliseconds: 80),
            child: _SettingsGroup(
              title: _S.money,
              children: [
                _SettingsTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: _S.wallets,
                  subtitle: _S.walletsSubtitle,
                  onTap: () => context.push('/wallets'),
                ),
                _SettingsTile(
                  icon: Icons.category_rounded,
                  title: _S.categories,
                  subtitle: _S.categoriesSubtitle,
                  onTap: () => _openCategories(context),
                ),
                BlocBuilder<BudgetBloc, BudgetState>(
                  builder: (context, state) {
                    final limit = state is BudgetLoaded
                        ? state.status.limitMinor
                        : null;
                    return _SettingsTile(
                      icon: Icons.speed_rounded,
                      title: _S.monthlyLimit,
                      subtitle: limit == null
                          ? _S.limitNotSet
                          : formatMinor(limit),
                      onTap: () => showMonthlyLimitDialog(context),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.event_repeat_rounded,
                  title: _S.recurring,
                  subtitle: _S.recurringSubtitle,
                  onTap: () => showRecurringRules(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          EntranceAnimation(
            delay: const Duration(milliseconds: 120),
            child: _SettingsGroup(
              title: _S.homeScreen,
              children: [
                _SettingsTile(
                  icon: Icons.widgets_rounded,
                  title: _S.widget,
                  subtitle: _S.widgetSubtitle,
                  onTap: () => showWidgetSettingsSheet(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              _S.footer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
        Material(
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
      ],
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
