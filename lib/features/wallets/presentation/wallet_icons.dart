// lib/features/wallets/presentation/wallet_icons.dart

import 'package:flutter/material.dart';

class WalletIconSpec {
  const WalletIconSpec(this.icon, this.color, this.label);

  final IconData icon;
  final Color color;
  final String label;
}

abstract final class WalletIcons {
  static const defaultKey = 'wallet';

  static const _specs = <String, WalletIconSpec>{
    // Existing keys (kept so saved wallets still work)
    'wallet': WalletIconSpec(
      Icons.account_balance_wallet_rounded,
      Color(0xFF10B981),
      'Wallet',
    ),
    'bank': WalletIconSpec(
      Icons.account_balance_rounded,
      Color(0xFF3B82F6),
      'Bank',
    ),
    'smartphone': WalletIconSpec(
      Icons.smartphone_rounded,
      Color(0xFF8B5CF6),
      'Mobile',
    ),
    'credit_card': WalletIconSpec(
      Icons.credit_card_rounded,
      Color(0xFFF59E0B),
      'Card',
    ),
    'savings': WalletIconSpec(
      Icons.savings_rounded,
      Color(0xFFEC4899),
      'Savings',
    ),
    'cash': WalletIconSpec(Icons.payments_rounded, Color(0xFF22C55E), 'Cash'),
    'vault': WalletIconSpec(Icons.lock_rounded, Color(0xFF64748B), 'Vault'),
    'briefcase': WalletIconSpec(
      Icons.work_rounded,
      Color(0xFFB45309),
      'Business',
    ),
    // New keys
    'coins': WalletIconSpec(Icons.toll_rounded, Color(0xFFEAB308), 'Coins'),
    'investments': WalletIconSpec(
      Icons.trending_up_rounded,
      Color(0xFF14B8A6),
      'Invest',
    ),
    'crypto': WalletIconSpec(
      Icons.currency_bitcoin_rounded,
      Color(0xFFF97316),
      'Crypto',
    ),
    'home': WalletIconSpec(Icons.home_rounded, Color(0xFF6366F1), 'Home'),
    'travel': WalletIconSpec(
      Icons.flight_takeoff_rounded,
      Color(0xFF0EA5E9),
      'Travel',
    ),
    'shopping': WalletIconSpec(
      Icons.shopping_bag_rounded,
      Color(0xFFD946EF),
      'Shopping',
    ),
    'emergency': WalletIconSpec(
      Icons.health_and_safety_rounded,
      Color(0xFFEF4444),
      'Emergency',
    ),
    'family': WalletIconSpec(
      Icons.family_restroom_rounded,
      Color(0xFF06B6D4),
      'Family',
    ),
  };

  static List<String> get keys => _specs.keys.toList(growable: false);

  static WalletIconSpec spec(String? key) => _specs[key] ?? _specs[defaultKey]!;

  static IconData icon(String? key) => spec(key).icon;
  static Color color(String? key) => spec(key).color;
  static String label(String? key) => spec(key).label;

  static String normalize(String? key) =>
      _specs.containsKey(key) ? key! : defaultKey;
}
