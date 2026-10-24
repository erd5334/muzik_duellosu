class PartyPlayer {
  final String id;
  final String name;
  final String avatar;
  int score;
  int roundScore;
  bool isHost;
  bool hasAnswered;
  bool? isCorrect;
  int? selectedOptionIndex;
  int timeSpentMs;
  int rank;

  PartyPlayer({
    required this.id,
    required this.name,
    required this.avatar,
    this.score = 0,
    this.roundScore = 0,
    this.isHost = false,
    this.hasAnswered = false,
    this.isCorrect,
    this.selectedOptionIndex,
    this.timeSpentMs = 0,
    this.rank = 1,
  });

  factory PartyPlayer.fromJson(Map<String, dynamic> json) {
    return PartyPlayer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Oyuncu',
      avatar: json['avatar'] as String? ?? '🎧',
      score: json['score'] as int? ?? 0,
      roundScore: json['roundScore'] as int? ?? 0,
      isHost: json['isHost'] as bool? ?? false,
      hasAnswered: json['hasAnswered'] as bool? ?? false,
      isCorrect: json['isCorrect'] as bool?,
      selectedOptionIndex: json['selectedOptionIndex'] as int?,
      timeSpentMs: json['timeSpentMs'] as int? ?? 0,
      rank: json['rank'] as int? ?? 1,
    );
  }
}

class PartyPodiumPlayer {
  final String id;
  final String name;
  final String avatar;
  final int score;
  final int correctCount;
  final String averageTimeSec;
  final int rank;

  PartyPodiumPlayer({
    required this.id,
    required this.name,
    required this.avatar,
    required this.score,
    required this.correctCount,
    required this.averageTimeSec,
    required this.rank,
  });

  factory PartyPodiumPlayer.fromJson(Map<String, dynamic> json) {
    return PartyPodiumPlayer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Oyuncu',
      avatar: json['avatar'] as String? ?? '🎧',
      score: json['score'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      averageTimeSec: json['averageTimeSec']?.toString() ?? '0.0',
      rank: json['rank'] as int? ?? 1,
    );
  }
}

class PartyRoomData {
  final String roomCode;
  String hostId;
  String categoryId;
  int roundCount;
  int roundDurationSec;
  List<PartyPlayer> players;
  List<PartyPodiumPlayer> podium;
  List<PartyPlayer> finalRankings;

  PartyRoomData({
    required this.roomCode,
    required this.hostId,
    required this.categoryId,
    required this.roundCount,
    required this.roundDurationSec,
    required this.players,
    this.podium = const [],
    this.finalRankings = const [],
  });

  factory PartyRoomData.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>? ?? {};
    final pList = (json['players'] as List<dynamic>? ?? [])
        .map((p) => PartyPlayer.fromJson(p as Map<String, dynamic>))
        .toList();

    return PartyRoomData(
      roomCode: json['roomCode']?.toString() ?? '',
      hostId: json['hostId'] as String? ?? '',
      categoryId: settings['category'] as String? ?? 'pop_90s',
      roundCount: settings['roundCount'] as int? ?? 5,
      roundDurationSec: settings['roundDurationSec'] as int? ?? 10,
      players: pList,
    );
  }
}
