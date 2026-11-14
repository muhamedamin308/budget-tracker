import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../database/daos/wallet_dao.dart';

@singleton
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._walletDao) : super(ThemeMode.system) {
    _loadTheme();
  }

  final WalletDao _walletDao;

  static const String _themeKey = 'app_theme_mode';

  Future<void> _loadTheme() async {
    final val = await _walletDao.getSetting(_themeKey);
    if (val != null) {
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == val,
        orElse: () => ThemeMode.system,
      );
      emit(mode);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await _walletDao.setSetting(_themeKey, mode.name);
  }
}
