import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../domain/recurring_rule_entity.dart';
import '../domain/recurring_use_cases.dart';

@injectable
class RecurringBloc extends Bloc<RecurringEvent, RecurringState> {
  RecurringBloc(
    this._watchRules,
    this._saveRule,
    this._setRuleActive,
    this._deleteRule,
  ) : super(const RecurringLoading()) {
    on<RecurringStarted>((event, emit) => _watch(emit));
    on<RecurringRetryRequested>((event, emit) => _watch(emit));
    on<_RulesReceived>((event, emit) {
      final current = state;
      emit(
        RecurringLoaded(
          event.rules,
          isSaving: current is RecurringLoaded && current.isSaving,
          saveRevision: current is RecurringLoaded ? current.saveRevision : 0,
          errorMessage: current is RecurringLoaded
              ? current.errorMessage
              : null,
        ),
      );
    });
    on<_RulesWatchFailed>((event, emit) {
      final current = state;
      if (current is RecurringLoaded) {
        emit(current.copyWith(errorMessage: event.message));
      } else {
        emit(RecurringError(event.message));
      }
    });
    on<RuleSaveRequested>(_onRuleSaveRequested);
    on<RuleToggled>(_onRuleToggled);
    on<RuleDeleted>(_onRuleDeleted);
  }

  final WatchRules _watchRules;
  final SaveRule _saveRule;
  final SetRuleActive _setRuleActive;
  final DeleteRule _deleteRule;
  StreamSubscription<List<RecurringRuleEntity>>? _subscription;

  Future<void> _watch(Emitter<RecurringState> emit) async {
    emit(const RecurringLoading());
    await _subscription?.cancel();
    if (emit.isDone) return;
    _subscription = _watchRules().listen(
      (rules) {
        if (!isClosed) add(_RulesReceived(rules));
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed) add(_RulesWatchFailed(error.toString()));
      },
    );
  }

  Future<void> _onRuleSaveRequested(
    RuleSaveRequested event,
    Emitter<RecurringState> emit,
  ) async {
    final beforeSave = state;
    if (beforeSave is RecurringLoaded) {
      emit(beforeSave.copyWith(isSaving: true, clearError: true));
    }
    final result = await _saveRule(event.draft);
    result.fold((failure) => _emitFailure(emit, failure), (_) {
      final current = state;
      if (current is RecurringLoaded) {
        emit(
          current.copyWith(
            isSaving: false,
            saveRevision: current.saveRevision + 1,
            clearError: true,
          ),
        );
      }
    });
  }

  Future<void> _onRuleToggled(
    RuleToggled event,
    Emitter<RecurringState> emit,
  ) async {
    final result = await _setRuleActive(event.id, event.isActive);
    result.fold((failure) => _emitFailure(emit, failure), (_) {});
  }

  Future<void> _onRuleDeleted(
    RuleDeleted event,
    Emitter<RecurringState> emit,
  ) async {
    final result = await _deleteRule(event.id);
    result.fold((failure) => _emitFailure(emit, failure), (_) {});
  }

  void _emitFailure(Emitter<RecurringState> emit, Failure failure) {
    final current = state;
    if (current is RecurringLoaded) {
      emit(current.copyWith(isSaving: false, errorMessage: failure.message));
    } else {
      emit(RecurringError(failure.message));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

sealed class RecurringEvent extends Equatable {
  const RecurringEvent();
}

final class RecurringStarted extends RecurringEvent {
  const RecurringStarted();

  @override
  List<Object?> get props => [];
}

final class RecurringRetryRequested extends RecurringEvent {
  const RecurringRetryRequested();

  @override
  List<Object?> get props => [];
}

final class RuleSaveRequested extends RecurringEvent {
  const RuleSaveRequested(this.draft);

  final RecurringRuleDraft draft;

  @override
  List<Object?> get props => [draft];
}

final class RuleToggled extends RecurringEvent {
  const RuleToggled({required this.id, required this.isActive});

  final int id;
  final bool isActive;

  @override
  List<Object?> get props => [id, isActive];
}

final class RuleDeleted extends RecurringEvent {
  const RuleDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

final class _RulesReceived extends RecurringEvent {
  const _RulesReceived(this.rules);

  final List<RecurringRuleEntity> rules;

  @override
  List<Object?> get props => [rules];
}

final class _RulesWatchFailed extends RecurringEvent {
  const _RulesWatchFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class RecurringState extends Equatable {
  const RecurringState();
}

final class RecurringLoading extends RecurringState {
  const RecurringLoading();

  @override
  List<Object?> get props => [];
}

final class RecurringLoaded extends RecurringState {
  const RecurringLoaded(
    this.rules, {
    this.isSaving = false,
    this.saveRevision = 0,
    this.errorMessage,
  });

  final List<RecurringRuleEntity> rules;
  final bool isSaving;
  final int saveRevision;
  final String? errorMessage;

  RecurringLoaded copyWith({
    bool? isSaving,
    int? saveRevision,
    String? errorMessage,
    bool clearError = false,
  }) => RecurringLoaded(
    rules,
    isSaving: isSaving ?? this.isSaving,
    saveRevision: saveRevision ?? this.saveRevision,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [rules, isSaving, saveRevision, errorMessage];
}

final class RecurringError extends RecurringState {
  const RecurringError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
