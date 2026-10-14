class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String previewUrl;
  final String artworkUrl;
  final String categoryId;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.previewUrl,
    required this.artworkUrl,
    required this.categoryId,
  });

  factory Song.fromAppleJson(Map<String, dynamic> json, String categoryId) {
    String artwork = json['artworkUrl100'] as String? ?? '';
    // Yüksek çözünürlüklü kapak (100x100 -> 600x600)
    artwork = artwork.replaceAll('100x100bb', '600x600bb');

    return Song(
      id: (json['trackId'] ?? json['collectionId'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
      title: _cleanTitle(json['trackName'] as String? ?? 'Bilinmeyen Şarkı'),
      artist: json['artistName'] as String? ?? 'Bilinmeyen Sanatçı',
      album: json['collectionName'] as String? ?? '',
      previewUrl: json['previewUrl'] as String? ?? '',
      artworkUrl: artwork,
      categoryId: categoryId,
    );
  }

  static String _cleanTitle(String raw) {
    // Parantez içi gereksiz ekleri temizle ("Şıkıdım (Hepsi Senin mi?) [Remix]" -> "Şıkıdım")
    var cleaned = raw.replaceAll(RegExp(r'\[.*?\]'), '');
    if (cleaned.contains('(feat.')) {
      cleaned = cleaned.replaceAll(RegExp(r'\(feat\..*?\)'), '');
    }
    if (cleaned.contains('(Remastered')) {
      cleaned = cleaned.replaceAll(RegExp(r'\(Remastered.*?\)'), '');
    }
    return cleaned.trim();
  }
}
