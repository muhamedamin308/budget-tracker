import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../domain/category_entity.dart';
import '../domain/category_use_cases.dart';

@injectable
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc(
    this._watchCategories,
    this._addCategory,
    this._renameCategory,
    this._archiveCategory,
  ) : super(const CategoriesInitial()) {
    on<CategoriesStarted>((event, emit) => _watch(emit));
    on<CategoriesRetryRequested>((event, emit) => _watch(emit));
    on<_CategoriesReceived>(
      (event, emit) => emit(CategoriesLoaded(event.categories)),
    );
    on<_CategoriesWatchFailed>(
      (event, emit) => emit(CategoriesError(event.message)),
    );
    on<CategoryAdded>(_onCategoryAdded);
    on<CategoryRenamed>(_onCategoryRenamed);
    on<CategoryArchived>(_onCategoryArchived);
  }

  final WatchCategories _watchCategories;
  final AddCategory _addCategory;
  final RenameCategory _renameCategory;
  final ArchiveCategory _archiveCategory;

  StreamSubscription<List<CategoryEntity>>? _subscription;

  Future<void> _watch(Emitter<CategoriesState> emit) async {
    emit(const CategoriesLoading());
    await _subscription?.cancel();
    if (emit.isDone) return;
    _subscription = _watchCategories().listen(
      (categories) {
        if (!isClosed) add(_CategoriesReceived(categories));
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed) add(_CategoriesWatchFailed(error.toString()));
      },
    );
  }

  Future<void> _onCategoryAdded(
    CategoryAdded event,
    Emitter<CategoriesState> emit,
  ) async {
    final result = await _addCategory(name: event.name, type: event.type);
    result.fold((failure) => _emitFailure(emit, failure), (_) {});
  }

  Future<void> _onCategoryRenamed(
    CategoryRenamed event,
    Emitter<CategoriesState> emit,
  ) async {
    final result = await _renameCategory(id: event.id, name: event.name);
    result.fold((failure) => _emitFailure(emit, failure), (_) {});
  }

  Future<void> _onCategoryArchived(
    CategoryArchived event,
    Emitter<CategoriesState> emit,
  ) async {
    final result = await _archiveCategory(event.id);
    result.fold((failure) => _emitFailure(emit, failure), (_) {});
  }

  void _emitFailure(Emitter<CategoriesState> emit, Failure failure) {
    final currentState = state;
    if (currentState is CategoriesLoaded) {
      emit(currentState.copyWith(errorMessage: failure.message));
    } else {
      emit(CategoriesError(failure.message));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

sealed class CategoriesEvent extends Equatable {
  const CategoriesEvent();
}

final class CategoriesStarted extends CategoriesEvent {
  const CategoriesStarted();

  @override
  List<Object?> get props => [];
}

final class CategoriesRetryRequested extends CategoriesEvent {
  const CategoriesRetryRequested();

  @override
  List<Object?> get props => [];
}

final class CategoryAdded extends CategoriesEvent {
  const CategoryAdded({required this.name, required this.type});

  final String name;
  final CategoryType type;

  @override
  List<Object?> get props => [name, type];
}

final class CategoryRenamed extends CategoriesEvent {
  const CategoryRenamed({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

final class CategoryArchived extends CategoriesEvent {
  const CategoryArchived(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

final class _CategoriesReceived extends CategoriesEvent {
  const _CategoriesReceived(this.categories);

  final List<CategoryEntity> categories;

  @override
  List<Object?> get props => [categories];
}

final class _CategoriesWatchFailed extends CategoriesEvent {
  const _CategoriesWatchFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class CategoriesState extends Equatable {
  const CategoriesState();
}

final class CategoriesInitial extends CategoriesState {
  const CategoriesInitial();

  @override
  List<Object?> get props => [];
}

final class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();

  @override
  List<Object?> get props => [];
}

final class CategoriesLoaded extends CategoriesState {
  const CategoriesLoaded(this.categories, {this.errorMessage});

  final List<CategoryEntity> categories;
  final String? errorMessage;

  CategoriesLoaded copyWith({String? errorMessage}) =>
      CategoriesLoaded(categories, errorMessage: errorMessage);

  @override
  List<Object?> get props => [categories, errorMessage];
}

final class CategoriesError extends CategoriesState {
  const CategoriesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
