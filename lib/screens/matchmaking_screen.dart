import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isWaitingFriend = game.status == GameStatus.waitingFriendInRoom;
    final isOpponentFound = game.status == GameStatus.opponentFound;
    final opponent = game.opponent;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [
              // Üst İptal Butonu
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary),
                  onPressed: () => game.resetToHome(),
                ),
              ),

              const Spacer(),

              // Kategori Bilgisi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  game.selectedCategory?.title ?? 'Şarkıyı Bil Bakalım',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.amber,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              if (isWaitingFriend) ...[
                // ÖZEL ODA KODU EKRANI
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.amber.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ÖZEL ODA OLUŞTURULDU',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.amber, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${game.createdRoomCode ?? "----"}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4.0,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: AppTheme.amber, size: 22),
                              onPressed: () {
                                if (game.createdRoomCode != null) {
                                  Clipboard.setData(ClipboardData(text: game.createdRoomCode!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Oda kodu kopyalandı!')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (game.createdRoomCode != null) {
                            final code = game.createdRoomCode!;
                            final text = Uri.encodeComponent(
                              '🎵 Sahne Senin: Şarkıyı Bil oyununda düelloya davet edildin!\n\n'
                              'Oda Kodum: #$code\n\n'
                              'Hemen uygulamayı aç, "Arkadaşla Oyna" -> "Koda Katıl" bölümüne #$code yaz ve yarışalım! 🎧',
                            );
                            final url = Uri.parse('whatsapp://send?text=$text');
                            final webUrl = Uri.parse('https://api.whatsapp.com/send?text=$text');
                            try {
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } else {
                                await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                              }
                            } catch (_) {
                              await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text(
                          'WhatsApp ile Davet Et',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${game.totalMatchRounds} Turluk Maç İçin Arkadaşın Bekleniyor...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 18),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.amber),
                      ),
                    ],
                  ),
                ),
              ] else if (!isOpponentFound) ...[
                // GENEL RADAR ARAMASI
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _radarController,
                        builder: (context, child) {
                          return Container(
                            width: 120 + _radarController.value * 100,
                            height: 120 + _radarController.value * 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.amber.withValues(alpha: 1.0 - _radarController.value),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface,
                          border: Border.all(color: AppTheme.border, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🎧', style: TextStyle(fontSize: 40)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Rakip Aranıyor...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Türkiye genelindeki müzikseverler taranıyor',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ] else ...[
                // EŞLEŞME SAĞLANDI
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildUserCard(
                      name: game.playerName,
                      avatar: game.playerAvatar,
                      tag: 'Sen',
                      title: game.selectedTitle,
                      isHighlighted: false,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.amber,
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    _buildUserCard(
                      name: opponent?.name ?? 'Rakip',
                      avatar: opponent?.avatar ?? '🎸',
                      tag: opponent?.city ?? 'Türkiye',
                      title: opponent?.title ?? 'Çaylak Dinleyici',
                      isHighlighted: true,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Eşleşme Sağlandı!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.emerald,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${game.totalMatchRounds} turluk düello başlıyor...',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard({
    required String name,
    required String avatar,
    required String tag,
    String? title,
    required bool isHighlighted,
  }) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? AppTheme.amber : AppTheme.border,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.surfaceLight,
            child: avatar.startsWith('http')
                ? ClipOval(
                    child: Image.network(
                      avatar,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Text('🎧', style: TextStyle(fontSize: 26)),
                    ),
                  )
                : Text(avatar, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (title != null && title.isNotEmpty) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isHighlighted ? AppTheme.amber.withValues(alpha: 0.15) : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isHighlighted ? AppTheme.amber.withValues(alpha: 0.4) : AppTheme.border,
                  width: 0.8,
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isHighlighted ? AppTheme.amber : AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 3),
          Text(
            tag,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
