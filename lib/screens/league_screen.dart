import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/league_model.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().fetchLeagueData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final league = game.leagueGroup;
    final tier = league?.tier ?? LeagueTier.bronze;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🏆 HAFTALIK LİG',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppTheme.amber, size: 22),
            onPressed: () => _showLeagueRulesDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Üst Lig Bilgi Kartı (Hero Header)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildTierHeader(tier, league, game),
            ),

            // 2. Tab Bar (Grubum / Ödüller)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.amber.withValues(alpha: 0.5)),
                  ),
                  labelColor: AppTheme.amber,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  tabs: const [
                    Tab(text: '👥 Lig Grubum (25)'),
                    Tab(text: '🎁 Sezon Ödülleri'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 3. Tab Bar İçerikleri
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGroupTab(league, game),
                  _buildRewardsTab(tier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierHeader(LeagueTier tier, LeagueGroupData? league, GameProvider game) {
    final nextTier = tier == LeagueTier.legends
        ? null
        : LeagueTier.values[tier.index + 1];
    final trophiesNeeded = nextTier != null ? (nextTier.minTrophies - game.trophies) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tier.primaryColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: tier.primaryColor.withValues(alpha: 0.15),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Rozet İkonu
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: tier.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: tier.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: Text(
                tier.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tier.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: tier.primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 12, color: AppTheme.amber),
                          const SizedBox(width: 4),
                          Text(
                            league?.formattedTimeRemaining ?? 'Haftalık',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${game.trophies} 🏆',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (league != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: league.currentUserRank <= 5
                              ? AppTheme.emerald.withValues(alpha: 0.2)
                              : (league.currentUserRank >= 21 ? AppTheme.crimson.withValues(alpha: 0.2) : Colors.white10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${league.currentUserRank}. Sıra',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: league.currentUserRank <= 5
                                ? AppTheme.emerald
                                : (league.currentUserRank >= 21 ? const Color(0xFFFCA5A5) : AppTheme.textMuted),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Hedef / Terfi Bilgisi
                Text(
                  nextTier != null
                      ? (trophiesNeeded > 0
                          ? '${nextTier.displayName}\'ne $trophiesNeeded 🏆 kaldı'
                          : 'Terfiye hazırsın!')
                      : '👑 En yüksek ligdesin! Şampiyonluğu koru.',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTab(LeagueGroupData? league, GameProvider game) {
    if (league == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.amber));
    }

    return Column(
      children: [
        // Bilgi Bandı (Terfi / Düşme Sınırları)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.emerald, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('İlk 5: Üst Lig ⬆', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.emerald)),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('6-20: Ligde Kal ➡', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.crimson, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('Son 5: Düşme ⬇', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFCA5A5))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 25 Kişilik Sıralama Listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            physics: const BouncingScrollPhysics(),
            itemCount: league.players.length,
            itemBuilder: (ctx, idx) {
              final player = league.players[idx];
              return _buildPlayerRow(player, league.tier);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(LeaguePlayer player, LeagueTier tier) {
    final isTop3 = player.rank <= 3;
    final isPromotion = player.rank <= 5;
    final isDemotion = player.rank >= 21 && tier != LeagueTier.bronze;

    Color rankColor = Colors.white70;
    Widget rankWidget;
    if (player.rank == 1) {
      rankWidget = const Text('🥇', style: TextStyle(fontSize: 20));
    } else if (player.rank == 2) {
      rankWidget = const Text('🥈', style: TextStyle(fontSize: 20));
    } else if (player.rank == 3) {
      rankWidget = const Text('🥉', style: TextStyle(fontSize: 20));
    } else {
      rankWidget = Text(
        '#${player.rank}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: isPromotion ? AppTheme.emerald : (isDemotion ? const Color(0xFFFCA5A5) : rankColor),
        ),
      );
    }

    Color bgColor = player.isCurrentUser
        ? AppTheme.amber.withValues(alpha: 0.12)
        : AppTheme.surfaceLight;
    BorderSide borderSide = player.isCurrentUser
        ? const BorderSide(color: AppTheme.amber, width: 1.5)
        : (isPromotion
            ? BorderSide(color: AppTheme.emerald.withValues(alpha: 0.3), width: 1.0)
            : (isDemotion
                ? BorderSide(color: AppTheme.crimson.withValues(alpha: 0.3), width: 1.0)
                : const BorderSide(color: AppTheme.border)));

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.fromBorderSide(borderSide),
      ),
      child: Row(
        children: [
          // Sıra Numarası
          SizedBox(
            width: 32,
            child: Center(child: rankWidget),
          ),
          const SizedBox(width: 8),

          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: player.isCurrentUser ? AppTheme.amber : (isTop3 ? Colors.amber.withValues(alpha: 0.6) : AppTheme.border),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                player.avatar,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Oyuncu İsmi & Rozet
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: player.isCurrentUser ? AppTheme.amber : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (player.isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SEN',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ),
                    ],
                  ],
                ),
                if (player.badgeTitle.isNotEmpty)
                  Text(
                    player.badgeTitle,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),

          // Trend İkonu & Kupa
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${player.trophies}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text('🏆', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 2),
              if (isPromotion)
                const Text(
                  '▲ Terfi',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.emerald),
                )
              else if (isDemotion)
                const Text(
                  '▼ Düşme',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFFCA5A5)),
                )
              else
                const Text(
                  '— Sabit',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab(LeagueTier currentTier) {
    final game = context.watch<GameProvider>();
    final league = game.leagueGroup;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: LeagueTier.values.length,
      itemBuilder: (ctx, idx) {
        final tier = LeagueTier.values[idx];
        final isCurrent = tier == currentTier;
        final rewards = league?.getRewardsForTier(tier) ?? tier.weeklyRewards;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCurrent ? tier.primaryColor.withValues(alpha: 0.12) : AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? tier.primaryColor : AppTheme.border,
              width: isCurrent ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: tier.gradientColors),
                ),
                child: Center(
                  child: Text(tier.icon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tier.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: tier.primaryColor,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tier.primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'MEVCUT LİGİN',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tier.minTrophies}+ Kupa Barajı',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    // Ödül hapları
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildRewardChip('🪙 +${rewards['coins']} Altın', Colors.amber),
                        _buildRewardChip('⚡ +${rewards['xp']} XP', Colors.lightBlueAccent),
                        _buildRewardChip('✨ +${rewards['shards']} Joker Parça', Colors.purpleAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  void _showLeagueRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.border)),
        title: const Row(
          children: [
            Text('🏆', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Lig Sistemi Nasıl Çalışır?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Her hafta Pazar 23:59\'da ligler tamamlanır ve sıfırlanır.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            SizedBox(height: 6),
            Text('• 25 kişilik grubunda ilk 5\'e (yeşil) girersen BİR ÜST LİGE terfi edersin.', style: TextStyle(fontSize: 12, color: AppTheme.emerald, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('• Son 5\'e (kırmızı) kalırsan BİR ALT LİGE düşersin (Bronz hariç).', style: TextStyle(fontSize: 12, color: Color(0xFFFCA5A5), fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('• Düelloları kazandıkça +25 🏆 kazanırsın, kaybettikçe -12 🏆 kaybedersin.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            SizedBox(height: 6),
            Text('• Hafta bittiğinde ligine özel dev Altın, XP ve Universal Joker parçası ödülleri hesabına yüklenir.', style: TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anladım', style: TextStyle(color: AppTheme.amber, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
