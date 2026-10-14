import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/duel_question.dart';
import '../models/category_model.dart';

class MusicApiService {
  static final MusicApiService _instance = MusicApiService._internal();
  factory MusicApiService() => _instance;
  MusicApiService._internal();

  final Map<String, List<Song>> _categoryCache = {};
  final Random _rnd = Random();

  // Sabit Türk Sanatçı Havuzları (Geniş ve garanti arama terimleri)
  final Map<String, List<String>> _curatedArtists = {
    'pop_90s': [
      'Tarkan', 'Sezen Aksu', 'Mustafa Sandal', 'Kenan Doğulu',
      'Sertab Erener', 'Burak Kut', 'Mirkelam', 'Levent Yüksel',
      'Aşkın Nur Yengi', 'Yaşar', 'Harun Kolçak', 'İzel'
    ],
    'rock_tr': [
      'Barış Manço', 'Cem Karaca', 'Erkin Koray', 'Duman',
      'Mor ve Ötesi', 'Şebnem Ferah', 'Haluk Levent', 'Teoman',
      'Moğollar', 'Kurtalan Ekspres', 'Pentagram', 'Kurban'
    ],
    'hit_2000s': [
      'Hande Yener', 'Demet Akalın', 'Serdar Ortaç', 'Yalın',
      'Murat Boz', 'Sıla', 'Gülşen', 'Hadise',
      'Bengü', 'Gökhan Türkmen', 'Atiye', 'Emre Aydın'
    ],
    'rap_tr': [
      'Ceza', 'Sagopa Kajmer', 'Ezhel', 'Şanışer',
      'Norm Ender', 'Motive', 'Uzi', 'Gazapizm',
      'Şehinşah', 'Anıl Piyancı', 'Allame', 'Sefo'
    ],
    'arabesk_tr': [
      'Müslüm Gürses', 'Ferdi Tayfur', 'İbrahim Tatlıses', 'Orhan Gencebay',
      'Bergen', 'Kibariye', 'Güllü', 'Ceylan',
      'Azer Bülbül', 'Ebru Gündeş', 'Sibel Can', 'Hakan Taşıyan'
    ],
  };

  /// Kategoriye ait şarkıları Apple iTunes API üzerinden çeker
  Future<List<Song>> fetchSongsForCategory(MusicCategory category) async {
    if (_categoryCache.containsKey(category.id) && _categoryCache[category.id]!.length >= 10) {
      return _categoryCache[category.id]!;
    }

    List<Song> songs = [];
    final List<String> artists = _curatedArtists[category.id] ??
        (category.searchQuery.isNotEmpty
            ? category.searchQuery.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
            : [category.title]);

    final isSingleArtist = artists.length == 1;
    // Rastgele sanatçılar seç veya tek sanatçıysa onu al
    final shuffledArtists = List<String>.from(artists)..shuffle(_rnd);
    final selectedArtists = shuffledArtists.take(isSingleArtist ? 1 : 4);

    for (final artist in selectedArtists) {
      try {
        final uri = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(artist)}&country=tr&media=music&entity=song&limit=${isSingleArtist ? 50 : 15}',
        );

        final response = await http.get(uri).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = data['results'] as List<dynamic>? ?? [];
          final artistMatches = isSingleArtist
              ? results.where((item) => (item['artistName'] as String? ?? '').toLowerCase().contains(artist.toLowerCase())).length
              : 0;
          final isTrueSingleArtist = isSingleArtist && (artistMatches >= 2 || results.length <= 3);

          for (final item in results) {
            final preview = item['previewUrl'] as String?;
            if (preview != null && preview.isNotEmpty) {
              if (isTrueSingleArtist) {
                final itemArtist = (item['artistName'] as String? ?? '').toLowerCase();
                if (!itemArtist.contains(artist.toLowerCase())) continue;
              }
              songs.add(Song.fromAppleJson(item, category.id));
            }
          }
        }
      } catch (e) {
        // Ağ hatası veya timeout durumunda devam et
      }
    }

    // Şarkıları karıştır ve aynı şarkı adlarını tekilleştir
    final uniqueSongs = <String, Song>{};
    for (final s in songs) {
      final key = '${s.artist}_${s.title}'.toLowerCase();
      if (!uniqueSongs.containsKey(key)) {
        uniqueSongs[key] = s;
      }
    }

    // Eğer havuz 5'ten azsa genel kategoriden takviye yap (asla boş kalmaz)
    if (uniqueSongs.length < 5 && category.id != 'pop_90s') {
      final fallbackSongs = await fetchSongsForCategory(MusicCategory.defaultCategories.first);
      for (final s in fallbackSongs) {
        final key = '${s.artist}_${s.title}'.toLowerCase();
        if (!uniqueSongs.containsKey(key)) {
          uniqueSongs[key] = s;
        }
      }
    }

    final resultList = uniqueSongs.values.toList()..shuffle(_rnd);
    _categoryCache[category.id] = resultList;
    return resultList;
  }

  /// 5 soruluk bir düello turu hazırlar (Doğru şarkı + 3 çeldirici seçenek)
  Future<List<DuelQuestion>> generateDuelQuestions(MusicCategory category, {int roundCount = 5}) async {
    final pool = await fetchSongsForCategory(category);
    if (pool.length < 5) {
      throw Exception('Yeterli şarkı bulunamadı. Lütfen internet bağlantınızı kontrol edin.');
    }

    final shuffledPool = List<Song>.from(pool)..shuffle(_rnd);
    final selectedSongs = shuffledPool.take(roundCount).toList();

    // Havuzda 4'ten az farklı sanatçı varsa (Tek Sanatçı / Özel Sanatçı Modu), her zaman Şarkı Adı sorusu sor
    final uniqueArtists = pool.map((s) => s.artist.toLowerCase()).toSet();
    final isSingleArtistMode = uniqueArtists.length < 4;

    List<DuelQuestion> questions = [];

    for (int i = 0; i < selectedSongs.length; i++) {
      final targetSong = selectedSongs[i];
      // Tek sanatçı modunda her zaman şarkı adı sorulur
      final type = isSingleArtistMode
          ? QuestionType.songTitle
          : (_rnd.nextBool() ? QuestionType.songTitle : QuestionType.artistName);

      List<String> options = [];
      String correctAnswer = type == QuestionType.songTitle ? targetSong.title : targetSong.artist;
      options.add(correctAnswer);

      // Havuzdan 3 adet çeldirici bul
      final otherSongs = pool.where((s) => s.id != targetSong.id).toList()..shuffle(_rnd);
      for (final other in otherSongs) {
        final optionVal = type == QuestionType.songTitle ? other.title : other.artist;
        if (!options.contains(optionVal) && optionVal.isNotEmpty) {
          options.add(optionVal);
        }
        if (options.length >= 4) break;
      }

      // Eğer 4 seçenek dolmadıysa yedek ekle
      while (options.length < 4) {
        options.add('Seçenek ${options.length + 1}');
      }

      // Seçenekleri karıştır
      options.shuffle(_rnd);
      final correctIndex = options.indexOf(correctAnswer);

      questions.add(DuelQuestion(
        song: targetSong,
        type: type,
        options: options,
        correctOptionIndex: correctIndex,
      ));
    }

    return questions;
  }
}
