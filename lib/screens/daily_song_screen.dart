import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/daily_song_model.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class DailySongScreen extends StatefulWidget {
  const DailySongScreen({super.key});

  @override
  State<DailySongScreen> createState() => _DailySongScreenState();
}

class _DailySongScreenState extends State<DailySongScreen> {
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
    StreamSubscription? _posSub;
  StreamSubscription? _stateSub;
  Timer? _stopTimer;

  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  void _initAudio() {
    _posSub = _player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
      });

      final game = context.read<GameProvider>();
      final progress = game.dailySongProgress;
      if (progress != null && !progress.isCompleted) {
        final maxSec = progress.unlockedSeconds;
        if (pos.inMilliseconds >= (maxSec * 1000).toInt()) {
          _player.pause();
          _stopTimer?.cancel();
          setState(() {
            _isPlaying = false;
            _currentPosition = Duration.zero;
          });
        }
      }
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    _posSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _togglePlay(GameProvider game) async {
    final data = game.dailySongData;
    final progress = game.dailySongProgress;
    if (data == null || progress == null) return;

    if (_isPlaying) {
      await _player.pause();
      _stopTimer?.cancel();
      setState(() {
        _isPlaying = false;
      });
    } else {
      final previewUrl = data.song.previewUrl;
      if (previewUrl.isEmpty) return;

      final limitSec = progress.isCompleted && progress.isWon ? 30.0 : progress.unlockedSeconds;
      await _player.stop();
      await _player.play(UrlSource(previewUrl));

      _stopTimer?.cancel();
      _stopTimer = Timer(Duration(milliseconds: (limitSec * 1000).toInt()), () async {
        if (!mounted) return;
        await _player.pause();
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      });

      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _filterSuggestions(String query, List<String> pool) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final lower = query.toLowerCase().trim();
    final results = pool.where((s) => s.toLowerCase().contains(lower)).take(6).toList();

    setState(() {
      _filteredSuggestions = results;
      _showSuggestions = results.isNotEmpty;
    });
  }

  void _onGuessSubmit(GameProvider game) async {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;

    _searchFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
      _searchController.clear();
    });

    final isCorrect = await game.submitDailySongGuess(text);
    if (!mounted) return;

    if (isCorrect) {
      _player.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.emerald,
          content: Text('🎉 DOĞRU TAHMİN! Günün Şarkısını bildin!'),
        ),
      );
    }
  }

  void _onSkip(GameProvider game) async {
    _searchFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
      _searchController.clear();
    });

    await game.skipDailySongStep();
  }

  void _shareResult(DailySongData data, DailySongProgress progress, int streak) {
    final stepText = progress.isWon ? '${progress.solvedStep}. denemede bildim!' : 'Bugün bilemedim';
    final shareText = '''🎵 Sahne Senin - Günün Şarkısı #${data.dayNumber}
${progress.emojiSummary} ($stepText)
🔥 $streak Günlük Seri
Sen de bil: sahnesenin.com''';

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Skorun panoya kopyalandı! WhatsApp veya Instagram Story\'de paylaşabilirsin 📲',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final data = game.dailySongData;
    final progress = game.dailySongProgress;

    if (data == null || progress == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.amber),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            _player.stop();
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              'GÜNÜN ŞARKISI #${data.dayNumber}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '${game.dailyStreak}',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFF87171), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: [
                  // 1. Kademeli Dinleme Barı (Stepped Segmented Bar)
                  _buildSegmentedAudioBar(progress),
                  const SizedBox(height: 12),

                  // 2. Play / Pause Butonu & Süre Bilgisi
                  _buildAudioControl(game, data, progress),
                  const SizedBox(height: 14),

                  // 3. 6 Deneme Listesi (Attempts Grid)
                  Expanded(
                    child: _buildAttemptsList(progress, data),
                  ),

                  // 4. Sonuç veya Giriş Bölümü
                  if (progress.isCompleted)
                    _buildCompletedBanner(game, data, progress)
                  else
                    _buildGuessInputSection(game, data),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedAudioBar(DailySongProgress progress) {
    const steps = DailySongProgress.stepSeconds;
    final maxLimit = progress.unlockedSeconds;

    return Column(
      children: [
        Row(
          children: List.generate(steps.length, (idx) {
            final sec = steps[idx];
            final isUnlocked = sec <= maxLimit || progress.isCompleted;
            final isCurrent = idx == progress.currentStep && !progress.isCompleted;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: isCurrent
                      ? AppTheme.amber
                      : (isUnlocked ? const Color(0xFF10B981) : AppTheme.surfaceLight),
                  border: Border.all(
                    color: isCurrent ? AppTheme.amber : Colors.white10,
                    width: 1,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Çalıyor: ${_currentPosition.inSeconds} sn / ${progress.unlockedSeconds.toStringAsFixed(0)} sn',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.amber),
            ),
            const Text(
              'Toplam 16 sn',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudioControl(GameProvider game, DailySongData data, DailySongProgress progress) {
    return GestureDetector(
      onTap: () => _togglePlay(game),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.amber.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 38,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildAttemptsList(DailySongProgress progress, DailySongData data) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: DailySongProgress.maxAttempts,
      itemBuilder: (ctx, idx) {
        final hasAttempt = idx < progress.attempts.length;
        final attempt = hasAttempt ? progress.attempts[idx] : null;
        final isCurrent = idx == progress.currentStep && !progress.isCompleted;

        Color borderColor = AppTheme.border;
        Color bgColor = AppTheme.surfaceLight;
        Widget leadingIcon;

        if (attempt != null) {
          if (attempt.isCorrect) {
            borderColor = AppTheme.emerald;
            bgColor = AppTheme.emerald.withValues(alpha: 0.15);
            leadingIcon = const Text('🟩', style: TextStyle(fontSize: 16));
          } else if (attempt.isSkipped) {
            borderColor = Colors.white24;
            bgColor = Colors.white.withValues(alpha: 0.05);
            leadingIcon = const Text('⬛', style: TextStyle(fontSize: 16));
          } else {
            borderColor = AppTheme.crimson;
            bgColor = AppTheme.crimson.withValues(alpha: 0.15);
            leadingIcon = const Text('🟥', style: TextStyle(fontSize: 16));
          }
        } else if (isCurrent) {
          borderColor = AppTheme.amber;
          bgColor = AppTheme.amber.withValues(alpha: 0.08);
          leadingIcon = const Text('▶️', style: TextStyle(fontSize: 14));
        } else {
          leadingIcon = const Text('⚪', style: TextStyle(fontSize: 12));
        }

        String displayText;
        if (attempt != null) {
          displayText = attempt.isSkipped ? 'Pas Geçildi (+Süre Açıldı)' : (attempt.guess ?? '');
        } else if (isCurrent) {
          displayText = '${DailySongProgress.stepSeconds[idx].toStringAsFixed(0)} sn dinleyip tahmin et...';
        } else {
          displayText = 'Kilitli (+${DailySongProgress.stepSeconds[idx].toStringAsFixed(0)} sn)';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1.0),
          ),
          child: Row(
            children: [
              leadingIcon,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: attempt != null ? FontWeight.w800 : FontWeight.w500,
                    color: attempt != null
                        ? (attempt.isCorrect ? Colors.white : (attempt.isSkipped ? AppTheme.textMuted : const Color(0xFFFCA5A5)))
                        : (isCurrent ? Colors.white : AppTheme.textMuted),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuessInputSection(GameProvider game, DailySongData data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arama Önerileri Dropdown Listesi
        if (_showSuggestions && _filteredSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filteredSuggestions.length,
              separatorBuilder: (ctx, i) => const Divider(color: AppTheme.border, height: 1),
              itemBuilder: (ctx, i) {
                final suggestion = _filteredSuggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Text('🎵', style: TextStyle(fontSize: 14)),
                  title: Text(
                    suggestion,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  onTap: () {
                    _searchController.text = suggestion;
                    setState(() {
                      _showSuggestions = false;
                    });
                  },
                );
              },
            ),
          ),

        // Metin Girişi
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Şarkı veya sanatçı adı ara...',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.amber, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterSuggestions('', data.searchPool);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) => _filterSuggestions(val, data.searchPool),
            onSubmitted: (_) => _onGuessSubmit(game),
          ),
        ),
        const SizedBox(height: 10),

        // Butonlar: Pas Geç & Tahmin Et
        Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                onPressed: () => _onSkip(game),
                icon: const Icon(Icons.skip_next_rounded, size: 18, color: AppTheme.textSecondary),
                label: const Text('Pas Geç', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: ElevatedButton.icon(
                onPressed: () => _onGuessSubmit(game),
                icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.black),
                label: const Text('Tahmin Et', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.amber,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedBanner(GameProvider game, DailySongData data, DailySongProgress progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: progress.isWon ? AppTheme.emerald : AppTheme.crimson,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  data.song.artworkUrl,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 58,
                    height: 58,
                    color: AppTheme.surfaceLight,
                    child: const Icon(Icons.music_note, color: AppTheme.amber),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.isWon
                          ? '🎉 ${progress.solvedStep}. Saniyede Bildin!'
                          : '😔 Bugün Şansın Yaver Gitmedi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: progress.isWon ? AppTheme.emerald : const Color(0xFFF87171),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.song.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      data.song.artist,
                      style: const TextStyle(fontSize: 12, color: AppTheme.amber, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ödül Rozetleri
          if (progress.isWon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text('⚡ +250 XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.amber)),
                  Text('🪙 +150 Altın', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('✨ +3 Joker', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA78BFA))),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Paylaş Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _shareResult(data, progress, game.dailyStreak),
              icon: const Icon(Icons.share_rounded, size: 18, color: Colors.black),
              label: const Text('📲 Sonucu Paylaş (Viral)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emerald,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
