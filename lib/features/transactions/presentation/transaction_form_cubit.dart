import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../../wallets/domain/wallet_entity.dart';
import '../../wallets/domain/wallet_use_cases.dart';
import '../domain/transaction_entity.dart';
import '../domain/transaction_use_cases.dart';

@injectable
class TransactionFormCubit extends Cubit<TransactionFormState> {
  TransactionFormCubit(
    this._categoryRepository,
    this._addIncome,
    this._addExpense,
    this._updateTransaction,
    this._watchWallets,
  ) : super(const TransactionFormState());

  final CategoryRepository _categoryRepository;
  final AddIncome _addIncome;
  final AddExpense _addExpense;
  final UpdateTransaction _updateTransaction;
  final WatchWallets _watchWallets;
  TransactionEntity? _transaction;

  Future<void> initialize({
    required TransactionKind kind,
    TransactionEntity? transaction,
  }) async {
    _transaction = transaction;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final categories = await _categoryRepository.watchCategories().first;
      final wallets = await _watchWallets().first;
      final activeWallets = wallets.where((w) => !w.isArchived).toList();
      final active = categories
          .where((category) => _matchesType(category.type, kind))
          .toList();
      if (transaction != null &&
          active.every((category) => category.id != transaction.categoryId)) {
        final originalCategory = await _categoryRepository.getById(
          transaction.categoryId,
        );
        if (originalCategory != null) active.add(originalCategory);
      }

      final lastUsed = transaction == null
          ? await _categoryRepository.getLastUsedCategory(_categoryType(kind))
          : null;
      final selectedCategoryId =
          transaction?.categoryId ??
          lastUsed?.id ??
          (active.isEmpty ? null : active.first.id);

      final selectedWalletId = transaction != null
          ? (activeWallets.any((w) => w.id == transaction.walletId)
              ? transaction.walletId
              : (activeWallets.isEmpty ? null : activeWallets.first.id))
          : (activeWallets.isEmpty ? null : activeWallets.first.id);

      emit(
        state.copyWith(
          kind: kind,
          amountText: transaction == null
              ? ''
              : (transaction.amountMinor / 100).toStringAsFixed(2),
          title: transaction?.title ?? '',
          categories: active,
          wallets: activeWallets,
          selectedCategoryId: selectedCategoryId,
          selectedWalletId: selectedWalletId,
          isLoading: false,
          isSubmitting: false,
          clearError: true,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Could not load categories: $error',
        ),
      );
    }
  }

  void amountChanged(String value) =>
      emit(state.copyWith(amountText: value, clearError: true));

  void titleChanged(String value) =>
      emit(state.copyWith(title: value, clearError: true));

  void categorySelected(int id) =>
      emit(state.copyWith(selectedCategoryId: id, clearError: true));

  void walletSelected(int id) =>
      emit(state.copyWith(selectedWalletId: id, clearError: true));

  Future<void> submit() async {
    if (state.isLoading || state.isSubmitting) return;
    final amount = double.tryParse(state.amountText.trim());
    if (amount == null || !amount.isFinite || amount <= 0) {
      emit(state.copyWith(errorMessage: 'Enter an amount greater than zero.'));
      return;
    }
    final categoryId = state.selectedCategoryId;
    if (categoryId == null) {
      emit(state.copyWith(errorMessage: 'Select a category.'));
      return;
    }
    final walletId = state.selectedWalletId;
    if (walletId == null) {
      emit(state.copyWith(errorMessage: 'Select a wallet.'));
      return;
    }
    final amountMinor = (amount * 100).round();
    if (amountMinor <= 0) {
      emit(state.copyWith(errorMessage: 'Amount is too small.'));
      return;
    }
    if (state.kind == TransactionKind.income && state.title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Income title is required.'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));
    final transaction = _transaction;
    final Either<Failure, Unit> result;
    if (transaction != null) {
      result = await _updateTransaction(
        id: transaction.id,
        originalCategoryId: transaction.categoryId,
        draft: TransactionDraft(
          kind: state.kind,
          amountMinor: amountMinor,
          categoryId: categoryId,
          title: state.kind == TransactionKind.income
              ? state.title.trim()
              : null,
          createdAt: transaction.createdAt,
          walletId: walletId,
        ),
      );
    } else if (state.kind == TransactionKind.income) {
      result = await _addIncome(
        amountMinor: amountMinor,
        categoryId: categoryId,
        title: state.title.trim(),
        walletId: walletId,
      );
    } else {
      result = await _addExpense(
        amountMinor: amountMinor,
        categoryId: categoryId,
        walletId: walletId,
      );
    }

    result.fold(
      (failure) => emit(
        state.copyWith(isSubmitting: false, errorMessage: failure.message),
      ),
      (_) => emit(state.copyWith(isSubmitting: false, isSubmitted: true)),
    );
  }

  CategoryType _categoryType(TransactionKind kind) => switch (kind) {
    TransactionKind.income => CategoryType.income,
    TransactionKind.expense => CategoryType.expense,
  };

  bool _matchesType(CategoryType categoryType, TransactionKind kind) =>
      categoryType == _categoryType(kind);
}

class TransactionFormState extends Equatable {
  const TransactionFormState({
    this.kind = TransactionKind.expense,
    this.amountText = '',
    this.title = '',
    this.categories = const [],
    this.wallets = const [],
    this.selectedCategoryId,
    this.selectedWalletId,
    this.isLoading = true,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.errorMessage,
  });

  final TransactionKind kind;
  final String amountText;
  final String title;
  final List<CategoryEntity> categories;
  final List<WalletEntity> wallets;
  final int? selectedCategoryId;
  final int? selectedWalletId;
  final bool isLoading;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? errorMessage;

  TransactionFormState copyWith({
    TransactionKind? kind,
    String? amountText,
    String? title,
    List<CategoryEntity>? categories,
    List<WalletEntity>? wallets,
    int? selectedCategoryId,
    int? selectedWalletId,
    bool clearSelectedCategory = false,
    bool clearSelectedWallet = false,
    bool? isLoading,
    bool? isSubmitting,
    bool? isSubmitted,
    String? errorMessage,
    bool clearError = false,
  }) => TransactionFormState(
    kind: kind ?? this.kind,
    amountText: amountText ?? this.amountText,
    title: title ?? this.title,
    categories: categories ?? this.categories,
    wallets: wallets ?? this.wallets,
    selectedCategoryId: clearSelectedCategory
        ? null
        : selectedCategoryId ?? this.selectedCategoryId,
    selectedWalletId: clearSelectedWallet
        ? null
        : selectedWalletId ?? this.selectedWalletId,
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isSubmitted: isSubmitted ?? this.isSubmitted,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [
    kind,
    amountText,
    title,
    categories,
    wallets,
    selectedCategoryId,
    selectedWalletId,
    isLoading,
    isSubmitting,
    isSubmitted,
    errorMessage,
  ];
}
