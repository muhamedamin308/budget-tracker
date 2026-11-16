import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/widget_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/recurring/domain/recurring_use_cases.dart';
import 'features/recurring/presentation/recurring_generation_runner.dart';
import 'features/security/presentation/lock_screen_overlay.dart';
import 'features/security/presentation/privacy_cubit.dart';
import 'features/security/presentation/security_cubit.dart';
import 'features/transactions/domain/transaction_entity.dart';
import 'features/transactions/presentation/transaction_form_sheet.dart';

class BudgetTrackerApp extends StatefulWidget {
  const BudgetTrackerApp({super.key});

  @override
  State<BudgetTrackerApp> createState() => _BudgetTrackerAppState();
}

class _BudgetTrackerAppState extends State<BudgetTrackerApp>
    with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getIt<WidgetSyncService>().startListening();
    _initHomeWidgetClick();
  }

  void _initHomeWidgetClick() {
    _widgetClickSubscription = HomeWidget.widgetClicked.listen((uri) {
      _handleWidgetUri(uri);
    });

    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        _handleWidgetUri(uri);
      }
    });
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme == 'budgettracker' &&
        (uri.host == 'add-expense' || uri.path.contains('add-expense'))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = AppRouter.rootNavigatorKey.currentContext;
        if (context != null) {
          showTransactionForm(context, kind: TransactionKind.expense);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      getIt<SecurityCubit>().onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      getIt<SecurityCubit>().onAppResumed();
      unawaited(runRecurringGeneration(getIt<GenerateDueRecurring>()));
      unawaited(getIt<WidgetSyncService>().syncNow());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider.value(value: getIt<PrivacyCubit>()),
        BlocProvider.value(value: getIt<SecurityCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Budget Tracker',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: getIt<AppRouter>().router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return LockScreenOverlay(child: child ?? const SizedBox.shrink());
            },
          );
        },
      ),
    );
  }
}
