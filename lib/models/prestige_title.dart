import 'package:flutter/material.dart';
import 'player_stats.dart';
import 'collection_badge.dart';

enum TitleCategory {
  general,
  categoryMastery,
  artistMastery,
  streak,
  collector,
}

class PrestigeTitle {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final TitleCategory category;
  final String description;
  final int targetValue;
  final String? targetKey; // categoryId or artist name substring

  const PrestigeTitle({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.category,
    required this.description,
    this.targetValue = 1,
    this.targetKey,
  });

  bool isUnlocked(PlayerStats stats, List<CollectionBadge> badges, {int trophies = 0}) {
    if (id == 'rookie') return true;

    switch (category) {
      case TitleCategory.general:
        if (id == 'duelist_50') return stats.totalMatches >= targetValue;
        if (id == 'genius_50') return stats.totalCorrectAnswers >= targetValue;
        if (id == 'league_diamond') return trophies >= targetValue;
        return false;

      case TitleCategory.categoryMastery:
        if (targetKey == null) return false;
        final cStats = stats.categoryStats[targetKey];
        return (cStats?.correctAnswers ?? 0) >= targetValue;

      case TitleCategory.artistMastery:
        if (targetKey == null) return false;
        final keyLower = targetKey!.toLowerCase();
        int totalForArtist = 0;
        for (final entry in stats.artistCorrectAnswers.entries) {
          if (entry.key.toLowerCase().contains(keyLower)) {
            totalForArtist += entry.value;
          }
        }
        return totalForArtist >= targetValue;

      case TitleCategory.streak:
        return stats.bestStreak >= targetValue;

      case TitleCategory.collector:
        return badges.any((b) => b.isUnlocked);
    }
  }

  int getProgress(PlayerStats stats, List<CollectionBadge> badges, {int trophies = 0}) {
    if (id == 'rookie') return 1;

    switch (category) {
      case TitleCategory.general:
        if (id == 'duelist_50') return stats.totalMatches.clamp(0, targetValue);
        if (id == 'genius_50') return stats.totalCorrectAnswers.clamp(0, targetValue);
        if (id == 'league_diamond') return trophies.clamp(0, targetValue);
        return 0;

      case TitleCategory.categoryMastery:
        if (targetKey == null) return 0;
        return (stats.categoryStats[targetKey]?.correctAnswers ?? 0).clamp(0, targetValue);

      case TitleCategory.artistMastery:
        if (targetKey == null) return 0;
        final keyLower = targetKey!.toLowerCase();
        int totalForArtist = 0;
        for (final entry in stats.artistCorrectAnswers.entries) {
          if (entry.key.toLowerCase().contains(keyLower)) {
            totalForArtist += entry.value;
          }
        }
        return totalForArtist.clamp(0, targetValue);

      case TitleCategory.streak:
        return stats.bestStreak.clamp(0, targetValue);

      case TitleCategory.collector:
        return badges.where((b) => b.isUnlocked).length.clamp(0, targetValue);
    }
  }

  static const List<PrestigeTitle> allTitles = [
    // Genel Başlangıç
    PrestigeTitle(
      id: 'rookie',
      name: 'Çaylak Dinleyici',
      icon: '🎧',
      color: Color(0xFF94A3B8),
      category: TitleCategory.general,
      description: 'Müzik arenasına ilk adım',
      targetValue: 0,
    ),

    // Sanatçı Ustalıkları
    PrestigeTitle(
      id: 'megastar_fan',
      name: 'Megastar Fanatiği',
      icon: '👑',
      color: Color(0xFFF59E0B),
      category: TitleCategory.artistMastery,
      description: 'Tarkan şarkılarında 5 doğru yanıt ver',
      targetValue: 5,
      targetKey: 'Tarkan',
    ),
    PrestigeTitle(
      id: 'damar_master',
      name: 'Damar Üstadı',
      icon: '🍷',
      color: Color(0xFFDC2626),
      category: TitleCategory.artistMastery,
      description: 'Müslüm Gürses şarkılarında 5 doğru yanıt ver',
      targetValue: 5,
      targetKey: 'Müslüm',
    ),
    PrestigeTitle(
      id: 'rock_legend',
      name: 'Gülpembe Yolcusu',
      icon: '🎸',
      color: Color(0xFFEF4444),
      category: TitleCategory.artistMastery,
      description: 'Barış Manço şarkılarında 5 doğru yanıt ver',
      targetValue: 5,
      targetKey: 'Barış Manço',
    ),
    PrestigeTitle(
      id: 'minik_serce',
      name: 'Minik Serçe Aşığı',
      icon: '🕊️',
      color: Color(0xFFEC4899),
      category: TitleCategory.artistMastery,
      description: 'Sezen Aksu şarkılarında 5 doğru yanıt ver',
      targetValue: 5,
      targetKey: 'Sezen Aksu',
    ),
    PrestigeTitle(
      id: 'battle_king',
      name: 'Battle Kralı',
      icon: '🎤',
      color: Color(0xFF10B981),
      category: TitleCategory.artistMastery,
      description: 'Ceza şarkılarında 5 doğru yanıt ver',
      targetValue: 5,
      targetKey: 'Ceza',
    ),
    PrestigeTitle(
      id: 'rap_philosopher',
      name: 'Rap Filozofu',
      icon: '📜',
      color: Color(0xFF06B6D4),
      category: TitleCategory.artistMastery,
      description: 'Sagopa Kajmer şarkılarında 5 doğru yanıt ver',
      targetValue: 5,
      targetKey: 'Sagopa',
    ),
    PrestigeTitle(
      id: 'anadolu_rocker',
      name: 'Rock Ozanı',
      icon: '⚡',
      color: Color(0xFFF97316),
      category: TitleCategory.artistMastery,
      description: 'Cem Karaca şarkılarında 5 doğru yanıt ver',
      targetValue: 5,
      targetKey: 'Cem Karaca',
    ),
    PrestigeTitle(
      id: 'ferdi_baba',
      name: 'Huzurum Kalmadı',
      icon: '💔',
      color: Color(0xFF9333EA),
      category: TitleCategory.artistMastery,
      description: 'Ferdi Tayfur şarkılarında 5 doğru yanıt ver',
      targetValue: 5,
      targetKey: 'Ferdi Tayfur',
    ),

    // Kategori Ustalıkları
    PrestigeTitle(
      id: 'pop_90s_master',
      name: "90'lar Efsanesi",
      icon: '📻',
      color: Color(0xFFF59E0B),
      category: TitleCategory.categoryMastery,
      description: "90'lar Türkçe Pop kategorisinde 15 doğru bil",
      targetValue: 15,
      targetKey: 'pop_90s',
    ),
    PrestigeTitle(
      id: 'rock_tr_master',
      name: 'Rock Yıldızı',
      icon: '⚡',
      color: Color(0xFFEF4444),
      category: TitleCategory.categoryMastery,
      description: 'Anadolu & Türkçe Rock kategorisinde 15 doğru bil',
      targetValue: 15,
      targetKey: 'rock_tr',
    ),
    PrestigeTitle(
      id: 'hit_2000s_master',
      name: 'Milenyum Fırtınası',
      icon: '💿',
      color: Color(0xFF3B82F6),
      category: TitleCategory.categoryMastery,
      description: "2000'ler Türkçe Hit kategorisinde 15 doğru bil",
      targetValue: 15,
      targetKey: 'hit_2000s',
    ),
    PrestigeTitle(
      id: 'rap_tr_master',
      name: 'Türkçe Rap Dehası',
      icon: '🔥',
      color: Color(0xFF10B981),
      category: TitleCategory.categoryMastery,
      description: 'Türkçe Rap & HipHop kategorisinde 15 doğru bil',
      targetValue: 15,
      targetKey: 'rap_tr',
    ),
    PrestigeTitle(
      id: 'arabesk_master',
      name: 'Efkar Babası',
      icon: '🚬',
      color: Color(0xFF8B5CF6),
      category: TitleCategory.categoryMastery,
      description: 'Damar & Arabesk kategorisinde 15 doğru bil',
      targetValue: 15,
      targetKey: 'arabesk_tr',
    ),
    PrestigeTitle(
      id: 'turku_master',
      name: 'Bozkırın Tezenesi',
      icon: '🪕',
      color: Color(0xFF14B8A6),
      category: TitleCategory.categoryMastery,
      description: 'Türküler & Ozanlar kategorisinde 15 doğru bil',
      targetValue: 15,
      targetKey: 'turku_tr',
    ),

    // Galibiyet & Seri & Koleksiyon
    PrestigeTitle(
      id: 'streak_5',
      name: 'Yenilmez',
      icon: '🔥',
      color: Color(0xFFF97316),
      category: TitleCategory.streak,
      description: 'Arka arkaya 5 düello kazan',
      targetValue: 5,
    ),
    PrestigeTitle(
      id: 'streak_10',
      name: 'Durdurulamaz Güç',
      icon: '⚡',
      color: Color(0xFFEF4444),
      category: TitleCategory.streak,
      description: 'Arka arkaya 10 düello kazan',
      targetValue: 10,
    ),
    PrestigeTitle(
      id: 'genius_50',
      name: 'Müzik Profesörü',
      icon: '🎓',
      color: Color(0xFF8B5CF6),
      category: TitleCategory.general,
      description: 'Toplam 50 doğru yanıta ulaş',
      targetValue: 50,
    ),
    PrestigeTitle(
      id: 'collector_1',
      name: 'Plak Koleksiyoneri',
      icon: '🏆',
      color: Color(0xFFF59E0B),
      category: TitleCategory.collector,
      description: 'En az bir koleksiyon plağını tamamla',
      targetValue: 1,
    ),
    PrestigeTitle(
      id: 'league_diamond',
      name: 'Lig Şampiyonu',
      icon: '💎',
      color: Color(0xFF38BDF8),
      category: TitleCategory.general,
      description: 'Ligde 1600 kupa (Elmas Lig) barajını aş',
      targetValue: 1600,
    ),
  ];
}
