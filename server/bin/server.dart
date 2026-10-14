import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class Player {
  final String id;
  final String name;
  final String avatar;
  final String platform; // "Web" or "Android"
  final WebSocket socket;
  int totalScore = 0;
  bool currentRoundAnswered = false;
  int currentRoundScore = 0;

  Player({
    required this.id,
    required this.name,
    required this.avatar,
    required this.platform,
    required this.socket,
  });

  void send(Map<String, dynamic> data) {
    try {
      socket.add(jsonEncode(data));
    } catch (e) {
      // Socket kapalı olabilir
    }
  }
}

class QuestionItem {
  final String title;
  final String artist;
  final String previewUrl;
  final String artworkUrl;
  final String promptText;
  final List<String> options;
  final int correctIndex;

  QuestionItem({
    required this.title,
    required this.artist,
    required this.previewUrl,
    required this.artworkUrl,
    required this.promptText,
    required this.options,
    required this.correctIndex,
  });

  Map<String, dynamic> toClientJson() {
    return {
      'promptText': promptText,
      'previewUrl': previewUrl,
      'artworkUrl': artworkUrl,
      'options': options,
      'title': title,
      'artist': artist,
    };
  }
}

class DuelRoom {
  final String id;
  final String categoryId;
  final Player player1;
  final Player player2;
  final List<QuestionItem> questions;

  int currentRound = 0;
  Timer? roundTimer;
  bool isFinished = false;

  DuelRoom({
    required this.id,
    required this.categoryId,
    required this.player1,
    required this.player2,
    required this.questions,
  });

  void start() {
    // 1. Oyunculara eşleşme bilgisini gönder
    player1.send({
      'type': 'match_found',
      'roomId': id,
      'opponent': {
        'name': player2.name,
        'avatar': player2.avatar,
        'platform': player2.platform,
      },
    });

    player2.send({
      'type': 'match_found',
      'roomId': id,
      'opponent': {
        'name': player1.name,
        'avatar': player1.avatar,
        'platform': player1.platform,
      },
    });

    // 2. 2 saniye sonra 1. turu başlat
    Timer(const Duration(milliseconds: 2000), () {
      _startRound(0);
    });
  }

  void _startRound(int roundIndex) {
    if (isFinished) return;
    currentRound = roundIndex;
    player1.currentRoundAnswered = false;
    player2.currentRoundAnswered = false;
    player1.currentRoundScore = 0;
    player2.currentRoundScore = 0;

    final q = questions[roundIndex];

    final payload = {
      'type': 'round_start',
      'roundIndex': roundIndex,
      'totalRounds': questions.length,
      'question': q.toClientJson(),
    };

    player1.send(payload);
    player2.send(payload);

    // 10 saniye süre dolduğunda turu bitir
    roundTimer?.cancel();
    roundTimer = Timer(const Duration(milliseconds: 10500), () {
      _endRound();
    });
  }

  void handleAnswer(Player player, int optionIndex, int timeRemainingMs) {
    if (player.currentRoundAnswered || isFinished) return;

    player.currentRoundAnswered = true;
    final q = questions[currentRound];
    final isCorrect = optionIndex == q.correctIndex;

    int earnedScore = 0;
    if (isCorrect) {
      final factor = (timeRemainingMs / 10000.0).clamp(0.05, 1.0);
      earnedScore = (factor * 950 + 50).toInt();
    }

    player.currentRoundScore = earnedScore;
    player.totalScore += earnedScore;

    // Cevap verene kendi sonucunu bildir
    player.send({
      'type': 'answer_result',
      'isCorrect': isCorrect,
      'correctIndex': q.correctIndex,
      'earnedScore': earnedScore,
      'yourTotalScore': player.totalScore,
    });

    // Rakibe bildir
    final opponent = (player == player1) ? player2 : player1;
    opponent.send({
      'type': 'opponent_answered',
      'isCorrect': isCorrect,
      'opponentEarnedScore': earnedScore,
      'opponentTotalScore': player.totalScore,
    });

    // İki oyuncu da cevapladıysa turu hemen bitir
    if (player1.currentRoundAnswered && player2.currentRoundAnswered) {
      roundTimer?.cancel();
      Timer(const Duration(milliseconds: 1500), () {
        _endRound();
      });
    }
  }

  void _endRound() {
    if (isFinished) return;
    roundTimer?.cancel();

    final q = questions[currentRound];
    final endPayload = {
      'type': 'round_end',
      'roundIndex': currentRound,
      'correctIndex': q.correctIndex,
      'songTitle': q.title,
      'artist': q.artist,
      'artworkUrl': q.artworkUrl,
      'player1Score': player1.totalScore,
      'player2Score': player2.totalScore,
    };

    player1.send(endPayload);
    player2.send(endPayload);

    // Sonraki tura veya maç sonuna geç
    Timer(const Duration(milliseconds: 2500), () {
      if (currentRound + 1 < questions.length) {
        _startRound(currentRound + 1);
      } else {
        _finishMatch();
      }
    });
  }

  void _finishMatch() {
    if (isFinished) return;
    isFinished = true;
    roundTimer?.cancel();

    final matchSummary = {
      'type': 'match_over',
      'player1': {
        'id': player1.id,
        'name': player1.name,
        'score': player1.totalScore,
      },
      'player2': {
        'id': player2.id,
        'name': player2.name,
        'score': player2.totalScore,
      },
      'songs': questions.map((q) => {
        'title': q.title,
        'artist': q.artist,
        'artworkUrl': q.artworkUrl,
      }).toList(),
    };

    player1.send(matchSummary);
    player2.send(matchSummary);
  }

  void handleDisconnect(Player disconnectedPlayer) {
    if (isFinished) return;
    isFinished = true;
    roundTimer?.cancel();

    final other = (disconnectedPlayer == player1) ? player2 : player1;
    other.send({
      'type': 'opponent_disconnected',
      'message': '${disconnectedPlayer.name} bağlantıyı kesti. Kazanan sensin!',
    });
  }
}

class Matchmaker {
  final Map<String, List<Player>> _waitingQueues = {};
  final Map<String, DuelRoom> _activeRooms = {};
  final Random _rnd = Random();

  void enqueue(Player player, String categoryId) async {
    _waitingQueues.putIfAbsent(categoryId, () => []);
    final queue = _waitingQueues[categoryId]!;

    // Varsa eski kaydını temizle
    queue.removeWhere((p) => p.id == player.id);
    queue.add(player);

    print('👤 [Kuyruk] ${player.name} (${player.platform}) $categoryId sırasına girdi. Kuyrukta: ${queue.length} kişi.');

    if (queue.length >= 2) {
      final p1 = queue.removeAt(0);
      final p2 = queue.removeAt(0);

      print('⚡ [EŞLEŞME] ${p1.name} VS ${p2.name} ($categoryId)!');
      final questions = await _fetchQuestions(categoryId);

      final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
      final room = DuelRoom(
        id: roomId,
        categoryId: categoryId,
        player1: p1,
        player2: p2,
        questions: questions,
      );

      _activeRooms[p1.id] = room;
      _activeRooms[p2.id] = room;

      room.start();
    }
  }

  void handleAnswer(Player player, int optionIndex, int remainingMs) {
    final room = _activeRooms[player.id];
    if (room != null) {
      room.handleAnswer(player, optionIndex, remainingMs);
    }
  }

  void removePlayer(Player player) {
    for (final queue in _waitingQueues.values) {
      queue.removeWhere((p) => p.id == player.id);
    }

    final room = _activeRooms.remove(player.id);
    if (room != null) {
      room.handleDisconnect(player);
    }
  }

  Future<List<QuestionItem>> _fetchQuestions(String categoryId) async {
    // Apple iTunes API'den canlı çekim
    final artists = _getArtistsForCategory(categoryId)..shuffle(_rnd);
    final selectedArtists = artists.take(4).toList();

    List<Map<String, dynamic>> rawSongs = [];
    final client = HttpClient();

    for (final artist in selectedArtists) {
      try {
        final uri = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(artist)}&country=tr&media=music&entity=song&limit=12',
        );
        final req = await client.getUrl(uri);
        final resp = await req.close();
        if (resp.statusCode == 200) {
          final body = await resp.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          for (final item in data['results'] ?? []) {
            final preview = item['previewUrl'] as String?;
            if (preview != null && preview.isNotEmpty) {
              rawSongs.add(item);
            }
          }
        }
      } catch (e) {
        // Hata durumunda devam et
      }
    }
    client.close();

    // 5 soru oluştur
    rawSongs.shuffle(_rnd);
    final targetSongs = rawSongs.take(5).toList();

    List<QuestionItem> questions = [];
    for (int i = 0; i < targetSongs.length; i++) {
      final s = targetSongs[i];
      final title = _cleanTitle(s['trackName'] ?? 'Bilinmeyen');
      final artist = s['artistName'] ?? 'Bilinmeyen';
      String artwork = (s['artworkUrl100'] ?? '').replaceAll('100x100bb', '600x600bb');
      final preview = s['previewUrl'] ?? '';

      final isTitleQuestion = _rnd.nextBool();
      final promptText = isTitleQuestion ? 'Bu Şarkının Adı Ne?' : 'Bu Şarkıyı Kim Söylüyor?';
      final correctAnswer = isTitleQuestion ? title : artist;

      List<String> options = [correctAnswer];
      for (final other in rawSongs) {
        final opt = isTitleQuestion
            ? _cleanTitle(other['trackName'] ?? '')
            : (other['artistName'] ?? '');
        if (!options.contains(opt) && opt.isNotEmpty) {
          options.add(opt);
        }
        if (options.length >= 4) break;
      }

      while (options.length < 4) {
        options.add('Seçenek ${options.length + 1}');
      }

      options.shuffle(_rnd);
      final correctIndex = options.indexOf(correctAnswer);

      questions.add(QuestionItem(
        title: title,
        artist: artist,
        previewUrl: preview,
        artworkUrl: artwork,
        promptText: promptText,
        options: options,
        correctIndex: correctIndex,
      ));
    }

    return questions;
  }

  List<String> _getArtistsForCategory(String cat) {
    switch (cat) {
      case 'pop_90s':
        return ['Tarkan', 'Sezen Aksu', 'Mustafa Sandal', 'Kenan Doğulu', 'Sertab Erener', 'Mirkelam', 'Burak Kut'];
      case 'rock_tr':
        return ['Barış Manço', 'Cem Karaca', 'Erkin Koray', 'Duman', 'Mor ve Ötesi', 'Şebnem Ferah', 'Teoman'];
      case 'hit_2000s':
        return ['Hande Yener', 'Demet Akalın', 'Serdar Ortaç', 'Yalın', 'Murat Boz', 'Sıla', 'Gülşen'];
      case 'rap_tr':
        return ['Ceza', 'Sagopa Kajmer', 'Ezhel', 'Şanışer', 'Motive', 'Norm Ender', 'Uzi'];
      case 'arabesk_tr':
      default:
        return ['Müslüm Gürses', 'Ferdi Tayfur', 'İbrahim Tatlıses', 'Orhan Gencebay', 'Bergen'];
    }
  }

  String _cleanTitle(String raw) {
    var c = raw.replaceAll(RegExp(r'\[.*?\]'), '');
    if (c.contains('(feat.')) c = c.replaceAll(RegExp(r'\(feat\..*?\)'), '');
    if (c.contains('(Remastered')) c = c.replaceAll(RegExp(r'\(Remastered.*?\)'), '');
    return c.trim();
  }
}

void main() async {
  final matchmaker = Matchmaker();
  final port = 6060;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('========================================================');
  print('🚀 Müzik Düellosu WebSocket Sunucusu Aktif!');
  print('📍 Adres: ws://0.0.0.0:$port (veya ws://192.168.1.180:$port)');
  print('========================================================');

  await for (HttpRequest req in server) {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      try {
        final socket = await WebSocketTransformer.upgrade(req);
        Player? player;

        socket.listen((message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            final type = data['type'] as String?;

            if (type == 'join_queue') {
              final id = data['playerId'] ?? 'p_${DateTime.now().millisecondsSinceEpoch}';
              final name = data['playerName'] ?? 'Oyuncu';
              final avatar = data['avatar'] ?? '🎧';
              final platform = data['platform'] ?? 'Bilinmeyen';
              final category = data['category'] ?? 'pop_90s';

              player = Player(
                id: id,
                name: name,
                avatar: avatar,
                platform: platform,
                socket: socket,
              );

              matchmaker.enqueue(player!, category);
            } else if (type == 'submit_answer' && player != null) {
              final optionIndex = data['optionIndex'] as int;
              final remainingMs = data['timeRemainingMs'] as int;
              matchmaker.handleAnswer(player!, optionIndex, remainingMs);
            }
          } catch (e) {
            print('Mesaj işleme hatası: $e');
          }
        }, onDone: () {
          if (player != null) {
            print('❌ [Ayrıldı] ${player!.name} (${player!.platform})');
            matchmaker.removePlayer(player!);
          }
        }, onError: (err) {
          if (player != null) {
            matchmaker.removePlayer(player!);
          }
        });
      } catch (e) {
        print('WebSocket upgrade hatası: $e');
      }
    } else {
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write('Muzik Duellosu Server is running.')
        ..close();
    }
  }
}
