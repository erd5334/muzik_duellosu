import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/duel_question.dart';
import '../models/category_model.dart';
import '../models/daily_song_model.dart';

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

  // ==================== GÜNÜN ŞARKISI (HEARDLE) ====================

  static final List<DailySongItem> _curatedDailySongs = [
    const DailySongItem(
      artist: 'Barış Manço',
      title: 'Gülpembe',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/bf/25/4b/bf254b04-f5f4-279c-7b3b-857e4e137a6b/cover.jpg/600x600bb.jpg',
      previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/4a/1c/b5/4a1cb5b9-1f48-a083-0975-f8b1e4277bbf/mzaf_7824883391851240366.plus.aac.p.m4a',
    ),
    const DailySongItem(
      artist: 'Tarkan',
      title: 'Kıl Oldum',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/8e/3c/64/8e3c64c1-eebe-86a3-d02f-bfa4a6d2fdbd/cover.jpg/600x600bb.jpg',
      previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/a5/d2/97/a5d29792-50d4-8d96-c143-bf688f98ec4e/mzaf_16480579973216892556.plus.aac.p.m4a',
    ),
    const DailySongItem(
      artist: 'Sezen Aksu',
      title: 'Sen Ağlama',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/40/e3/d3/40e3d386-8968-3e3c-f4b0-a35948332aa6/cover.jpg/600x600bb.jpg',
      previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/8f/3e/eb/8f3eeb88-06fc-8d13-cb2e-e4787a2a059b/mzaf_10672776366099953833.plus.aac.p.m4a',
    ),
    const DailySongItem(
      artist: 'Duman',
      title: 'Senden Daha Güzel',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/eb/fa/d7/ebfad733-4f05-7f41-0ca0-be58d4a5db22/cover.jpg/600x600bb.jpg',
      previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/c3/85/3e/c3853e5e-5b23-74b5-bf6e-6be12cf2c498/mzaf_1495026922572520853.plus.aac.p.m4a',
    ),
    const DailySongItem(
      artist: 'Müslüm Gürses',
      title: 'Affet',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/f4/bc/cf/f4bccc58-48b8-7c85-e115-45c10b7b122e/cover.jpg/600x600bb.jpg',
      previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/b9/ca/26/b9ca26a2-6eb6-dc46-d242-cf1097fa668e/mzaf_13501258837372228392.plus.aac.p.m4a',
    ),
    const DailySongItem(
      artist: 'Sertab Erener',
      title: 'Yanarım',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/0c/33/c0/0c33c0ce-d4a9-85e8-5ee4-ee49b290cb7c/cover.jpg/600x600bb.jpg',
      previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/8b/6f/a7/8b6fa7c5-d72b-8390-34ee-38e932b13be9/mzaf_6755498877119159937.plus.aac.p.m4a',
    ),
    const DailySongItem(
      artist: 'Kenan Doğulu',
      title: 'Yaparım Bilirsin',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/5e/5c/bb/5e5cbb34-871c-43f1-d009-844c8df6395b/cover.jpg/600x600bb.jpg',
      previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/21/29/7a/21297a7f-c6ad-45e3-cf9e-6ce5cb6a2b8e/mzaf_17292271811560388913.plus.aac.p.m4a',
    ),
    const DailySongItem(
      artist: 'Şebnem Ferah',
      title: 'Sil Baştan',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/ee/1f/ef/ee1fef0a-a035-71c1-11a5-e36611f7c653/cover.jpg/600x600bb.jpg',
      previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/9c/04/aa/9c04aa60-0d92-23c3-6316-f368fdfb5eb7/mzaf_11843105159048383842.plus.aac.p.m4a',
    ),
    const DailySongItem(
      artist: 'Mor ve Ötesi',
      title: 'Bir Derdim Var',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/80/7e/d3/807ed37e-61ea-f725-d913-6f8101a93e36/cover.jpg/600x600bb.jpg',
      previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/1b/2a/82/1b2a829f-3ef8-cceb-d98c-8f43eb911850/mzaf_16238612140409865181.plus.aac.p.m4a',
    ),
    const DailySongItem(
      artist: 'Haluk Levent',
      title: 'Elfida',
      artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/e0/75/4a/e0754a1d-a3df-a6df-16fc-0c2ef3a778c1/cover.jpg/600x600bb.jpg',
      previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/7e/6b/6b/7e6b6b77-d3c5-bc9a-b44c-c376174a7b54/mzaf_13506169527712398501.plus.aac.p.m4a',
    ),
  ];

  Future<DailySongData> fetchDailySong() async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      final response = await http
          .get(Uri.parse('http://80.253.246.132:6060/api/daily-song?date=$dateStr'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DailySongData.fromJson(data);
      }
    } catch (e) {
      // Çevrimdışı veya sunucu gecikmesinde fallback çalışır
    }

    // Fallback: Deterministic günlük şarkı
    int hash = 0;
    for (int i = 0; i < dateStr.length; i++) {
      hash = ((hash << 5) - hash) + dateStr.codeUnitAt(i);
      hash &= 0x7FFFFFFF;
    }
    final index = hash % _curatedDailySongs.length;
    final selected = _curatedDailySongs[index];

    final searchPool = _curatedDailySongs.map((s) => s.displayName).toList();

    return DailySongData(
      date: dateStr,
      dayNumber: (hash % 1000) + 1,
      song: selected,
      searchPool: searchPool,
    );
  }
}
