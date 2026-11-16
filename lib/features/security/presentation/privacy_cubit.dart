import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/database/daos/wallet_dao.dart';

@singleton
class PrivacyCubit extends Cubit<bool> {
  PrivacyCubit(this._walletDao) : super(false) {
    _loadState();
  }

  final WalletDao _walletDao;
  static const String _prefKey = 'privacy_mode_enabled';

  Future<void> _loadState() async {
    final val = await _walletDao.getSetting(_prefKey);
    if (val != null) {
      emit(val == 'true');
    }
  }

  Future<void> toggle() async {
    final newState = !state;
    emit(newState);
    await _walletDao.setSetting(_prefKey, newState.toString());
  }

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    emit(enabled);
    await _walletDao.setSetting(_prefKey, enabled.toString());
  }
}
