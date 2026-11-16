import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/database/daos/wallet_dao.dart';
import '../domain/security_settings.dart';

class SecurityState extends Equatable {
  const SecurityState({
    required this.isBiometricEnabled,
    required this.timeout,
    required this.isLocked,
    required this.canCheckBiometrics,
  });

  final bool isBiometricEnabled;
  final AutoLockTimeout timeout;
  final bool isLocked;
  final bool canCheckBiometrics;

  SecurityState copyWith({
    bool? isBiometricEnabled,
    AutoLockTimeout? timeout,
    bool? isLocked,
    bool? canCheckBiometrics,
  }) {
    return SecurityState(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      timeout: timeout ?? this.timeout,
      isLocked: isLocked ?? this.isLocked,
      canCheckBiometrics: canCheckBiometrics ?? this.canCheckBiometrics,
    );
  }

  @override
  List<Object?> get props => [isBiometricEnabled, timeout, isLocked, canCheckBiometrics];
}

@singleton
class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit(this._walletDao)
      : super(const SecurityState(
          isBiometricEnabled: false,
          timeout: AutoLockTimeout.immediately,
          isLocked: false,
          canCheckBiometrics: false,
        )) {
    _init();
  }

  final WalletDao _walletDao;
  final LocalAuthentication _auth = LocalAuthentication();

  static const String _keyBiometricEnabled = 'security_biometric_enabled';
  static const String _keyTimeoutSeconds = 'security_timeout_seconds';

  DateTime? _pausedAt;

  Future<void> _init() async {
    final canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();

    final enabledStr = await _walletDao.getSetting(_keyBiometricEnabled);
    final timeoutStr = await _walletDao.getSetting(_keyTimeoutSeconds);

    final isEnabled = enabledStr == 'true' && canCheck;
    final timeout = AutoLockTimeout.fromSeconds(int.tryParse(timeoutStr ?? '0'));

    emit(state.copyWith(
      canCheckBiometrics: canCheck,
      isBiometricEnabled: isEnabled,
      timeout: timeout,
      isLocked: isEnabled,
    ));

    if (isEnabled) {
      authenticate();
    }
  }

  Future<bool> authenticate() async {
    if (!state.isBiometricEnabled) {
      emit(state.copyWith(isLocked: false));
      return true;
    }

    try {
      final success = await _auth.authenticate(
        localizedReason: 'Authenticate to access Budget Tracker',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (success) {
        emit(state.copyWith(isLocked: false));
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  void onAppPaused() {
    if (!state.isBiometricEnabled) return;
    _pausedAt = DateTime.now();
  }

  void onAppResumed() {
    if (!state.isBiometricEnabled || state.isLocked) return;

    if (_pausedAt != null) {
      final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
      if (elapsed >= state.timeout.seconds) {
        emit(state.copyWith(isLocked: true));
        authenticate();
      }
      _pausedAt = null;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      final authenticated = await authenticate();
      if (!authenticated) return;
    }

    emit(state.copyWith(isBiometricEnabled: enabled, isLocked: false));
    await _walletDao.setSetting(_keyBiometricEnabled, enabled.toString());
  }

  Future<void> setTimeout(AutoLockTimeout timeout) async {
    emit(state.copyWith(timeout: timeout));
    await _walletDao.setSetting(_keyTimeoutSeconds, timeout.seconds.toString());
  }

  void lockManually() {
    if (state.isBiometricEnabled) {
      emit(state.copyWith(isLocked: true));
    }
  }
}
