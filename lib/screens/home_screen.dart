import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/friend_duel_dialog.dart';
import '../widgets/store_dialog.dart';
import '../widgets/collection_dialog.dart';
import '../widgets/career_stats_dialog.dart';
import '../widgets/banner_ad_widget.dart';
import 'season_pass_screen.dart';
import 'daily_song_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final categories = game.categories;

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const BannerAdWidget(),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Üst Başlık: Profil & Enerji & Mağaza & Koleksiyon
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    // Profil ve Seviye
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showEditProfileDialog(context, game),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.surfaceLight,
                                border: Border.all(
                                  color: game.isVip ? Colors.amber : AppTheme.amber,
                                  width: game.isVip ? 2.0 : 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: game.playerAvatar.startsWith('http')
                                    ? Image.network(
                                        game.playerAvatar,
                                        width: 42,
                                        height: 42,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                          child: Text('🎧', style: TextStyle(fontSize: 20)),
                                        ),
                                      )
                                    : Center(
                                        child: Text(game.playerAvatar, style: const TextStyle(fontSize: 20)),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          game.playerName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: game.isVip ? Colors.amber : AppTheme.textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (game.isVip) ...[
                                        const SizedBox(width: 4),
                                        const Text('👑', style: TextStyle(fontSize: 12)),
                                      ],
                                      const SizedBox(width: 4),
                                      const Icon(Icons.edit_rounded, size: 12, color: AppTheme.textMuted),
                                    ],
                                  ),
                                  Text(
                                    game.playerStats.totalMatches > 0
                                        ? '${game.playerStats.wins} Zafer • %${game.playerStats.winRate.toStringAsFixed(0)} Kazanma'
                                        : 'Seviye 1 • Müzik Çırağı',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.amber),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Enerji Göstergesi (Dokununca Mağaza / Reklam açılır)
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => showDialog(context: context, builder: (_) => const StoreDialog()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: game.energy > 0 ? AppTheme.amber : AppTheme.crimson),
                        ),
                        child: Row(
                          children: [
                            Text(game.energy > 0 ? '⚡' : '🪫', style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            Text(
                              game.energy >= GameProvider.maxEnergy
                                  ? '${game.energy}/${GameProvider.maxEnergy}'
                                  : '${game.energy}/${GameProvider.maxEnergy} (${game.minutesUntilNextEnergy}d)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: game.energy > 0 ? AppTheme.amber : AppTheme.crimson,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Müzik Pass Butonu
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Text('🎟️', style: TextStyle(fontSize: 20)),
                          tooltip: 'Müzik Pass & Görevler',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SeasonPassScreen()),
                          ),
                        ),
                        if (game.seasonPass.unclaimedRewardCount > 0 || game.seasonPass.claimableMissionCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.crimson,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Kariyer & İstatistik Butonu
                    IconButton(
                      icon: const Icon(Icons.insights_rounded, color: Color(0xFF38BDF8), size: 24),
                      tooltip: 'Kariyer & İstatistikler',
                      onPressed: () => showDialog(context: context, builder: (_) => const CareerStatsDialog()),
                    ),

                    // Koleksiyon Butonu
                    IconButton(
                      icon: const Icon(Icons.stars_rounded, color: AppTheme.amber, size: 24),
                      tooltip: 'Plak Koleksiyonu',
                      onPressed: () => showDialog(context: context, builder: (_) => const CollectionDialog()),
                    ),

                    // Mağaza Butonu
                    IconButton(
                      icon: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                      tooltip: 'Müzik Mağazası',
                      onPressed: () => showDialog(context: context, builder: (_) => const StoreDialog()),
                    ),
                  ],
                ),
              ),
            ),

            if (game.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.crimson.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.crimson.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.crimson, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            game.errorMessage!,
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 2. Büyük Hızlı Düello Kartı (Hero Banner)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF222638),
                        Color(0xFF161925),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF2E344A)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '⚡ CANLI 1v1 DÜELLO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.amber,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Icon(Icons.bolt_rounded, color: AppTheme.amber, size: 24),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Şarkıyı İlk Bilen Kazanır!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Türkiye genelinde anlık rakip bul, hız bonusuyla puanları topla.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (categories.isEmpty) return;
                                final quickCategory = categories.firstWhere(
                                  (c) => c.id == 'karma_all',
                                  orElse: () => categories[Random().nextInt(categories.length)],
                                );
                                game.startDuel(quickCategory);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bolt_rounded, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'Hızlı Rakip Bul',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => const FriendDuelDialog(),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.border, width: 1.5),
                                backgroundColor: AppTheme.surfaceLight,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.group_rounded, size: 20, color: AppTheme.amber),
                                  SizedBox(width: 6),
                                  Text(
                                    'Arkadaşla Oyna',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2.5 Kariyer Karnesi Özeti Şeridi
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => showDialog(context: context, builder: (_) => const CareerStatsDialog()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.insights_rounded, color: Color(0xFF38BDF8), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Kariyer Karnesi',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    game.playerStats.totalMatches > 0
                                        ? '%${game.playerStats.winRate.toStringAsFixed(0)} Kazanma (${game.playerStats.wins}G - ${game.playerStats.losses}M)'
                                        : 'Henüz maç yapılmadı',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.amber),
                                  ),
                                ],
                              ),
                              Text(
                                game.playerStats.totalCorrectAnswers > 0
                                    ? '${game.playerStats.totalCorrectAnswers} doğru şarkı tahmini • En iyi seri: ${game.playerStats.bestStreak} 🔥'
                                    : 'Kategori ve sanatçı bazlı başarılarını incele',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2.6 Müzik Pass (Sezon Bileti & Görevler) Canlı Şeridi
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SeasonPassScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: game.seasonPass.isGoldUnlocked
                            ? [const Color(0xFF2C2108), const Color(0xFF18130B)]
                            : [const Color(0xFF1E2538), const Color(0xFF131722)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: game.seasonPass.isGoldUnlocked
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF2E374E),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: game.seasonPass.isGoldUnlocked
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Seviye Plak Rozeti
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: game.seasonPass.isGoldUnlocked
                                  ? [const Color(0xFFFFD54F), const Color(0xFFD97706)]
                                  : [const Color(0xFF38BDF8), const Color(0xFF1E293B)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              game.seasonPass.currentLevel >= 20
                                  ? '⭐${game.seasonPass.endlessLevel}'
                                  : '${game.seasonPass.currentLevel}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: game.seasonPass.isGoldUnlocked ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Bilgi & İlerleme Çubuğu
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    game.seasonPass.seasonName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: game.seasonPass.isGoldUnlocked ? AppTheme.amber : Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  if (game.seasonPass.isGoldUnlocked) ...[
                                    const SizedBox(width: 4),
                                    const Text('👑', style: TextStyle(fontSize: 11)),
                                  ],
                                  const Spacer(),
                                  Text(
                                    game.seasonPass.currentLevelXpText,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: game.seasonPass.currentLevelProgress,
                                  minHeight: 6,
                                  backgroundColor: AppTheme.background,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    game.seasonPass.isGoldUnlocked ? AppTheme.amber : const Color(0xFF38BDF8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Ödül / Bildirim Rozeti
                        if (game.seasonPass.unclaimedRewardCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎁', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  '${game.seasonPass.unclaimedRewardCount} AL',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                                ),
                              ],
                            ),
                          )
                        else
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2.7 Günün Şarkısı (Heardle / Wordle Modu) Şeridi
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailySongScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1735), Color(0xFF140F24)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.45)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('🌟', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Günün Şarkısı',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('🔥', style: TextStyle(fontSize: 10)),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${game.dailyStreak}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFF87171)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                game.dailySongProgress?.isCompleted == true
                                    ? (game.dailySongProgress!.isWon
                                        ? '🎉 Bugünkü şarkıyı ${game.dailySongProgress!.solvedStep}. saniyede bildin!'
                                        : 'Bugünkü şarkı tamamlandı. Yarın yeni şarkı!')
                                    : '1 saniyede şarkıyı tahmin et, ödülleri kap! 🎧',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: game.dailySongProgress?.isCompleted == true
                                      ? (game.dailySongProgress!.isWon ? AppTheme.emerald : AppTheme.textMuted)
                                      : const Color(0xFFA78BFA),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (game.dailySongProgress?.isCompleted == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: game.dailySongProgress!.isWon
                                  ? AppTheme.emerald.withValues(alpha: 0.15)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: game.dailySongProgress!.isWon ? AppTheme.emerald : Colors.white24,
                              ),
                            ),
                            child: Text(
                              game.dailySongProgress!.isWon ? '✅ Bildin' : 'Bitti',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: game.dailySongProgress!.isWon ? AppTheme.emerald : AppTheme.textMuted,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Oyna 🎧',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Çalma Listeleri Başlığı
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Çalma Listeleri & Kategoriler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '5 Liste',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Kategori Kartları
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = categories[index];
                    return _buildCategoryCard(context, cat, game);
                  },
                  childCount: categories.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, MusicCategory cat, GameProvider game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => game.startDuel(cat),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Kategori İkonu
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: cat.badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cat.badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(cat.icon, color: cat.badgeColor, size: 26),
                ),
                const SizedBox(width: 14),

                // Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Kategori Plak İlerlemesi (Örn: 0/17 veya 7 Parça)
                          Builder(
                            builder: (context) {
                              final catBadges = (cat.id == 'karma_all')
                                  ? game.badges
                                  : game.badges.where((b) => b.categoryId == cat.id).toList();

                              if (catBadges.isEmpty) return const SizedBox.shrink();

                              final unlockedCount = catBadges.where((b) => b.isUnlocked).length;
                              final totalCount = catBadges.length;
                              final hasUnlocked = unlockedCount > 0;
                              final cStats = game.playerStats.categoryStats[cat.id];

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => CollectionDialog(initialCategoryId: cat.id),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: hasUnlocked
                                              ? AppTheme.amber.withValues(alpha: 0.15)
                                              : AppTheme.surfaceLight,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: hasUnlocked
                                                ? AppTheme.amber.withValues(alpha: 0.35)
                                                : AppTheme.borderSubtle,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('💿', style: TextStyle(fontSize: 10)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$unlockedCount/$totalCount',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: hasUnlocked ? AppTheme.amber : AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (cStats != null && cStats.matches > 0) ...[
                                    const SizedBox(width: 6),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => CareerStatsDialog(initialCategoryId: cat.id),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.insights_rounded, size: 10, color: Color(0xFF38BDF8)),
                                              const SizedBox(width: 3),
                                              Text(
                                                '%${cStats.winRate.toStringAsFixed(0)} (${cStats.wins}G)',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF38BDF8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, GameProvider game) {
    final textController = TextEditingController(text: game.playerName);
    String selectedAvatar = game.playerAvatar;
    final avatars = ['🎧', '🎸', '🎹', '🎷', '🎤', '🎺', '💻', '📱', '🔥', '👑'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Text('Profilini Düzenle', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Avatar Seç:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: avatars.map((av) {
                  final isSel = selectedAvatar == av;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedAvatar = av),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSel ? AppTheme.amber.withValues(alpha: 0.2) : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? AppTheme.amber : Colors.transparent),
                      ),
                      child: Text(av, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Oyuncu Adı:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: textController,
                maxLength: 16,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: game.googleUserId != null
                    ? OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await game.logoutGoogle();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Google hesabından çıkış yapıldı.'),
                                backgroundColor: AppTheme.amber,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.crimson),
                          backgroundColor: AppTheme.crimson.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, color: AppTheme.crimson, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Çıkış Yap (${game.googleUserEmail ?? "Google"})',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.crimson, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final success = await game.loginWithGoogle();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Google ile bağlandınız: ${game.playerName}!'),
                                backgroundColor: AppTheme.emerald,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.amber),
                          backgroundColor: AppTheme.amber.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🌐', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 8),
                            Text(
                              'Google ile Giriş Yap',
                              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  game.updateProfile(newName, selectedAvatar);
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
