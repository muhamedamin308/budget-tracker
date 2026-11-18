import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../../features/home/presentation/home_page.dart';
import '../../features/budget/presentation/budget_bloc.dart';
import '../../core/di/injection.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/stats/presentation/stats_page.dart';
import '../../features/shell/presentation/month_cubit.dart';
import '../../features/shell/presentation/navigation_shell.dart';
import '../../features/wallets/presentation/wallets_page.dart';
import '../../features/transactions/presentation/transactions_history_page.dart';
import '../../features/backup/presentation/backup_page.dart';

@singleton
class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  AppRouter()
    : router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => getIt<MonthCubit>()),
                BlocProvider(
                  create: (context) => getIt<BudgetBloc>()
                    ..add(BudgetMonthChanged(context.read<MonthCubit>().state)),
                ),
              ],
              child: NavigationShell(navigationShell: navigationShell),
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: HomePage()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/stats',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: StatsPage()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/settings',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: SettingsPage()),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/wallets',
            builder: (context, state) => const WalletsPage(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsHistoryPage(),
          ),
          GoRoute(
            path: '/backups',
            builder: (context, state) => const BackupPage(),
          ),
        ],
      );

  final GoRouter router;
}
