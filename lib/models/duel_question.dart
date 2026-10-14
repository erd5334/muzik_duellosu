import 'song.dart';

enum QuestionType { songTitle, artistName }

class DuelQuestion {
  final Song song;
  final QuestionType type;
  final List<String> options; // 4 seçenek
  int correctOptionIndex;
  final String? customPrompt;
  
  bool isAnswered = false;
  int? selectedOptionIndex;
  int userScoreEarned = 0;
  int opponentScoreEarned = 0;
  Set<int> eliminatedOptions = {}; // 50/50 jokeri için elenenler

  DuelQuestion({
    required this.song,
    required this.type,
    required this.options,
    this.correctOptionIndex = -1,
    this.customPrompt,
  });

  String get promptText {
    if (customPrompt != null && !customPrompt!.contains('??') && customPrompt!.isNotEmpty) {
      return customPrompt!;
    }
    return type == QuestionType.songTitle ? 'Bu Şarkının Adı Ne?' : 'Bu Şarkıyı Kim Söylüyor?';
  }

  String get correctAnswer =>
      (correctOptionIndex >= 0 && correctOptionIndex < options.length) ? options[correctOptionIndex] : '';
}
