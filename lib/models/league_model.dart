import 'package:flutter/material.dart';

enum LeagueTier {
  bronze,
  silver,
  gold,
  diamond,
  legends;

  String get displayName {
    switch (this) {
      case LeagueTier.bronze:
        return 'Bronz Ligi';
      case LeagueTier.silver:
        return 'Gümüş Ligi';
      case LeagueTier.gold:
        return 'Altın Ligi';
      case LeagueTier.diamond:
        return 'Elmas Ligi';
      case LeagueTier.legends:
        return 'Efsaneler Ligi';
    }
  }

  String get icon {
    switch (this) {
      case LeagueTier.bronze:
        return '🥉';
      case LeagueTier.silver:
        return '🥈';
      case LeagueTier.gold:
        return '🥇';
      case LeagueTier.diamond:
        return '💎';
      case LeagueTier.legends:
        return '👑';
    }
  }

  Color get primaryColor {
    switch (this) {
      case LeagueTier.bronze:
        return const Color(0xFFCD7F32);
      case LeagueTier.silver:
        return const Color(0xFFE2E8F0);
      case LeagueTier.gold:
        return const Color(0xFFF59E0B);
      case LeagueTier.diamond:
        return const Color(0xFF38BDF8);
      case LeagueTier.legends:
        return const Color(0xFFA855F7);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case LeagueTier.bronze:
        return [const Color(0xFF8C5320), const Color(0xFFCD7F32)];
      case LeagueTier.silver:
        return [const Color(0xFF64748B), const Color(0xFFCBD5E1)];
      case LeagueTier.gold:
        return [const Color(0xFFD97706), const Color(0xFFFBBF24)];
      case LeagueTier.diamond:
        return [const Color(0xFF0284C7), const Color(0xFF38BDF8)];
      case LeagueTier.legends:
        return [const Color(0xFF7E22CE), const Color(0xFFC084FC)];
    }
  }

  int get minTrophies {
    switch (this) {
      case LeagueTier.bronze:
        return 0;
      case LeagueTier.silver:
        return 300;
      case LeagueTier.gold:
        return 800;
      case LeagueTier.diamond:
        return 1600;
      case LeagueTier.legends:
        return 2800;
    }
  }

  Map<String, dynamic> get weeklyRewards {
    switch (this) {
      case LeagueTier.bronze:
        return {'coins': 250, 'xp': 200, 'shards': 1};
      case LeagueTier.silver:
        return {'coins': 500, 'xp': 400, 'shards': 2};
      case LeagueTier.gold:
        return {'coins': 1000, 'xp': 800, 'shards': 4};
      case LeagueTier.diamond:
        return {'coins': 2000, 'xp': 1500, 'shards': 8};
      case LeagueTier.legends:
        return {'coins': 5000, 'xp': 3000, 'shards': 15};
    }
  }

  static LeagueTier fromString(String? val) {
    if (val == null) return LeagueTier.bronze;
    return LeagueTier.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => LeagueTier.bronze,
    );
  }
}

enum LeagueTrend {
  promotion,
  safe,
  demotion;
}

class LeaguePlayer {
  final String id;
  final String name;
  final String avatar;
  final int trophies;
  int rank;
  final bool isCurrentUser;
  final String badgeTitle;
  LeagueTrend trend;

  LeaguePlayer({
    required this.id,
    required this.name,
    required this.avatar,
    required this.trophies,
    required this.rank,
    this.isCurrentUser = false,
    this.badgeTitle = '',
    this.trend = LeagueTrend.safe,
  });

  factory LeaguePlayer.fromJson(Map<String, dynamic> json, {String currentUserId = ''}) {
    final id = json['id']?.toString() ?? '';
    final trendStr = json['trend']?.toString() ?? 'safe';
    LeagueTrend trend = LeagueTrend.safe;
    if (trendStr == 'promotion') trend = LeagueTrend.promotion;
    if (trendStr == 'demotion') trend = LeagueTrend.demotion;

    return LeaguePlayer(
      id: id,
      name: json['name']?.toString() ?? 'Oyuncu',
      avatar: json['avatar']?.toString() ?? '🎧',
      trophies: (json['trophies'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      isCurrentUser: id == currentUserId || (json['isCurrentUser'] == true),
      badgeTitle: json['badgeTitle']?.toString() ?? '',
      trend: trend,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'trophies': trophies,
    'rank': rank,
    'isCurrentUser': isCurrentUser,
    'badgeTitle': badgeTitle,
    'trend': trend.name,
  };
}

class LeagueGroupData {
  final LeagueTier tier;
  final int weekNumber;
  final DateTime endsAt;
  final List<LeaguePlayer> players;
  final int currentUserTrophies;
  final int currentUserRank;
  final int promotionCutoff;
  final int demotionCutoff;
  final bool isDemotionEnabled;
  final Map<String, dynamic>? tierRewards;

  LeagueGroupData({
    required this.tier,
    required this.weekNumber,
    required this.endsAt,
    required this.players,
    required this.currentUserTrophies,
    required this.currentUserRank,
    this.promotionCutoff = 5,
    this.demotionCutoff = 21,
    this.isDemotionEnabled = true,
    this.tierRewards,
  });

  Map<String, dynamic> getRewardsForTier(LeagueTier t) {
    if (tierRewards != null && tierRewards!.containsKey(t.name)) {
      final map = tierRewards![t.name];
      if (map is Map) {
        return {
          'coins': (map['coinsReward'] ?? map['coins'] ?? 100) as int,
          'xp': (map['xpReward'] ?? map['xp'] ?? 100) as int,
          'shards': (map['jokerShardsReward'] ?? map['shards'] ?? 1) as int,
        };
      }
    }
    return t.weeklyRewards;
  }

  Duration get timeRemaining {
    final diff = endsAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get formattedTimeRemaining {
    final dur = timeRemaining;
    if (dur.isNegative || dur.inSeconds == 0) return 'Sezon Bitti';
    final days = dur.inDays;
    final hours = dur.inHours % 24;
    final minutes = dur.inMinutes % 60;
    if (days > 0) return '$days gün $hours sa';
    return '$hours sa $minutes dk';
  }

  factory LeagueGroupData.fromJson(Map<String, dynamic> json, {String currentUserId = ''}) {
    final tier = LeagueTier.fromString(json['tier']?.toString());
    final rawPlayers = (json['players'] as List<dynamic>?) ?? [];
    final players = rawPlayers
        .map((p) => LeaguePlayer.fromJson(p as Map<String, dynamic>, currentUserId: currentUserId))
        .toList();

    final isDemotionEnabled = json['isDemotionEnabled'] != false;
    final promotionCutoff = (json['promotionCutoff'] as num?)?.toInt() ?? 5;
    final demotionCutoff = (json['demotionCutoff'] as num?)?.toInt() ?? 21;
    final tierRewards = json['tierRewards'] as Map<String, dynamic>?;

    // Sort players by trophies descending
    players.sort((a, b) => b.trophies.compareTo(a.trophies));
    for (int i = 0; i < players.length; i++) {
      players[i].rank = i + 1;
      if (players[i].rank <= promotionCutoff) {
        players[i].trend = LeagueTrend.promotion;
      } else if (isDemotionEnabled && players[i].rank >= demotionCutoff && tier != LeagueTier.bronze) {
        players[i].trend = LeagueTrend.demotion;
      } else {
        players[i].trend = LeagueTrend.safe;
      }
    }

    final curUser = players.firstWhere(
      (p) => p.isCurrentUser || p.id == currentUserId,
      orElse: () => LeaguePlayer(
        id: currentUserId,
        name: 'Ben',
        avatar: '🎧',
        trophies: (json['currentUserTrophies'] as num?)?.toInt() ?? 0,
        rank: (json['currentUserRank'] as num?)?.toInt() ?? players.length,
        isCurrentUser: true,
      ),
    );

    DateTime endsAt;
    try {
      endsAt = DateTime.parse(json['endsAt']?.toString() ?? '');
    } catch (_) {
      // Default to next Sunday midnight UTC+3
      final now = DateTime.now();
      final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
      final nextSunday = DateTime(now.year, now.month, now.day + (daysUntilSunday == 0 ? 7 : daysUntilSunday), 23, 59, 59);
      endsAt = nextSunday;
    }

    return LeagueGroupData(
      tier: tier,
      weekNumber: (json['weekNumber'] as num?)?.toInt() ?? 1,
      endsAt: endsAt,
      players: players,
      currentUserTrophies: curUser.trophies,
      currentUserRank: curUser.rank,
      promotionCutoff: promotionCutoff,
      demotionCutoff: demotionCutoff,
      isDemotionEnabled: isDemotionEnabled,
      tierRewards: tierRewards,
    );
  }
}
