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
        ],
      );

  final GoRouter router;
}
