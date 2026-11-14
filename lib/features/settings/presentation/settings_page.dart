// lib/features/settings/presentation/settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../categories/presentation/categories_bloc.dart';
import 'categories_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => getIt<CategoriesBloc>()..add(const CategoriesStarted()),
      child: SafeArea(
        child: Column(
          children: [
            EntranceAnimation(child: _StudioHeader(isDark: isDark)),
            const Expanded(child: CategoriesPage()),
          ],
        ),
      ),
    );
  }
}

class _StudioHeader extends StatelessWidget {
  const _StudioHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.darkCardGradient
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F7F2), Color(0xFFF8FCFB)],
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryEmerald.withValues(
            alpha: isDark ? 0.24 : 0.14,
          ),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryEmerald.withValues(
              alpha: isDark ? 0.18 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferences & Studio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Categories, limits & recurring rules',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _FeaturePill(
                icon: Icons.currency_exchange_rounded,
                label: 'EGP Currency',
                color: AppTheme.primaryEmerald,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _FeaturePill(
                icon: Icons.offline_bolt_rounded,
                label: 'Offline Safe',
                color: AppTheme.infoBlue,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _FeaturePill(
                icon: Icons.shield_rounded,
                label: 'Drift SQLite',
                color: AppTheme.warningAmber,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.07),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.24 : 0.14),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: isDark ? Colors.white.withValues(alpha: 0.9) : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
