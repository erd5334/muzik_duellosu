import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/party_room.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class PartyLobbyScreen extends StatelessWidget {
  const PartyLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final room = game.partyRoom;
    final players = game.partyPlayers;
    final isHost = game.isPartyHost;
    final canStart = players.length >= 2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showLeaveDialog(context, game);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('🎉 Parti Odası'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
              onPressed: () => _showLeaveDialog(context, game),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    // 1. PIN Kodu Hero Kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.surface,
                            AppTheme.surfaceLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.amber.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ODA PIN KODU',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.amber,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '#${room?.roomCode ?? "----"}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Kopyala Butonu
                              OutlinedButton.icon(
                                onPressed: () {
                                  if (room != null) {
                                    Clipboard.setData(ClipboardData(text: room.roomCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('PIN #${room.roomCode} kopyalandı! Arkadaşlarına gönder.'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.amber),
                                label: const Text(
                                  'Kopyala',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.amber, fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.amber),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Kural / Ayar Bilgi Şeridi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.music_note_rounded, size: 16, color: AppTheme.amber),
                              const SizedBox(width: 6),
                              Text(
                                game.selectedCategory?.title ?? '90\'lar Pop',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 16, color: AppTheme.borderSubtle),
                          Row(
                            children: [
                              const Icon(Icons.repeat_rounded, size: 16, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 6),
                              Text(
                                '${room?.roundCount ?? 5} Tur',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 16, color: AppTheme.borderSubtle),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 6),
                              Text(
                                '${room?.roundDurationSec ?? 10} sn / soru',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. Oyuncular Başlığı
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Oyuncular (${players.length} / 8)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        if (!canStart)
                          const Text(
                            'En az 2 oyuncu gerekiyor',
                            style: TextStyle(fontSize: 11, color: AppTheme.amber, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 4. Oyuncular Izgarası (Grid)
                    Expanded(
                      child: GridView.builder(
                        itemCount: 8,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 4 : 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (ctx, i) {
                          if (i < players.length) {
                            final p = players[i];
                            return _buildPlayerCard(p);
                          } else {
                            return _buildEmptySlotCard(i + 1);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: Container(
          color: AppTheme.surface,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
              ),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () => _showLeaveDialog(context, game),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ayrıl', style: TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isHost
                      ? ElevatedButton.icon(
                          onPressed: canStart ? () => game.startPartyGame() : null,
                          icon: const Icon(Icons.rocket_launch_rounded, color: Colors.black),
                          label: Text(
                            canStart ? 'Partiyi Başlat (${players.length} Oyuncu)' : 'Oyuncular Bekleniyor...',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canStart ? AppTheme.amber : AppTheme.surfaceLight,
                            disabledBackgroundColor: AppTheme.surfaceLight,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: const Center(
                            child: Text(
                              'Kurucunun oyunu başlatması bekleniyor... ⏳',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(PartyPlayer player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: player.isHost ? AppTheme.amber.withValues(alpha: 0.6) : AppTheme.borderSubtle,
          width: player.isHost ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.surfaceLight,
            child: player.avatar.startsWith('http')
                ? ClipOval(
                    child: Image.network(
                      player.avatar,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Text('🎧', style: TextStyle(fontSize: 16)),
                    ),
                  )
                : Text(player.avatar, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (player.isHost)
                  const Row(
                    children: [
                      Text('👑 ', style: TextStyle(fontSize: 10)),
                      Text(
                        'Oda Kurucusu',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.amber,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Hazır',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.emerald,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlotCard(int slotNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.surfaceLight.withValues(alpha: 0.3),
            child: Text(
              '$slotNumber',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Oyuncu Bekleniyor...',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Parti Odasından Çıkılsın mı?'),
        content: const Text('Oda oturumunuz sonlandırılacak ve ana menüye döneceksiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              game.leavePartyRoom();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            child: const Text('Ayrıl', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
