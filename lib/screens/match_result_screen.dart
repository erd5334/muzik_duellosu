import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/song_listen_sheet.dart';

class MatchResultScreen extends StatelessWidget {
  const MatchResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isWinner = game.userTotalScore > game.opponentTotalScore;
    final isDraw = game.userTotalScore == game.opponentTotalScore;

    final title = isDraw ? 'BERABERE!' : (isWinner ? 'ZAFER SENİN!' : 'KAYBETTİN');
    final titleColor = isDraw ? AppTheme.amber : (isWinner ? AppTheme.emerald : AppTheme.crimson);
    final iconEmoji = isDraw ? '🤝' : (isWinner ? '🏆' : '💔');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Sonuç Rozeti & Başlık
              Text(iconEmoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),

              // Skor Kartı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Kullanıcı Skoru
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.surfaceLight,
                              child: game.playerAvatar.startsWith('http')
                                  ? ClipOval(
                                      child: Image.network(
                                        game.playerAvatar,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Text('🎧', style: TextStyle(fontSize: 20)),
                                      ),
                                    )
                                  : Text(game.playerAvatar, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(height: 8),
                            const Text('Sen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              game.userTotalScore.toString(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isWinner ? AppTheme.emerald : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),

                        // Ortadaki VS
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'VS',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted),
                          ),
                        ),

                        // Rakip Skoru
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.surfaceLight,
                              child: (game.opponent?.avatar != null && game.opponent!.avatar.startsWith('http'))
                                  ? ClipOval(
                                      child: Image.network(
                                        game.opponent!.avatar,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Text('🎸', style: TextStyle(fontSize: 20)),
                                      ),
                                    )
                                  : Text(game.opponent?.avatar ?? '🎸', style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(height: 8),
                            Text(game.opponent?.name ?? 'Rakip', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              game.opponentTotalScore.toString(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: !isWinner && !isDraw ? AppTheme.crimson : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (game.lastEarnedCoins > 0 || game.lastEarnedShards > 0 || game.lastEarnedXp > 0 || game.lastEarnedTrophies != 0) ...[
                      const SizedBox(height: 14),
                      const Divider(color: AppTheme.borderSubtle, height: 1),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Kupa Ödülü / Kaybı
                          if (game.lastEarnedTrophies != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (game.lastEarnedTrophies > 0 ? Colors.amber : AppTheme.crimson).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (game.lastEarnedTrophies > 0 ? Colors.amber : AppTheme.crimson).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🏆', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${game.lastEarnedTrophies > 0 ? "+" : ""}${game.lastEarnedTrophies} Kupa',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: game.lastEarnedTrophies > 0 ? Colors.amber : const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Sezon Pass XP Ödülü
                          if (game.lastEarnedXp > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('⚡', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 5),
                                  Text(
                                    '+${game.lastEarnedXp} Sezon XP',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Altın Ödülü
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🪙', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 5),
                                Text(
                                  '+${game.lastEarnedCoins} Altın',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Plak Parçası Ödülü
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('💿', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 5),
                                Text(
                                  game.lastRewardedBadgeName != null
                                      ? '+${game.lastEarnedShards} ${game.lastRewardedBadgeName} Plağı'
                                      : '+${game.lastEarnedShards} Plak Parçası',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD8B4FE),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // "Maçta Çalan Şarkılar" Başlığı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.queue_music_rounded, color: AppTheme.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Maçta Çalan Şarkılar (${game.questions.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(Icons.headphones_rounded, color: AppTheme.amber, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Dinlemek için dokun',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Şarkı Listesi
              Expanded(
                child: ListView.builder(
                  itemCount: game.questions.length,
                  itemBuilder: (context, index) {
                    final q = game.questions[index];
                    final isUserCorrect = q.selectedOptionIndex == q.correctOptionIndex;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => SongListenSheet.show(context, q.song),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: q.song.artworkUrl.isNotEmpty
                                      ? Image.network(
                                          q.song.artworkUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, error, stackTrace) => Container(
                                            color: AppTheme.surfaceLight,
                                            child: const Icon(Icons.music_note, color: AppTheme.amber, size: 20),
                                          ),
                                        )
                                      : Container(
                                          color: AppTheme.surfaceLight,
                                          child: const Icon(Icons.music_note, color: AppTheme.amber, size: 20),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      q.song.title,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      q.song.artist,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Puan / Durum
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isUserCorrect ? '+${q.userScoreEarned}' : '0',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isUserCorrect ? AppTheme.emerald : AppTheme.textMuted,
                                    ),
                                  ),
                                  Text(
                                    isUserCorrect ? 'Doğru' : 'Yanlış',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isUserCorrect ? AppTheme.emerald : AppTheme.crimson,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              // Kulaklık / Dinle Butonu
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.borderSubtle),
                                ),
                                child: const Icon(
                                  Icons.headphones_rounded,
                                  color: AppTheme.amber,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Alt Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (!game.hasNoAds && !game.isVip) {
                          AdService.instance.showInterstitialAd(
                            onDismissed: () => game.resetToHome(),
                          );
                        } else {
                          game.resetToHome();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Ana Menü',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (game.selectedCategory != null) {
                          if (!game.hasNoAds && !game.isVip) {
                            AdService.instance.showInterstitialAd(
                              onDismissed: () => game.startDuel(game.selectedCategory!),
                            );
                          } else {
                            game.startDuel(game.selectedCategory!);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.amber,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Rövanş Oyna',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
