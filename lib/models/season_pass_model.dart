enum RewardType { coins, energy, joker, shard, endlessChest }

class PassReward {
  final RewardType type;
  final int amount;
  final String title;
  final String icon;

  const PassReward({
    required this.type,
    required this.amount,
    required this.title,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'amount': amount,
    'title': title,
    'icon': icon,
  };

  factory PassReward.fromJson(Map<String, dynamic> json) {
    return PassReward(
      type: RewardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RewardType.coins,
      ),
      amount: json['amount'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      icon: json['icon'] as String? ?? '🎁',
    );
  }
}

class SeasonPassTier {
  final int level;
  final int requiredXp;
  final PassReward freeReward;
  final PassReward goldReward;
  bool isFreeClaimed;
  bool isGoldClaimed;

  SeasonPassTier({
    required this.level,
    required this.requiredXp,
    required this.freeReward,
    required this.goldReward,
    this.isFreeClaimed = false,
    this.isGoldClaimed = false,
  });

  Map<String, dynamic> toJson() => {
    'level': level,
    'requiredXp': requiredXp,
    'freeReward': freeReward.toJson(),
    'goldReward': goldReward.toJson(),
    'isFreeClaimed': isFreeClaimed,
    'isGoldClaimed': isGoldClaimed,
  };

  factory SeasonPassTier.fromJson(Map<String, dynamic> json) {
    return SeasonPassTier(
      level: json['level'] as int? ?? 1,
      requiredXp: json['requiredXp'] as int? ?? 250,
      freeReward: PassReward.fromJson(json['freeReward'] as Map<String, dynamic>),
      goldReward: PassReward.fromJson(json['goldReward'] as Map<String, dynamic>),
      isFreeClaimed: json['isFreeClaimed'] as bool? ?? false,
      isGoldClaimed: json['isGoldClaimed'] as bool? ?? false,
    );
  }
}

enum MissionCategory { daily, weekly, seasonal }

class SeasonMission {
  final String id;
  final String title;
  final String description;
  final MissionCategory category;
  final String actionKey; // 'complete_match', 'win_match', 'fast_answer', 'category_win'
  final String? filterCategory; // 'rock', 'pop_90s' etc.
  final int target;
  int current;
  final int xpReward;
  final int coinReward;
  bool isClaimed;
  final String icon;

  SeasonMission({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.actionKey,
    this.filterCategory,
    required this.target,
    this.current = 0,
    required this.xpReward,
    this.coinReward = 0,
    this.isClaimed = false,
    required this.icon,
  });

  bool get isCompleted => current >= target;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'actionKey': actionKey,
    'filterCategory': filterCategory,
    'target': target,
    'current': current,
    'xpReward': xpReward,
    'coinReward': coinReward,
    'isClaimed': isClaimed,
    'icon': icon,
  };

  factory SeasonMission.fromJson(Map<String, dynamic> json) {
    return SeasonMission(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: MissionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => MissionCategory.daily,
      ),
      actionKey: json['actionKey'] as String? ?? 'complete_match',
      filterCategory: json['filterCategory'] as String?,
      target: json['target'] as int? ?? 1,
      current: json['current'] as int? ?? 0,
      xpReward: json['xpReward'] as int? ?? 100,
      coinReward: json['coinReward'] as int? ?? 0,
      isClaimed: json['isClaimed'] as bool? ?? false,
      icon: json['icon'] as String? ?? '🎯',
    );
  }
}

class SeasonPassData {
  final String seasonId;
  final String seasonName;
  final DateTime endDate;
  int currentXp;
  bool isGoldUnlocked;
  int endlessChestClaimCount;
  List<SeasonPassTier> tiers;
  List<SeasonMission> missions;

  static const int xpPerTier = 250;
  static const int maxTier = 20;
  static const int endlessChestXp = 500;

  SeasonPassData({
    required this.seasonId,
    required this.seasonName,
    required this.endDate,
    this.currentXp = 0,
    this.isGoldUnlocked = false,
    this.endlessChestClaimCount = 0,
    required this.tiers,
    required this.missions,
  });

  /// Kullanıcının mevcut ana seviyesi (1 - 20)
  int get currentLevel {
    final level = (currentXp ~/ xpPerTier) + 1;
    return level > maxTier ? maxTier : level;
  }

  /// 20. seviye bittikten sonraki Sonsuz Sandık seviyesi
  int get endlessLevel {
    if (currentXp <= maxTier * xpPerTier) return 0;
    final extraXp = currentXp - (maxTier * xpPerTier);
    return extraXp ~/ endlessChestXp;
  }

  /// Mevcut seviyedeki ilerleme yüzdesi (0.0 - 1.0)
  double get currentLevelProgress {
    if (currentLevel >= maxTier) {
      if (endlessLevel > 0) {
        final extraXp = (currentXp - (maxTier * xpPerTier)) % endlessChestXp;
        return extraXp / endlessChestXp;
      }
      return 1.0;
    }
    final xpInCurrentTier = currentXp % xpPerTier;
    return xpInCurrentTier / xpPerTier;
  }

  /// Mevcut seviyedeki XP / Gereken XP metni
  String get currentLevelXpText {
    if (currentLevel >= maxTier) {
      final extraXp = (currentXp - (maxTier * xpPerTier)) % endlessChestXp;
      return '$extraXp / $endlessChestXp XP';
    }
    final xpInCurrentTier = currentXp % xpPerTier;
    return '$xpInCurrentTier / $xpPerTier XP';
  }

  /// Toplanabilir ödül var mı?
  int get unclaimedRewardCount {
    int count = 0;
    final lvl = currentLevel;
    for (final t in tiers) {
      if (t.level <= lvl) {
        if (!t.isFreeClaimed) count++;
        if (isGoldUnlocked && !t.isGoldClaimed) count++;
      }
    }
    // Sonsuz sandık hakları
    final totalChestRights = endlessLevel;
    final availableChests = totalChestRights - endlessChestClaimCount;
    if (availableChests > 0) {
      count += availableChests;
    }
    return count;
  }

  /// Tamamlanmış ama toplanmamış görev sayısı
  int get claimableMissionCount {
    return missions.where((m) => m.isCompleted && !m.isClaimed).length;
  }

  Map<String, dynamic> toJson() => {
    'seasonId': seasonId,
    'seasonName': seasonName,
    'endDate': endDate.toIso8601String(),
    'currentXp': currentXp,
    'isGoldUnlocked': isGoldUnlocked,
    'endlessChestClaimCount': endlessChestClaimCount,
    'tiers': tiers.map((t) => t.toJson()).toList(),
    'missions': missions.map((m) => m.toJson()).toList(),
  };

  factory SeasonPassData.fromJson(Map<String, dynamic> json) {
    return SeasonPassData(
      seasonId: json['seasonId'] as String? ?? 'season_1',
      seasonName: json['seasonName'] as String? ?? "Sezon 1: 90'lar Fırtınası",
      endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 28)),
      currentXp: json['currentXp'] as int? ?? 0,
      isGoldUnlocked: json['isGoldUnlocked'] as bool? ?? false,
      endlessChestClaimCount: json['endlessChestClaimCount'] as int? ?? 0,
      tiers: (json['tiers'] as List<dynamic>?)
              ?.map((e) => SeasonPassTier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          defaultTiers,
      missions: (json['missions'] as List<dynamic>?)
              ?.map((e) => SeasonMission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          defaultMissions,
    );
  }

  static List<SeasonPassTier> get defaultTiers {
    return List.generate(20, (index) {
      final lvl = index + 1;
      PassReward free;
      PassReward gold;

      if (lvl == 20) {
        free = const PassReward(
          type: RewardType.coins,
          amount: 1000,
          title: '1.000 Altın Çantası',
          icon: '💰',
        );
        gold = const PassReward(
          type: RewardType.shard,
          amount: 50,
          title: 'Efsanevi Plak Tacı & 50 Plak',
          icon: '👑',
        );
      } else if (lvl % 5 == 0) {
        free = PassReward(
          type: RewardType.joker,
          amount: 3,
          title: '3x %50 Joker',
          icon: '🃏',
        );
        gold = PassReward(
          type: RewardType.coins,
          amount: 750,
          title: '750 Altın Sandığı',
          icon: '🏆',
        );
      } else if (lvl % 2 == 0) {
        free = PassReward(
          type: RewardType.energy,
          amount: 5,
          title: '+5 Tam Enerji',
          icon: '⚡',
        );
        gold = PassReward(
          type: RewardType.shard,
          amount: 15,
          title: '15 Plak Parçası',
          icon: '💿',
        );
      } else {
        free = PassReward(
          type: RewardType.coins,
          amount: 150 + (lvl * 10),
          title: '${150 + (lvl * 10)} Altın',
          icon: '🪙',
        );
        gold = PassReward(
          type: RewardType.joker,
          amount: 2,
          title: '2x Joker Paketi',
          icon: '✨',
        );
      }

      return SeasonPassTier(
        level: lvl,
        requiredXp: xpPerTier,
        freeReward: free,
        goldReward: gold,
      );
    });
  }

  static List<SeasonMission> get defaultMissions {
    return [
      // Günlük Görevler
      SeasonMission(
        id: 'daily_matches_3',
        title: 'Sahneye Çık',
        description: '3 müzik düellosu tamamla',
        category: MissionCategory.daily,
        actionKey: 'complete_match',
        target: 3,
        xpReward: 120,
        coinReward: 50,
        icon: '🎤',
      ),
      SeasonMission(
        id: 'daily_win_1',
        title: 'Günün Yıldızı',
        description: 'Herhangi bir kategoride 1 galibiyet al',
        category: MissionCategory.daily,
        actionKey: 'win_match',
        target: 1,
        xpReward: 150,
        coinReward: 75,
        icon: '⭐',
      ),
      SeasonMission(
        id: 'daily_fast_2',
        title: 'Hızlı Refleks',
        description: '2 şarkıyı 3 saniyenin altında doğru bil',
        category: MissionCategory.daily,
        actionKey: 'fast_answer',
        target: 2,
        xpReward: 130,
        coinReward: 40,
        icon: '⚡',
      ),

      // Haftalık Görevler
      SeasonMission(
        id: 'weekly_wins_10',
        title: 'Seri Galip',
        description: 'Hafta boyunca toplam 10 düello kazan',
        category: MissionCategory.weekly,
        actionKey: 'win_match',
        target: 10,
        xpReward: 600,
        coinReward: 250,
        icon: '🔥',
      ),
      SeasonMission(
        id: 'weekly_pop90s_5',
        title: '90’lar Rüzgarı',
        description: "90'lar Pop kategorisinde 5 galibiyet elde et",
        category: MissionCategory.weekly,
        actionKey: 'category_win',
        filterCategory: 'pop_90s',
        target: 5,
        xpReward: 500,
        coinReward: 200,
        icon: '📻',
      ),
      SeasonMission(
        id: 'weekly_matches_20',
        title: 'Müzik Maratonu',
        description: 'Toplam 20 düello tamamla',
        category: MissionCategory.weekly,
        actionKey: 'complete_match',
        target: 20,
        xpReward: 750,
        coinReward: 300,
        icon: '🎧',
      ),

      // Sezonluk Büyük Görevler
      SeasonMission(
        id: 'season_all_categories',
        title: 'Müzik Ansiklopedisi',
        description: 'Tüm farklı kategorilerde en az 3 galibiyet al',
        category: MissionCategory.seasonal,
        actionKey: 'win_match',
        target: 15,
        xpReward: 1800,
        coinReward: 800,
        icon: '🏆',
      ),
      SeasonMission(
        id: 'season_total_50',
        title: 'Sahne Efsanesi',
        description: 'Sezon boyunca 50 düello kazan',
        category: MissionCategory.seasonal,
        actionKey: 'win_match',
        target: 50,
        xpReward: 2500,
        coinReward: 1200,
        icon: '👑',
      ),
    ];
  }
}
