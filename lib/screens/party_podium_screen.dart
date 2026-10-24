import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/party_room.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class PartyPodiumScreen extends StatelessWidget {
  const PartyPodiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final room = game.partyRoom;
    final podium = room?.podium ?? [];
    final rankings = room?.finalRankings ?? [];

    final first = podium.isNotEmpty ? podium[0] : null;
    final second = podium.length > 1 ? podium[1] : null;
    final third = podium.length > 2 ? podium[2] : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          game.resetToHome();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text('👑', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 6),
                const Text(
                  'PARTİ ŞAMPİYONLARI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.amber,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rankings.length} oyuncu kıyasıya yarıştı!',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                // 2. Podyum (1., 2., 3. Sıralaması)
                if (podium.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2. Sıra (Gümüş)
                      if (second != null)
                        Expanded(
                          child: _buildPodiumColumn(
                            player: second,
                            height: 120,
                            color: const Color(0xFFCBD5E1),
                            medalEmoji: '🥈',
                            rankText: '2.',
                          ),
                        )
                      else
                        const Spacer(),

                      const SizedBox(width: 8),

                      // 1. Sıra (Altın - En Yüksek)
                      if (first != null)
                        Expanded(
                          child: _buildPodiumColumn(
                            player: first,
                            height: 165,
                            color: AppTheme.amber,
                            medalEmoji: '🥇',
                            rankText: '1.',
                            isWinner: true,
                          ),
                        )
                      else
                        const Spacer(),

                      const SizedBox(width: 8),

                      // 3. Sıra (Bronz)
                      if (third != null)
                        Expanded(
                          child: _buildPodiumColumn(
                            player: third,
                            height: 90,
                            color: const Color(0xFFCD7F32),
                            medalEmoji: '🥉',
                            rankText: '3.',
                          ),
                        )
                      else
                        const Spacer(),
                    ],
                  ),

                const SizedBox(height: 28),

                // 3. Genel Sıralama Tablosu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.leaderboard_rounded, color: AppTheme.amber, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Genel Skor Tablosu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppTheme.borderSubtle, height: 1),
                      const SizedBox(height: 8),

                      for (int i = 0; i < rankings.length; i++)
                        _buildRankingRow(rankings[i], i + 1),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => game.resetToHome(),
                icon: const Icon(Icons.home_rounded, color: Colors.black),
                label: const Text(
                  'Ana Menüye Dön',
                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.amber,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumColumn({
    required PartyPodiumPlayer player,
    required double height,
    required Color color,
    required String medalEmoji,
    required String rankText,
    bool isWinner = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isWinner) const Text('👑', style: TextStyle(fontSize: 22)),
        // Avatar
        CircleAvatar(
          radius: isWinner ? 24 : 20,
          backgroundColor: AppTheme.surfaceLight,
          child: player.avatar.startsWith('http')
              ? ClipOval(
                  child: Image.network(
                    player.avatar,
                    width: isWinner ? 48 : 40,
                    height: isWinner ? 48 : 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Text('🎧', style: TextStyle(fontSize: 20)),
                  ),
                )
              : Text(player.avatar, style: TextStyle(fontSize: isWinner ? 22 : 18)),
        ),
        const SizedBox(height: 6),
        Text(
          player.name,
          style: TextStyle(
            fontSize: isWinner ? 13 : 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${player.score} Puan',
          style: TextStyle(
            fontSize: isWinner ? 12 : 10,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 8),

        // Podyum Bloğu
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0.15),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(medalEmoji, style: TextStyle(fontSize: isWinner ? 30 : 22)),
              const SizedBox(height: 4),
              Text(
                rankText,
                style: TextStyle(
                  fontSize: isWinner ? 20 : 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingRow(PartyPlayer player, int rank) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          // Sıra No
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppTheme.amber.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: rank <= 3 ? AppTheme.amber : AppTheme.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.surface,
            child: player.avatar.startsWith('http')
                ? ClipOval(
                    child: Image.network(
                      player.avatar,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Text('🎧', style: TextStyle(fontSize: 14)),
                    ),
                  )
                : Text(player.avatar, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10),

          // İsim
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Puan
          Text(
            '${player.score} Puan',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.amber,
            ),
          ),
        ],
      ),
    );
  }
}
