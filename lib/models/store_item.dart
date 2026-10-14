import 'dart:convert';

class StoreRewards {
  final int coins;
  final int energy;
  final int jokers;
  final bool removeAds;
  final bool isVip;

  const StoreRewards({
    this.coins = 0,
    this.energy = 0,
    this.jokers = 0,
    this.removeAds = false,
    this.isVip = false,
  });

  factory StoreRewards.fromJson(dynamic json) {
    if (json == null) return const StoreRewards();
    Map<String, dynamic> map = {};
    if (json is String) {
      try {
        map = jsonDecode(json);
      } catch (_) {}
    } else if (json is Map) {
      map = Map<String, dynamic>.from(json);
    }
    return StoreRewards(
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      energy: (map['energy'] as num?)?.toInt() ?? 0,
      jokers: (map['jokers'] as num?)?.toInt() ?? 0,
      removeAds: map['remove_ads'] == true,
      isVip: map['is_vip'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'energy': energy,
    'jokers': jokers,
    'remove_ads': removeAds,
    'is_vip': isVip,
  };
}

class StoreItem {
  final String id;
  final String type; // 'in_app' or 'in_game'
  final String title;
  final String subtitle;
  final String priceLabel;
  final int coinsCost;
  final String badgeLabel;
  final String badgeColor;
  final String icon;
  final int displayOrder;
  final bool isActive;
  final StoreRewards rewards;

  const StoreItem({
    required this.id,
    this.type = 'in_app',
    required this.title,
    this.subtitle = '',
    required this.priceLabel,
    this.coinsCost = 0,
    this.badgeLabel = '',
    this.badgeColor = '',
    this.icon = '🛍️',
    this.displayOrder = 0,
    this.isActive = true,
    this.rewards = const StoreRewards(),
  });

  bool get isInGame => type == 'in_game';
  bool get isInApp => type == 'in_app';

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    return StoreItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'in_app',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      priceLabel: json['price_label'] as String? ?? '',
      coinsCost: (json['coins_cost'] as num?)?.toInt() ?? 0,
      badgeLabel: json['badge_label'] as String? ?? '',
      badgeColor: json['badge_color'] as String? ?? '',
      icon: json['icon'] as String? ?? '🛍️',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] == null || json['is_active'] == 1 || json['is_active'] == true,
      rewards: StoreRewards.fromJson(json['rewards_json'] ?? json['rewards']),
    );
  }

  // Varsayılan Sabit Paketler (Offline veya ilk açılış için)
  static List<StoreItem> get defaultItems => [
    const StoreItem(
      id: 'vip_club',
      type: 'in_app',
      title: 'Altın Plak VIP Kulübü',
      subtitle: 'Ömür boyu reklamsız + Sınırsız enerji + 10 Joker + VIP profil rozeti',
      priceLabel: '₺99,99',
      badgeLabel: '👑 VIP',
      badgeColor: '#F59E0B',
      icon: '👑',
      displayOrder: 1,
      rewards: StoreRewards(energy: 9999, jokers: 10, removeAds: true, isVip: true),
    ),
    const StoreItem(
      id: 'remove_ads',
      type: 'in_app',
      title: 'Reklamları Kaldır',
      subtitle: 'Ömür boyu tüm geçiş ve banner reklamları kalkar',
      priceLabel: '₺49,99',
      badgeLabel: '🛡️ TEMİZ OYUN',
      badgeColor: '#10B981',
      icon: '🛡️',
      displayOrder: 2,
      rewards: StoreRewards(removeAds: true),
    ),
    const StoreItem(
      id: 'coins_500',
      type: 'in_app',
      title: '500 Altın Çantası',
      subtitle: 'Eksik plak parçalarını hemen tamamla',
      priceLabel: '₺19,99',
      icon: '🪙',
      displayOrder: 3,
      rewards: StoreRewards(coins: 500),
    ),
    const StoreItem(
      id: 'coins_1500',
      type: 'in_app',
      title: '1.500 Altın Sandığı',
      subtitle: '🎁 +100 Altın Bonus Hediye',
      priceLabel: '₺49,99',
      badgeLabel: '🔥 POPÜLER',
      badgeColor: '#F59E0B',
      icon: '💰',
      displayOrder: 4,
      rewards: StoreRewards(coins: 1500),
    ),
    const StoreItem(
      id: 'coins_4000',
      type: 'in_app',
      title: '4.000 Altın Kasası',
      subtitle: '🎁 +500 Altın Bonus Hediye',
      priceLabel: '₺99,99',
      badgeLabel: '💎 AVANTAJLI',
      badgeColor: '#3B82F6',
      icon: '🏦',
      displayOrder: 5,
      rewards: StoreRewards(coins: 4000),
    ),
    const StoreItem(
      id: 'coins_10000',
      type: 'in_app',
      title: '10.000 Altın Hazinesi',
      subtitle: '👑 Efsane Plak Sandığı (Tüm Sanatçılar)',
      priceLabel: '₺199,99',
      badgeLabel: '👑 MEGA',
      badgeColor: '#8B5CF6',
      icon: '👑',
      displayOrder: 6,
      rewards: StoreRewards(coins: 10000),
    ),
    const StoreItem(
      id: 'energy_10',
      type: 'in_app',
      title: '10 Enerji',
      subtitle: 'Hemen düelloya kesintisiz devam et',
      priceLabel: '₺9,99',
      icon: '⚡',
      displayOrder: 7,
      rewards: StoreRewards(energy: 10),
    ),
    const StoreItem(
      id: 'energy_25',
      type: 'in_app',
      title: '25 Enerji + 2 Joker',
      subtitle: '🎁 2 adet %50 jokeri hediye',
      priceLabel: '₺29,99',
      badgeLabel: 'FIRSAT',
      badgeColor: '#10B981',
      icon: '⚡',
      displayOrder: 8,
      rewards: StoreRewards(energy: 25, jokers: 2),
    ),
    const StoreItem(
      id: 'energy_60',
      type: 'in_app',
      title: '60 Enerji + 5 Joker',
      subtitle: '🎁 5 adet %50 jokeri hediye',
      priceLabel: '₺49,99',
      badgeLabel: 'POPÜLER',
      badgeColor: '#F59E0B',
      icon: '⚡',
      displayOrder: 9,
      rewards: StoreRewards(energy: 60, jokers: 5),
    ),
    const StoreItem(
      id: 'energy_150',
      type: 'in_app',
      title: '150 Enerji + 15 Joker',
      subtitle: '👑 Maraton Paketi (15 adet %50 jokeri)',
      priceLabel: '₺99,99',
      badgeLabel: 'DEV PAKET',
      badgeColor: '#EC4899',
      icon: '⚡',
      displayOrder: 10,
      rewards: StoreRewards(energy: 150, jokers: 15),
    ),
    const StoreItem(
      id: 'gold_joker_1',
      type: 'in_game',
      title: '1 Adet %50 Jokeri',
      subtitle: '100 Altın karşılığı 1 joker kazan',
      priceLabel: '100 Altın',
      coinsCost: 100,
      badgeLabel: '%50 JOKER',
      badgeColor: '#F59E0B',
      icon: '🎯',
      displayOrder: 11,
      rewards: StoreRewards(jokers: 1),
    ),
    const StoreItem(
      id: 'gold_joker_3',
      type: 'in_game',
      title: '3 Adet %50 Jokeri',
      subtitle: '250 Altın karşılığı 3 joker kazan (50 Altın Tasarruf!)',
      priceLabel: '250 Altın',
      coinsCost: 250,
      badgeLabel: 'AVANTAJLI',
      badgeColor: '#10B981',
      icon: '🎯',
      displayOrder: 12,
      rewards: StoreRewards(jokers: 3),
    ),
    const StoreItem(
      id: 'gold_joker_10',
      type: 'in_game',
      title: '10 Adet %50 Jokeri',
      subtitle: '750 Altın karşılığı 10 joker kazan (250 Altın Tasarruf!)',
      priceLabel: '750 Altın',
      coinsCost: 750,
      badgeLabel: 'EN POPÜLER',
      badgeColor: '#EC4899',
      icon: '🎯',
      displayOrder: 13,
      rewards: StoreRewards(jokers: 10),
    ),
  ];
}
