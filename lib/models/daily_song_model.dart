class DailySongItem {
  final String title;
  final String artist;
  final String previewUrl;
  final String artworkUrl;

  const DailySongItem({
    required this.title,
    required this.artist,
    required this.previewUrl,
    required this.artworkUrl,
  });

  String get displayName => '$artist - $title';

  factory DailySongItem.fromJson(Map<String, dynamic> json) {
    return DailySongItem(
      title: json['title'] as String? ?? 'Bilinmeyen Şarkı',
      artist: json['artist'] as String? ?? 'Bilinmeyen Sanatçı',
      previewUrl: json['previewUrl'] as String? ?? '',
      artworkUrl: json['artworkUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'previewUrl': previewUrl,
    'artworkUrl': artworkUrl,
  };
}

class DailySongData {
  final String date;
  final int dayNumber;
  final DailySongItem song;
  final List<String> searchPool;

  const DailySongData({
    required this.date,
    required this.dayNumber,
    required this.song,
    required this.searchPool,
  });

  factory DailySongData.fromJson(Map<String, dynamic> json) {
    return DailySongData(
      date: json['date'] as String? ?? '',
      dayNumber: json['dayNumber'] as int? ?? 1,
      song: DailySongItem.fromJson((json['song'] as Map<String, dynamic>?) ?? {}),
      searchPool: (json['searchPool'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class DailySongAttempt {
  final String? guess;
  final bool isSkipped;
  final bool isCorrect;

  const DailySongAttempt({
    this.guess,
    this.isSkipped = false,
    this.isCorrect = false,
  });

  Map<String, dynamic> toJson() => {
    'guess': guess,
    'isSkipped': isSkipped,
    'isCorrect': isCorrect,
  };

  factory DailySongAttempt.fromJson(Map<String, dynamic> json) {
    return DailySongAttempt(
      guess: json['guess'] as String?,
      isSkipped: json['isSkipped'] as bool? ?? false,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }
}

class DailySongProgress {
  final String date;
  final List<DailySongAttempt> attempts;
  bool isCompleted;
  bool isWon;
  int solvedStep; // 1 to 6 (0 if lost)

  static const List<double> stepSeconds = [1.0, 2.0, 4.0, 7.0, 11.0, 16.0];
  static const int maxAttempts = 6;

  DailySongProgress({
    required this.date,
    List<DailySongAttempt>? attempts,
    this.isCompleted = false,
    this.isWon = false,
    this.solvedStep = 0,
  }) : attempts = attempts ?? [];

  int get currentStep => attempts.length;

  double get unlockedSeconds {
    if (isCompleted && isWon) return stepSeconds.last;
    final idx = currentStep.clamp(0, stepSeconds.length - 1);
    return stepSeconds[idx];
  }

  String get emojiSummary {
    final buffer = StringBuffer();
    for (int i = 0; i < maxAttempts; i++) {
      if (i < attempts.length) {
        final a = attempts[i];
        if (a.isCorrect) {
          buffer.write('🟩');
        } else if (a.isSkipped) {
          buffer.write('⬛');
        } else {
          buffer.write('🟥');
        }
      } else {
        buffer.write('⬜');
      }
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'attempts': attempts.map((a) => a.toJson()).toList(),
    'isCompleted': isCompleted,
    'isWon': isWon,
    'solvedStep': solvedStep,
  };

  factory DailySongProgress.fromJson(Map<String, dynamic> json) {
    final rawAttempts = json['attempts'] as List<dynamic>? ?? [];
    return DailySongProgress(
      date: json['date'] as String? ?? '',
      attempts: rawAttempts.map((a) => DailySongAttempt.fromJson(a as Map<String, dynamic>)).toList(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isWon: json['isWon'] as bool? ?? false,
      solvedStep: json['solvedStep'] as int? ?? 0,
    );
  }
}
