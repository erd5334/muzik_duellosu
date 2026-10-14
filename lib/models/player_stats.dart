import 'dart:convert';

class CategoryStats {
  int matches;
  int wins;
  int draws;
  int losses;
  int correctAnswers;
  Map<String, int> artistCorrectAnswers;

  CategoryStats({
    this.matches = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.correctAnswers = 0,
    Map<String, int>? artistCorrectAnswers,
  }) : artistCorrectAnswers = artistCorrectAnswers ?? {};

  double get winRate => matches > 0 ? (wins / matches) * 100 : 0.0;

  /// Bu kategoride en çok doğru bilinen sanatçılar
  List<MapEntry<String, int>> get topArtists {
    final list = artistCorrectAnswers.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    final artMap = <String, int>{};
    if (json['artistCorrectAnswers'] is Map) {
      final rawArt = json['artistCorrectAnswers'] as Map;
      for (final entry in rawArt.entries) {
        artMap[entry.key.toString()] = (entry.value as num?)?.toInt() ?? 0;
      }
    }

    return CategoryStats(
      matches: (json['matches'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      artistCorrectAnswers: artMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'matches': matches,
    'wins': wins,
    'draws': draws,
    'losses': losses,
    'correctAnswers': correctAnswers,
    'artistCorrectAnswers': artistCorrectAnswers,
  };
}

class PlayerStats {
  int totalMatches;
  int wins;
  int draws;
  int losses;
  int currentStreak;
  int bestStreak;
  int totalScore;
  int totalCorrectAnswers;
  Map<String, CategoryStats> categoryStats;
  Map<String, int> artistCorrectAnswers;

  PlayerStats({
    this.totalMatches = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalScore = 0,
    this.totalCorrectAnswers = 0,
    Map<String, CategoryStats>? categoryStats,
    Map<String, int>? artistCorrectAnswers,
  })  : categoryStats = categoryStats ?? {},
        artistCorrectAnswers = artistCorrectAnswers ?? {};

  double get winRate => totalMatches > 0 ? (wins / totalMatches) * 100 : 0.0;

  /// En çok doğru bilinen sanatçıların sıralı listesi
  List<MapEntry<String, int>> get topArtists {
    final list = artistCorrectAnswers.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  CategoryStats getCategoryStats(String categoryId) {
    return categoryStats.putIfAbsent(categoryId, () => CategoryStats());
  }

  /// Doğru cevap verildiğinde sanatçı ve kategori sayacını artır
  void recordCorrectAnswer({required String artist, required String categoryId}) {
    totalCorrectAnswers++;
    final cleanArtist = artist.trim();
    if (cleanArtist.isNotEmpty && cleanArtist.toLowerCase() != 'bilinmeyen') {
      artistCorrectAnswers[cleanArtist] = (artistCorrectAnswers[cleanArtist] ?? 0) + 1;
    }
    final cStats = getCategoryStats(categoryId);
    cStats.correctAnswers++;
    if (cleanArtist.isNotEmpty && cleanArtist.toLowerCase() != 'bilinmeyen') {
      cStats.artistCorrectAnswers[cleanArtist] = (cStats.artistCorrectAnswers[cleanArtist] ?? 0) + 1;
    }
  }

  /// Maç bittiğinde galibiyet/mağlubiyet sonucunu işle
  void recordMatchResult({
    required String categoryId,
    required bool isWinner,
    required bool isDraw,
    required int matchScore,
  }) {
    totalMatches++;
    totalScore += matchScore;

    final cStats = getCategoryStats(categoryId);
    cStats.matches++;

    if (isWinner) {
      wins++;
      cStats.wins++;
      currentStreak++;
      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
      }
    } else if (isDraw) {
      draws++;
      cStats.draws++;
      // Beraberlikte seri sıfırlanmaz
    } else {
      losses++;
      cStats.losses++;
      currentStreak = 0;
    }
  }

  factory PlayerStats.fromJson(dynamic json) {
    if (json == null) return PlayerStats();
    Map<String, dynamic> map = {};
    if (json is String) {
      try {
        map = jsonDecode(json);
      } catch (_) {}
    } else if (json is Map) {
      map = Map<String, dynamic>.from(json);
    }

    final catMap = <String, CategoryStats>{};
    if (map['categoryStats'] is Map) {
      final rawCat = map['categoryStats'] as Map;
      for (final entry in rawCat.entries) {
        if (entry.value is Map) {
          catMap[entry.key.toString()] = CategoryStats.fromJson(Map<String, dynamic>.from(entry.value as Map));
        }
      }
    }

    final artMap = <String, int>{};
    if (map['artistCorrectAnswers'] is Map) {
      final rawArt = map['artistCorrectAnswers'] as Map;
      for (final entry in rawArt.entries) {
        artMap[entry.key.toString()] = (entry.value as num?)?.toInt() ?? 0;
      }
    }

    return PlayerStats(
      totalMatches: (map['totalMatches'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      draws: (map['draws'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
      totalScore: (map['totalScore'] as num?)?.toInt() ?? 0,
      totalCorrectAnswers: (map['totalCorrectAnswers'] as num?)?.toInt() ?? 0,
      categoryStats: catMap,
      artistCorrectAnswers: artMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalMatches': totalMatches,
    'wins': wins,
    'draws': draws,
    'losses': losses,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'totalScore': totalScore,
    'totalCorrectAnswers': totalCorrectAnswers,
    'categoryStats': categoryStats.map((k, v) => MapEntry(k, v.toJson())),
    'artistCorrectAnswers': artistCorrectAnswers,
  };
}
