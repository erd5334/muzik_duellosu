import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prestige_title.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class ProfileTitlesDialog extends StatefulWidget {
  const ProfileTitlesDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ProfileTitlesDialog(),
    );
  }

  @override
  State<ProfileTitlesDialog> createState() => _ProfileTitlesDialogState();
}

class _ProfileTitlesDialogState extends State<ProfileTitlesDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late String _selectedAvatar;
  TitleCategory? _filterCategory;

  final List<String> _avatars = [
    '🎧', '🎸', '🎹', '🎷', '🎤', '🎺', '💻', '📱', '🔥', '👑', '🌟', '💎'
  ];

  @override
  void initState() {
    super.initState();
    final game = Provider.of<GameProvider>(context, listen: false);
    _nameController = TextEditingController(text: game.playerName);
    _selectedAvatar = game.playerAvatar;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Tutamaç
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Başlık & Kapat Butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🎖️', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profil & Prestij Unvanları',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Unvanını seç, düellolarda ve ligde rakibine göster',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.amber,
            labelColor: AppTheme.amber,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: const [
              Tab(text: '🎖️ Prestij Unvanları'),
              Tab(text: '👤 Profil Bilgileri'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTitlesTab(game),
                _buildProfileTab(game),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PRESTİJ UNVANLARI TAB ====================

  Widget _buildTitlesTab(GameProvider game) {
    final all = PrestigeTitle.allTitles;
    final filtered = _filterCategory == null
        ? all
        : all.where((t) => t.category == _filterCategory).toList();

    return Column(
      children: [
        // Filtre Butonları
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tümü', null),
                const SizedBox(width: 6),
                _buildFilterChip('👑 Sanatçı', TitleCategory.artistMastery),
                const SizedBox(width: 6),
                _buildFilterChip('📻 Kategori', TitleCategory.categoryMastery),
                const SizedBox(width: 6),
                _buildFilterChip('🔥 Seri & Zafer', TitleCategory.streak),
                const SizedBox(width: 6),
                _buildFilterChip('🏆 Genel & Plak', TitleCategory.general),
              ],
            ),
          ),
        ),

        // Unvan Listesi
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final title = filtered[index];
              final isUnlocked = title.isUnlocked(
                game.playerStats,
                game.badges,
                trophies: game.trophies,
              );
              final isEquipped = game.selectedTitle == title.name;
              final progress = title.getProgress(
                game.playerStats,
                game.badges,
                trophies: game.trophies,
              );

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEquipped
                      ? AppTheme.amber.withValues(alpha: 0.12)
                      : (isUnlocked ? AppTheme.surfaceLight : AppTheme.surfaceLight.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isEquipped
                        ? AppTheme.amber
                        : (isUnlocked ? AppTheme.border : AppTheme.borderSubtle),
                    width: isEquipped ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // İkon / Rozet
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: title.color.withValues(alpha: isUnlocked ? 0.2 : 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isUnlocked ? title.color : AppTheme.borderSubtle,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          title.icon,
                          style: TextStyle(
                            fontSize: 22,
                            color: isUnlocked ? null : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Başlık ve Açıklama
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isUnlocked ? AppTheme.textPrimary : AppTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isEquipped) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.amber,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'KUŞANILDI',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            title.description,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          if (!isUnlocked && title.targetValue > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (progress / title.targetValue).clamp(0.0, 1.0),
                                      minHeight: 4,
                                      backgroundColor: AppTheme.surface,
                                      valueColor: AlwaysStoppedAnimation<Color>(title.color),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$progress / ${title.targetValue}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Kuşan / Kilitli Butonu
                    if (isEquipped)
                      const Icon(Icons.check_circle_rounded, color: AppTheme.amber, size: 22)
                    else if (isUnlocked)
                      ElevatedButton(
                        onPressed: () {
                          game.setSelectedTitle(title.name);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Kuşan',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 12, color: AppTheme.textMuted),
                            SizedBox(width: 4),
                            Text(
                              'Kilitli',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, TitleCategory? cat) {
    final isSelected = _filterCategory == cat;
    return InkWell(
      onTap: () => setState(() => _filterCategory = cat),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.amber : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.amber : AppTheme.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // ==================== PROFİL BİLGİLERİ TAB ====================

  Widget _buildProfileTab(GameProvider game) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Önizleme Kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.surfaceLight,
                  AppTheme.surfaceLight.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.surface,
                  child: _selectedAvatar.startsWith('http')
                      ? ClipOval(
                          child: Image.network(
                            _selectedAvatar,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text('🎧', style: TextStyle(fontSize: 26)),
                          ),
                        )
                      : Text(_selectedAvatar, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.isNotEmpty ? _nameController.text : game.playerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '🎖️ ${game.selectedTitle}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🏆 ${game.trophies} Kupa • ${game.playerStats.wins} Zafer (%${game.playerStats.winRate.toStringAsFixed(0)})',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Avatar Seçimi
          const Text(
            'Avatar Seç:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _avatars.map((av) {
              final isSel = _selectedAvatar == av;
              return InkWell(
                onTap: () => setState(() => _selectedAvatar = av),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isSel ? AppTheme.amber.withValues(alpha: 0.2) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? AppTheme.amber : AppTheme.borderSubtle,
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(av, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // İsim Değiştirme
          const Text(
            'Oyuncu Adı:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            maxLength: 16,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Yeni oyuncu adı...',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.amber),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Google & Apple Hesap Bağlama Bölümü
          SizedBox(
            width: double.infinity,
            child: game.isLoggedIn
                ? OutlinedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      await game.logout();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Hesaptan çıkış yapıldı.'),
                          backgroundColor: AppTheme.amber,
                        ),
                      );
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
                            'Çıkış Yap (${game.userEmail?.isNotEmpty == true ? game.userEmail : (game.isAppleLoggedIn ? "Apple" : "Google")})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.crimson,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      //  Apple ile Giriş Yap Butonu (iOS için Apple HIG uyumlu)
                      ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          final success = await game.loginWithApple();
                          if (success) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Apple ile bağlandınız: ${game.playerName}! 🍏'),
                                backgroundColor: AppTheme.emerald,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apple, color: Colors.black, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Apple ile Giriş Yap',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 🌐 Google ile Giriş Yap Butonu
                      OutlinedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          final success = await game.loginWithGoogle();
                          if (success) {
                            messenger.showSnackBar(
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
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // Değişiklikleri Kaydet Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final newName = _nameController.text.trim();
                if (newName.isNotEmpty) {
                  game.updateProfile(newName, _selectedAvatar);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil başarıyla güncellendi!'),
                      backgroundColor: AppTheme.emerald,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Değişiklikleri Kaydet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
