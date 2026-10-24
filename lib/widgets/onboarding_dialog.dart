import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompleted = prefs.getBool('has_completed_onboarding') ?? false;
    if (!hasCompleted && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const OnboardingDialog(),
      );
    }
  }

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': '🎧',
      'tag': 'CANLI DÜELLO',
      'title': 'Sahne Senin\'e Hoş Geldin!',
      'desc': 'Türkiye\'nin en heyecanlı canlı müzik yarışması!\nŞarkıyı ilk saniyede dinle, rakiplerinden daha hızlı bil ve sahnenin yıldızı ol.',
      'color': AppTheme.amber,
    },
    {
      'icon': '🔥',
      'tag': 'KOMBO ÇARPANI',
      'title': 'Alevli Komboları Patlat!',
      'desc': 'Peş peşe doğru basarak 2x, 3x ve 4x serileri yakala!\nHer kombo maç sonunda sana ekstra skor bonusu ve zafer getirir.',
      'color': Color(0xFFEA580C),
    },
    {
      'icon': '🎁',
      'tag': 'HOŞ GELDİN PAKETİ',
      'title': 'Başlangıç Hediyen Hazır!',
      'desc': 'Haftalık liglerde yarış, arkadaşlarınla parti odaları kur!\nSahneye fırtına gibi başlaman için ilk hediyen bizden:',
      'color': AppTheme.emerald,
      'isFinal': true,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _claimAndFinish();
    }
  }

  Future<void> _claimAndFinish() async {
    HapticFeedback.heavyImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);

    if (mounted) {
      final game = context.read<GameProvider>();
      game.claimWelcomeGift(coins: 500, jokers: 1);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
          content: const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hoş geldin! +500 Altın ve +1 Joker hesabına yüklendi.',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 540),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final s = _slides[index];
                  final isFinal = s['isFinal'] == true;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // İkon Rozeti
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (s['color'] as Color).withValues(alpha: 0.15),
                            border: Border.all(color: (s['color'] as Color).withValues(alpha: 0.4), width: 2),
                          ),
                          child: Center(
                            child: Text(s['icon'] as String, style: const TextStyle(fontSize: 42)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Etiket
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (s['color'] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            s['tag'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: s['color'] as Color,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Başlık
                        Text(
                          s['title'] as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Açıklama
                        Text(
                          s['desc'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        if (isFinal) ...[
                          const SizedBox(height: 20),
                          // Hediye Kartı
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Text('🪙', style: TextStyle(fontSize: 22)),
                                    SizedBox(width: 8),
                                    Text(
                                      '+500 Altın',
                                      style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.amber, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Text('|', style: TextStyle(color: AppTheme.border, fontSize: 18)),
                                Row(
                                  children: [
                                    Text('🎯', style: TextStyle(fontSize: 22)),
                                    SizedBox(width: 8),
                                    Text(
                                      '+1 Joker',
                                      style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.emerald, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Alt Bar: Nokta Göstergeleri & Buton
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Sayfa Göstergeleri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? AppTheme.amber : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Aksiyon Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage == _slides.length - 1 ? AppTheme.emerald : AppTheme.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'Hediyemi Al & Başla! 🚀' : 'Devam Et ➔',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
