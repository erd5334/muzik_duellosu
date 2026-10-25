import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class PartyDialog extends StatefulWidget {
  const PartyDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PartyDialog(),
    );
  }

  @override
  State<PartyDialog> createState() => _PartyDialogState();
}

class _PartyDialogState extends State<PartyDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pinController = TextEditingController();

  MusicCategory _selectedCategory = MusicCategory.defaultCategories[0];
  int _selectedRounds = 5;
  int _selectedDuration = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final categories = game.categories;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('👥', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Çok Kişilik Parti Modu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Arkadaş grubunla 3 ila 8 kişi canlı yarış!',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tab Bar (Oda Kur / Odaya Katıl)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppTheme.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              tabs: const [
                Tab(text: '🎉 Parti Odası Kur'),
                Tab(text: '🔑 Odaya Katıl (PIN)'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreateRoomTab(categories, game),
                _buildJoinRoomTab(game),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCreateRoomTab(List<MusicCategory> categories, GameProvider game) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1. Müzik Kategorisi Seç:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = categories[i];
                final isSelected = _selectedCategory.id == cat.id;
                return ChoiceChip(
                  avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.black : cat.badgeColor),
                  label: Text(cat.title),
                  selected: isSelected,
                  selectedColor: AppTheme.amber,
                  backgroundColor: AppTheme.surfaceLight,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          const Text('2. Şarkı (Tur) Sayısı:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [5, 7, 10].map((rounds) {
              final isSelected = _selectedRounds == rounds;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selectedRounds = rounds),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? AppTheme.amber.withValues(alpha: 0.15) : AppTheme.surfaceLight,
                      side: BorderSide(color: isSelected ? AppTheme.amber : AppTheme.borderSubtle, width: isSelected ? 2 : 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      '$rounds Tur',
                      style: TextStyle(
                        color: isSelected ? AppTheme.amber : AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          const Text('3. Soru Başına Süre:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [7, 10, 15].map((sec) {
              final isSelected = _selectedDuration == sec;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selectedDuration = sec),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? AppTheme.amber.withValues(alpha: 0.15) : AppTheme.surfaceLight,
                      side: BorderSide(color: isSelected ? AppTheme.amber : AppTheme.borderSubtle, width: isSelected ? 2 : 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      '$sec Saniye',
                      style: TextStyle(
                        color: isSelected ? AppTheme.amber : AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Buton: Parti Odasını Kur
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                game.createPartyRoom(
                  category: _selectedCategory,
                  roundCount: _selectedRounds,
                  durationSec: _selectedDuration,
                );
              },
              icon: const Icon(Icons.celebration_rounded, color: Colors.black),
              label: const Text(
                'Parti Odasını Aç & Arkadaşları Çağır',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.amber,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRoomTab(GameProvider game) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Arkadaşının kurduğu odanın 4 haneli PIN kodunu gir:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        // PIN Giriş Alanı
        SizedBox(
          width: 220,
          child: TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            maxLength: 4,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 12,
              color: AppTheme.amber,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onChanged: (val) {
              if (val.trim().length == 4) {
                FocusScope.of(context).unfocus();
              }
            },
            onSubmitted: (code) {
              FocusScope.of(context).unfocus();
              if (code.trim().length == 4) {
                Navigator.pop(context);
                game.joinPartyRoom(code.trim());
              }
            },
            decoration: InputDecoration(
              counterText: '',
              hintText: '0000',
              hintStyle: TextStyle(
                fontSize: 32,
                letterSpacing: 12,
                color: AppTheme.textMuted.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.amber, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              FocusScope.of(context).unfocus();
              final code = _pinController.text.trim();
              if (code.length == 4) {
                Navigator.pop(context);
                game.joinPartyRoom(code);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen 4 haneli geçerli oda kodunu girin!')),
                );
              }
            },
            icon: const Icon(Icons.login_rounded, color: Colors.black),
            label: const Text(
              'Odaya Katıl',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.amber,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}
