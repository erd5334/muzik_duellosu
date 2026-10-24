import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/season_pass_model.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class SeasonPassScreen extends StatefulWidget {
  const SeasonPassScreen({super.key});

  @override
  State<SeasonPassScreen> createState() => _SeasonPassScreenState();
}

class _SeasonPassScreenState extends State<SeasonPassScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MissionCategory? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final pass = game.seasonPass;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎟️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              pass.seasonName.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Kalan Süre Rozeti
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: AppTheme.amber),
                    SizedBox(width: 4),
                    Text(
                      '28 Gün',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Cafcaflı Başlık & İlerleme Paneli (Hero Banner)
          _buildHeroHeader(game, pass),

          // 2. Sekmeler (Ödül Yolu vs Görevler)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎟️ Ödül Yolu'),
                      if (pass.unclaimedRewardCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppTheme.crimson,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${pass.unclaimedRewardCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎯 Görevler'),
                      if (pass.claimableMissionCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppTheme.emerald,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${pass.claimableMissionCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Sekme İçerikleri
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRewardTrackTab(game, pass),
                _buildMissionsTab(game, pass),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Cafcaflı Hero Başlık & XP İlerleme Çubuğu
  Widget _buildHeroHeader(GameProvider game, SeasonPassData pass) {
    final currentLvl = pass.currentLevel;
    final isEndless = currentLvl >= SeasonPassData.maxTier;
    final endlessLvl = pass.endlessLevel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: pass.isGoldUnlocked
                ? [
                    const Color(0xFF2C2209),
                    const Color(0xFF1B160B),
                    const Color(0xFF0F121C),
                  ]
                : [
                    const Color(0xFF1E2438),
                    const Color(0xFF141824),
                    const Color(0xFF0F121C),
                  ],
          ),
          border: Border.all(
            color: pass.isGoldUnlocked ? const Color(0xFFF59E0B) : const Color(0xFF333C57),
            width: pass.isGoldUnlocked ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: pass.isGoldUnlocked
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Seviye Plak Rozeti
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: pass.isGoldUnlocked
                              ? [const Color(0xFFFFE082), const Color(0xFFD97706)]
                              : [const Color(0xFF38BDF8), const Color(0xFF1E293B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: pass.isGoldUnlocked
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                                : const Color(0xFF38BDF8).withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isEndless ? '⭐$endlessLvl' : '$currentLvl',
                          style: TextStyle(
                            fontSize: isEndless ? 16 : 22,
                            fontWeight: FontWeight.w900,
                            color: pass.isGoldUnlocked ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (pass.isGoldUnlocked)
                      const Positioned(
                        top: -2,
                        child: Text('👑', style: TextStyle(fontSize: 14)),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // XP Bilgisi & İlerleme
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEndless
                                ? 'SONSUZ PLAK SEVİYESİ ($endlessLvl)'
                                : 'SEVİYE $currentLvl / ${SeasonPassData.maxTier}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: pass.isGoldUnlocked ? AppTheme.amber : Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            pass.currentLevelXpText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // İlerleme Çubuğu
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: pass.currentLevelProgress,
                          minHeight: 10,
                          backgroundColor: AppTheme.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pass.isGoldUnlocked ? AppTheme.amber : const Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isEndless
                          ? 'Her 500 XP\'de bir Sonsuz Sandık kazanırsınız!'
                          : 'Sonraki seviyeye ${SeasonPassData.xpPerTier - (pass.currentXp % SeasonPassData.xpPerTier)} XP kaldı',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Alt Butonlar (Gold Pass Aç & Tümünü Topla)
            Row(
              children: [
                if (!pass.isGoldUnlocked)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showUnlockGoldDialog(context, game),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD54F), Color(0xFFF59E0B), Color(0xFFB45309)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('👑', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 6),
                            Text(
                              'GOLD PASS AÇ (2X ÖDÜL)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.amber),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('👑', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 6),
                          Text(
                            'GOLD PASS AKTİF (TÜM ÖDÜLLER AÇIK)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (pass.unclaimedRewardCount > 0) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final claimed = game.claimAllPassRewards();
                      if (claimed.isNotEmpty && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${claimed.length} adet ödül başarıyla toplandı! 🎉'),
                            backgroundColor: AppTheme.emerald,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.done_all_rounded, size: 16, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'TÜMÜNÜ AL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Ödül Yolu (1-20 Seviye ve Sonsuz Sandık)
  Widget _buildRewardTrackTab(GameProvider game, SeasonPassData pass) {
    final currentLvl = pass.currentLevel;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: pass.tiers.length + 1, // +1 Sonsuz Sandık için
      itemBuilder: (context, index) {
        if (index == pass.tiers.length) {
          // Sonsuz Sandık Bölümü (Endgame Loop)
          return _buildEndlessChestCard(game, pass);
        }

        final tier = pass.tiers[index];
        final isUnlocked = tier.level <= currentLvl;
        final isCurrentTier = tier.level == currentLvl;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentTier
                  ? const Color(0xFF232A3D)
                  : (isUnlocked ? AppTheme.surface : AppTheme.surface.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrentTier
                    ? AppTheme.amber
                    : (isUnlocked ? const Color(0xFF333C54) : AppTheme.border),
                width: isCurrentTier ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Sol Bölüm: Ücretsiz Ödül
                Expanded(
                  flex: 4,
                  child: _buildRewardItem(
                    reward: tier.freeReward,
                    isGold: false,
                    isUnlocked: isUnlocked,
                    isClaimed: tier.isFreeClaimed,
                    onClaim: isUnlocked && !tier.isFreeClaimed
                        ? () {
                            final r = game.claimPassTierReward(tier.level, false);
                            if (r != null) _showRewardEarnedDialog(context, r);
                          }
                        : null,
                  ),
                ),

                // Orta Bölüm: Seviye Numarası & Çizgi
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isUnlocked ? AppTheme.amber : const Color(0xFF262C3E),
                          border: Border.all(
                            color: isUnlocked ? Colors.white : AppTheme.border,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${tier.level}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isUnlocked ? Colors.black : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sağ Bölüm: Gold VIP Ödül
                Expanded(
                  flex: 4,
                  child: _buildRewardItem(
                    reward: tier.goldReward,
                    isGold: true,
                    isUnlocked: isUnlocked && pass.isGoldUnlocked,
                    isClaimed: tier.isGoldClaimed,
                    onClaim: isUnlocked && pass.isGoldUnlocked && !tier.isGoldClaimed
                        ? () {
                            final r = game.claimPassTierReward(tier.level, true);
                            if (r != null) _showRewardEarnedDialog(context, r);
                          }
                        : null,
                    isLockedGold: !pass.isGoldUnlocked,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tekil Ödül Kartı
  Widget _buildRewardItem({
    required PassReward reward,
    required bool isGold,
    required bool isUnlocked,
    required bool isClaimed,
    VoidCallback? onClaim,
    bool isLockedGold = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGold
            ? const Color(0xFF2D230D).withValues(alpha: isUnlocked ? 0.7 : 0.3)
            : const Color(0xFF191D2B).withValues(alpha: isUnlocked ? 0.8 : 0.4),
        borderRadius: BorderRadius.horizontal(
          left: isGold ? Radius.zero : const Radius.circular(17),
          right: isGold ? const Radius.circular(17) : Radius.zero,
        ),
      ),
      child: Column(
        crossAxisAlignment: isGold ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isGold) ...[
                const Text('👑', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
              ],
              Text(
                isGold ? 'GOLD ÖDÜL' : 'ÜCRETSİZ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isGold ? AppTheme.amber : const Color(0xFF94A3B8),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: isGold ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isGold) Text(reward.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  reward.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isClaimed ? AppTheme.textMuted : Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isGold) ...[
                const SizedBox(width: 6),
                Text(reward.icon, style: const TextStyle(fontSize: 22)),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Buton Durumu (Al, Alındı veya Kilitli)
          if (isClaimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 14),
                  SizedBox(width: 4),
                  Text('Alındı', style: TextStyle(fontSize: 10, color: AppTheme.emerald, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else if (onClaim != null)
            ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: isGold ? AppTheme.amber : AppTheme.emerald,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('AL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            )
          else if (isLockedGold)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 12, color: AppTheme.amber),
                  SizedBox(width: 4),
                  Text('Gold Gerek', style: TextStyle(fontSize: 10, color: AppTheme.amber, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            const Icon(Icons.lock_rounded, size: 16, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  /// Sonsuz Bonus Sandık Kartı (Endgame Loop - 20+ Seviye)
  Widget _buildEndlessChestCard(GameProvider game, SeasonPassData pass) {
    final availableChests = pass.endlessLevel - pass.endlessChestClaimCount;
    final canOpen = availableChests > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B1D54), Color(0xFF1E152E), Color(0xFF131722)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFA855F7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 44)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'SONSUZ PLAK SANDIĞI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD8B4FE),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA855F7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('20+ SEVİYE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Her 500 XP\'de bir sınırsız altın, joker, plak ve enerji sandığı açın!',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Açılabilir Sandık: $availableChests Adet',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: canOpen ? AppTheme.emerald : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: canOpen
                ? () {
                    final reward = game.openEndlessChest();
                    if (reward != null) _showRewardEarnedDialog(context, reward);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              canOpen ? 'AÇ' : 'KİLİTLİ',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Görevler Sekmesi
  Widget _buildMissionsTab(GameProvider game, SeasonPassData pass) {
    final missions = pass.missions.where((m) {
      if (_selectedCategoryFilter == null) return true;
      return m.category == _selectedCategoryFilter;
    }).toList();

    return Column(
      children: [
        // Filtre Butonları (Tümü, Günlük, Haftalık, Sezonluk)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('Tümü', null),
              const SizedBox(width: 8),
              _buildFilterChip('Günlük', MissionCategory.daily),
              const SizedBox(width: 8),
              _buildFilterChip('Haftalık', MissionCategory.weekly),
              const SizedBox(width: 8),
              _buildFilterChip('Sezonluk', MissionCategory.seasonal),
            ],
          ),
        ),

        // Görev Kartları Listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index];
              return _buildMissionCard(game, mission);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, MissionCategory? category) {
    final isSelected = _selectedCategoryFilter == category;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedCategoryFilter = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.amber : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.amber : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCard(GameProvider game, SeasonMission mission) {
    final progress = (mission.current / mission.target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: mission.isCompleted && !mission.isClaimed
                ? AppTheme.emerald
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            // İkon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(mission.icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),

            // Görev Bilgisi & İlerleme
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mission.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          mission.category == MissionCategory.daily
                              ? 'GÜNLÜK'
                              : (mission.category == MissionCategory.weekly ? 'HAFTALIK' : 'SEZONLUK'),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.amber),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    mission.description,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),

                  // Progress Bar & Hedef
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppTheme.background,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              mission.isCompleted ? AppTheme.emerald : AppTheme.amber,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${mission.current}/${mission.target}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Ödül / Al Butonu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 11)),
                    Text(
                      '+${mission.xpReward} XP',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.amber),
                    ),
                  ],
                ),
                if (mission.rewardLabel.isNotEmpty)
                  Text(
                    mission.rewardLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70),
                  )
                else if (mission.coinReward > 0)
                  Text(
                    '+${mission.coinReward} 🪙',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70),
                  ),
                const SizedBox(height: 6),

                if (mission.isClaimed)
                  const Text('Alındı ✅', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold))
                else if (mission.isCompleted)
                  ElevatedButton(
                    onPressed: () {
                      final ok = game.claimMissionReward(mission.id);
                      if (ok && context.mounted) {
                        final extraText = mission.rewardLabel.isNotEmpty ? ' ve ${mission.rewardLabel}' : '';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('+${mission.xpReward} XP$extraText kazandın! 🎉'),
                            backgroundColor: AppTheme.emerald,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 26),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('AL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                  )
                else
                  Text(
                    '%${(progress * 100).toInt()}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Gold Pass Açma Diyaloğu
  void _showUnlockGoldDialog(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1812),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
        ),
        title: const Row(
          children: [
            Text('👑', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'GOLD PASS\'E GEÇ',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.amber, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Müzik Pass Sezon 1\'in tüm VIP ayrıcalıklarını hemen açın:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            _buildGoldFeature('20 Seviyenin Tamamında 2x Ekstra Ödül'),
            _buildGoldFeature('Özel Plak Parçaları & Joker Paketleri'),
            _buildGoldFeature('20. Seviyede "Efsanevi Plak Tacı"'),
            _buildGoldFeature('Sonsuz Bonus Sandık Kilidi'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sezon Fiyatı:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Row(
                    children: [
                      const Text('🪙 1.500 Altın', style: TextStyle(color: AppTheme.amber, fontWeight: FontWeight.w900, fontSize: 15)),
                      const SizedBox(width: 4),
                      Text('(${game.coins} var)', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final success = game.unlockGoldPass(useCoins: true);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tebrikler! Gold Pass başarıyla açıldı! 👑🎉'),
                    backgroundColor: AppTheme.amber,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yetersiz altın! Mağazadan altın temin edebilirsiniz.'),
                    backgroundColor: AppTheme.crimson,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('1.500 ALTIN İLE AÇ', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white))),
        ],
      ),
    );
  }

  /// Ödül Kazanıldı Kutlama Penceresi
  void _showRewardEarnedDialog(BuildContext context, PassReward reward) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppTheme.amber),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(reward.icon, style: const TextStyle(fontSize: 54)),
            const SizedBox(height: 14),
            const Text(
              'ÖDÜL KAZANILDI! 🎉',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.amber),
            ),
            const SizedBox(height: 6),
            Text(
              reward.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('HARİKA', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}
