import 'package:flutter/material.dart';

/// Mapping of icon keys to IconData for categories
class CategoryIcons {
  static const Map<String, IconData> _legacyIconMap = {
    'salary': Icons.work_rounded,
    'bonus': Icons.star_rounded,
    'freelance': Icons.business_center_rounded,
    'gift': Icons.card_giftcard_rounded,
    'refund': Icons.request_quote_rounded,
    'other': Icons.more_horiz_rounded,
    'transport': Icons.directions_bus_rounded,
    'food_drinks': Icons.restaurant_rounded,
    'groceries': Icons.local_grocery_store_rounded,
    'bills_utilities': Icons.receipt_long_rounded,
    'rent': Icons.home_rounded,
    'health': Icons.medical_services_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'entertainment': Icons.movie_rounded,
    'education': Icons.school_rounded,
    'subscriptions': Icons.credit_card_rounded,
    'custom': Icons.category_rounded,
  };

  static const Map<String, IconData> _iconMap = {
    // Food & Dining
    'restaurant': Icons.restaurant_rounded,
    'coffee': Icons.coffee_rounded,
    'fast_food': Icons.fastfood_rounded,
    'grocery': Icons.local_grocery_store_rounded,
    'cake': Icons.cake_rounded,
    'local_bar': Icons.local_bar_rounded,
    'liquor': Icons.liquor_rounded,

    // Shopping
    'shopping_bag': Icons.shopping_bag_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'store': Icons.store_rounded,
    'mall': Icons.store_rounded,
    'point_of_sale': Icons.point_of_sale_rounded,
    'attach_money': Icons.attach_money_rounded,

    // Transportation
    'directions_car': Icons.directions_car_rounded,
    'directions_bus': Icons.directions_bus_rounded,
    'train': Icons.train_rounded,
    'flight': Icons.flight_rounded,
    'two_wheeler': Icons.two_wheeler_rounded,
    'electric_scooter': Icons.electric_scooter_rounded,
    'local_shipping': Icons.local_shipping_rounded,
    'local_taxi': Icons.local_taxi_rounded,

    // Entertainment
    'movie': Icons.movie_rounded,
    'music_note': Icons.music_note_rounded,
    'theater_comedy': Icons.theater_comedy_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'gamepad': Icons.gamepad_rounded,
    'casino': Icons.casino_rounded,
    'festival': Icons.festival_rounded,

    // Home & Utilities
    'home': Icons.home_rounded,
    'apartment': Icons.apartment_rounded,
    'cottage': Icons.cottage_rounded,
    'vacation': Icons.villa_rounded,
    'bolt': Icons.bolt_rounded,
    'water_drop': Icons.water_drop_rounded,
    'gas_meter': Icons.gas_meter_rounded,
    'wifi': Icons.wifi_rounded,
    'build': Icons.build_rounded,
    'plumbing': Icons.plumbing_rounded,

    // Health & Wellness
    'medical_services': Icons.medical_services_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'pharmacy': Icons.local_pharmacy_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'spa': Icons.spa_rounded,
    'psychology': Icons.psychology_rounded,
    'self_improvement': Icons.self_improvement_rounded,

    // Education
    'school': Icons.school_rounded,
    'menu_book': Icons.menu_book_rounded,
    'cast_for_education': Icons.cast_for_education_rounded,
    'work': Icons.work_rounded,
    'badge': Icons.badge_rounded,
    'laptop': Icons.laptop_rounded,
    'devices': Icons.devices_rounded,

    // Personal Care
    'face': Icons.face_rounded,
    'face_retouching_natural': Icons.face_retouching_natural_rounded,
    'dry_cleaning': Icons.dry_cleaning_rounded,
    'cleaning_services': Icons.cleaning_services_rounded,
    'laundry': Icons.local_laundry_service_rounded,
    'watch': Icons.watch_rounded,
    'jewelry': Icons.diamond_rounded,

    // Finance & Bills
    'account_balance': Icons.account_balance_rounded,
    'credit_card': Icons.credit_card_rounded,
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'request_quote': Icons.request_quote_rounded,
    'insurance': Icons.verified_user_rounded,
    'real_estate_agent': Icons.real_estate_agent_rounded,

    // Communication
    'phone': Icons.phone_rounded,
    'email': Icons.email_rounded,
    'chat': Icons.chat_rounded,
    'language': Icons.language_rounded,
    'public': Icons.public_rounded,
    'cell_tower': Icons.cell_tower_rounded,

    // Gifts & Charity
    'card_giftcard': Icons.card_giftcard_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,
    'favorite': Icons.favorite_rounded,
    'celebration': Icons.celebration_rounded,
    'redeem': Icons.redeem_rounded,

    // Income
    'savings': Icons.savings_rounded,
    'trending_up': Icons.trending_up_rounded,
    'payments': Icons.payments_rounded,
    'monetization_on': Icons.monetization_on_rounded,
    'business_center': Icons.business_center_rounded,

    // Other
    'more_horiz': Icons.more_horiz_rounded,
    'category': Icons.category_rounded,
    'sell': Icons.sell_rounded,
    'label': Icons.label_rounded,
    'bookmark': Icons.bookmark_rounded,
    'star': Icons.star_rounded,
  };

  /// Get IconData for a given icon key
  static IconData getIcon(String iconKey) {
    return _iconMap[iconKey] ??
        _legacyIconMap[iconKey] ??
        Icons.category_rounded;
  }

  static String selectableKeyFor(String iconKey) {
    if (_iconMap.containsKey(iconKey)) return iconKey;
    final icon = _legacyIconMap[iconKey];
    if (icon == null) return 'category';
    for (final entry in _iconMap.entries) {
      if (entry.value == icon) return entry.key;
    }
    return 'category';
  }

  /// Get all available icon keys
  static List<String> get availableIconKeys => _iconMap.keys.toList();

  /// Get all available icons for display
  static List<IconData> get availableIcons => _iconMap.values.toList();
}
