import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';

class SongListenSheet extends StatefulWidget {
  final Song song;

  const SongListenSheet({
    super.key,
    required this.song,
  });

  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SongListenSheet(song: song),
    );
  }

  @override
  State<SongListenSheet> createState() => _SongListenSheetState();
}

class _SongListenSheetState extends State<SongListenSheet> {
  late final AudioPlayer _previewPlayer;
  bool _isPlayingPreview = false;
  bool _isLoadingPreview = false;

  @override
  void initState() {
    super.initState();
    _previewPlayer = AudioPlayer();
    _previewPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingPreview = (state == PlayerState.playing);
          if (state == PlayerState.playing || state == PlayerState.paused || state == PlayerState.completed) {
            _isLoadingPreview = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _previewPlayer.stop();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePreview() async {
    if (widget.song.previewUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu şarkı için önizleme bulunamadı.')),
      );
      return;
    }

    try {
      if (_isPlayingPreview) {
        await _previewPlayer.pause();
      } else {
        setState(() => _isLoadingPreview = true);
        await _previewPlayer.play(UrlSource(widget.song.previewUrl));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    }
  }

  Future<void> _openExternalMusicUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uygulama açılamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = Uri.encodeComponent('${widget.song.artist} - ${widget.song.title}');
    final youtubeUrl = 'https://www.youtube.com/results?search_query=$query';
    final youtubeMusicUrl = 'https://music.youtube.com/search?q=$query';
    final spotifyUrl = 'https://open.spotify.com/search/$query';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Çekme çubuğu
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Şarkı Bilgisi & Albüm Kapağı
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: widget.song.artworkUrl.isNotEmpty
                      ? Image.network(
                          widget.song.artworkUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => Container(
                            color: AppTheme.surfaceLight,
                            child: const Icon(Icons.music_note, color: AppTheme.amber, size: 28),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceLight,
                          child: const Icon(Icons.music_note, color: AppTheme.amber, size: 28),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.song.artist,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: AppTheme.borderSubtle, height: 1),
          const SizedBox(height: 16),

          // 1. Uygulama İçi 30 Sn Önizleme Oynatıcı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _togglePreview,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.amber,
                      shape: BoxShape.circle,
                    ),
                    child: _isLoadingPreview
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Icon(
                            _isPlayingPreview ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPlayingPreview ? 'Önizleme Çalıyor...' : '30 Sn Önizlemeyi Dinle',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Uygulama içinden hızlıca dinle',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Platform Başlığı
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tam Şarkıyı Dinle',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. YouTube Butonu (En Sağlam & Ücretsiz)
          _buildPlatformButton(
            title: "YouTube'da Dinle",
            subtitle: "Klip veya tam şarkıyı ücretsiz aç",
            icon: Icons.play_circle_filled_rounded,
            iconColor: const Color(0xFFFF0000),
            onTap: () => _openExternalMusicUrl(youtubeUrl),
          ),

          const SizedBox(height: 8),

          // 3. Spotify Butonu
          _buildPlatformButton(
            title: "Spotify'da Dinle",
            subtitle: "Spotify uygulaması veya webde ara",
            icon: Icons.graphic_eq_rounded,
            iconColor: const Color(0xFF1DB954),
            onTap: () => _openExternalMusicUrl(spotifyUrl),
          ),

          const SizedBox(height: 8),

          // 4. YouTube Music Butonu
          _buildPlatformButton(
            title: "YouTube Music'te Dinle",
            subtitle: "YouTube Music kitaplığında dinle",
            icon: Icons.album_rounded,
            iconColor: const Color(0xFFFF4500),
            onTap: () => _openExternalMusicUrl(youtubeMusicUrl),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}
