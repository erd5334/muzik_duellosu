import 'package:flutter/material.dart';

class MusicCategory {
  final String id;
  final String title;
  final String subtitle;
  final String searchQuery;
  final IconData icon;
  final Color badgeColor;
  int masteryLevel; // 1-5 seviye

  MusicCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.searchQuery,
    required this.icon,
    required this.badgeColor,
    this.masteryLevel = 1,
  });

  static IconData _parseIcon(String? iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star_rounded;
      case 'mic':
        return Icons.mic_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'bolt':
        return Icons.electric_bolt_rounded;
      case 'headphones':
        return Icons.headphones_rounded;
      case 'sparkles':
        return Icons.auto_awesome_rounded;
      case 'speaker':
        return Icons.speaker_group_rounded;
      case 'note':
        return Icons.music_note_rounded;
      case 'radio':
        return Icons.radio_rounded;
      case 'shuffle':
        return Icons.shuffle_rounded;
      case 'album':
      default:
        return Icons.album_rounded;
    }
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFF59E0B);
    final cleanHex = hex.replaceAll('#', '');
    try {
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFF59E0B);
  }

  factory MusicCategory.fromJson(Map<String, dynamic> json) {
    return MusicCategory(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      searchQuery: json['search_query']?.toString() ?? (json['title']?.toString() ?? ''),
      icon: _parseIcon(json['icon_name']?.toString()),
      badgeColor: _parseColor(json['color_hex']?.toString()),
      masteryLevel: json['mastery_level'] is int ? json['mastery_level'] as int : 1,
    );
  }

  static List<MusicCategory> get defaultCategories => [
    MusicCategory(
      id: 'pop_90s',
      title: "90'lar Türkçe Pop",
      subtitle: 'Tarkan, Sezen Aksu, Mustafa Sandal, Kenan Doğulu, Mirkelam',
      searchQuery: '90lar turkce pop',
      icon: Icons.album_rounded,
      badgeColor: const Color(0xFFF59E0B), // Kehribar
      masteryLevel: 3,
    ),
    MusicCategory(
      id: 'rock_tr',
      title: 'Anadolu Rock & Türkçe Rock',
      subtitle: 'Barış Manço, Cem Karaca, Erkin Koray, Duman, Mor ve Ötesi, Şebnem Ferah',
      searchQuery: 'anadolu rock',
      icon: Icons.electric_bolt_rounded,
      badgeColor: const Color(0xFFEF4444), // Crimson
      masteryLevel: 2,
    ),
    MusicCategory(
      id: 'hit_2000s',
      title: "2000'ler Türkçe Hit",
      subtitle: 'Hande Yener, Demet Akalın, Serdar Ortaç, Yalın, Murat Boz, Sıla',
      searchQuery: '2000ler turkce hit',
      icon: Icons.headphones_rounded,
      badgeColor: const Color(0xFF3B82F6), // Mavi
      masteryLevel: 2,
    ),
    MusicCategory(
      id: 'pop_2010s',
      title: '2010+ Günümüz Pop & Alternatif',
      subtitle: 'Mabel Matiz, Edis, Simge, Zeynep Bastık, Madrigal, Dolu Kadehi Ters Tut',
      searchQuery: 'turkce pop hit',
      icon: Icons.auto_awesome_rounded,
      badgeColor: const Color(0xFFEC4899), // Pembe
      masteryLevel: 2,
    ),
    MusicCategory(
      id: 'rap_tr',
      title: 'Türkçe Rap & HipHop',
      subtitle: 'Ceza, Sagopa Kajmer, Ezhel, Şanışer, Motive, Uzi, Norm Ender',
      searchQuery: 'turkce rap',
      icon: Icons.speaker_group_rounded,
      badgeColor: const Color(0xFF10B981), // Zümrüt
      masteryLevel: 1,
    ),
    MusicCategory(
      id: 'arabesk_tr',
      title: 'Damar & Arabesk Klasikleri',
      subtitle: 'Müslüm Gürses, Ferdi Tayfur, İbrahim Tatlıses, Bergen, Ceylan',
      searchQuery: 'muslum gurses ibrahim tatlises',
      icon: Icons.music_note_rounded,
      badgeColor: const Color(0xFF8B5CF6), // Mor
      masteryLevel: 1,
    ),
    MusicCategory(
      id: 'turku_tr',
      title: 'Türküler & Ozanlar',
      subtitle: 'Neşet Ertaş, Aşık Veysel, Selda Bağcan, Musa Eroğlu, Erdal Erzincan',
      searchQuery: 'turkuler neset ertas',
      icon: Icons.library_music_rounded,
      badgeColor: const Color(0xFF14B8A6), // Turkuaz
      masteryLevel: 1,
    ),
    MusicCategory(
      id: 'nostalji_tr',
      title: "70'ler & 80'ler Nostalji",
      subtitle: 'Ajda Pekkan, Nilüfer, Erol Evgin, İlhan İrem, Sezen Aksu',
      searchQuery: 'yesilcam nostalji 70ler',
      icon: Icons.radio_rounded,
      badgeColor: const Color(0xFFF97316), // Portakal
      masteryLevel: 1,
    ),
    MusicCategory(
      id: 'karma_all',
      title: 'Karma Çalma Listesi (Hepsi)',
      subtitle: "90'lar, 2000'ler, Pop, Rock, Rap, Arabesk, Türkü, Karadeniz - Tüm Şarkılar!",
      searchQuery: 'turkce hit karma',
      icon: Icons.shuffle_rounded,
      badgeColor: const Color(0xFFE11D48), // Rose
      masteryLevel: 5,
    ),
  ];
}
