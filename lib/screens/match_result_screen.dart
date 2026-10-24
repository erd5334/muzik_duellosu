import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/duel_question.dart';
import '../providers/game_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/song_listen_sheet.dart';

class MatchResultScreen extends StatefulWidget {
  const MatchResultScreen({super.key});

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = Provider.of<GameProvider>(context, listen: false);
      if (game.userTotalScore > game.opponentTotalScore) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 180), () {
          HapticFeedback.mediumImpact();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isWinner = game.userTotalScore > game.opponentTotalScore;
    final isDraw = game.userTotalScore == game.opponentTotalScore;
    final diff = (game.userTotalScore - game.opponentTotalScore).abs();
    final isNearMiss = !isWinner && !isDraw && diff <= 150;

    final title = isDraw
        ? 'BERABERE!'
        : (isWinner
            ? 'ZAFER SENİN!'
            : (isNearMiss ? 'ÇOK YAKLAŞTIN!' : 'KAYBETTİN'));
    final titleColor = isDraw
        ? AppTheme.amber
        : (isWinner
            ? AppTheme.emerald
            : (isNearMiss ? const Color(0xFFF97316) : AppTheme.crimson));
    final iconEmoji = isDraw ? '🤝' : (isWinner ? '🏆' : (isNearMiss ? '🎯' : '💔'));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 650;
            final isShort = constraints.maxHeight < 620;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 24.0 : 16.0,
                vertical: isShort ? 8.0 : 14.0,
              ),
              child: Column(
                children: [
                  // Sonuç Rozeti & Başlık
                  Text(iconEmoji, style: TextStyle(fontSize: isShort ? 34 : 44)),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isShort ? 22 : 26,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (isNearMiss) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Fark sadece $diff puan! Bir sonraki maç senin olabilir! 🔥',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF97316)),
                      ),
                    ),
                  ],
                  SizedBox(height: isShort ? 10 : 14),

                  // Geniş ekranda Skor Kartı ve Performans Kartı yan yana, dar ekranda alt alta
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildScoreCard(game, isWinner, isDraw)),
                        const SizedBox(width: 14),
                        Expanded(flex: 5, child: _buildStatsComparisonCard(game)),
                      ],
                    )
                  else ...[
                    _buildScoreCard(game, isWinner, isDraw),
                    const SizedBox(height: 10),
                    _buildStatsComparisonCard(game),
                  ],

                  SizedBox(height: isShort ? 12 : 18),

                  // "Maçta Çalan Şarkılar" Başlığı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.queue_music_rounded, color: AppTheme.amber, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Maçta Çalan Şarkılar (${game.questions.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.headphones_rounded, color: AppTheme.amber, size: 13),
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
                  const SizedBox(height: 8),

                  // Şarkı Listesi (SingleChildScrollView içinde overflow yapmaz)
                  for (int i = 0; i < game.questions.length; i++)
                    _buildSongRow(context, game.questions[i]),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: Row(
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    backgroundColor: isNearMiss ? const Color(0xFFEA580C) : AppTheme.amber,
                    foregroundColor: isNearMiss ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isNearMiss ? 'Hemen Rövanş Al! 🔥' : 'Rövanş Oyna',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isNearMiss ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(GameProvider game, bool isWinner, bool isDraw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
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
                    radius: 22,
                    backgroundColor: AppTheme.surfaceLight,
                    child: game.playerAvatar.startsWith('http')
                        ? ClipOval(
                            child: Image.network(
                              game.playerAvatar,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Text('🎧', style: TextStyle(fontSize: 18)),
                            ),
                          )
                        : Text(game.playerAvatar, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 6),
                  const Text('Sen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    game.userTotalScore.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isWinner ? AppTheme.emerald : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              // Ortadaki VS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted),
                ),
              ),

              // Rakip Skoru
              Column(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.surfaceLight,
                    child: (game.opponent?.avatar != null && game.opponent!.avatar.startsWith('http'))
                        ? ClipOval(
                            child: Image.network(
                              game.opponent!.avatar,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Text('🎸', style: TextStyle(fontSize: 18)),
                            ),
                          )
                        : Text(game.opponent?.avatar ?? '🎸', style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 6),
                  Text(game.opponent?.name ?? 'Rakip', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    game.opponentTotalScore.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: !isWinner && !isDraw ? AppTheme.crimson : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (game.lastEarnedCoins > 0 || game.lastEarnedShards > 0 || game.lastEarnedXp > 0 || game.lastEarnedTrophies != 0) ...[
            const SizedBox(height: 10),
            const Divider(color: AppTheme.borderSubtle, height: 1),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                if (game.lastEarnedTrophies != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (game.lastEarnedTrophies > 0 ? Colors.amber : AppTheme.crimson).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (game.lastEarnedTrophies > 0 ? Colors.amber : AppTheme.crimson).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${game.lastEarnedTrophies > 0 ? "+" : ""}${game.lastEarnedTrophies} Kupa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: game.lastEarnedTrophies > 0 ? Colors.amber : const Color(0xFFFCA5A5),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (game.lastEarnedXp > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '+${game.lastEarnedXp} Sezon XP',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '+${game.lastEarnedCoins} Altın',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.amber,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💿', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        game.lastRewardedBadgeName != null
                            ? '+${game.lastEarnedShards} ${game.lastRewardedBadgeName} Plağı'
                            : '+${game.lastEarnedShards} Plak',
                        style: const TextStyle(
                          fontSize: 12,
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
    );
  }

  Widget _buildStatsComparisonCard(GameProvider game) {
    final totalRounds = game.questions.isNotEmpty ? game.questions.length : 5;
    final userCorrect = game.userCorrectCount;
    final oppCorrect = game.opponentCorrectCount;
    final userAvgSec = game.userAverageTimeSec;
    final oppAvgSec = game.opponentAverageTimeSec;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sen',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.amber),
                ),
              ),
              const Text(
                '📊 MAÇ PERFORMANSI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Expanded(
                child: Text(
                  game.opponent?.name ?? 'Rakip',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppTheme.borderSubtle, height: 1),
          const SizedBox(height: 8),

          // Metrik 1: Doğru Yanıt Sayısı
          _buildStatRow(
            userVal: '$userCorrect / $totalRounds',
            metric: '🎯 Doğru Yanıt',
            oppVal: '$oppCorrect / $totalRounds',
            userIsBetter: userCorrect > oppCorrect,
            oppIsBetter: oppCorrect > userCorrect,
          ),
          const SizedBox(height: 6),

          // Metrik 2: Ortalama Yanıt Hızı
          _buildStatRow(
            userVal: '${userAvgSec.toStringAsFixed(1)} sn',
            metric: '⚡ Ortalama Hız',
            oppVal: '${oppAvgSec.toStringAsFixed(1)} sn',
            userIsBetter: userAvgSec > 0 && (oppAvgSec <= 0 || userAvgSec < oppAvgSec),
            oppIsBetter: oppAvgSec > 0 && (userAvgSec <= 0 || oppAvgSec < userAvgSec),
          ),
          if (game.maxMatchCombo >= 2) ...[
            const SizedBox(height: 6),
            _buildStatRow(
              userVal: '${game.maxMatchCombo}x Seri',
              metric: '🔥 En İyi Kombo',
              oppVal: '-',
              userIsBetter: true,
              oppIsBetter: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String userVal,
    required String metric,
    required String oppVal,
    required bool userIsBetter,
    required bool oppIsBetter,
  }) {
    return Row(
      children: [
        // Sol: Kullanıcı Değeri
        Expanded(
          child: Text(
            userVal,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: userIsBetter ? AppTheme.emerald : AppTheme.textPrimary,
            ),
          ),
        ),
        // Orta: Metrik Etiketi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Text(
            metric,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          ),
        ),
        // Sağ: Rakip Değeri
        Expanded(
          child: Text(
            oppVal,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: oppIsBetter ? AppTheme.emerald : AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSongRow(BuildContext context, DuelQuestion q) {
    final isUserCorrect = q.selectedOptionIndex == q.correctOptionIndex;
    final isOppCorrect = q.isOpponentCorrect == true ||
        (q.opponentSelectedOptionIndex != null && q.opponentSelectedOptionIndex == q.correctOptionIndex);
    final userTimeSec = (q.userAnswerTimeMs / 1000.0).toStringAsFixed(1);
    final oppTimeSec = (q.opponentAnswerTimeMs / 1000.0).toStringAsFixed(1);

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
                          errorBuilder: (context, error, stackTrace) => Container(
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
              // Sen & Rakip Yanıt Sonuçları
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sen: ',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                      Text(
                        isUserCorrect ? '✔ ${userTimeSec}s' : '✘',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isUserCorrect ? AppTheme.emerald : AppTheme.crimson,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Rakip: ',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                      Text(
                        isOppCorrect ? '✔ ${oppTimeSec}s' : '✘',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isOppCorrect ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                        ),
                      ),
                    ],
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
  }
}
