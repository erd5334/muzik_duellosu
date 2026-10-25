import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class FriendDuelDialog extends StatefulWidget {
  const FriendDuelDialog({super.key});

  @override
  State<FriendDuelDialog> createState() => _FriendDuelDialogState();
}

class _FriendDuelDialogState extends State<FriendDuelDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();

  List<MusicCategory> _categories = MusicCategory.defaultCategories;
  late MusicCategory _selectedCategory;
  int _selectedRounds = 10; // Varsayılan 10, istenirse 20!
  int _selectedDuration = 10; // 10 veya 15 saniye

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final game = Provider.of<GameProvider>(context, listen: false);
    if (game.categories.isNotEmpty) {
      _categories = game.categories;
    }
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.border, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.group_rounded, color: AppTheme.amber, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Arkadaşla Oyna',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sekmeler (Oda Kur / Koda Katıl)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppTheme.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                tabs: const [
                  Tab(text: 'Özel Oda Kur'),
                  Tab(text: 'Koda Katıl'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(
              height: 310,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. ÖZEL ODA KUR (Ayar Seçenekleri)
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori Seçimi
                        const Text('Kategori', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<MusicCategory>(
                              value: _selectedCategory,
                              dropdownColor: AppTheme.surfaceLight,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.amber),
                              items: _categories.map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Tur Sayısı (Kaçta Bitsin?)
                        const Text('Tur Sayısı (Kaçta Bitsin?)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [5, 10, 15, 20].map((rounds) {
                            final isSel = _selectedRounds == rounds;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => setState(() => _selectedRounds = rounds),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSel ? AppTheme.amber : AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isSel ? AppTheme.amber : AppTheme.border),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$rounds Tur',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isSel ? Colors.black : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Süre Seçimi
                        const Text('Soru Başına Süre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDurationOption(10, '10 Saniye (Standart)'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDurationOption(15, '15 Saniye (Rahat)'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Oda Oluştur Butonu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              game.createCustomRoom(
                                category: _selectedCategory,
                                roundCount: _selectedRounds,
                                durationSec: _selectedDuration,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Odayı Aç ($_selectedRounds Tur)',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. KODA KATIL
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Arkadaşının verdiği 4 haneli oda kodunu gir:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 180,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.amber, width: 1.5),
                        ),
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white),
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
                              game.joinCustomRoom(code.trim());
                            }
                          },
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: '4821',
                            hintStyle: TextStyle(color: AppTheme.textMuted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            final code = _codeController.text.trim();
                            if (code.length == 4) {
                              Navigator.pop(context);
                              game.joinCustomRoom(code);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lütfen 4 haneli geçerli bir kod girin!')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Odaya Katıl & Başla', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildDurationOption(int duration, String label) {
    final isSel = _selectedDuration == duration;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _selectedDuration = duration),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.amber : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSel ? AppTheme.amber : AppTheme.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSel ? Colors.black : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
