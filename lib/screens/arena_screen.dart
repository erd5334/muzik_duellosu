import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/vinyl_record.dart';
import '../widgets/waveform_visualizer.dart';
import '../widgets/tactile_choice_button.dart';

class ArenaScreen extends StatelessWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final question = game.currentQuestion;

    if (question == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.amber)),
      );
    }

    final roundNum = game.currentRoundIndex + 1;
    final totalRounds = game.totalMatchRounds;
    final opponent = game.opponent;
    final maxMs = game.roundDurationSec * 1000;
    final currentScorePotential = ((game.remainingMs / maxMs) * 950 + 50).toInt();

    String? userStatus;
    Color? userStatusColor;
    if (question.isAnswered) {
      final isUserCorrect = question.selectedOptionIndex == question.correctOptionIndex;
      userStatus = isUserCorrect ? '+${question.userScoreEarned}' : '0';
      userStatusColor = isUserCorrect ? AppTheme.emerald : AppTheme.crimson;
    }

    String? oppStatus;
    Color? oppStatusColor;
    if (question.opponentHasAnswered) {
      if (question.isAnswered || game.status == GameStatus.roundResult) {
        final isOppCorrect = question.isOpponentCorrect == true || question.opponentSelectedOptionIndex == question.correctOptionIndex;
        oppStatus = isOppCorrect ? '+${question.opponentScoreEarned}' : '0';
        oppStatusColor = isOppCorrect ? AppTheme.emerald : AppTheme.crimson;
      } else {
        oppStatus = '⚡ Cevapladı';
        oppStatusColor = AppTheme.amber;
      }
    } else {
      oppStatus = 'Düşünüyor';
      oppStatusColor = AppTheme.textMuted;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(game.selectedCategory?.title ?? 'Şarkıyı Bil Bakalım'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
            onPressed: () => _showExitDialog(context, game),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscapeOrShort = constraints.maxHeight < 640 || constraints.maxWidth > constraints.maxHeight * 1.15;

            return Column(
              children: [
                // 1. Üst Skor & Karşılaşma Barı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        _buildPlayerBadge(
                          name: game.playerName,
                          avatar: game.playerAvatar,
                          score: game.userTotalScore,
                          isLeft: true,
                          statusText: userStatus,
                          statusColor: userStatusColor,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.borderSubtle),
                                ),
                                child: Text(
                                  'TUR $roundNum / $totalRounds',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.amber,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              WaveformVisualizer(
                                isPlaying: game.isAudioPlaying,
                                barCount: 7,
                                height: 14,
                              ),
                            ],
                          ),
                        ),
                        _buildPlayerBadge(
                          name: opponent?.name ?? 'Rakip',
                          avatar: opponent?.avatar ?? '🎸',
                          score: game.opponentTotalScore,
                          isLeft: false,
                          statusText: oppStatus,
                          statusColor: oppStatusColor,
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Zaman Sayacı (Hız Çubuğu)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: game.timerProgress,
                          minHeight: 5,
                          backgroundColor: AppTheme.surfaceLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            game.timerProgress > 0.35 ? AppTheme.amber : AppTheme.crimson,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kalan: ${(game.remainingMs / 1000).toStringAsFixed(1)}s',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          if (game.status == GameStatus.playing)
                            Text(
                              '⚡ Hız Bonusu: +$currentScorePotential Puan',
                              style: const TextStyle(fontSize: 11, color: AppTheme.amber, fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. İçerik Alanı (Yatay veya Dikey Adaptif)
                Expanded(
                  child: isLandscapeOrShort
                      ? _buildLandscapeLayout(context, game, question, constraints)
                      : _buildPortraitLayout(context, game, question, constraints),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Yatay veya Kısa Ekranlar İçin 2 Sütunlu Taşmayan Düzen (MuMu Player / Web)
  Widget _buildLandscapeLayout(
    BuildContext context,
    GameProvider game,
    dynamic question,
    BoxConstraints constraints,
  ) {
    final vinylSize = min(130.0, constraints.maxHeight * 0.36);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sol Sütun: Plak & Bilgiler & Joker
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VinylRecord(
                    isPlaying: game.isAudioPlaying,
                    artworkUrl: (question.isAnswered || game.status == GameStatus.roundResult)
                        ? question.song.artworkUrl
                        : null,
                    size: vinylSize,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      question.promptText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (question.isAnswered) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${question.song.title} • ${question.song.artist}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildPowerUpButton(game, question),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Sağ Sütun: 4 Seçenek Butonu
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: _buildChoiceButton(game, question, index, isCompact: true),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Standart Telefonlar İçin Dikey Düzen
  Widget _buildPortraitLayout(
    BuildContext context,
    GameProvider game,
    dynamic question,
    BoxConstraints constraints,
  ) {
    return Column(
      children: [
        // Orta Alan: Plak & Soru
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              VinylRecord(
                isPlaying: game.isAudioPlaying,
                artworkUrl: (question.isAnswered || game.status == GameStatus.roundResult)
                    ? question.song.artworkUrl
                    : null,
                size: min(150.0, constraints.maxHeight * 0.26),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  question.promptText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (question.isAnswered) ...[
                const SizedBox(height: 6),
                Text(
                  '${question.song.title} • ${question.song.artist}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Alt Alan: 4 Seçenek
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildChoiceButton(game, question, index, isCompact: false),
              );
            }),
          ),
        ),

        // Joker Butonu
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildPowerUpButton(game, question),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAvatar(String avatar) {
    if (avatar.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: 14,
          height: 14,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Text('🎸', style: TextStyle(fontSize: 10)),
        ),
      );
    }
    return Text(avatar, style: const TextStyle(fontSize: 10));
  }

  Widget _buildChoiceButton(GameProvider game, dynamic question, int index, {required bool isCompact}) {
    final labels = ['A', 'B', 'C', 'D'];
    final optionText = question.options[index];
    final isEliminated = question.eliminatedOptions.contains(index);
    final isSelected = question.selectedOptionIndex == index;
    final isCorrect = question.correctOptionIndex == index;
    final showResult = question.isAnswered || game.status == GameStatus.roundResult;

    // Rakibin seçimi göstergesi
    Widget? opponentBadge;
    if (question.opponentHasAnswered && question.opponentSelectedOptionIndex == index) {
      final oppAvatar = game.opponent?.avatar ?? '🎸';
      if (showResult) {
        final isOppCorrect = question.isOpponentCorrect == true || index == question.correctOptionIndex;
        final color = isOppCorrect ? AppTheme.emerald : AppTheme.crimson;
        opponentBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniAvatar(oppAvatar),
              const SizedBox(width: 4),
              Text(
                isOppCorrect ? '✔' : '✘',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        );
      } else {
        opponentBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniAvatar(oppAvatar),
              const SizedBox(width: 4),
              const Text(
                'Rakip',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.amber),
              ),
            ],
          ),
        );
      }
    }

    return TactileChoiceButton(
      label: labels[index],
      text: optionText,
      isCompact: isCompact,
      isEliminated: isEliminated,
      isSelected: isSelected,
      isCorrect: isCorrect,
      showResult: showResult,
      opponentBadge: opponentBadge,
      onTap: () => game.answerQuestion(index),
    );
  }

  Widget _buildPowerUpButton(GameProvider game, dynamic question) {
    return OutlinedButton.icon(
      onPressed: (question.isAnswered ||
              game.powerUp5050Count <= 0 ||
              question.eliminatedOptions.isNotEmpty)
          ? null
          : () => game.use5050PowerUp(),
      icon: const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.amber),
      label: Text(
        '50/50 Jokeri (${game.powerUp5050Count})',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.border),
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  Widget _buildPlayerBadge({
    required String name,
    required String avatar,
    required int score,
    required bool isLeft,
    String? statusText,
    Color? statusColor,
  }) {
    return Row(
      children: [
        if (isLeft) ...[
          CircleAvatar(
            backgroundColor: AppTheme.surfaceLight,
            radius: 16,
            child: avatar.startsWith('http')
                ? ClipOval(
                    child: Image.network(
                      avatar,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Text('🎧', style: TextStyle(fontSize: 16)),
                    ),
                  )
                : Text(avatar, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isLeft && statusText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: (statusColor ?? AppTheme.textMuted).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: (statusColor ?? AppTheme.textMuted).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor ?? AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (isLeft && statusText != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: (statusColor ?? AppTheme.textMuted).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: (statusColor ?? AppTheme.textMuted).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor ?? AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        if (!isLeft) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.surfaceLight,
            radius: 16,
            child: avatar.startsWith('http')
                ? ClipOval(
                    child: Image.network(
                      avatar,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Text('🎸', style: TextStyle(fontSize: 16)),
                    ),
                  )
                : Text(avatar, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ],
    );
  }

  void _showExitDialog(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Düellodan Çıkılsın mı?'),
        content: const Text('Maçtan çıkarsanız bu düello yenilgi sayılacaktır.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Devam Et', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              game.resetToHome();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            child: const Text('Çık', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
