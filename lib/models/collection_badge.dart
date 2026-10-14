class CollectionBadge {
  final String id;
  final String categoryId;
  final String artistName;
  final String title; // "Popun Kralı", "BABA", "Gülpembe Efsanesi"
  final String tier; // "Bronz", "Gümüş", "Altın", "Elmas"
  final int totalShardsRequired;
  final String emoji;
  final String imageUrl; // Sanatçının gerçek plak içi fotoğrafı (Deezer CDN)
  int currentShards;
  bool isUnlocked;
  bool isEquipped;

  CollectionBadge({
    required this.id,
    required this.categoryId,
    required this.artistName,
    required this.title,
    required this.tier,
    required this.totalShardsRequired,
    required this.emoji,
    required this.imageUrl,
    this.currentShards = 0,
    this.isUnlocked = false,
    this.isEquipped = false,
  });

  int get remainingShards => (totalShardsRequired - currentShards).clamp(0, totalShardsRequired);
  double get progress => (currentShards / totalShardsRequired).clamp(0.0, 1.0);

  factory CollectionBadge.fromJson(Map<String, dynamic> json) {
    return CollectionBadge(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      artistName: json['artist_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      tier: json['tier']?.toString() ?? 'Bronz',
      totalShardsRequired: json['total_shards'] is int
          ? json['total_shards'] as int
          : (int.tryParse(json['total_shards']?.toString() ?? '30') ?? 30),
      emoji: json['emoji']?.toString() ?? '🎵',
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }

  static List<CollectionBadge> get defaultBadges => [];
}
