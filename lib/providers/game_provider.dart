import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/category_model.dart';
import '../models/collection_badge.dart';
import '../models/duel_question.dart';
import '../models/song.dart';
import '../models/store_item.dart';
import '../models/player_stats.dart';
import '../models/season_pass_model.dart';
import 'package:http/http.dart' as http;
import '../services/music_api_service.dart';
import '../services/auth_service.dart';
import '../services/purchase_service.dart';

enum GameStatus {
  idle,
  searchingOpponent,
  waitingFriendInRoom, // Özel oda açıldı, arkadaş bekleniyor
  opponentFound,
  roundIntro,
  playing,
  roundResult,
  matchOver,
  error,
}

class Opponent {
  final String name;
  final String city;
  final String avatar;
  final int level;

  const Opponent({
    required this.name,
    required this.city,
    required this.avatar,
    this.level = 10,
  });
}

class GameProvider extends ChangeNotifier with WidgetsBindingObserver {
  final MusicApiService _apiService = MusicApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _rnd = Random();

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _pingTimer;

  GameStatus _status = GameStatus.idle;
  GameStatus get status => _status;

  MusicCategory? _selectedCategory;
  MusicCategory? get selectedCategory => _selectedCategory;

  List<MusicCategory> _categories = List.from(MusicCategory.defaultCategories);
  List<MusicCategory> get categories => _categories;

  Opponent? _opponent;
  Opponent? get opponent => _opponent;

  List<DuelQuestion> _questions = [];
  List<DuelQuestion> get questions => _questions;

  int _currentRoundIndex = 0;
  int get currentRoundIndex => _currentRoundIndex;
  DuelQuestion? _currentQuestion;
  DuelQuestion? get currentQuestion => _currentQuestion;

  int _totalMatchRounds = 5;
  int get totalMatchRounds => _totalMatchRounds;

  int _roundDurationSec = 10;
  int get roundDurationSec => _roundDurationSec;

  int _userTotalScore = 0;
  int get userTotalScore => _userTotalScore;

  int _opponentTotalScore = 0;
  int get opponentTotalScore => _opponentTotalScore;

  int _remainingMs = 10000;
  int get remainingMs => _remainingMs;
  double get timerProgress => (_remainingMs / (_roundDurationSec * 1000)).clamp(0.0, 1.0);

  Timer? _countdownTimer;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isAudioPlaying = false;
  bool get isAudioPlaying => _isAudioPlaying;

  int powerUp5050Count = 2;
  bool _isMultiplayer = false;
  bool get isMultiplayer => _isMultiplayer;

  // Özel Oda Bilgileri
  String? _createdRoomCode;
  String? get createdRoomCode => _createdRoomCode;
  bool _isCustomRoom = false;
  bool get isCustomRoom => _isCustomRoom;

  // Profil
  String _customPlayerName = kIsWeb ? 'Web Oyuncusu' : 'MuMu Android';
  String get playerName => _customPlayerName;
  String _customAvatar = kIsWeb ? '💻' : '📱';
  String get playerAvatar => _customAvatar;
  String? _googleUserId;
  String? get googleUserId => _googleUserId;
  String? _googleUserEmail;
  String? get googleUserEmail => _googleUserEmail;

  // Ekonomi & Enerji Sistemi
  int _energy = 10;
  int get energy => _energy;
  static const int maxEnergy = 10;
  static const int energyRegenIntervalMinutes = 12; // 1 enerji 12 dakikada dolar (1 saatte 5 enerji)
  int _minutesUntilNextEnergy = energyRegenIntervalMinutes;
  int get minutesUntilNextEnergy => _minutesUntilNextEnergy;
  int _lastEnergyTimestamp = 0;
  Timer? _energyTimer;

  int _coins = 350;
  int get coins => _coins;

  int _dailyAdsWatchedForEnergy = 0;
  int get dailyAdsWatchedForEnergy => _dailyAdsWatchedForEnergy;
  static const int maxDailyAdsForEnergy = 2;

  bool _hasNoAds = false;
  bool get hasNoAds => _hasNoAds;

  bool _isVip = false;
  bool get isVip => _isVip;

  // Son Maçta Kazanılan Ödüller
  int _lastEarnedCoins = 0;
  int get lastEarnedCoins => _lastEarnedCoins;
  int _lastEarnedShards = 0;
  int get lastEarnedShards => _lastEarnedShards;
  int _lastEarnedXp = 0;
  int get lastEarnedXp => _lastEarnedXp;
  String? _lastRewardedBadgeName;
  String? get lastRewardedBadgeName => _lastRewardedBadgeName;

  List<CollectionBadge> _badges = List.from(CollectionBadge.defaultBadges);
  List<CollectionBadge> get badges => _badges;

  // Kariyer & Detaylı İstatistikler
  PlayerStats _playerStats = PlayerStats();
  PlayerStats get playerStats => _playerStats;

  // Sezon Bileti & Görev Sistemi (Müzik Pass)
  SeasonPassData _seasonPass = SeasonPassData(
    seasonId: 'season_1',
    seasonName: "Sezon 1: 90'lar Fırtınası",
    endDate: DateTime.now().add(const Duration(days: 28)),
    tiers: SeasonPassData.defaultTiers,
    missions: SeasonPassData.defaultMissions,
  );
  SeasonPassData get seasonPass => _seasonPass;

  // Uzaktan Yönetilen Mağaza Paketleri
  List<StoreItem> _storeItems = List.from(StoreItem.defaultItems);
  List<StoreItem> get storeItems => _storeItems;
  List<StoreItem> get inAppStoreItems => _storeItems.where((i) => i.isInApp && i.isActive).toList();
  List<StoreItem> get inGameStoreItems => _storeItems.where((i) => i.isInGame && i.isActive).toList();
  StoreItem? getStoreItem(String id) => _storeItems.where((i) => i.id == id).firstOrNull;

  // Sıfır Gecikmeli Ses Önbelleği (RAM'de BytesSource olarak tutulur)
  final Map<String, Uint8List> _audioCache = {};
  final Set<String> _pendingAudioFetches = {};

  Future<void> preloadSong(String url) async {
    if (url.isEmpty || _audioCache.containsKey(url) || _pendingAudioFetches.contains(url)) return;
    if (!kIsWeb && Platform.isIOS) {
      // iOS'ta audioplayers paketi setSourceBytes desteklemez; doğrudan AVPlayer CDN akışı kullanılır.
      return;
    }
    _pendingAudioFetches.add(url);
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _audioCache[url] = res.bodyBytes;
        debugPrint('⚡ [SES ÖN-YÜKLENDİ] ${res.bodyBytes.lengthInBytes} bayt RAM\'e alındı: $url');
      }
    } catch (e) {
      debugPrint('⚠️ [SES ÖN-YÜKLEME UYARISI] $url: $e');
    } finally {
      _pendingAudioFetches.remove(url);
    }
  }

  void _calculateEnergyRecovery() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_energy >= maxEnergy) {
      _minutesUntilNextEnergy = energyRegenIntervalMinutes;
      _lastEnergyTimestamp = now;
      return;
    }

    if (_lastEnergyTimestamp <= 0) {
      _lastEnergyTimestamp = now;
      _minutesUntilNextEnergy = energyRegenIntervalMinutes;
      return;
    }

    final elapsedMs = now - _lastEnergyTimestamp;
    final regenIntervalMs = energyRegenIntervalMinutes * 60 * 1000;
    final recoveredEnergy = elapsedMs ~/ regenIntervalMs;

    if (recoveredEnergy > 0) {
      final oldEnergy = _energy;
      _energy = min(maxEnergy, _energy + recoveredEnergy);
      if (_energy >= maxEnergy) {
        _minutesUntilNextEnergy = energyRegenIntervalMinutes;
        _lastEnergyTimestamp = now;
      } else {
        final remainderMs = elapsedMs % regenIntervalMs;
        final remainingMs = regenIntervalMs - remainderMs;
        _minutesUntilNextEnergy = max(1, (remainingMs / (60 * 1000)).ceil());
        _lastEnergyTimestamp = now - remainderMs;
      }
      if (_energy != oldEnergy) {
        _saveUserData();
      }
    } else {
      final remainingMs = regenIntervalMs - elapsedMs;
      _minutesUntilNextEnergy = max(1, (remainingMs / (60 * 1000)).ceil());
    }
  }

  void _initEnergyTimer() {
    _energyTimer?.cancel();
    _energyTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_energy < maxEnergy) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final regenIntervalMs = energyRegenIntervalMinutes * 60 * 1000;
        final elapsedMs = now - _lastEnergyTimestamp;
        final recovered = elapsedMs ~/ regenIntervalMs;

        if (recovered > 0) {
          _energy = min(maxEnergy, _energy + recovered);
          if (_energy >= maxEnergy) {
            _minutesUntilNextEnergy = energyRegenIntervalMinutes;
            _lastEnergyTimestamp = now;
          } else {
            final remainderMs = elapsedMs % regenIntervalMs;
            _minutesUntilNextEnergy = max(1, ((regenIntervalMs - remainderMs) / (60 * 1000)).ceil());
            _lastEnergyTimestamp = now - remainderMs;
          }
          _saveUserData();
          notifyListeners();
        } else {
          final remainingMinutes = max(1, ((regenIntervalMs - elapsedMs) / (60 * 1000)).ceil());
          if (_minutesUntilNextEnergy != remainingMinutes) {
            _minutesUntilNextEnergy = remainingMinutes;
            notifyListeners();
          }
        }
      } else {
        if (_minutesUntilNextEnergy != energyRegenIntervalMinutes) {
          _minutesUntilNextEnergy = energyRegenIntervalMinutes;
          notifyListeners();
        }
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _coins = prefs.getInt('user_coins') ?? _coins;
      _energy = prefs.getInt('user_energy') ?? _energy;
      _hasNoAds = prefs.getBool('user_has_no_ads') ?? _hasNoAds;
      _isVip = prefs.getBool('user_is_vip') ?? _isVip;
      powerUp5050Count = prefs.getInt('user_jokers') ?? powerUp5050Count;

      final savedTimestamp = prefs.getInt('last_energy_timestamp');
      if (savedTimestamp != null && savedTimestamp > 0) {
        _lastEnergyTimestamp = savedTimestamp;
        // Çevrimdışı geçen sürede biriken enerjiyi hesapla ve tamamla
        _calculateEnergyRecovery();
      } else {
        // Eski sürümde timestamp henüz kaydedilmediyse enerjiyi fulle ve zaman damgasını başlat
        _energy = maxEnergy;
        _lastEnergyTimestamp = DateTime.now().millisecondsSinceEpoch;
        _minutesUntilNextEnergy = energyRegenIntervalMinutes;
      }

      final savedName = prefs.getString('user_player_name');
      if (savedName != null && savedName.isNotEmpty) {
        _customPlayerName = savedName;
      }

      final savedAvatar = prefs.getString('user_player_avatar');
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        _customAvatar = savedAvatar;
      }

      final badgesJson = prefs.getString('user_badges_data');
      if (badgesJson != null && badgesJson.isNotEmpty) {
        try {
          final Map<String, dynamic> badgesMap = jsonDecode(badgesJson);
          for (final badge in _badges) {
            if (badgesMap.containsKey(badge.id)) {
              final data = badgesMap[badge.id] as Map<String, dynamic>;
              badge.currentShards = data['currentShards'] ?? 0;
              badge.isUnlocked = data['isUnlocked'] ?? false;
              badge.isEquipped = data['isEquipped'] ?? false;
            }
          }
        } catch (_) {}
      }

      final statsJson = prefs.getString('user_player_stats');
      if (statsJson != null && statsJson.isNotEmpty) {
        try {
          _playerStats = PlayerStats.fromJson(statsJson);
        } catch (e) {
          debugPrint('İstatistik yükleme hatası: $e');
        }
      }

      final passJson = prefs.getString('user_season_pass_data');
      if (passJson != null && passJson.isNotEmpty) {
        try {
          _seasonPass = SeasonPassData.fromJson(jsonDecode(passJson));
        } catch (e) {
          debugPrint('Season pass yükleme hatası: $e');
        }
      }

      _googleUserId = prefs.getString('user_google_id');
      _googleUserEmail = prefs.getString('user_google_email');
      notifyListeners();
      if (_googleUserId != null && _googleUserId!.isNotEmpty) {
        fetchProfileFromServer();
      }
    } catch (e) {
      debugPrint('Kullanıcı verisi yükleme hatası: $e');
    }
  }

  /// Sunucu SQLite veritabanındaki son durumu (Admin paneli & rozet ilerlemeleri dahil) çeker
  Future<void> fetchProfileFromServer() async {
    if (_googleUserId == null || _googleUserId!.isEmpty) return;
    try {
      final res = await http.get(
        Uri.parse('http://80.253.246.132:6060/api/user/profile?google_id=$_googleUserId'),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        bool changed = false;

        if (data['is_banned'] == 1) {
          _errorMessage = 'Hesabınız askıya alınmıştır: ${data['ban_reason'] ?? ''}';
          notifyListeners();
          return;
        }

        if (data.containsKey('coins')) {
          final sCoins = (data['coins'] as num).toInt();
          if (_coins != sCoins) {
            _coins = sCoins;
            changed = true;
          }
        }
        if (data.containsKey('energy')) {
          final sEnergy = (data['energy'] as num).toInt();
          if (sEnergy > _energy) {
            _energy = sEnergy;
            changed = true;
          } else if (_energy > sEnergy) {
            _saveUserData();
          }
        }
        if (data.containsKey('powerup_count')) {
          final sJokers = (data['powerup_count'] as num).toInt();
          if (powerUp5050Count != sJokers) {
            powerUp5050Count = sJokers;
            changed = true;
          }
        }
        if (data.containsKey('is_vip')) {
          final sVip = (data['is_vip'] == 1 || data['is_vip'] == true);
          if (_isVip != sVip) {
            _isVip = sVip;
            changed = true;
          }
        }
        if (data.containsKey('has_no_ads')) {
          final sNoAds = (data['has_no_ads'] == 1 || data['has_no_ads'] == true);
          if (_hasNoAds != sNoAds) {
            _hasNoAds = sNoAds;
            changed = true;
          }
        }
        if (data.containsKey('name') && data['name'] != null && (data['name'] as String).isNotEmpty) {
          if (_customPlayerName != data['name']) {
            _customPlayerName = data['name'];
            changed = true;
          }
        }
        if (data.containsKey('avatar') && data['avatar'] != null && (data['avatar'] as String).isNotEmpty) {
          if (_customAvatar != data['avatar']) {
            _customAvatar = data['avatar'];
            changed = true;
          }
        }

        // Sunucudan gelen plak/rozet koleksiyonunu güvenle birleştir
        if (data['badges_data'] != null && (data['badges_data'] as String).isNotEmpty) {
          try {
            final Map<String, dynamic> remoteBadges = jsonDecode(data['badges_data'] as String);
            if (remoteBadges.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              final localJson = prefs.getString('user_badges_data');
              Map<String, dynamic> localBadges = {};
              if (localJson != null && localJson.isNotEmpty) {
                try { localBadges = jsonDecode(localJson); } catch (_) {}
              }

              for (final badge in _badges) {
                final rData = remoteBadges[badge.id] as Map<String, dynamic>?;
                if (rData != null) {
                  final rShards = (rData['currentShards'] as num?)?.toInt() ?? 0;
                  final rUnlocked = rData['isUnlocked'] == true;
                  final rEquipped = rData['isEquipped'] == true;

                  if (rShards > badge.currentShards) badge.currentShards = rShards;
                  if (rUnlocked) badge.isUnlocked = true;
                  if (rEquipped) badge.isEquipped = true;

                  localBadges[badge.id] = {
                    'currentShards': badge.currentShards,
                    'isUnlocked': badge.isUnlocked,
                    'isEquipped': badge.isEquipped,
                  };
                }
              }

              // Ayrıca henüz belleğe girmemiş rozetlerin sunucu verisini de yerel haritaya ekle
              for (final entry in remoteBadges.entries) {
                if (!localBadges.containsKey(entry.key)) {
                  localBadges[entry.key] = entry.value;
                }
              }

              await prefs.setString('user_badges_data', jsonEncode(localBadges));
              changed = true;
              debugPrint('📀 [PLAKLAR SENKRONİZE EDİLDİ] Sunucudaki plak koleksiyonu başarıyla yüklendi.');
            }
          } catch (e) {
            debugPrint('Rozet veri birleştirme hatası: $e');
          }
        }

        // Sunucudan gelen kariyer istatistiklerini senkronize et
        if (data['stats_json'] != null && (data['stats_json'] as String).isNotEmpty && data['stats_json'] != '{}') {
          try {
            final remoteStats = PlayerStats.fromJson(data['stats_json']);
            if (remoteStats.totalMatches > _playerStats.totalMatches) {
              _playerStats = remoteStats;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_player_stats', jsonEncode(_playerStats.toJson()));
      await prefs.setString('user_season_pass_data', jsonEncode(_seasonPass.toJson()));
              changed = true;
              debugPrint('📊 [İSTATİSTİKLER SENKRONİZE EDİLDİ] Sunucu kariyer karnesi yüklendi.');
            }
          } catch (e) {
            debugPrint('İstatistik veri birleştirme hatası: $e');
          }
        }

        if (changed) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_coins', _coins);
          await prefs.setInt('user_energy', _energy);
          await prefs.setInt('user_jokers', powerUp5050Count);
          await prefs.setBool('user_is_vip', _isVip);
          await prefs.setBool('user_has_no_ads', _hasNoAds);
          await prefs.setString('user_player_name', _customPlayerName);
          await prefs.setString('user_player_avatar', _customAvatar);
          notifyListeners();
          debugPrint('✅ [PROFİL GÜNCELLENDİ] Altın: $_coins, Enerji: $_energy, VIP: $_isVip');
        }
      }
    } catch (e) {
      debugPrint('Sunucudan profil çekme hatası: $e');
    }
  }

  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_coins', _coins);
      await prefs.setInt('user_energy', _energy);
      await prefs.setInt('last_energy_timestamp', _lastEnergyTimestamp);
      await prefs.setBool('user_has_no_ads', _hasNoAds);
      await prefs.setBool('user_is_vip', _isVip);
      await prefs.setInt('user_jokers', powerUp5050Count);
      await prefs.setString('user_player_name', _customPlayerName);
      await prefs.setString('user_player_avatar', _customAvatar);
      await prefs.setString('user_player_stats', jsonEncode(_playerStats.toJson()));
      await prefs.setString('user_season_pass_data', jsonEncode(_seasonPass.toJson()));
      if (_googleUserId != null) await prefs.setString('user_google_id', _googleUserId!);
      if (_googleUserEmail != null) await prefs.setString('user_google_email', _googleUserEmail!);

      String? badgesJson;
      if (_badges.isNotEmpty) {
        final Map<String, dynamic> badgesMap = {};
        for (final badge in _badges) {
          badgesMap[badge.id] = {
            'currentShards': badge.currentShards,
            'isUnlocked': badge.isUnlocked,
            'isEquipped': badge.isEquipped,
          };
        }
        badgesJson = jsonEncode(badgesMap);
        await prefs.setString('user_badges_data', badgesJson);
      } else {
        badgesJson = prefs.getString('user_badges_data');
      }

      // Sunucu Veritabanı ile Anlık Senkronizasyon (SQLite)
      if (_googleUserId != null) {
        final Map<String, dynamic> payload = {
          'google_id': _googleUserId,
          'email': _googleUserEmail ?? '',
          'name': _customPlayerName,
          'avatar': _customAvatar,
          'energy': _energy,
          'last_energy_timestamp': _lastEnergyTimestamp,
          'coins': _coins,
          'powerup_count': powerUp5050Count,
          'has_no_ads': _hasNoAds ? 1 : 0,
          'is_vip': _isVip ? 1 : 0,
          'stats_json': jsonEncode(_playerStats.toJson()),
        };

        if (badgesJson != null && badgesJson.isNotEmpty && badgesJson != '{}') {
          payload['badges_data'] = badgesJson;
        }

        http.post(
          Uri.parse('http://80.253.246.132:6060/api/user/sync'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).then((res) {
          if (res.statusCode == 200) {
            try {
              final rData = jsonDecode(res.body);
              if (rData['user'] != null) {
                final u = rData['user'];
                final sCoins = (u['coins'] as num?)?.toInt();
                final sEnergy = (u['energy'] as num?)?.toInt();
                final sVip = (u['is_vip'] == 1);
                final sNoAds = (u['has_no_ads'] == 1);
                final sJokers = (u['powerup_count'] as num?)?.toInt();
                bool needNotify = false;
                if (sCoins != null && sCoins != _coins) { _coins = sCoins; needNotify = true; }
                if (sEnergy != null && sEnergy > _energy) { _energy = sEnergy; needNotify = true; }
                if (sJokers != null && sJokers != powerUp5050Count) { powerUp5050Count = sJokers; needNotify = true; }
                if (sVip != _isVip) { _isVip = sVip; needNotify = true; }
                if (sNoAds != _hasNoAds) { _hasNoAds = sNoAds; needNotify = true; }
                if (needNotify) notifyListeners();
              }
            } catch (_) {}
          }
        }).catchError((_) {});
      }
    } catch (e) {
      debugPrint('Kullanıcı verisi kaydetme hatası: $e');
    }
  }

  void awardMatchRewards() {
    final isWinner = _userTotalScore > _opponentTotalScore;
    final isDraw = _userTotalScore == _opponentTotalScore;

    if (_selectedCategory != null) {
      _playerStats.recordMatchResult(
        categoryId: _selectedCategory!.id,
        isWinner: isWinner,
        isDraw: isDraw,
        matchScore: _userTotalScore,
      );
    }

    final earnedCoins = isWinner ? 50 : (isDraw ? 25 : 10);
    _coins += earnedCoins;
    _lastEarnedCoins = earnedCoins;

    final earnedShards = isWinner ? 3 : (isDraw ? 2 : 1);
    _lastEarnedShards = earnedShards;
    _lastRewardedBadgeName = null;

    if (_selectedCategory != null) {
      final catId = _selectedCategory!.id.toLowerCase();
      final catTitle = _selectedCategory!.title.toLowerCase();

      // 1. Doğrudan sanatçı kategorisi eşleşmesi (Örn: 'artist_tarkan', 'Tarkan Özel Düello')
      CollectionBadge? targetBadge = _badges.where((b) {
        if (b.isUnlocked) return false;
        final aName = b.artistName.toLowerCase();
        return aName.isNotEmpty && (catId.contains(aName) || catTitle.contains(aName));
      }).firstOrNull;

      // 2. Kategori ID eşleşmesi (Örn: 'pop_90s', 'arabesk_tr', 'cat_1791715274917' vb.)
      // RASTGELE SÜRPRİZ DAĞITIM: O kategoride kilitli tüm sanatçılar arasından rastgele birini seç!
      if (targetBadge == null) {
        final categoryLockedBadges = _badges.where((b) => b.categoryId == _selectedCategory!.id && !b.isUnlocked).toList();
        if (categoryLockedBadges.isNotEmpty) {
          targetBadge = categoryLockedBadges[Random().nextInt(categoryLockedBadges.length)];
        }
      }

      // 3. Karma çalma listesi veya kategoride kilitli rozet kalmadıysa:
      // Kilitli rozetler arasından rastgele birine plak parçası hediye et!
      if (targetBadge == null) {
        final allLocked = _badges.where((b) => !b.isUnlocked).toList();
        if (allLocked.isNotEmpty) {
          targetBadge = allLocked[Random().nextInt(allLocked.length)];
        }
      }

      if (targetBadge != null) {
        _lastRewardedBadgeName = targetBadge.artistName;
        targetBadge.currentShards = min(targetBadge.totalShardsRequired, targetBadge.currentShards + earnedShards);
        if (targetBadge.currentShards >= targetBadge.totalShardsRequired) {
          targetBadge.isUnlocked = true;
        }
      }
    }

    // Sezon Bileti XP'si & Görev Takibi
    final earnedXp = isWinner ? 60 : (isDraw ? 35 : 20);
    _lastEarnedXp = earnedXp;
    _seasonPass.currentXp += earnedXp;
    trackMissionProgress('complete_match', amount: 1);
    if (isWinner) {
      trackMissionProgress('win_match', amount: 1);
      if (_selectedCategory != null) {
        trackMissionProgress('category_win', amount: 1, categoryId: _selectedCategory!.id);
      }
    }

    _saveUserData();
    notifyListeners();
  }

  // ==================== SEZON BİLETİ (MÜZİK PASS) İŞLEMLERİ ====================

  void addSeasonPassXp(int xp) {
    if (xp <= 0) return;
    _seasonPass.currentXp += xp;
    _saveUserData();
    notifyListeners();
  }

  bool unlockGoldPass({bool useCoins = false}) {
    if (_seasonPass.isGoldUnlocked) return true;
    if (useCoins) {
      if (_coins < 1500) return false;
      _coins -= 1500;
    }
    _seasonPass.isGoldUnlocked = true;
    _saveUserData();
    notifyListeners();
    return true;
  }

  PassReward? claimPassTierReward(int level, bool isGold) {
    final tier = _seasonPass.tiers.firstWhere((t) => t.level == level, orElse: () => _seasonPass.tiers.first);
    if (tier.level > _seasonPass.currentLevel) return null;

    PassReward reward;
    if (isGold) {
      if (!_seasonPass.isGoldUnlocked || tier.isGoldClaimed) return null;
      tier.isGoldClaimed = true;
      reward = tier.goldReward;
    } else {
      if (tier.isFreeClaimed) return null;
      tier.isFreeClaimed = true;
      reward = tier.freeReward;
    }

    _applyReward(reward);
    _saveUserData();
    notifyListeners();
    return reward;
  }

  List<PassReward> claimAllPassRewards() {
    final List<PassReward> claimed = [];
    final currentLvl = _seasonPass.currentLevel;

    for (final tier in _seasonPass.tiers) {
      if (tier.level <= currentLvl) {
        if (!tier.isFreeClaimed) {
          tier.isFreeClaimed = true;
          _applyReward(tier.freeReward);
          claimed.add(tier.freeReward);
        }
        if (_seasonPass.isGoldUnlocked && !tier.isGoldClaimed) {
          tier.isGoldClaimed = true;
          _applyReward(tier.goldReward);
          claimed.add(tier.goldReward);
        }
      }
    }

    if (claimed.isNotEmpty) {
      _saveUserData();
      notifyListeners();
    }
    return claimed;
  }

  PassReward? openEndlessChest() {
    final available = _seasonPass.endlessLevel - _seasonPass.endlessChestClaimCount;
    if (available <= 0) return null;

    _seasonPass.endlessChestClaimCount++;
    const reward = PassReward(
      type: RewardType.endlessChest,
      amount: 500,
      title: 'Sonsuz Plak Sandığı (+500 Altın, 2x Joker, 10 Plak, +5 Enerji)',
      icon: '🎁',
    );
    _coins += 500;
    powerUp5050Count += 2;
    _energy += 5; // Kazanılan ödül enerjisi 10 tavanına takılmaz, eklenir

    final locked = _badges.where((b) => !b.isUnlocked).toList();
    if (locked.isNotEmpty) {
      final b = locked[Random().nextInt(locked.length)];
      b.currentShards = min(b.totalShardsRequired, b.currentShards + 10);
      if (b.currentShards >= b.totalShardsRequired) b.isUnlocked = true;
    }

    _saveUserData();
    notifyListeners();
    return reward;
  }

  void _applyReward(PassReward reward) {
    switch (reward.type) {
      case RewardType.coins:
        _coins += reward.amount;
        break;
      case RewardType.energy:
        _energy += reward.amount; // Ödül enerjisi 10 tavanına takılmaz, taşar (örn: 8 + 5 = 13)
        break;
      case RewardType.joker:
        powerUp5050Count += reward.amount;
        break;
      case RewardType.shard:
        final locked = _badges.where((b) => !b.isUnlocked).toList();
        if (locked.isNotEmpty) {
          final b = locked[Random().nextInt(locked.length)];
          b.currentShards = min(b.totalShardsRequired, b.currentShards + reward.amount);
          if (b.currentShards >= b.totalShardsRequired) b.isUnlocked = true;
        }
        break;
      case RewardType.endlessChest:
        _coins += reward.amount;
        break;
    }
  }

  void trackMissionProgress(String actionKey, {int amount = 1, String? categoryId}) {
    bool hasChanged = false;
    for (final mission in _seasonPass.missions) {
      if (mission.isClaimed || mission.isCompleted) continue;
      if (mission.actionKey == actionKey) {
        if (mission.filterCategory != null && categoryId != null) {
          if (!categoryId.toLowerCase().contains(mission.filterCategory!.toLowerCase())) {
            continue;
          }
        }
        mission.current = min(mission.target, mission.current + amount);
        hasChanged = true;
      }
    }
    if (hasChanged) {
      _saveUserData();
      notifyListeners();
    }
  }

  bool claimMissionReward(String missionId) {
    final mission = _seasonPass.missions.firstWhere((m) => m.id == missionId, orElse: () => _seasonPass.missions.first);
    if (!mission.isCompleted || mission.isClaimed) return false;

    mission.isClaimed = true;
    addSeasonPassXp(mission.xpReward);
    if (mission.coinReward > 0) {
      _coins += mission.coinReward;
    }
    _saveUserData();
    notifyListeners();
    return true;
  }

  bool tryConsumeEnergy() {
    if (_energy >= 1) {
      final wasMax = _energy >= maxEnergy;
      _energy--;
      if (wasMax || _lastEnergyTimestamp <= 0) {
        _lastEnergyTimestamp = DateTime.now().millisecondsSinceEpoch;
        _minutesUntilNextEnergy = energyRegenIntervalMinutes;
      }
      _saveUserData();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool watchAdForEnergy() {
    if (_dailyAdsWatchedForEnergy < maxDailyAdsForEnergy) {
      _dailyAdsWatchedForEnergy++;
      _energy = min(maxEnergy, _energy + 2);
      if (_energy >= maxEnergy) {
        _lastEnergyTimestamp = DateTime.now().millisecondsSinceEpoch;
        _minutesUntilNextEnergy = energyRegenIntervalMinutes;
      }
      _saveUserData();
      notifyListeners();
      return true;
    }
    return false;
  }

  void addEnergy(int amount) {
    _energy += amount;
    if (_energy >= maxEnergy) {
      _lastEnergyTimestamp = DateTime.now().millisecondsSinceEpoch;
      _minutesUntilNextEnergy = energyRegenIntervalMinutes;
    }
    _saveUserData();
    notifyListeners();
  }

  void addCoins(int amount) {
    _coins += amount;
    _saveUserData();
    notifyListeners();
  }

  void addJokers(int amount) {
    powerUp5050Count += amount;
    _saveUserData();
    notifyListeners();
  }

  void buyRemoveAds() {
    _hasNoAds = true;
    _energy = min(maxEnergy, _energy + 2);
    if (_energy >= maxEnergy) {
      _lastEnergyTimestamp = DateTime.now().millisecondsSinceEpoch;
      _minutesUntilNextEnergy = energyRegenIntervalMinutes;
    }
    powerUp5050Count += 2;
    _saveUserData();
    notifyListeners();
  }

  void buyVipPackage() {
    _isVip = true;
    _hasNoAds = true;
    _energy += 100;
    _lastEnergyTimestamp = DateTime.now().millisecondsSinceEpoch;
    _minutesUntilNextEnergy = energyRegenIntervalMinutes;
    powerUp5050Count += 10;
    _customAvatar = '👑';
    _saveUserData();
    notifyListeners();
  }

  /// Altın ile Oyun İçi Mağaza Eşyası / Joker Satın Alma
  Future<bool> buyStoreItemWithCoins(StoreItem item) async {
    if (_coins < item.coinsCost) {
      return false;
    }
    _coins -= item.coinsCost;
    if (item.rewards.jokers > 0) {
      powerUp5050Count += item.rewards.jokers;
    }
    if (item.rewards.energy > 0) {
      _energy += item.rewards.energy;
    }
    await _saveUserData();
    notifyListeners();
    return true;
  }

  /// Google Play veya Uzaktan Gelen Mağaza Ödül Reçetesini Hesaba Tanımla
  void applyStoreItemRewards(String itemId) {
    final item = getStoreItem(itemId);
    if (item != null) {
      final r = item.rewards;
      if (r.coins > 0) _coins += r.coins;
      if (r.energy > 0) _energy += r.energy;
      if (r.jokers > 0) powerUp5050Count += r.jokers;
      if (r.removeAds) _hasNoAds = true;
      if (r.isVip) {
        _isVip = true;
        _hasNoAds = true;
        _customAvatar = '👑';
        _energy = max(_energy, 100);
      }
      _saveUserData();
      notifyListeners();
    } else {
      // Emniyet Fallback
      switch (itemId) {
        case 'remove_ads':
          buyRemoveAds();
          break;
        case 'vip_club':
          buyVipPackage();
          break;
        case 'coins_500':
          addCoins(500);
          break;
        case 'coins_1500':
          addCoins(1500);
          break;
        case 'coins_4000':
          addCoins(4000);
          break;
        case 'coins_10000':
          addCoins(10000);
          break;
        case 'energy_10':
          addEnergy(10);
          break;
        case 'energy_25':
          addEnergy(25);
          addJokers(2);
          break;
        case 'energy_60':
          addEnergy(60);
          addJokers(5);
          break;
        case 'energy_150':
          addEnergy(150);
          addJokers(15);
          break;
      }
    }
  }

  bool buyMissingShards(String badgeId, int priceInCoins) {
    final badge = _badges.firstWhere((b) => b.id == badgeId, orElse: () => _badges.first);
    if (_coins >= priceInCoins) {
      _coins -= priceInCoins;
      badge.currentShards = badge.totalShardsRequired;
      badge.isUnlocked = true;
      _saveUserData();
      notifyListeners();
      return true;
    }
    return false;
  }

  void equipBadge(String badgeId) {
    for (final b in _badges) {
      b.isEquipped = (b.id == badgeId);
    }
    final target = _badges.firstWhere((b) => b.id == badgeId);
    _customAvatar = target.imageUrl.isNotEmpty ? target.imageUrl : target.emoji;
    _saveUserData();
    notifyListeners();
  }

  void updateProfile(String name, String avatar) {
    _customPlayerName = name;
    _customAvatar = avatar;
    _saveUserData();
    notifyListeners();
  }

  Future<bool> loginWithGoogle() async {
    try {
      final user = await AuthService.instance.signInWithGoogle();
      if (user != null) {
        _googleUserId = user.id;
        _googleUserEmail = user.email;
        _customPlayerName = user.displayName;
        if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
          _customAvatar = user.photoUrl!;
        }

        // Sunucumuzdaki SQLite Veritabanı ile Senkronizasyon (Kayıt / Giriş)
        await _syncWithServer(user);

        await _saveUserData();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Google Giriş Hatası: $e');
    }
    return false;
  }

  Future<void> logoutGoogle() async {
    try {
      await AuthService.instance.signOut();
      _googleUserId = null;
      _googleUserEmail = null;
      _customPlayerName = 'Oyuncu_${Random().nextInt(9000) + 1000}';
      _customAvatar = '🎧';
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_google_id');
      await prefs.remove('user_google_email');
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      debugPrint('Çıkış Hatası: $e');
    }
  }

  Future<void> _syncWithServer(AuthUser user) async {
    try {
      final Map<String, dynamic> badgesMap = {};
      for (final badge in _badges) {
        badgesMap[badge.id] = {
          'currentShards': badge.currentShards,
          'isUnlocked': badge.isUnlocked,
          'isEquipped': badge.isEquipped,
        };
      }

      final body = jsonEncode({
        'google_id': user.id,
        'email': user.email,
        'name': user.displayName,
        'avatar': user.photoUrl ?? _customAvatar,
        'badges_data': jsonEncode(badgesMap),
        'stats_json': jsonEncode(_playerStats.toJson()),
        'energy': _energy,
        'last_energy_timestamp': _lastEnergyTimestamp,
      });

      final response = await http.post(
        Uri.parse('http://80.253.246.132:6060/api/auth/sync'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'logged_in') {
          final sUser = res['user'];
          _coins = sUser['coins'] ?? _coins;
          if (sUser['energy'] != null && (sUser['energy'] as num).toInt() > _energy) {
            _energy = (sUser['energy'] as num).toInt();
          }
          _hasNoAds = (sUser['has_no_ads'] == 1);
          _isVip = (sUser['is_vip'] == 1);
          powerUp5050Count = sUser['powerup_count'] ?? powerUp5050Count;
          if (sUser['stats_json'] != null && (sUser['stats_json'] as String).isNotEmpty && sUser['stats_json'] != '{}') {
            try {
              final remoteStats = PlayerStats.fromJson(sUser['stats_json']);
              if (remoteStats.totalMatches > _playerStats.totalMatches) {
                _playerStats = remoteStats;
              }
            } catch (_) {}
          }
          if (sUser['badges_data'] != null) {
            try {
              final Map<String, dynamic> bMap = jsonDecode(sUser['badges_data']);
              for (final b in _badges) {
                if (bMap.containsKey(b.id)) {
                  b.currentShards = bMap[b.id]['currentShards'] ?? b.currentShards;
                  b.isUnlocked = bMap[b.id]['isUnlocked'] ?? b.isUnlocked;
                  b.isEquipped = bMap[b.id]['isEquipped'] ?? b.isEquipped;
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Sunucu senkronizasyon hatası: $e');
    }
  }

  Future<void> fetchRemoteConfig() async {
    try {
      final res = await http
          .get(Uri.parse('http://80.253.246.132:6060/api/config/all'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data['categories'] is List) {
          final List remoteCatsRaw = data['categories'];
          final List<MusicCategory> updatedCats = [];
          for (final cJson in remoteCatsRaw) {
            try {
              updatedCats.add(MusicCategory.fromJson(cJson));
            } catch (_) {}
          }
          if (updatedCats.isNotEmpty) {
            _categories = updatedCats;
          }
        }
        if (data['badges'] is List) {
          final List remoteBadgesRaw = data['badges'];
          final List<CollectionBadge> updatedBadges = [];

          final prefs = await SharedPreferences.getInstance();
          final badgesJson = prefs.getString('user_badges_data');
          Map<String, dynamic> localProgress = {};
          if (badgesJson != null && badgesJson.isNotEmpty) {
            try {
              localProgress = jsonDecode(badgesJson);
            } catch (_) {}
          }

          for (final bJson in remoteBadgesRaw) {
            final b = CollectionBadge.fromJson(bJson);
            if (localProgress.containsKey(b.id)) {
              final p = localProgress[b.id] as Map<String, dynamic>;
              b.currentShards = p['currentShards'] ?? 0;
              b.isUnlocked = p['isUnlocked'] ?? false;
              b.isEquipped = p['isEquipped'] ?? false;
            } else {
              final existing = _badges.where((element) => element.id == b.id).firstOrNull;
              if (existing != null) {
                b.currentShards = existing.currentShards;
                b.isUnlocked = existing.isUnlocked;
                b.isEquipped = existing.isEquipped;
              }
            }
            updatedBadges.add(b);
          }
          if (updatedBadges.isNotEmpty) {
            _badges = updatedBadges;
            notifyListeners();
            if (_googleUserId != null && _googleUserId!.isNotEmpty) {
              fetchProfileFromServer();
            }
          }
        }
        if (data['store_items'] is List) {
          final List remoteItemsRaw = data['store_items'];
          final List<StoreItem> updatedItems = [];
          for (final itemJson in remoteItemsRaw) {
            try {
              updatedItems.add(StoreItem.fromJson(itemJson));
            } catch (_) {}
          }
          if (updatedItems.isNotEmpty) {
            _storeItems = updatedItems;
            notifyListeners();
            PurchaseService.instance.queryDynamicProducts(_storeItems.where((i) => i.isInApp).map((i) => i.id).toSet());
          }
        }

        // 4. Canlı Sezon Bileti & Görevler (LiveOps Müzik Pass)
        if (data['season_pass'] != null && data['season_pass'] is Map) {
          final Map<String, dynamic> remotePass = Map<String, dynamic>.from(data['season_pass']);
          final String sId = remotePass['seasonId'] ?? _seasonPass.seasonId;
          final String sName = remotePass['seasonName'] ?? _seasonPass.seasonName;
          final DateTime sEndDate = DateTime.tryParse(remotePass['endDate']?.toString() ?? '') ?? _seasonPass.endDate;

          // Seviyeleri (Tiers) yerel haklarla birleştir
          List<SeasonPassTier> updatedTiers = List.from(_seasonPass.tiers);
          if (remotePass['tiers'] is List) {
            final List remoteTiersList = remotePass['tiers'];
            updatedTiers = remoteTiersList.map((tJson) {
              final tier = SeasonPassTier.fromJson(Map<String, dynamic>.from(tJson));
              final localTier = _seasonPass.tiers.where((lt) => lt.level == tier.level).firstOrNull;
              if (localTier != null) {
                tier.isFreeClaimed = localTier.isFreeClaimed;
                tier.isGoldClaimed = localTier.isGoldClaimed;
              }
              return tier;
            }).toList();
          }

          // Görevleri (Missions) yerel ilerleme ile birleştir
          List<SeasonMission> updatedMissions = List.from(_seasonPass.missions);
          if (remotePass['missions'] is List) {
            final List remoteMissionsList = remotePass['missions'];
            updatedMissions = remoteMissionsList.map((mJson) {
              final mission = SeasonMission.fromJson(Map<String, dynamic>.from(mJson));
              final localMission = _seasonPass.missions.where((lm) => lm.id == mission.id).firstOrNull;
              if (localMission != null) {
                mission.current = localMission.current;
                mission.isClaimed = localMission.isClaimed;
              }
              return mission;
            }).toList();
          }

          _seasonPass = SeasonPassData(
            seasonId: sId,
            seasonName: sName,
            endDate: sEndDate,
            currentXp: _seasonPass.currentXp,
            isGoldUnlocked: _seasonPass.isGoldUnlocked,
            endlessChestClaimCount: _seasonPass.endlessChestClaimCount,
            tiers: updatedTiers,
            missions: updatedMissions,
          );
          await _saveUserData();
          notifyListeners();
          debugPrint('🎟️ [MÜZİK PASS GÜNCELLENDİ] Uzak sunucudan Sezon: $sName ve ${updatedMissions.length} görev yüklendi.');
        }
      }
    } catch (e) {
      debugPrint('Uzak konfigürasyon çekme hatası: $e');
    }
  }

  GameProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initEnergyTimer();
    _initApp();
    PurchaseService.instance.init(this);
    _initAudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isAudioPlaying = state == PlayerState.playing;
      notifyListeners();
    });
  }

  void _initAudioPlayer() {
    try {
      final audioContext = AudioContextConfig(
        respectSilence: false,
        route: AudioContextConfigRoute.speaker,
      ).build();
      _audioPlayer.setAudioContext(audioContext);
    } catch (e) {
      debugPrint('Audio context config error: $e');
    }
  }

  Future<void> _initApp() async {
    await _loadUserData();
    await fetchRemoteConfig();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _calculateEnergyRecovery();
      fetchProfileFromServer();
      _reconnectCustomRoomIfDisconnected();
      notifyListeners();
    }
  }

  /// WhatsApp veya başka bir uygulamaya geçildikten sonra dönüldüğünde odaya tekrar bağlan
  Future<void> _reconnectCustomRoomIfDisconnected() async {
    if (_status == GameStatus.waitingFriendInRoom && _createdRoomCode != null && _isCustomRoom) {
      debugPrint('🔄 [ÖZEL ODA YENİDEN BAĞLANMA] WhatsApp dönüşü sonrası odaya (#$_createdRoomCode) bağlanılıyor...');
      try {
        await _connectAndListen();
        _wsChannel?.sink.add(jsonEncode({
          'type': 'reconnect_custom_room',
          'roomCode': _createdRoomCode,
          'playerName': playerName,
          'avatar': playerAvatar,
          'platform': kIsWeb ? 'Web' : 'Android',
        }));
      } catch (e) {
        debugPrint('Özel odaya yeniden bağlanma hatası: $e');
      }
    }
  }

  /// Uzak Üretim Sunucusu (7/24 Aktif PM2 Servisi)
  String get _serverWsUrl => 'ws://80.253.246.132:6060';

  /// 1. Genel Rastgele Eşleşme (Standart 5 Tur) - Rakip Bulununca 1 Enerji Tüketir
  Future<void> startDuel(MusicCategory category) async {
    if (_energy < 1) {
      _errorMessage = '⚡ Enerjin tükendi! Reklam izleyerek enerji kazanabilir veya mağazayı ziyaret edebilirsin.';
      _status = GameStatus.error;
      notifyListeners();
      return;
    }

    _selectedCategory = category;
    _status = GameStatus.searchingOpponent;
    _errorMessage = null;
    _userTotalScore = 0;
    _opponentTotalScore = 0;
    _currentRoundIndex = 0;
    _opponent = null;
    _questions = [];
    _currentQuestion = null;
    _createdRoomCode = null;
    _isCustomRoom = false;
    _totalMatchRounds = 5;
    _roundDurationSec = 10;
    _isMultiplayer = true;
    notifyListeners();

    try {
      await _connectAndListen();
      _wsChannel?.sink.add(jsonEncode({
        'type': 'join_queue',
        'playerName': playerName,
        'avatar': playerAvatar,
        'platform': kIsWeb ? 'Web' : 'Android',
        'category': category.id,
      }));
    } catch (e) {
      debugPrint('Sunucuya bağlanılamadı: $e, yerel mod...');
      _fallbackToOfflineDuel(category);
    }
  }

  /// 2. Arkadaş İçin Özel Oda Kurma (Ayarlanabilir 5-20 Tur) - Enerji Ücretsizdir
  Future<void> createCustomRoom({
    required MusicCategory category,
    required int roundCount, // 5, 10, 15, 20 tur!
    required int durationSec,
  }) async {
    _selectedCategory = category;
    _status = GameStatus.searchingOpponent;
    _errorMessage = null;
    _userTotalScore = 0;
    _opponentTotalScore = 0;
    _currentRoundIndex = 0;
    _opponent = null;
    _questions = [];
    _currentQuestion = null;
    _isCustomRoom = true;
    _totalMatchRounds = roundCount;
    _roundDurationSec = durationSec;
    _isMultiplayer = true;
    notifyListeners();

    try {
      await _connectAndListen();
      _wsChannel?.sink.add(jsonEncode({
        'type': 'create_custom_room',
        'playerName': playerName,
        'avatar': playerAvatar,
        'platform': kIsWeb ? 'Web' : 'Android',
        'category': category.id,
        'roundCount': roundCount,
        'roundDurationSec': durationSec,
      }));
    } catch (e) {
      _status = GameStatus.error;
      _errorMessage = 'Oda açılamadı: $e';
      notifyListeners();
    }
  }

  /// 3. Arkadaşın Oda Koduna Katılma - Enerji Ücretsizdir
  Future<void> joinCustomRoom(String roomCode) async {
    _status = GameStatus.searchingOpponent;
    _errorMessage = null;
    _userTotalScore = 0;
    _opponentTotalScore = 0;
    _currentRoundIndex = 0;
    _opponent = null;
    _questions = [];
    _currentQuestion = null;
    _isCustomRoom = true;
    _isMultiplayer = true;
    notifyListeners();

    try {
      await _connectAndListen();
      _wsChannel?.sink.add(jsonEncode({
        'type': 'join_custom_room',
        'roomCode': roomCode,
        'playerName': playerName,
        'avatar': playerAvatar,
        'platform': kIsWeb ? 'Web' : 'Android',
      }));
    } catch (e) {
      _status = GameStatus.error;
      _errorMessage = 'Odaya bağlanılamadı: $e';
      notifyListeners();
    }
  }

  Future<void> _connectAndListen() async {
    await _disconnectWebSocket();
    final uri = Uri.parse(_serverWsUrl);
    _wsChannel = WebSocketChannel.connect(uri);

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_wsChannel != null) {
        try {
          _wsChannel?.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      }
    });

    _wsSubscription = _wsChannel?.stream.listen(
      _handleServerMessage,
      onError: (err) {
        debugPrint('WebSocket hatası: $err');
        _status = GameStatus.error;
        _errorMessage = 'Sunucu bağlantı hatası.';
        notifyListeners();
      },
      onDone: () {
        debugPrint('WebSocket bağlantısı kapandı.');
      },
    );
  }

  void _handleServerMessage(dynamic raw) async {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'waiting_for_host':
          _status = GameStatus.waitingFriendInRoom;
          _errorMessage = data['message'] as String? ?? 'Kurucunun dönmesi bekleniyor...';
          notifyListeners();
          break;

        case 'pong':
          // Heartbeat akışı aktif
          break;

        case 'room_created':
          _createdRoomCode = data['roomCode'] as String?;
          _status = GameStatus.waitingFriendInRoom;
          notifyListeners();
          break;

        case 'match_found':
          final isCustomMatch = _isCustomRoom || data['isCustom'] == true || _createdRoomCode != null;
          if (!isCustomMatch) {
            tryConsumeEnergy(); // Sadece genel rastgele eşleşmede enerji tüketilir, arkadaş maçında ücretsizdir!
          }
          final opp = data['opponent'] as Map<String, dynamic>;
          _opponent = Opponent(
            name: opp['name'] ?? 'Arkadaş',
            city: opp['platform'] ?? 'Türkiye',
            avatar: opp['avatar'] ?? '🎧',
          );
          _totalMatchRounds = data['totalRounds'] as int? ?? _totalMatchRounds;
          _status = GameStatus.opponentFound;
          notifyListeners();

          // Şarkıları arka planda RAM belleğe ön-yükle (0ms bekleme ve eşzamanlı başlatma)
          if (data['preloadUrls'] is List) {
            final List urls = data['preloadUrls'];
            for (final u in urls) {
              if (u != null && u.toString().isNotEmpty) {
                preloadSong(u.toString());
              }
            }
          }
          break;

        case 'round_start':
          final roundIdx = data['roundIndex'] as int;
          _totalMatchRounds = data['totalRounds'] as int? ?? _totalMatchRounds;
          _roundDurationSec = data['roundDurationSec'] as int? ?? _roundDurationSec;

          // Sıradaki turun şarkısı varsa erkenden yükle
          if (data['nextPreviewUrl'] != null && data['nextPreviewUrl'].toString().isNotEmpty) {
            preloadSong(data['nextPreviewUrl'].toString());
          }

          final qData = data['question'] as Map<String, dynamic>;
          final options = List<String>.from(qData['options'] as List);

          final song = Song(
            id: 's_$roundIdx',
            title: qData['title'] ?? '',
            artist: qData['artist'] ?? '',
            album: '',
            previewUrl: qData['previewUrl'] ?? '',
            artworkUrl: qData['artworkUrl'] ?? '',
            categoryId: _selectedCategory?.id ?? '',
          );

          final duelQuestion = DuelQuestion(
            song: song,
            type: QuestionType.songTitle,
            options: options,
            correctOptionIndex: (qData['correctIndex'] as num?)?.toInt() ?? -1,
            customPrompt: qData['promptText'] as String?,
          );

          _currentRoundIndex = roundIdx;
          _currentQuestion = duelQuestion;
          _questions.add(duelQuestion);

          _startLiveRound(duelQuestion);
          break;

        case 'answer_result':
          final correctIdx = data['correctIndex'] as int;
          final earned = data['earnedScore'] as int;
          final total = data['yourTotalScore'] as int;

          if (_currentQuestion != null) {
            _currentQuestion!.correctOptionIndex = correctIdx;
            _currentQuestion!.userScoreEarned = earned;
            _userTotalScore = total;
            if (earned > 0 && _selectedCategory != null) {
              _playerStats.recordCorrectAnswer(
                artist: _currentQuestion!.song.artist,
                categoryId: _selectedCategory!.id,
              );
            }
          }
          notifyListeners();
          break;

        case 'opponent_answered':
          final oppEarned = data['opponentEarnedScore'] as int;
          final oppTotal = data['opponentTotalScore'] as int;
          if (_currentQuestion != null) {
            _currentQuestion!.opponentScoreEarned = oppEarned;
            _opponentTotalScore = oppTotal;
          }
          notifyListeners();
          break;

        case 'round_end':
          final correctIdx = data['correctIndex'] as int;

          _countdownTimer?.cancel();
          await _audioPlayer.stop();

          if (_currentQuestion != null) {
            _currentQuestion!.correctOptionIndex = correctIdx;
            _currentQuestion!.isAnswered = true;
          }

          _status = GameStatus.roundResult;
          notifyListeners();
          break;

        case 'match_over':
          _countdownTimer?.cancel();
          await _audioPlayer.stop();
          awardMatchRewards();
          _status = GameStatus.matchOver;
          notifyListeners();
          break;

        case 'error_message':
        case 'opponent_disconnected':
          _errorMessage = data['message'] as String? ?? 'Bağlantı kesildi.';
          _status = GameStatus.error;
          notifyListeners();
          break;
      }
    } catch (e) {
      debugPrint('Mesaj işleme hatası: $e');
    }
  }

  void _startLiveRound(DuelQuestion question) async {
    _remainingMs = _roundDurationSec * 1000;
    _status = GameStatus.playing;
    notifyListeners();

    try {
      await _audioPlayer.stop();
      final url = question.song.previewUrl;
      if (url.isNotEmpty) {
        if (!kIsWeb && Platform.isIOS) {
          // iOS'ta audioplayers (AVPlayer) BytesSource (RAM) desteklemez.
          // AVPlayer doğrudan Apple/Deezer CDN URL akışını yerel olarak 0 gecikmeyle çalar.
          debugPrint('🌐 [iOS ÇALMA] Şarkı CDN üzerinden çalınıyor: $url');
          await _audioPlayer.play(UrlSource(url));
        } else if (_audioCache.containsKey(url)) {
          debugPrint('⚡ [RAM ÇALMA] Şarkı hafızadan 0ms gecikmeyle çalınıyor: $url');
          await _audioPlayer.play(BytesSource(_audioCache[url]!));
        } else {
          debugPrint('🌐 [AĞ AKIŞI] Şarkı Deezer CDN üzerinden çalınıyor: $url');
          await _audioPlayer.play(UrlSource(url));
        }
      }
    } catch (e) {
      debugPrint('Ses çalma hatası: $e');
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_remainingMs > 0) {
        _remainingMs -= 100;
        notifyListeners();
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  void answerQuestion(int optionIndex) async {
    final question = _currentQuestion;
    if (question == null || question.isAnswered || _status != GameStatus.playing) return;

    question.isAnswered = true;
    question.selectedOptionIndex = optionIndex;
    notifyListeners();

    if (_isMultiplayer && _wsChannel != null) {
      _wsChannel?.sink.add(jsonEncode({
        'type': 'submit_answer',
        'optionIndex': optionIndex,
        'timeRemainingMs': _remainingMs,
      }));
    } else {
      _handleOfflineAnswer(optionIndex);
    }
  }

  bool use5050PowerUp() {
    final question = _currentQuestion;
    if (question == null || question.isAnswered || powerUp5050Count <= 0 || question.eliminatedOptions.isNotEmpty) {
      return false;
    }

    // Doğru cevabın indeksini belirle
    int correctIdx = question.correctOptionIndex;
    if (correctIdx < 0 || correctIdx >= question.options.length) {
      final titleIdx = question.options.indexOf(question.song.title);
      final artistIdx = question.options.indexOf(question.song.artist);
      if (titleIdx >= 0) {
        correctIdx = titleIdx;
      } else if (artistIdx >= 0) {
        correctIdx = artistIdx;
      }
      question.correctOptionIndex = correctIdx;
    }

    if (correctIdx < 0 || correctIdx >= question.options.length) {
      debugPrint('⚠️ [50/50 JOKER] Doğru seçenek tespit edilemedi, joker tüketilmedi.');
      return false;
    }

    powerUp5050Count--;
    _saveUserData();

    // Sadece yanlış olan 3 indeksi listeye al (Doğru seçenek ASLA elenmez!)
    final wrongIndices = <int>[];
    for (int i = 0; i < question.options.length; i++) {
      if (i != correctIdx) {
        wrongIndices.add(i);
      }
    }
    wrongIndices.shuffle(_rnd);
    question.eliminatedOptions.addAll(wrongIndices.take(2));
    notifyListeners();
    return true;
  }

  void _fallbackToOfflineDuel(MusicCategory category) async {
    _isMultiplayer = false;
    try {
      final qList = await _apiService.generateDuelQuestions(category, roundCount: 5);
      for (final q in qList) {
        if (q.song.previewUrl.isNotEmpty) {
          preloadSong(q.song.previewUrl);
        }
      }
      tryConsumeEnergy(); // Bot rakip eşleştiğinde enerji tüketilir
      _opponent = const Opponent(name: 'Simüle Rakip', city: 'İzmir', avatar: '🎸', level: 12);
      _status = GameStatus.opponentFound;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 1500));
      _questions = qList;
      _currentRoundIndex = 0;
      _currentQuestion = _questions[0];
      _startLiveRound(_currentQuestion!);
    } catch (e) {
      _status = GameStatus.error;
      _errorMessage = 'Bağlantı hatası: $e';
      notifyListeners();
    }
  }

  void _handleOfflineAnswer(int optionIndex) async {
    final question = _currentQuestion;
    if (question == null) return;

    _countdownTimer?.cancel();
    await _audioPlayer.stop();

    final isCorrect = optionIndex == question.correctOptionIndex;
    if (isCorrect) {
      final factor = (_remainingMs / (_roundDurationSec * 1000.0)).clamp(0.05, 1.0);
      final score = (factor * 950 + 50).toInt();
      question.userScoreEarned = score;
      _userTotalScore += score;

      final timeSpentMs = (_roundDurationSec * 1000) - _remainingMs;
      if (timeSpentMs < 3000) {
        trackMissionProgress('fast_answer', amount: 1);
      }

      if (_selectedCategory != null) {
        _playerStats.recordCorrectAnswer(
          artist: question.song.artist,
          categoryId: _selectedCategory!.id,
        );
      }
    } else {
      question.userScoreEarned = 0;
    }

    _status = GameStatus.roundResult;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (_currentRoundIndex + 1 < _questions.length) {
        _currentRoundIndex++;
        _currentQuestion = _questions[_currentRoundIndex];
        _startLiveRound(_currentQuestion!);
      } else {
        awardMatchRewards();
        _status = GameStatus.matchOver;
        notifyListeners();
      }
    });
  }

  Future<void> _disconnectWebSocket() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _wsSubscription?.cancel();
    _wsSubscription = null;
    await _wsChannel?.sink.close();
    _wsChannel = null;
  }

  void resetToHome() {
    _countdownTimer?.cancel();
    _audioPlayer.stop();
    _disconnectWebSocket();
    _status = GameStatus.idle;
    _questions = [];
    _currentQuestion = null;
    _currentRoundIndex = 0;
    _userTotalScore = 0;
    _opponentTotalScore = 0;
    _createdRoomCode = null;
    _isCustomRoom = false;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PurchaseService.instance.dispose();
    _energyTimer?.cancel();
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    _disconnectWebSocket();
    super.dispose();
  }
}
