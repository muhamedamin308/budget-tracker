// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:budget_tracker/core/database/app_database.dart' as _i1070;
import 'package:budget_tracker/core/database/daos/budget_dao.dart' as _i661;
import 'package:budget_tracker/core/database/daos/category_dao.dart' as _i365;
import 'package:budget_tracker/core/database/daos/recurring_dao.dart' as _i657;
import 'package:budget_tracker/core/database/daos/transaction_dao.dart'
    as _i584;
import 'package:budget_tracker/core/di/injection.dart' as _i263;
import 'package:budget_tracker/core/router/app_router.dart' as _i729;
import 'package:budget_tracker/core/services/widget_sync_service.dart' as _i645;
import 'package:budget_tracker/features/budget/data/budget_repository_impl.dart'
    as _i13;
import 'package:budget_tracker/features/budget/domain/budget_repository.dart'
    as _i226;
import 'package:budget_tracker/features/budget/domain/budget_use_cases.dart'
    as _i1004;
import 'package:budget_tracker/features/budget/presentation/budget_bloc.dart'
    as _i370;
import 'package:budget_tracker/features/categories/data/category_repository_impl.dart'
    as _i352;
import 'package:budget_tracker/features/categories/domain/category_repository.dart'
    as _i601;
import 'package:budget_tracker/features/categories/domain/category_use_cases.dart'
    as _i1061;
import 'package:budget_tracker/features/categories/presentation/categories_bloc.dart'
    as _i888;
import 'package:budget_tracker/features/recurring/data/recurring_repository_impl.dart'
    as _i1043;
import 'package:budget_tracker/features/recurring/domain/recurring_repository.dart'
    as _i93;
import 'package:budget_tracker/features/recurring/domain/recurring_use_cases.dart'
    as _i31;
import 'package:budget_tracker/features/recurring/presentation/recurring_bloc.dart'
    as _i167;
import 'package:budget_tracker/features/shell/presentation/month_cubit.dart'
    as _i256;
import 'package:budget_tracker/features/stats/domain/watch_month_stats.dart'
    as _i453;
import 'package:budget_tracker/features/stats/presentation/stats_bloc.dart'
    as _i433;
import 'package:budget_tracker/features/transactions/data/transaction_repository_impl.dart'
    as _i20;
import 'package:budget_tracker/features/transactions/domain/transaction_repository.dart'
    as _i123;
import 'package:budget_tracker/features/transactions/domain/transaction_use_cases.dart'
    as _i403;
import 'package:budget_tracker/features/transactions/presentation/transaction_form_cubit.dart'
    as _i563;
import 'package:budget_tracker/features/transactions/presentation/transactions_bloc.dart'
    as _i680;
import 'package:budget_tracker/features/transactions/presentation/wallet_bloc.dart'
    as _i839;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    gh.singleton<_i729.AppRouter>(() => _i729.AppRouter());
    gh.lazySingleton<_i1070.AppDatabase>(() => databaseModule.appDatabase);
    gh.lazySingleton<_i661.BudgetDao>(
      () => _i661.BudgetDao(gh<_i1070.AppDatabase>()),
    );
    gh.lazySingleton<_i365.CategoryDao>(
      () => _i365.CategoryDao(gh<_i1070.AppDatabase>()),
    );
    gh.lazySingleton<_i657.RecurringDao>(
      () => _i657.RecurringDao(gh<_i1070.AppDatabase>()),
    );
    gh.lazySingleton<_i584.TransactionDao>(
      () => _i584.TransactionDao(gh<_i1070.AppDatabase>()),
    );
    gh.lazySingleton<_i93.RecurringRepository>(
      () => _i1043.RecurringRepositoryImpl(gh<_i657.RecurringDao>()),
    );
    gh.lazySingleton<_i226.BudgetRepository>(
      () => _i13.BudgetRepositoryImpl(gh<_i661.BudgetDao>()),
    );
    gh.lazySingleton<_i123.TransactionRepository>(
      () => _i20.TransactionRepositoryImpl(
        gh<_i584.TransactionDao>(),
        gh<_i365.CategoryDao>(),
      ),
    );
    gh.factory<_i256.MonthCubit>(
      () => _i256.MonthCubit(gh<_i123.TransactionRepository>()),
    );
    gh.factory<_i453.WatchMonthStats>(
      () => _i453.WatchMonthStats(gh<_i123.TransactionRepository>()),
    );
    gh.factory<_i31.WatchRules>(
      () => _i31.WatchRules(gh<_i93.RecurringRepository>()),
    );
    gh.factory<_i31.SetRuleActive>(
      () => _i31.SetRuleActive(gh<_i93.RecurringRepository>()),
    );
    gh.factory<_i31.DeleteRule>(
      () => _i31.DeleteRule(gh<_i93.RecurringRepository>()),
    );
    gh.factory<_i31.GenerateDueRecurring>(
      () => _i31.GenerateDueRecurring(gh<_i93.RecurringRepository>()),
    );
    gh.factory<_i403.WatchBalance>(
      () => _i403.WatchBalance(gh<_i123.TransactionRepository>()),
    );
    gh.factory<_i403.WatchMonthTransactions>(
      () => _i403.WatchMonthTransactions(gh<_i123.TransactionRepository>()),
    );
    gh.factory<_i403.DeleteTransaction>(
      () => _i403.DeleteTransaction(gh<_i123.TransactionRepository>()),
    );
    gh.factory<_i403.RestoreTransaction>(
      () => _i403.RestoreTransaction(gh<_i123.TransactionRepository>()),
    );
    gh.lazySingleton<_i601.CategoryRepository>(
      () => _i352.CategoryRepositoryImpl(gh<_i365.CategoryDao>()),
    );
    gh.factory<_i433.StatsBloc>(
      () => _i433.StatsBloc(gh<_i453.WatchMonthStats>()),
    );
    gh.factory<_i31.SaveRule>(
      () => _i31.SaveRule(
        gh<_i93.RecurringRepository>(),
        gh<_i601.CategoryRepository>(),
      ),
    );
    gh.factory<_i1004.WatchBudgetStatus>(
      () => _i1004.WatchBudgetStatus(gh<_i226.BudgetRepository>()),
    );
    gh.factory<_i1004.SetMonthlyLimit>(
      () => _i1004.SetMonthlyLimit(gh<_i226.BudgetRepository>()),
    );
    gh.factory<_i167.RecurringBloc>(
      () => _i167.RecurringBloc(
        gh<_i31.WatchRules>(),
        gh<_i31.SaveRule>(),
        gh<_i31.SetRuleActive>(),
        gh<_i31.DeleteRule>(),
      ),
    );
    gh.factory<_i1061.WatchCategories>(
      () => _i1061.WatchCategories(gh<_i601.CategoryRepository>()),
    );
    gh.factory<_i1061.AddCategory>(
      () => _i1061.AddCategory(gh<_i601.CategoryRepository>()),
    );
    gh.factory<_i1061.RenameCategory>(
      () => _i1061.RenameCategory(gh<_i601.CategoryRepository>()),
    );
    gh.factory<_i1061.ArchiveCategory>(
      () => _i1061.ArchiveCategory(gh<_i601.CategoryRepository>()),
    );
    gh.singleton<_i645.WidgetSyncService>(
      () => _i645.WidgetSyncServiceImpl(
        gh<_i403.WatchBalance>(),
        gh<_i1004.WatchBudgetStatus>(),
      ),
    );
    gh.factory<_i839.WalletBloc>(
      () => _i839.WalletBloc(gh<_i403.WatchBalance>()),
    );
    gh.factory<_i680.TransactionsBloc>(
      () => _i680.TransactionsBloc(
        gh<_i403.WatchMonthTransactions>(),
        gh<_i403.DeleteTransaction>(),
        gh<_i403.RestoreTransaction>(),
      ),
    );
    gh.factory<_i403.AddIncome>(
      () => _i403.AddIncome(
        gh<_i123.TransactionRepository>(),
        gh<_i601.CategoryRepository>(),
      ),
    );
    gh.factory<_i403.AddExpense>(
      () => _i403.AddExpense(
        gh<_i123.TransactionRepository>(),
        gh<_i601.CategoryRepository>(),
      ),
    );
    gh.factory<_i403.UpdateTransaction>(
      () => _i403.UpdateTransaction(
        gh<_i123.TransactionRepository>(),
        gh<_i601.CategoryRepository>(),
      ),
    );
    gh.factory<_i370.BudgetBloc>(
      () => _i370.BudgetBloc(
        gh<_i1004.WatchBudgetStatus>(),
        gh<_i1004.SetMonthlyLimit>(),
      ),
    );
    gh.factory<_i888.CategoriesBloc>(
      () => _i888.CategoriesBloc(
        gh<_i1061.WatchCategories>(),
        gh<_i1061.AddCategory>(),
        gh<_i1061.RenameCategory>(),
        gh<_i1061.ArchiveCategory>(),
      ),
    );
    gh.factory<_i563.TransactionFormCubit>(
      () => _i563.TransactionFormCubit(
        gh<_i601.CategoryRepository>(),
        gh<_i403.AddIncome>(),
        gh<_i403.AddExpense>(),
        gh<_i403.UpdateTransaction>(),
      ),
    );
    return this;
  }
}

class _$DatabaseModule extends _i263.DatabaseModule {}
