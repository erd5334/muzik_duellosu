const http = require('http');
const https = require('https');
const WebSocket = require('ws');

const path = require('path');
const fs = require('fs');

const PORT = 6060;

// SQLite Veritabanı Kurulumu (Kendi Sunucumuz)
let db = null;
try {
  const { DatabaseSync } = require('node:sqlite');
  const dbPath = path.join(__dirname, 'database.sqlite');
  db = new DatabaseSync(dbPath);
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      google_id TEXT PRIMARY KEY,
      email TEXT,
      name TEXT,
      avatar TEXT,
      energy INTEGER DEFAULT 10,
      coins INTEGER DEFAULT 350,
      powerup_count INTEGER DEFAULT 2,
      has_no_ads INTEGER DEFAULT 0,
      is_vip INTEGER DEFAULT 0,
      badges_data TEXT,
      stats_json TEXT DEFAULT '{}',
      last_energy_timestamp INTEGER DEFAULT 0,
      last_login INTEGER
    );

    CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      title TEXT,
      subtitle TEXT,
      color_hex TEXT,
      search_query TEXT,
      icon_name TEXT DEFAULT 'album',
      display_order INTEGER DEFAULT 0,
      is_active INTEGER DEFAULT 1
    );

    CREATE TABLE IF NOT EXISTS badges (
      id TEXT PRIMARY KEY,
      category_id TEXT,
      artist_name TEXT,
      title TEXT,
      tier TEXT,
      total_shards INTEGER,
      emoji TEXT,
      image_url TEXT,
      display_order INTEGER DEFAULT 0,
      is_active INTEGER DEFAULT 1
    );

    CREATE TABLE IF NOT EXISTS store_items (
      id TEXT PRIMARY KEY,
      type TEXT DEFAULT 'in_app',
      title TEXT,
      subtitle TEXT,
      price_label TEXT,
      coins_cost INTEGER DEFAULT 0,
      badge_label TEXT,
      badge_color TEXT,
      icon TEXT,
      display_order INTEGER DEFAULT 0,
      is_active INTEGER DEFAULT 1,
      rewards_json TEXT
    );

    CREATE TABLE IF NOT EXISTS season_pass (
      id TEXT PRIMARY KEY,
      data_json TEXT,
      updated_at INTEGER
    );
  `);

  // Güvenli Sütun Migrasyonu (Mevcut Veritabanı İçin)
  try { db.exec("ALTER TABLE categories ADD COLUMN search_query TEXT"); } catch (_) {}
  try { db.exec("ALTER TABLE categories ADD COLUMN icon_name TEXT DEFAULT 'album'"); } catch (_) {}

  // Başlangıç Kategorilerini ve Plaklarını Veritabanına Tohumla (Seed)
  const catCount = db.prepare('SELECT COUNT(*) as count FROM categories').get().count;
  if (catCount === 0) {
    const seedCategories = [
      ['pop_90s', "90'lar Türkçe Pop", "Tarkan, Sezen Aksu, Kenan Doğulu...", "#F59E0B", "90lar turkce pop", "album", 1],
      ['rock_tr', "Anadolu Rock & Türkçe Rock", "Barış Manço, Cem Karaca, Duman...", "#EF4444", "anadolu rock", "bolt", 2],
      ['hit_2000s', "2000'ler Türkçe Hit", "Hande Yener, Demet Akalın, Serdar Ortaç...", "#3B82F6", "2000ler turkce hit", "headphones", 3],
      ['pop_2010s', "2010+ Günümüz Pop & Alternatif", "Mabel Matiz, Edis, Simge...", "#EC4899", "turkce pop hit", "sparkles", 4],
      ['rap_tr', "Türkçe Rap & HipHop", "Ceza, Sagopa Kajmer, Ezhel...", "#10B981", "turkce rap", "speaker", 5],
      ['arabesk_tr', "Damar & Arabesk Klasikleri", "Müslüm Gürses, Ferdi Tayfur, İbrahim Tatlıses...", "#8B5CF6", "muslum gurses ibrahim tatlises", "note", 6],
      ['turku_tr', "Türküler & Ozanlar", "Neşet Ertaş, Aşık Veysel, Selda Bağcan...", "#14B8A6", "turkuler neset ertas", "album", 7],
      ['nostalji_tr', "70'ler & 80'ler Nostalji", "Ajda Pekkan, Nilüfer, Erol Evgin...", "#F97316", "yesilcam nostalji 70ler", "radio", 8],
      ['karma_all', "Karma Çalma Listesi (Hepsi)", "90lar, 2000ler, Pop, Rock, Rap, Arabesk - Tüm Şarkılar!", "#E11D48", "turkce hit karma", "shuffle", 9],
    ];
    const catStmt = db.prepare('INSERT INTO categories (id, title, subtitle, color_hex, search_query, icon_name, display_order) VALUES (?, ?, ?, ?, ?, ?, ?)');
    for (const c of seedCategories) catStmt.run(...c);
  } else {
    // Mevcut boş arama terimlerini güncelle
    const defaultQueries = {
      pop_90s: { q: '90lar turkce pop', icon: 'album' },
      rock_tr: { q: 'anadolu rock', icon: 'bolt' },
      hit_2000s: { q: '2000ler turkce hit', icon: 'headphones' },
      pop_2010s: { q: 'turkce pop hit', icon: 'sparkles' },
      rap_tr: { q: 'turkce rap', icon: 'speaker' },
      arabesk_tr: { q: 'muslum gurses ibrahim tatlises', icon: 'note' },
      turku_tr: { q: 'turkuler neset ertas', icon: 'album' },
      nostalji_tr: { q: 'yesilcam nostalji 70ler', icon: 'radio' },
      karma_all: { q: 'turkce hit karma', icon: 'shuffle' },
    };
    for (const [cid, info] of Object.entries(defaultQueries)) {
      try {
        db.prepare('UPDATE categories SET search_query = ?, icon_name = ? WHERE id = ? AND (search_query IS NULL OR search_query = "")').run(info.q, info.icon, cid);
      } catch (_) {}
    }
  }

  const badgeCount = db.prepare('SELECT COUNT(*) as count FROM badges').get().count;
  if (badgeCount === 0) {
    const seedBadges = [
      ['pop_burak', 'pop_90s', 'Burak Kut', 'Çırak Popçu', 'Bronz', 15, '🥉', 'https://cdn-images.dzcdn.net/images/artist/46212d700469e5094b2a0342f7ca1f10/250x250-000000-80-0-0.jpg', 1],
      ['pop_kenan', 'pop_90s', 'Kenan Doğulu', 'Festival Ustası', 'Gümüş', 30, '🥈', 'https://cdn-images.dzcdn.net/images/artist/c6676b89507b2f30a5ac8d67013beb7e/250x250-000000-80-0-0.jpg', 2],
      ['pop_sezen', 'pop_90s', 'Sezen Aksu', 'Minik Serçe Mertebesi', 'Altın', 45, '🥇', 'https://cdn-images.dzcdn.net/images/artist/9c62f746db8e41bb49eb13a3c254f597/250x250-000000-80-0-0.jpg', 3],
      ['pop_tarkan', 'pop_90s', 'Tarkan', 'Popun Kralı (Megastar)', 'Elmas', 60, '💎', 'https://cdn-images.dzcdn.net/images/artist/28634a4ad808e5b6bbb6714f06bd5fe8/250x250-000000-80-0-0.jpg', 4],
      ['arabesk_muslum', 'arabesk_tr', 'Müslüm Gürses', 'BABA (Tahtın Sahibi)', 'Elmas', 60, '👑', 'https://cdn-images.dzcdn.net/images/artist/e2f90f2f5ff19404cb530422c42b53ab/250x250-000000-80-0-0.jpg', 5],
      ['arabesk_ibrahim', 'arabesk_tr', 'İbrahim Tatlıses', 'İmparator Plaketi', 'Altın', 45, '🥇', 'https://cdn-images.dzcdn.net/images/artist/9a0d979d2700c25b7812b4739e60d2bc/250x250-000000-80-0-0.jpg', 6],
      ['rock_baris', 'rock_tr', 'Barış Manço', 'Gülpembe Efsanesi', 'Elmas', 60, '🎸', 'https://cdn-images.dzcdn.net/images/artist/4198b876473e604e493f0c0573349ca8/250x250-000000-80-0-0.jpg', 7],
      ['rock_duman', 'rock_tr', 'Duman', 'Köprüaltı Rock Ruhu', 'Gümüş', 30, '🥈', 'https://cdn-images.dzcdn.net/images/artist/420bd789cacec4d562f981f6eae6c76e/250x250-000000-80-0-0.jpg', 8],
      ['rock_sebnem', 'rock_tr', 'Şebnem Ferah', 'Rock Kraliçesi', 'Altın', 45, '🥇', 'https://cdn-images.dzcdn.net/images/artist/c926bdf25de4c5051216bd8bf3d10758/250x250-000000-80-0-0.jpg', 9],
      ['rap_ceza', 'rap_tr', 'Ceza', 'Holokost Hız Rekortmeni', 'Elmas', 60, '🎤', 'https://cdn-images.dzcdn.net/images/artist/2af230afdd9e93989d7d7288e93fb536/250x250-000000-80-0-0.jpg', 10],
      ['rap_sagopa', 'rap_tr', 'Sagopa Kajmer', 'Pesimist Şair', 'Altın', 45, '🥇', 'https://cdn-images.dzcdn.net/images/artist/861348e7f8b6d93d3e2fff5ea6df2dcd/250x250-000000-80-0-0.jpg', 11],
      ['turku_neset', 'turku_tr', 'Neşet Ertaş', 'Bozkırın Tezenesi', 'Elmas', 60, '🪕', 'https://cdn-images.dzcdn.net/images/artist/51a95b2587736cdff03415340c525cb0/250x250-000000-80-0-0.jpg', 12],
      ['nostalji_ajda', 'nostalji_tr', 'Ajda Pekkan', 'Süperstar Mertebesi', 'Elmas', 60, '✨', 'https://cdn-images.dzcdn.net/images/artist/0eb6285bff0fe71843971a6ce94f8404/250x250-000000-80-0-0.jpg', 13],
    ];
    const bStmt = db.prepare('INSERT INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
    for (const b of seedBadges) bStmt.run(...b);
  }

  // Başlangıç Mağaza Paketlerini Tohumla (Seed)
  const storeCount = db.prepare('SELECT COUNT(*) as count FROM store_items').get().count;
  if (storeCount === 0) {
    const seedStore = [
      ['vip_club', 'in_app', 'Altın Plak VIP Kulübü', 'Ömür boyu reklamsız + Sınırsız enerji + 10 Joker + VIP profil rozeti', '₺99,99', 0, '👑 VIP', '#F59E0B', '👑', 1, 1, JSON.stringify({ coins: 0, energy: 9999, jokers: 10, remove_ads: true, is_vip: true })],
      ['remove_ads', 'in_app', 'Reklamları Kaldır', 'Ömür boyu tüm geçiş ve banner reklamları kalkar', '₺49,99', 0, '🛡️ TEMİZ OYUN', '#10B981', '🛡️', 2, 1, JSON.stringify({ coins: 0, energy: 0, jokers: 0, remove_ads: true, is_vip: false })],
      ['coins_500', 'in_app', '500 Altın Çantası', 'Eksik plak parçalarını hemen tamamla', '₺19,99', 0, '', '', '🪙', 3, 1, JSON.stringify({ coins: 500, energy: 0, jokers: 0, remove_ads: false, is_vip: false })],
      ['coins_1500', 'in_app', '1.500 Altın Sandığı', '🎁 +100 Altın Bonus Hediye', '₺49,99', 0, '🔥 POPÜLER', '#F59E0B', '💰', 4, 1, JSON.stringify({ coins: 1500, energy: 0, jokers: 0, remove_ads: false, is_vip: false })],
      ['coins_4000', 'in_app', '4.000 Altın Kasası', '🎁 +500 Altın Bonus Hediye', '₺99,99', 0, '💎 AVANTAJLI', '#3B82F6', '🏦', 5, 1, JSON.stringify({ coins: 4000, energy: 0, jokers: 0, remove_ads: false, is_vip: false })],
      ['coins_10000', 'in_app', '10.000 Altın Hazinesi', '👑 Efsane Plak Sandığı (Tüm Sanatçılar)', '₺199,99', 0, '👑 MEGA', '#8B5CF6', '👑', 6, 1, JSON.stringify({ coins: 10000, energy: 0, jokers: 0, remove_ads: false, is_vip: false })],
      ['energy_10', 'in_app', '10 Enerji', 'Hemen düelloya kesintisiz devam et', '₺9,99', 0, '', '', '⚡', 7, 1, JSON.stringify({ coins: 0, energy: 10, jokers: 0, remove_ads: false, is_vip: false })],
      ['energy_25', 'in_app', '25 Enerji + 2 Joker', '🎁 2 adet %50 jokeri hediye', '₺29,99', 0, 'FIRSAT', '#10B981', '⚡', 8, 1, JSON.stringify({ coins: 0, energy: 25, jokers: 2, remove_ads: false, is_vip: false })],
      ['energy_60', 'in_app', '60 Enerji + 5 Joker', '🎁 5 adet %50 jokeri hediye', '₺49,99', 0, 'POPÜLER', '#F59E0B', '⚡', 9, 1, JSON.stringify({ coins: 0, energy: 60, jokers: 5, remove_ads: false, is_vip: false })],
      ['energy_150', 'in_app', '150 Enerji + 15 Joker', '👑 Maraton Paketi (15 adet %50 jokeri)', '₺99,99', 0, 'DEV PAKET', '#EC4899', '⚡', 10, 1, JSON.stringify({ coins: 0, energy: 150, jokers: 15, remove_ads: false, is_vip: false })],
      ['gold_joker_1', 'in_game', '1 Adet %50 Jokeri', '100 Altın karşılığı 1 joker kazan', '100 Altın', 100, '%50 JOKER', '#F59E0B', '🎯', 11, 1, JSON.stringify({ coins: 0, energy: 0, jokers: 1, remove_ads: false, is_vip: false })],
      ['gold_joker_3', 'in_game', '3 Adet %50 Jokeri', '250 Altın karşılığı 3 joker kazan (50 Altın Tasarruf!)', '250 Altın', 250, 'AVANTAJLI', '#10B981', '🎯', 12, 1, JSON.stringify({ coins: 0, energy: 0, jokers: 3, remove_ads: false, is_vip: false })],
      ['gold_joker_10', 'in_game', '10 Adet %50 Jokeri', '750 Altın karşılığı 10 joker kazan (250 Altın Tasarruf!)', '750 Altın', 750, 'EN POPÜLER', '#EC4899', '🎯', 13, 1, JSON.stringify({ coins: 0, energy: 0, jokers: 10, remove_ads: false, is_vip: false })],
    ];
    const sStmt = db.prepare('INSERT INTO store_items (id, type, title, subtitle, price_label, coins_cost, badge_label, badge_color, icon, display_order, is_active, rewards_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    for (const s of seedStore) sStmt.run(...s);
  }

  // Kullanıcı moderasyon ve istatistik sütunları ekle
  try { db.exec(`ALTER TABLE users ADD COLUMN is_banned INTEGER DEFAULT 0;`); } catch (_) {}
  try { db.exec(`ALTER TABLE users ADD COLUMN ban_reason TEXT DEFAULT '';`); } catch (_) {}
  try { db.exec(`ALTER TABLE users ADD COLUMN stats_json TEXT DEFAULT '{}';`); } catch (_) {}
  try { db.exec(`ALTER TABLE users ADD COLUMN last_energy_timestamp INTEGER DEFAULT 0;`); } catch (_) {}

  console.log('📦 SQLite Veritabanı ve Koleksiyon Tabloları Hazır:', dbPath);
} catch (e) {
  console.error('SQLite başlatılamadı:', e.message);
}

function getAllCategories() {
  if (!db) return [];
  return db.prepare('SELECT * FROM categories WHERE is_active = 1 ORDER BY display_order ASC').all();
}

function getAllBadges() {
  if (!db) return [];
  return db.prepare('SELECT * FROM badges WHERE is_active = 1 ORDER BY display_order ASC').all();
}

function getAllStoreItems(includeInactive = false) {
  if (!db) return [];
  const q = includeInactive
    ? 'SELECT * FROM store_items ORDER BY display_order ASC'
    : 'SELECT * FROM store_items WHERE is_active = 1 ORDER BY display_order ASC';
  return db.prepare(q).all();
}

function getUserByGoogleId(googleId) {
  if (!db) return null;
  const stmt = db.prepare('SELECT * FROM users WHERE google_id = ?');
  return stmt.get(googleId);
}


function getActiveSeasonPass() {
  if (!db) return null;
  try {
    const row = db.prepare('SELECT data_json FROM season_pass WHERE id = ?').get('active_season');
    if (row && row.data_json) {
      return JSON.parse(row.data_json);
    }
  } catch (e) {
    console.error('Season pass okuma hatası:', e);
  }
  return null;
}

function saveActiveSeasonPass(data) {
  if (!db) return false;
  try {
    const jsonStr = typeof data === 'string' ? data : JSON.stringify(data);
    const now = Date.now();
    const existing = db.prepare('SELECT id FROM season_pass WHERE id = ?').get('active_season');
    if (existing) {
      db.prepare('UPDATE season_pass SET data_json = ?, updated_at = ? WHERE id = ?').run(jsonStr, now, 'active_season');
    } else {
      db.prepare('INSERT INTO season_pass (id, data_json, updated_at) VALUES (?, ?, ?)').run('active_season', jsonStr, now);
    }
    return true;
  } catch (e) {
    console.error('Season pass kaydetme hatası:', e);
    return false;
  }
}

const CURATED_DAILY_SONGS = [
  { artist: 'Barış Manço', title: 'Gülpembe', artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/bf/25/4b/bf254b04-f5f4-279c-7b3b-857e4e137a6b/cover.jpg/600x600bb.jpg', previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/4a/1c/b5/4a1cb5b9-1f48-a083-0975-f8b1e4277bbf/mzaf_7824883391851240366.plus.aac.p.m4a' },
  { artist: 'Tarkan', title: 'Kıl Oldum', artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/8e/3c/64/8e3c64c1-eebe-86a3-d02f-bfa4a6d2fdbd/cover.jpg/600x600bb.jpg', previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/a5/d2/97/a5d29792-50d4-8d96-c143-bf688f98ec4e/mzaf_16480579973216892556.plus.aac.p.m4a' },
  { artist: 'Sezen Aksu', title: 'Sen Ağlama', artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/40/e3/d3/40e3d386-8968-3e3c-f4b0-a35948332aa6/cover.jpg/600x600bb.jpg', previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/8f/3e/eb/8f3eeb88-06fc-8d13-cb2e-e4787a2a059b/mzaf_10672776366099953833.plus.aac.p.m4a' },
  { artist: 'Duman', title: 'Senden Daha Güzel', artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/eb/fa/d7/ebfad733-4f05-7f41-0ca0-be58d4a5db22/cover.jpg/600x600bb.jpg', previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/c3/85/3e/c3853e5e-5b23-74b5-bf6e-6be12cf2c498/mzaf_1495026922572520853.plus.aac.p.m4a' },
  { artist: 'Müslüm Gürses', title: 'Affet', artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/f4/bc/cf/f4bccc58-48b8-7c85-e115-45c10b7b122e/cover.jpg/600x600bb.jpg', previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/b9/ca/26/b9ca26a2-6eb6-dc46-d242-cf1097fa668e/mzaf_13501258837372228392.plus.aac.p.m4a' },
  { artist: 'Sertab Erener', title: 'Yanarım', artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/0c/33/c0/0c33c0ce-d4a9-85e8-5ee4-ee49b290cb7c/cover.jpg/600x600bb.jpg', previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/8b/6f/a7/8b6fa7c5-d72b-8390-34ee-38e932b13be9/mzaf_6755498877119159937.plus.aac.p.m4a' },
  { artist: 'Kenan Doğulu', title: 'Yaparım Bilirsin', artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/5e/5c/bb/5e5cbb34-871c-43f1-d009-844c8df6395b/cover.jpg/600x600bb.jpg', previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/21/29/7a/21297a7f-c6ad-45e3-cf9e-6ce5cb6a2b8e/mzaf_17292271811560388913.plus.aac.p.m4a' },
  { artist: 'Şebnem Ferah', title: 'Sil Baştan', artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/ee/1f/ef/ee1fef0a-a035-71c1-11a5-e36611f7c653/cover.jpg/600x600bb.jpg', previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/9c/04/aa/9c04aa60-0d92-23c3-6316-f368fdfb5eb7/mzaf_11843105159048383842.plus.aac.p.m4a' },
  { artist: 'Mor ve Ötesi', title: 'Bir Derdim Var', artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/80/7e/d3/807ed37e-61ea-f725-d913-6f8101a93e36/cover.jpg/600x600bb.jpg', previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/1b/2a/82/1b2a829f-3ef8-cceb-d98c-8f43eb911850/mzaf_16238612140409865181.plus.aac.p.m4a' },
  { artist: 'Haluk Levent', title: 'Elfida', artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/e0/75/4a/e0754a1d-a3df-a6df-16fc-0c2ef3a778c1/cover.jpg/600x600bb.jpg', previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/7e/6b/6b/7e6b6b77-d3c5-bc9a-b44c-c376174a7b54/mzaf_13506169527712398501.plus.aac.p.m4a' }
];

const DAILY_SONG_CACHE = {};

function fetchDeezerTrack(artist, title) {
  return new Promise((resolve) => {
    const q = encodeURIComponent(artist + ' ' + title);
    https.get('https://api.deezer.com/search?q=' + q + '&limit=1', (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        try {
          const j = JSON.parse(d);
          if (j.data && j.data.length > 0 && j.data[0].preview) {
            resolve({
              previewUrl: j.data[0].preview,
              artworkUrl: j.data[0].album && j.data[0].album.cover_big ? j.data[0].album.cover_big : (j.data[0].album ? j.data[0].album.cover_medium : null)
            });
          } else {
            resolve(null);
          }
        } catch (_) { resolve(null); }
      });
    }).on('error', () => resolve(null));
  });
}

async function getDailySongForDate(dateStr) {
  if (DAILY_SONG_CACHE[dateStr]) {
    return DAILY_SONG_CACHE[dateStr];
  }

  let hash = 0;
  for (let i = 0; i < dateStr.length; i++) {
    hash = ((hash << 5) - hash) + dateStr.charCodeAt(i);
    hash |= 0;
  }
  const index = Math.abs(hash) % CURATED_DAILY_SONGS.length;
  const song = { ...CURATED_DAILY_SONGS[index] };
  const searchPool = CURATED_DAILY_SONGS.map(s => s.artist + ' - ' + s.title);

  try {
    const live = await fetchDeezerTrack(song.artist, song.title);
    if (live && live.previewUrl) {
      song.previewUrl = live.previewUrl;
      if (live.artworkUrl) song.artworkUrl = live.artworkUrl;
    }
  } catch (_) {}

  const result = {
    date: dateStr,
    dayNumber: Math.abs(hash) % 1000 + 1,
    song: song,
    searchPool: searchPool
  };
  DAILY_SONG_CACHE[dateStr] = result;
  return result;
}

const LEGACY_BADGE_MAP = {
  'pop_tarkan': 'badge_pop_tarkan',
  'pop_sezen': 'badge_pop_sezen_aksu',
  'pop_kenan': 'badge_pop_kenan_dogulu',
  'pop_burak': 'badge_pop_burak_kut',
  'arabesk_muslum': 'badge_arabesk_muslum_gurses',
  'arabesk_ibrahim': 'badge_arabesk_ibrahim_tatlises',
  'rock_baris': 'badge_rock_baris_manco',
  'rock_duman': 'badge_rock_duman',
  'rock_sebnem': 'badge_rock_sebnem_ferah',
  'rap_ceza': 'badge_rap_ceza',
  'rap_sagopa': 'badge_rap_sagopa_kajmer',
  'turku_neset': 'badge_turku_neset_ertas',
  'nostalji_ajda': 'badge_nostalji_ajda_pekkan',
};

function mergeBadges(existingJson, incomingJson) {
  let existing = {};
  let incoming = {};
  try { existing = JSON.parse(existingJson || '{}'); } catch (_) {}
  try { incoming = JSON.parse(incomingJson || '{}'); } catch (_) {}

  function normalizeMap(map) {
    const res = {};
    for (const [k, v] of Object.entries(map)) {
      const targetKey = LEGACY_BADGE_MAP[k] || k;
      if (!res[targetKey] || ((v.currentShards || 0) > (res[targetKey].currentShards || 0))) {
        res[targetKey] = { ...v };
      }
    }
    return res;
  }

  const normExisting = normalizeMap(existing);
  const normIncoming = normalizeMap(incoming);

  // Mevcut ilerlemeyi ASLA düşürme (Math.max) ve silme
  const merged = { ...normExisting };
  for (const [key, val] of Object.entries(normIncoming)) {
    if (!merged[key]) {
      merged[key] = val;
    } else {
      merged[key] = {
        currentShards: Math.max(merged[key].currentShards || 0, val.currentShards || 0),
        isUnlocked: Boolean(merged[key].isUnlocked || val.isUnlocked),
        isEquipped: val.isEquipped !== undefined ? val.isEquipped : merged[key].isEquipped,
      };
    }
  }

  return JSON.stringify(merged);
}

function mergeStats(existingJson, newJson) {
  let existing = {};
  let current = {};
  try { existing = JSON.parse(existingJson || '{}'); } catch (_) {}
  try {
    current = typeof newJson === 'string' ? JSON.parse(newJson || '{}') : (newJson || {});
  } catch (_) {}

  const merged = { ...current };

  merged.totalMatches = Math.max(existing.totalMatches || 0, current.totalMatches || 0);
  merged.wins = Math.max(existing.wins || 0, current.wins || 0);
  merged.draws = Math.max(existing.draws || 0, current.draws || 0);
  merged.losses = Math.max(existing.losses || 0, current.losses || 0);
  merged.bestStreak = Math.max(existing.bestStreak || 0, current.bestStreak || 0);
  merged.currentStreak = current.currentStreak !== undefined ? current.currentStreak : (existing.currentStreak || 0);
  merged.totalScore = Math.max(existing.totalScore || 0, current.totalScore || 0);
  merged.totalCorrectAnswers = Math.max(existing.totalCorrectAnswers || 0, current.totalCorrectAnswers || 0);

  // categoryStats birleştirme
  merged.categoryStats = { ...(existing.categoryStats || {}) };
  if (current.categoryStats) {
    for (const [k, v] of Object.entries(current.categoryStats)) {
      if (!merged.categoryStats[k]) {
        merged.categoryStats[k] = v;
      } else {
        const existCat = merged.categoryStats[k];
        const artMap = { ...(existCat.artistCorrectAnswers || {}) };
        if (v.artistCorrectAnswers) {
          for (const [ak, av] of Object.entries(v.artistCorrectAnswers)) {
            artMap[ak] = Math.max(artMap[ak] || 0, av || 0);
          }
        }
        merged.categoryStats[k] = {
          matches: Math.max(existCat.matches || 0, v.matches || 0),
          wins: Math.max(existCat.wins || 0, v.wins || 0),
          draws: Math.max(existCat.draws || 0, v.draws || 0),
          losses: Math.max(existCat.losses || 0, v.losses || 0),
          correctAnswers: Math.max(existCat.correctAnswers || 0, v.correctAnswers || 0),
          artistCorrectAnswers: artMap,
        };
      }
    }
  }

  // artistCorrectAnswers genel birleştirme
  merged.artistCorrectAnswers = { ...(existing.artistCorrectAnswers || {}) };
  if (current.artistCorrectAnswers) {
    for (const [k, v] of Object.entries(current.artistCorrectAnswers)) {
      merged.artistCorrectAnswers[k] = Math.max(merged.artistCorrectAnswers[k] || 0, v || 0);
    }
  }

  return JSON.stringify(merged);
}

function saveUser(user) {
  if (!db) return;

  const existing = getUserByGoogleId(user.google_id);
  const safeBadgesData = mergeBadges(existing ? existing.badges_data : '{}', user.badges_data);
  const safeStatsJson = mergeStats(existing ? existing.stats_json : '{}', user.stats_json);
  const safeLastEnergyTimestamp = user.last_energy_timestamp !== undefined
    ? user.last_energy_timestamp
    : (existing ? (existing.last_energy_timestamp || 0) : Date.now());

  const stmt = db.prepare(`
    INSERT INTO users (google_id, email, name, avatar, energy, coins, powerup_count, has_no_ads, is_vip, badges_data, stats_json, last_energy_timestamp, last_login, is_banned, ban_reason)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, '')
    ON CONFLICT(google_id) DO UPDATE SET
      email=excluded.email,
      name=excluded.name,
      avatar=excluded.avatar,
      energy=excluded.energy,
      coins=excluded.coins,
      powerup_count=excluded.powerup_count,
      has_no_ads=excluded.has_no_ads,
      is_vip=excluded.is_vip,
      badges_data=?,
      stats_json=?,
      last_energy_timestamp=?,
      last_login=excluded.last_login
  `);
  stmt.run(
    user.google_id,
    user.email,
    user.name,
    user.avatar,
    user.energy !== undefined ? user.energy : 10,
    user.coins !== undefined ? user.coins : 350,
    user.powerup_count !== undefined ? user.powerup_count : 2,
    user.has_no_ads ? 1 : 0,
    user.is_vip ? 1 : 0,
    safeBadgesData,
    safeStatsJson,
    safeLastEnergyTimestamp,
    Date.now(),
    safeBadgesData,
    safeStatsJson,
    safeLastEnergyTimestamp
  );
}

function fetchDeezerArtistImage(name) {
  return new Promise((resolve) => {
    const url = `https://api.deezer.com/search/artist?q=${encodeURIComponent(name)}`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.data && json.data.length > 0) {
            resolve(json.data[0].picture_medium || json.data[0].picture_big);
          } else {
            resolve(null);
          }
        } catch (_) { resolve(null); }
      });
    }).on('error', () => resolve(null));
  });
}


// ==================== HAFTALIK LİGLER & KÜME SİSTEMİ ====================
const BOT_NAMES = [
  'Melisa', 'Baran_99', 'Ece Rocker', 'Kaan M.', 'Melike_Pop', 'Caner 90s', 'Zeynep_K',
  'Burak TR', 'Ahmet_06', 'Selin Hits', 'Emre Rap', 'Buse_D', 'Oğuzhan', 'Gamze_Y',
  'Mert Can', 'Ezgi_Rock', 'Tolga', 'İrem_S', 'Murat_88', 'Gizem_A', 'Serkan', 'Duygu',
  'Alperen', 'Hilal', 'Onur_Pop'
];
const BOT_AVATARS = ['🎧', '🎸', '🎤', '🎹', '🎷', '🥁', '🎺', '🎻', '🎙️', '💿'];


// ==================== LİG AYARLARI & ÖDÜL MOTORU ====================
const DEFAULT_LEAGUE_CONFIG = {
  isDemotionEnabled: true,
  promotionCutoff: 5,
  demotionCutoff: 21,
  winTrophies: 25,
  lossTrophies: 12,
  tiers: {
    bronze: {
      displayName: 'Bronz Ligi',
      minTrophies: 0,
      coinsReward: 100,
      xpReward: 100,
      jokerShardsReward: 1
    },
    silver: {
      displayName: 'Gümüş Ligi',
      minTrophies: 300,
      coinsReward: 200,
      xpReward: 200,
      jokerShardsReward: 2
    },
    gold: {
      displayName: 'Altın Ligi',
      minTrophies: 800,
      coinsReward: 400,
      xpReward: 350,
      jokerShardsReward: 3
    },
    diamond: {
      displayName: 'Elmas Ligi',
      minTrophies: 1600,
      coinsReward: 800,
      xpReward: 600,
      jokerShardsReward: 5
    },
    legends: {
      displayName: 'Efsaneler Ligi',
      minTrophies: 2800,
      coinsReward: 1500,
      xpReward: 1000,
      jokerShardsReward: 8
    }
  }
};

function getLeagueSettings() {
  if (!db) return DEFAULT_LEAGUE_CONFIG;
  try {
    db.prepare('CREATE TABLE IF NOT EXISTS league_settings (id TEXT PRIMARY KEY, data_json TEXT, updated_at INTEGER)').run();
    const row = db.prepare('SELECT data_json FROM league_settings WHERE id = ?').get('active_league');
    if (row && row.data_json) {
      return JSON.parse(row.data_json);
    }
  } catch (e) {
    console.error('League settings okuma hatası:', e);
  }
  return DEFAULT_LEAGUE_CONFIG;
}

function saveLeagueSettings(data) {
  if (!db) return false;
  try {
    db.prepare('CREATE TABLE IF NOT EXISTS league_settings (id TEXT PRIMARY KEY, data_json TEXT, updated_at INTEGER)').run();
    const jsonStr = typeof data === 'string' ? data : JSON.stringify(data);
    const now = Date.now();
    const existing = db.prepare('SELECT id FROM league_settings WHERE id = ?').get('active_league');
    if (existing) {
      db.prepare('UPDATE league_settings SET data_json = ?, updated_at = ? WHERE id = ?').run(jsonStr, now, 'active_league');
    } else {
      db.prepare('INSERT INTO league_settings (id, data_json, updated_at) VALUES (?, ?, ?)').run('active_league', jsonStr, now);
    }
    return true;
  } catch (e) {
    console.error('League settings kaydetme hatası:', e);
    return false;
  }
}

function getTierForTrophies(trophies) {
  if (trophies >= 2800) return 'legends';
  if (trophies >= 1600) return 'diamond';
  if (trophies >= 800) return 'gold';
  if (trophies >= 300) return 'silver';
  return 'bronze';
}

function getNextSundayDate() {
  const now = new Date();
  const day = now.getDay(); // 0 is Sunday
  const daysUntilSunday = day === 0 ? 7 : (7 - day);
  const sunday = new Date(now.getFullYear(), now.getMonth(), now.getDate() + daysUntilSunday, 23, 59, 59);
  return sunday.toISOString();
}

function generateLeagueLeaderboard(userId, userTrophies, userName, userAvatar) {
  const config = getLeagueSettings();
  const trophies = Math.max(0, parseInt(userTrophies) || 120);
  const tier = getTierForTrophies(trophies);
  const endsAt = getNextSundayDate();

  // Tier base trophy ranges
  const tierBases = {
    bronze: [50, 290],
    silver: [300, 780],
    gold: [800, 1580],
    diamond: [1600, 2780],
    legends: [2800, 5200]
  };
  const [minT, maxT] = tierBases[tier] || [50, 300];

  const now = new Date();
  const weekNumber = Math.ceil((now.getDate() + 6 - now.getDay()) / 7) || 1;

  // Deterministik bot listesi
  const players = [];
  const baseSeed = weekNumber * 1000 + (tier.charCodeAt(0) * 10);

  for (let i = 0; i < 24; i++) {
    const pseudoRandom = ((baseSeed + (i * 37)) % 100) / 100.0;
    const botTrophies = Math.round(minT + pseudoRandom * (maxT - minT));
    players.push({
      id: 'bot_' + i,
      name: BOT_NAMES[i % BOT_NAMES.length],
      avatar: BOT_AVATARS[i % BOT_AVATARS.length],
      trophies: botTrophies,
      badgeTitle: tier === 'legends' ? 'Şampiyon' : (tier === 'diamond' ? 'Müzik Dehası' : 'Yarışmacı'),
      isCurrentUser: false
    });
  }

  // Kullanıcıyı ekle
  players.push({
    id: userId || 'current_user',
    name: userName || 'Ben',
    avatar: userAvatar || '🎧',
    trophies: trophies,
    badgeTitle: 'Yarışmacı',
    isCurrentUser: true
  });

  // Sırala
  players.sort((a, b) => b.trophies - a.trophies);

  for (let i = 0; i < players.length; i++) {
    players[i].rank = i + 1;
    if (players[i].rank <= 5) {
      players[i].trend = 'promotion';
    } else if (players[i].rank >= 21) {
      players[i].trend = tier === 'bronze' ? 'safe' : 'demotion';
    } else {
      players[i].trend = 'safe';
    }
  }

  const currentUser = players.find(p => p.isCurrentUser);

  return {
    tier: tier,
    weekNumber: weekNumber,
    endsAt: endsAt,
    players: players,
    currentUserTrophies: trophies,
    currentUserRank: currentUser ? currentUser.rank : players.length,
    promotionCutoff: config.promotionCutoff || 5,
    demotionCutoff: config.demotionCutoff || 21,
    isDemotionEnabled: config.isDemotionEnabled !== false,
    tierRewards: config.tiers
  };
}

const server = http.createServer(async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // 1. Web Yönetici Paneli Sayfası (/admin)
  if (req.method === 'GET' && (req.url === '/admin' || req.url === '/admin/')) {
    const adminPath = path.join(__dirname, 'admin.html');
    if (fs.existsSync(adminPath)) {
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      fs.createReadStream(adminPath).pipe(res);
      return;
    }
  }

  // 2.0. Günün Şarkısı
  // 2.0.2. Lig Ayarları & Ödülleri (Admin & App)
  if (req.method === 'GET' && req.url === '/api/league/config') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(getLeagueSettings()));
    return;
  }

  if (req.method === 'POST' && req.url === '/api/admin/league/config') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const success = saveLeagueSettings(data);
        res.writeHead(success ? 200 : 500, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: e.message }));
      }
    });
    return;
  }

  // 2.0.1. Haftalık Ligler & Liderlik Tablosu
  if (req.method === 'GET' && req.url.startsWith('/api/league/leaderboard')) {
    const urlObj = new URL(req.url, 'http://localhost');
    const userId = urlObj.searchParams.get('userId') || 'user_1';
    const trophies = parseInt(urlObj.searchParams.get('trophies')) || 150;
    const userName = urlObj.searchParams.get('userName') || 'Ben';
    const userAvatar = urlObj.searchParams.get('userAvatar') || '🎧';

    const data = generateLeagueLeaderboard(userId, trophies, userName, userAvatar);
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(data));
    return;
  }

  if (req.method === 'GET' && req.url.startsWith('/api/daily-song')) {
    const urlObj = new URL(req.url, 'http://localhost');
    const dateStr = urlObj.searchParams.get('date') || new Date().toISOString().slice(0, 10);
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    const dailyData = await getDailySongForDate(dateStr);
    res.end(JSON.stringify(dailyData));
    return;
  }

  // 2. Canlı Uygulama Konfigürasyonu (Kategoriler, Plaklar & Mağaza)
  if (req.method === 'GET' && req.url === '/api/config/all') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({
      categories: getAllCategories(),
      badges: getAllBadges(),
      store_items: getAllStoreItems(),
      season_pass: getActiveSeasonPass(),
    }));
    return;
  }

  // 2.1. Mağaza Paketleri Listesi
  if (req.method === 'GET' && req.url === '/api/store/items') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(getAllStoreItems()));
    return;
  }

  // 3. Yönetici Girişi
  if (req.method === 'POST' && req.url === '/api/admin/login') {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try {
        const { password } = JSON.parse(body);
        if (password === 'muzik123') { // Panel şifresi
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ token: 'admin_token_2026_authorized' }));
        } else {
          res.writeHead(401, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Geçersiz şifre' }));
        }
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // 4. Deezer Sanatçı Fotoğrafı Arama (Admin Tek Tık)
  if (req.method === 'GET' && req.url.startsWith('/api/admin/artist-image')) {
    const urlObj = new URL(req.url, 'http://localhost');
    const name = urlObj.searchParams.get('name') || '';
    const img = await fetchDeezerArtistImage(name);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ imageUrl: img }));
    return;
  }

  // 5. Plak Kaydet / Düzenle
  if (req.method === 'POST' && req.url === '/api/admin/badges/save') {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try {
        const b = JSON.parse(body);
        const stmt = db.prepare(`
          INSERT INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order, is_active)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
          ON CONFLICT(id) DO UPDATE SET
            category_id=excluded.category_id,
            artist_name=excluded.artist_name,
            title=excluded.title,
            tier=excluded.tier,
            total_shards=excluded.total_shards,
            emoji=excluded.emoji,
            image_url=excluded.image_url
        `);
        stmt.run(
          b.id,
          b.category_id,
          b.artist_name,
          b.title,
          b.tier,
          parseInt(b.total_shards) || 45,
          b.emoji || '💽',
          b.image_url,
          b.display_order || 0
        );
        console.log(`💽 [PLAK GÜNCELLENDİ] ${b.artist_name} (${b.title})`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // 6. Plak Sil
  if (req.method === 'POST' && req.url === '/api/admin/badges/delete') {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try {
        const { id } = JSON.parse(body);
        db.prepare('DELETE FROM badges WHERE id = ?').run(id);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // 6.5. Kategori Kaydet / Düzenle
  if (req.method === 'POST' && req.url === '/api/admin/categories/save') {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try {
        const c = JSON.parse(body);
        const stmt = db.prepare(`
          INSERT INTO categories (id, title, subtitle, color_hex, search_query, icon_name, display_order, is_active)
          VALUES (?, ?, ?, ?, ?, ?, ?, 1)
          ON CONFLICT(id) DO UPDATE SET
            title=excluded.title,
            subtitle=excluded.subtitle,
            color_hex=excluded.color_hex,
            search_query=excluded.search_query,
            icon_name=excluded.icon_name,
            display_order=excluded.display_order,
            is_active=1
        `);
        stmt.run(
          c.id,
          c.title,
          c.subtitle || '',
          c.color_hex || '#F59E0B',
          c.search_query || '',
          c.icon_name || 'album',
          parseInt(c.display_order) || 0
        );
        delete songCache[c.id];
        console.log(`📁 [KATEGORİ GÜNCELLENDİ] ${c.title} (${c.id})`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // 6.6. Kategori Sil
  if (req.method === 'POST' && req.url === '/api/admin/categories/delete') {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try {
        const { id } = JSON.parse(body);
        db.prepare('DELETE FROM categories WHERE id = ?').run(id);
        delete songCache[id];
        console.log(`🗑️ [KATEGORİ SİLİNDİ] ${id}`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // 6.7. Mağaza Paketleri Yönetimi (Admin)
  if (req.method === 'GET' && req.url === '/api/admin/store/items') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(getAllStoreItems(true)));
    return;
  }

  if (req.method === 'POST' && req.url === '/api/admin/store/save') {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try {
        const item = JSON.parse(body);
        const stmt = db.prepare(`
          INSERT INTO store_items (id, type, title, subtitle, price_label, coins_cost, badge_label, badge_color, icon, display_order, is_active, rewards_json)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            type=excluded.type,
            title=excluded.title,
            subtitle=excluded.subtitle,
            price_label=excluded.price_label,
            coins_cost=excluded.coins_cost,
            badge_label=excluded.badge_label,
            badge_color=excluded.badge_color,
            icon=excluded.icon,
            display_order=excluded.display_order,
            is_active=excluded.is_active,
            rewards_json=excluded.rewards_json
        `);
        stmt.run(
          item.id,
          item.type || 'in_app',
          item.title,
          item.subtitle || '',
          item.price_label || '',
          parseInt(item.coins_cost) || 0,
          item.badge_label || '',
          item.badge_color || '',
          item.icon || '🛍️',
          parseInt(item.display_order) || 0,
          item.is_active === 0 ? 0 : 1,
          typeof item.rewards_json === 'string' ? item.rewards_json : JSON.stringify(item.rewards_json || {})
        );
        console.log(`🛍️ [MAĞAZA PAKETİ GÜNCELLENDİ] ${item.title} (${item.id})`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  if (req.method === 'POST' && req.url === '/api/admin/store/delete') {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try {
        const { id } = JSON.parse(body);
        db.prepare('DELETE FROM store_items WHERE id = ?').run(id);
        console.log(`🗑️ [MAĞAZA PAKETİ SİLİNDİ] ${id}`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // 7. İstatistikler & Kullanıcılar
  // 6.5. Sezon Bileti & Görevler Yönetimi
  if (req.method === 'GET' && req.url === '/api/admin/season-pass') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(getActiveSeasonPass() || {}));
    return;
  }

  if (req.method === 'POST' && req.url === '/api/admin/season-pass/save') {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try {
        const payload = JSON.parse(body);
        const ok = saveActiveSeasonPass(payload);
        console.log(`🎟️ [SEZON BİLETİ GÜNCELLENDİ] ${payload.seasonName || 'Aktif Sezon'}`);
        res.writeHead(ok ? 200 : 500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: ok }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  if (req.method === 'GET' && req.url === '/api/admin/stats') {
    const uCount = db ? db.prepare('SELECT COUNT(*) as count FROM users').get().count : 0;
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ usersCount: uCount }));
    return;
  }

  if (req.method === 'GET' && req.url === '/api/admin/users') {
    const users = db ? db.prepare('SELECT google_id, email, name, avatar, energy, coins, powerup_count, has_no_ads, is_vip, is_banned, ban_reason, badges_data, stats_json, last_energy_timestamp, last_login FROM users ORDER BY last_login DESC LIMIT 200').all() : [];
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(users));
    return;
  }

  // Oyuncu Bilgilerini Güncelle (Admin)
  if (req.method === 'POST' && req.url === '/api/admin/users/update') {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try {
        const u = JSON.parse(body);
        const stmt = db.prepare(`
          UPDATE users SET
            name = ?,
            coins = ?,
            energy = ?,
            powerup_count = ?,
            is_vip = ?,
            has_no_ads = ?
          WHERE google_id = ?
        `);
        stmt.run(
          u.name,
          parseInt(u.coins) || 0,
          parseInt(u.energy) || 0,
          parseInt(u.powerup_count) || 0,
          u.is_vip ? 1 : 0,
          u.has_no_ads ? 1 : 0,
          u.google_id
        );
        console.log(`👤 [ADMIN OYUNCU DÜZENLEME] ${u.name} (ID: ${u.google_id}) güncellendi.`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // Oyuncu Kısıtla / Yasağı Kaldır (Admin)
  if (req.method === 'POST' && req.url === '/api/admin/users/ban') {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try {
        const { google_id, is_banned, ban_reason } = JSON.parse(body);
        const stmt = db.prepare(`
          UPDATE users SET is_banned = ?, ban_reason = ? WHERE google_id = ?
        `);
        stmt.run(is_banned ? 1 : 0, ban_reason || '', google_id);
        console.log(`🚫 [ADMIN OYUNCU KISITLAMA] ID: ${google_id} => ${is_banned ? 'KISITLANDI' : 'YASAK KALDIRILDI'} (${ban_reason || 'Neden yok'})`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // Oyuncu Hesabını Sil (Admin)
  if (req.method === 'POST' && req.url === '/api/admin/users/delete') {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => {
      try {
        const { google_id } = JSON.parse(body);
        db.prepare('DELETE FROM users WHERE google_id = ?').run(google_id);
        console.log(`🗑️ [ADMIN OYUNCU SİLİNDİ] ID: ${google_id}`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // Google ile Giriş / Kayıt Senkronizasyon Uç Noktası
  if (req.method === 'POST' && req.url === '/api/auth/sync') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        let user = getUserByGoogleId(data.google_id);
        if (user && user.is_banned) {
          console.log(`🚫 [KISITLI GİRİŞ ENGELLENDİ] ${user.name} (${user.email}) engellendi.`);
          res.writeHead(403, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'banned', message: user.ban_reason || 'Hesabınız askıya alınmıştır.' }));
          return;
        }
        if (!user) {
          user = {
            google_id: data.google_id,
            email: data.email,
            name: data.name,
            avatar: data.avatar,
            energy: data.energy !== undefined ? data.energy : 10,
            coins: 350,
            powerup_count: 2,
            has_no_ads: 0,
            is_vip: 0,
            badges_data: data.badges_data || '{}',
            stats_json: data.stats_json || '{}',
            last_energy_timestamp: data.last_energy_timestamp || Date.now(),
          };
          saveUser(user);
          user = getUserByGoogleId(data.google_id);
          console.log(`🎉 [YENİ KAYIT] ${user.name} (${user.email}) veritabanına eklendi!`);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ status: 'registered', user }));
        } else {
          if (data.stats_json || data.badges_data) {
            saveUser({
              ...user,
              badges_data: data.badges_data || user.badges_data,
              stats_json: data.stats_json || user.stats_json,
            });
            user = getUserByGoogleId(data.google_id);
          }
          console.log(`🔑 [GİRİŞ YAPILDI] ${user.name} sunucu profilini aldı.`);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ status: 'logged_in', user }));
        }
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // Kullanıcı Profilini Sunucudan Getir (Mobil Uygulama Açılış & Yenileme)
  if (req.method === 'GET' && req.url.startsWith('/api/user/profile')) {
    const parsedUrl = new URL(req.url, 'http://localhost');
    const gid = parsedUrl.searchParams.get('google_id');
    if (!gid) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'google_id gerekli' }));
      return;
    }
    const user = getUserByGoogleId(gid);
    if (!user) {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'user_not_found' }));
      return;
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(user));
    return;
  }

  // Kullanıcı İlerleme Senkronizasyonu (Altın, Rozet, Enerji vb.)
  if (req.method === 'POST' && req.url === '/api/user/sync') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        if (data.google_id) {
          const existing = getUserByGoogleId(data.google_id);
          if (existing && existing.is_banned) {
            res.writeHead(403, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: 'banned', message: existing.ban_reason || 'Hesabınız askıya alınmıştır.' }));
            return;
          }
          saveUser(data);
          const current = getUserByGoogleId(data.google_id);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ status: 'synced', user: current }));
        } else {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'google_id gerekli' }));
        }
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('Müzik Düellosu Game Server aktif (Port: ' + PORT + ')');
});

const wss = new WebSocket.Server({ server });

// Genişletilmiş Sanatçı ve Tür Havuzları
const CATEGORY_ARTISTS = {
  pop_90s: [
    'Tarkan', 'Sezen Aksu', 'Mustafa Sandal', 'Kenan Doğulu', 'Sertab Erener',
    'Burak Kut', 'Mirkelam', 'Levent Yüksel', 'Yaşar', 'Aşkın Nur Yengi',
    'Harun Kolçak', 'İzel', 'Çelik', 'Bendeniz', 'Yonca Evcimik',
    'Rafet El Roman', 'Emel Müftüoğlu', 'Kerim Tekin', 'Serdar Ortaç', 'Soner Arıca',
    'Hakan Peker', 'Seden Gürel', 'Nazan Öncel', 'Yıldız Tilbe', 'Suat Suna',
    'Demet Sağıroğlu', 'Tayfun Duygulu', 'Reyhan Karaca', 'Gökhan Tepe', 'Zerrin Özer'
  ],
  hit_2000s: [
    'Hande Yener', 'Demet Akalın', 'Serdar Ortaç', 'Yalın', 'Murat Boz',
    'Sıla', 'Gülşen', 'Hadise', 'Bengü', 'Gökhan Türkmen',
    'Atiye', 'Emre Aydın', 'Gripin', 'Yüksek Sadakat', 'Manga',
    'Mor ve Ötesi', 'Duman', 'Zeynep Casalini', 'Rober Hatemo', 'Berksan',
    'İrem Derici', 'Gökhan Özen', 'Tan Taşçı', 'Kutsi', 'Sinan Akçıl',
    'Ziynet Sali', 'Murat Dalkılıç', 'Ece Seçkin', 'Simge', 'Oğuzhan Koç'
  ],
  pop_2010s: [
    'Mabel Matiz', 'Edis', 'Simge', 'Zeynep Bastık', 'Madrigal',
    'Dolu Kadehi Ters Tut', 'Köfn', 'Melike Şahin', 'Sena Şener', 'Yüzyüzeyken Konuşuruz',
    'Emir Can İğrek', 'Buray', 'Tuğçe Kandemir', 'İlyas Yalçıntaş', 'Bilal Sonses',
    'Merve Özbey', 'Dedublüman', 'Kaan Boşnak', 'Perdenin Ardındakiler', 'Adamlar',
    'İkilem', 'Canozan', 'KÖFN', 'Semicenk', 'Derya Uluğ'
  ],
  rock_tr: [
    'Barış Manço', 'Cem Karaca', 'Erkin Koray', 'Duman', 'Mor ve Ötesi',
    'Şebnem Ferah', 'Haluk Levent', 'Teoman', 'Moğollar', 'Kurtalan Ekspres',
    'Pentagram', 'Kurban', 'Athena', 'Ogün Sanlısoy', 'Hayko Cepkin',
    'Feridun Düzağaç', 'Redd', 'Vega', 'Flört', 'Yavuz Çetin',
    'Bulutsuzluk Özlemi', 'Hardal', 'Pilli Bebek', 'Kıraç', 'Murat Göğebakan'
  ],
  rap_tr: [
    'Ceza', 'Sagopa Kajmer', 'Ezhel', 'Şanışer', 'Norm Ender',
    'Motive', 'Uzi', 'Gazapizm', 'Şehinşah', 'Anıl Piyancı',
    'Allame', 'Sefo', 'Defkhan', 'Çakal', 'Reckol',
    'Heijan', 'Muti', 'Sansar Salvo', 'Hayki', 'Patron',
    'Blok3', 'Baneva', 'Lvbel C5', 'Ati242', 'No.1', 'Aero'
  ],
  arabesk_tr: [
    'Müslüm Gürses', 'Ferdi Tayfur', 'İbrahim Tatlıses', 'Orhan Gencebay', 'Bergen',
    'Kibariye', 'Güllü', 'Ceylan', 'Azer Bülbül', 'Ebru Gündeş',
    'Sibel Can', 'Hakan Taşıyan', 'Gökhan Güney', 'Cengiz Kurtoğlu', 'Ümit Besen',
    'Arif Susam', 'Kamuran Akkor', 'Bedia Akartürk', 'Mine Koşan', 'Coşkun Sabah'
  ],
  turku_tr: [
    'Neşet Ertaş', 'Aşık Veysel', 'Selda Bağcan', 'Musa Eroğlu', 'Erdal Erzincan',
    'Arif Sağ', 'Muhlis Akarsu', 'Aşık Mahzuni Şerif', 'Sabahat Akkiraz', 'Belkıs Akkale',
    'Zara', 'Kubat', 'Yavuz Bingöl', 'Tolga Çandar', 'Ruhi Su',
    'Sevcan Orhan', 'İlkay Akkaya', 'Ali Ekber Çiçek', 'Erkan Oğur', 'İsmail Altunsaray'
  ],
  nostalji_tr: [
    'Ajda Pekkan', 'Nilüfer', 'Erol Evgin', 'İlhan İrem', 'Sezen Aksu',
    'Tanju Okan', 'Berkant', 'Semiramis Pekkan', 'Ayten Alpman', 'Füsun Önal',
    'Güzin ile Baha', 'Alpay', 'Modern Folk Üçlüsü', 'Ayla Dikmen', 'Hümeyra',
    'Seyyal Taner', 'Yeliz', 'Tülay Özer', 'Esmeray', 'Banu Kırbağ'
  ]
};

function cleanTitle(raw) {
  if (!raw) return 'Bilinmeyen';
  let c = raw.replace(/\[.*?\]/g, '');
  c = c.replace(/\(feat\..*?\)/gi, '');
  c = c.replace(/\(Remastered.*?\)/gi, '');
  c = c.replace(/\(Orijinal.*?\)/gi, '');
  c = c.replace(/\(Akustik.*?\)/gi, '');
  return c.trim();
}

// Şarkı Belleği (Sunucu tarafında kategorilere göre geniş şarkı havuzu)
const songCache = {};

async function fetchSongsForPool(categoryId) {
  if (categoryId === 'karma_all' || categoryId === 'all_mix') {
    let allSongs = [];
    for (const cat of Object.keys(CATEGORY_ARTISTS)) {
      const catPool = await fetchSongsForPool(cat);
      allSongs = allSongs.concat(catPool);
    }
    const unique = [];
    const seen = new Set();
    for (const s of allSongs) {
      const key = `${s.title.toLowerCase()}_${s.artist.toLowerCase()}`;
      if (!seen.has(key)) {
        seen.add(key);
        unique.push(s);
      }
    }
    return unique.sort(() => Math.random() - 0.5);
  }

  if (!songCache[categoryId]) songCache[categoryId] = [];
  const currentPool = songCache[categoryId];

  // Havuzda 80'den fazla şarkı varsa direkt kullan
  if (currentPool.length >= 80) {
    return [...currentPool].sort(() => Math.random() - 0.5);
  }

  let artists = CATEGORY_ARTISTS[categoryId];
  if (!artists) {
    if (db) {
      try {
        const catRow = db.prepare('SELECT * FROM categories WHERE id = ?').get(categoryId);
        if (catRow && (catRow.search_query || catRow.title)) {
          const rawQ = catRow.search_query || catRow.title;
          artists = rawQ.split(',').map(s => s.trim()).filter(Boolean);
        }
      } catch (e) {}
    }
  }
  if (!artists || artists.length === 0) {
    artists = CATEGORY_ARTISTS.pop_90s;
  }

  const isSingleArtist = artists.length === 1;
  const shuffledArtists = [...artists].sort(() => Math.random() - 0.5);
  const selectedArtists = isSingleArtist ? artists : shuffledArtists.slice(0, 10);

  for (const artist of selectedArtists) {
    try {
      const limit = isSingleArtist ? 50 : 20;
      const url = `https://itunes.apple.com/search?term=${encodeURIComponent(artist)}&country=tr&media=music&entity=song&limit=${limit}`;
      const res = await new Promise((resolve) => {
        https.get(url, (resp) => {
          let data = '';
          resp.on('data', chunk => data += chunk);
          resp.on('end', () => {
            try { resolve(JSON.parse(data)); } catch (e) { resolve({ results: [] }); }
          });
        }).on('error', () => resolve({ results: [] }));
      });

      if (res && res.results) {
        // Akıllı filtre: Arama terimi gelen şarkıcı isimlerinde birden fazla geçiyorsa tekil sanatçıdır (Örn: Tarkan).
        // Eğer "Karadeniz", "Türkü", "Halay" gibi bir tür/kelimeyse şarkıcı isimleriyle uyuşmaz, tüm şarkıları havuza al!
        const artistMatches = isSingleArtist
          ? res.results.filter(item => item.artistName && item.artistName.toLowerCase().includes(artist.toLowerCase())).length
          : 0;
        const isTrueSingleArtist = isSingleArtist && (artistMatches >= 2 || res.results.length <= 3);

        for (const item of res.results) {
          if (item.previewUrl && item.trackName) {
            if (isTrueSingleArtist && !item.artistName?.toLowerCase().includes(artist.toLowerCase())) {
              continue;
            }
            const title = cleanTitle(item.trackName);
            const artistName = item.artistName || 'Bilinmeyen';
            const exists = currentPool.some(s => s.title.toLowerCase() === title.toLowerCase() && s.artist.toLowerCase() === artistName.toLowerCase());
            if (!exists) {
              currentPool.push({
                title,
                artist: artistName,
                previewUrl: item.previewUrl,
                artworkUrl: (item.artworkUrl100 || '').replace('100x100bb', '600x600bb'),
              });
            }
          }
        }
      }
    } catch (e) {}
  }

  return [...currentPool].sort(() => Math.random() - 0.5);
}

async function prepareQuestions(categoryId, count = 5) {
  let pool = await fetchSongsForPool(categoryId);
  if (pool.length < 5) {
    console.log(`[UYARI] Kategori (${categoryId}) havuzu yetersiz (${pool.length} şarkı). Popüler yedek havuzdan tamamlanıyor...`);
    const fallbackPool = await fetchSongsForPool('pop_90s');
    pool = [...pool, ...fallbackPool];
  }

  const uniqueArtists = new Set(pool.map(s => s.artist.toLowerCase()));
  const isSingleArtistMode = uniqueArtists.size < 4;

  const shuffledPool = [...pool].sort(() => Math.random() - 0.5);
  const targets = shuffledPool.slice(0, count);

  const questions = [];
  for (let i = 0; i < targets.length; i++) {
    const target = targets[i];
    const isTitleQuestion = isSingleArtistMode ? true : (Math.random() > 0.5);
    const promptText = isTitleQuestion 
      ? (isSingleArtistMode ? `${target.artist}'ın Çalan Şarkısı Hangisi?` : 'Bu Şarkının Adı Ne?') 
      : 'Bu Şarkıyı Kim Söylüyor?';
    const correctAnswer = isTitleQuestion ? target.title : target.artist;

    const options = [correctAnswer];
    const otherSongs = pool.filter(s => s.title !== target.title).sort(() => Math.random() - 0.5);

    for (const other of otherSongs) {
      const opt = isTitleQuestion ? other.title : other.artist;
      if (!options.includes(opt) && opt && opt.length > 0) {
        options.push(opt);
      }
      if (options.length >= 4) break;
    }

    while (options.length < 4) {
      options.push(`Seçenek ${options.length + 1}`);
    }

    options.sort(() => Math.random() - 0.5);
    const correctIndex = options.indexOf(correctAnswer);

    questions.push({
      title: target.title,
      artist: target.artist,
      previewUrl: target.previewUrl,
      artworkUrl: target.artworkUrl,
      promptText,
      options,
      correctIndex,
    });
  }

  return questions;
}

// Gerçekçi Robot Oyuncu Profilleri (İnsan gibi oynayan botlar)
const BOT_PROFILES = [
  { name: 'Melis_K', avatar: '🎧' },
  { name: 'Ahmet92', avatar: '🔥' },
  { name: 'BarisRock', avatar: '🎸' },
  { name: 'Zeynep34', avatar: '✨' },
  { name: 'Caner_G', avatar: '👑' },
  { name: 'Elif_Pop', avatar: '🎵' },
  { name: 'Burak06', avatar: '⚡' },
  { name: 'Selin99', avatar: '🌸' },
  { name: 'Emre_Ist', avatar: '🎤' },
  { name: 'GizemMuzik', avatar: '🎶' },
  { name: 'Mert_Tr', avatar: '🎯' },
  { name: 'Gamze_Ak', avatar: '💎' },
  { name: 'Deniz_Efe', avatar: '🌟' },
  { name: 'Volkan_M', avatar: '🚀' },
  { name: 'AyseGitar', avatar: '🎼' },
  { name: 'Ozan_90lar', avatar: '📻' },
  { name: 'Tugba_Vip', avatar: '👑' },
  { name: 'Kaan_Beat', avatar: '🎧' },
  { name: 'Buse_C', avatar: '💫' },
  { name: 'Yigit_Rock', avatar: '⚡' },
  { name: 'Ceren_Pop', avatar: '🎙️' },
  { name: 'Furkan_Rap', avatar: '🔥' },
  { name: 'Asli_Hit', avatar: '✨' },
  { name: 'Tolga_Bass', avatar: '🎸' },
  { name: 'Ece_Melodi', avatar: '🎵' },
];

function createBotPlayer() {
  const profile = BOT_PROFILES[Math.floor(Math.random() * BOT_PROFILES.length)];
  return {
    id: 'bot_' + Date.now() + '_' + Math.floor(Math.random() * 1000),
    name: profile.name,
    avatar: profile.avatar,
    platform: 'Mobil',
    totalScore: 0,
    currentRoundAnswered: false,
    isBot: true,
    room: null,
    send: (data) => {}, // Bot için ağ gönderimi gerekmez
  };
}

// Oda Yönetimi
class DuelRoom {
  constructor({ id, code, isCustom, settings, p1, p2, questions }) {
    this.id = id;
    this.code = code;
    this.isCustom = isCustom;
    this.settings = settings;
    this.p1 = p1;
    this.p2 = p2;
    this.questions = questions;
    this.currentRound = 0;
    this.timer = null;
    this.botAnswerTimer = null;
    this.isFinished = false;

    p1.room = this;
    p2.room = this;
  }

  start() {
    console.log(`[ODA ${this.code || this.id}] Maç Başladı: ${this.p1.name} VS ${this.p2.name} | ${this.questions.length} Tur`);

    const preloadUrls = (this.questions || []).map(q => q.previewUrl).filter(Boolean);

    this.p1.send({
      type: 'match_found',
      roomId: this.id,
      roomCode: this.code,
      isCustom: this.isCustom,
      totalRounds: this.questions.length,
      settings: this.settings,
      preloadUrls,
      opponent: { name: this.p2.name, avatar: this.p2.avatar, platform: this.p2.platform },
    });

    this.p2.send({
      type: 'match_found',
      roomId: this.id,
      roomCode: this.code,
      isCustom: this.isCustom,
      totalRounds: this.questions.length,
      settings: this.settings,
      preloadUrls,
      opponent: { name: this.p1.name, avatar: this.p1.avatar, platform: this.p1.platform },
    });

    setTimeout(() => this.startRound(0), 2500);
  }

  startRound(roundIndex) {
    if (this.isFinished || !this.questions || !this.questions[roundIndex]) return;
    this.currentRound = roundIndex;
    this.p1.currentRoundAnswered = false;
    this.p2.currentRoundAnswered = false;

    const q = this.questions[roundIndex];
    const durationMs = (this.settings.roundDurationSec || 10) * 1000;
    const nextPreviewUrl = (this.questions && this.questions[roundIndex + 1]) ? this.questions[roundIndex + 1].previewUrl : null;

    const payload = {
      type: 'round_start',
      roundIndex,
      totalRounds: this.questions.length,
      roundDurationSec: this.settings.roundDurationSec || 10,
      nextPreviewUrl,
      question: {
        title: q.title,
        artist: q.artist,
        previewUrl: q.previewUrl,
        artworkUrl: q.artworkUrl,
        promptText: q.promptText,
        options: q.options,
        correctIndex: q.correctIndex,
      },
    };

    this.p1.send(payload);
    this.p2.send(payload);

    clearTimeout(this.timer);
    clearTimeout(this.botAnswerTimer);
    this.timer = setTimeout(() => this.endRound(), durationMs + 500);

    // Eğer oyunculardan biri bot ise insan gibi düşünüp cevap versin
    const botPlayer = this.p1.isBot ? this.p1 : (this.p2.isBot ? this.p2 : null);
    if (botPlayer) {
      // 2.2 - 5.2 saniye arası insan tepki süresi
      const answerDelayMs = Math.floor(2200 + Math.random() * 3000);
      this.botAnswerTimer = setTimeout(() => {
        if (this.isFinished || this.currentRound !== roundIndex || botPlayer.currentRoundAnswered) return;
        const willBeCorrect = Math.random() < 0.78; // %78 başarı oranı
        let chosenOptionIndex = q.correctIndex;
        if (!willBeCorrect) {
          const wrongOptions = [0, 1, 2, 3].filter(idx => idx !== q.correctIndex);
          chosenOptionIndex = wrongOptions[Math.floor(Math.random() * wrongOptions.length)];
        }
        const remainingMs = Math.max(200, durationMs - answerDelayMs);
        this.handleAnswer(botPlayer, chosenOptionIndex, remainingMs);
      }, answerDelayMs);
    }
  }

  handleAnswer(player, optionIndex, remainingMs) {
    if (player.currentRoundAnswered || this.isFinished) return;
    player.currentRoundAnswered = true;

    const q = this.questions[this.currentRound];
    const isCorrect = optionIndex === q.correctIndex;
    const maxMs = (this.settings.roundDurationSec || 10) * 1000;

    let score = 0;
    if (isCorrect) {
      const factor = Math.min(1.0, Math.max(0.05, remainingMs / maxMs));
      score = Math.floor(factor * 950 + 50);
    }

    player.totalScore += score;

    player.send({
      type: 'answer_result',
      isCorrect,
      correctIndex: q.correctIndex,
      earnedScore: score,
      yourTotalScore: player.totalScore,
    });

    const opponent = player === this.p1 ? this.p2 : this.p1;
    opponent.send({
      type: 'opponent_answered',
      isCorrect,
      opponentEarnedScore: score,
      opponentTotalScore: player.totalScore,
    });

    if (this.p1.currentRoundAnswered && this.p2.currentRoundAnswered) {
      clearTimeout(this.timer);
      clearTimeout(this.botAnswerTimer);
      setTimeout(() => this.endRound(), 1400);
    }
  }

  endRound() {
    if (this.isFinished) return;
    clearTimeout(this.timer);
    clearTimeout(this.botAnswerTimer);

    const q = this.questions[this.currentRound];
    const endPayload = {
      type: 'round_end',
      roundIndex: this.currentRound,
      correctIndex: q.correctIndex,
      songTitle: q.title,
      artist: q.artist,
      artworkUrl: q.artworkUrl,
      player1Score: this.p1.totalScore,
      player2Score: this.p2.totalScore,
    };

    this.p1.send(endPayload);
    this.p2.send(endPayload);

    setTimeout(() => {
      if (this.currentRound + 1 < this.questions.length) {
        this.startRound(this.currentRound + 1);
      } else {
        this.finishMatch();
      }
    }, 2400);
  }

  finishMatch() {
    if (this.isFinished) return;
    this.isFinished = true;
    clearTimeout(this.timer);
    clearTimeout(this.botAnswerTimer);

    const summary = {
      type: 'match_over',
      player1: { name: this.p1.name, score: this.p1.totalScore },
      player2: { name: this.p2.name, score: this.p2.totalScore },
      songs: this.questions.map(q => ({
        title: q.title,
        artist: q.artist,
        artworkUrl: q.artworkUrl,
      })),
    };

    this.p1.send(summary);
    this.p2.send(summary);
  }

  handleDisconnect(disconnectedPlayer) {
    if (this.isFinished) return;
    this.isFinished = true;
    clearTimeout(this.timer);
    clearTimeout(this.botAnswerTimer);

    const other = disconnectedPlayer === this.p1 ? this.p2 : this.p1;
    if (!other.isBot) {
      other.send({
        type: 'opponent_disconnected',
        message: `${disconnectedPlayer.name} oyundan ayrıldı. Zafer senin!`,
      });
    }
  }
}

const publicQueues = {};
const customRooms = {};
const activeRooms = new Map();

function generateRoomCode() {
  let code;
  do {
    code = Math.floor(1000 + Math.random() * 9000).toString();
  } while (customRooms[code]);
  return code;
}

wss.on('connection', (ws) => {
  const player = {
    id: 'p_' + Date.now() + '_' + Math.floor(Math.random() * 1000),
    name: 'Oyuncu',
    avatar: '🎧',
    platform: 'Mobil',
    totalScore: 0,
    currentRoundAnswered: false,
    room: null,
    send: (data) => {
      try { ws.send(JSON.stringify(data)); } catch (e) {}
    }
  };

  ws.on('message', async (message) => {
    try {
      const data = JSON.parse(message);
      const type = data.type;

      if (data.googleId) {
        const u = getUserByGoogleId(data.googleId);
        if (u && u.is_banned) {
          player.send({
            type: 'error_message',
            message: 'Hesabınız askıya alınmıştır: ' + (u.ban_reason || 'Kural ihlali tespit edildi.')
          });
          return;
        }
      }

      if (type === 'join_queue') {
        player.name = data.playerName || 'Oyuncu';
        player.avatar = data.avatar || '🎧';
        player.platform = data.platform || 'Mobil';
        player.totalScore = 0;
        const cat = data.category || 'pop_90s';

        if (!publicQueues[cat]) publicQueues[cat] = [];
        publicQueues[cat] = publicQueues[cat].filter(p => p.id !== player.id);
        publicQueues[cat].push(player);

        console.log(`👤 [Genel Kuyruk] ${player.name} (${cat}) sırasına girdi.`);

        if (publicQueues[cat].length >= 2) {
          const p1 = publicQueues[cat].shift();
          const p2 = publicQueues[cat].shift();

          if (p1.botTimer) clearTimeout(p1.botTimer);
          if (p2.botTimer) clearTimeout(p2.botTimer);

          const questions = await prepareQuestions(cat, 5);
          const room = new DuelRoom({
            id: 'room_' + Date.now(),
            isCustom: false,
            settings: { roundCount: 5, roundDurationSec: 10, category: cat },
            p1,
            p2,
            questions,
          });

          activeRooms.set(p1.id, room);
          activeRooms.set(p2.id, room);
          room.start();
        } else if (publicQueues[cat].length === 1) {
          // Eğer 3.5 - 5 saniye içinde başka insan gelmezse gerçekçi bir bot bağla
          const waitingPlayer = player;
          if (waitingPlayer.botTimer) clearTimeout(waitingPlayer.botTimer);
          const botWaitMs = Math.floor(3500 + Math.random() * 1500);

          waitingPlayer.botTimer = setTimeout(async () => {
            if (publicQueues[cat] && publicQueues[cat].some(p => p.id === waitingPlayer.id)) {
              publicQueues[cat] = publicQueues[cat].filter(p => p.id !== waitingPlayer.id);

              const bot = createBotPlayer();
              console.log(`🤖 [BOT EŞLEŞTİRME] ${waitingPlayer.name} için bot rakip atandı: ${bot.name} (${bot.avatar})`);

              const questions = await prepareQuestions(cat, 5);
              const room = new DuelRoom({
                id: 'room_' + Date.now(),
                isCustom: false,
                settings: { roundCount: 5, roundDurationSec: 10, category: cat },
                p1: waitingPlayer,
                p2: bot,
                questions,
              });

              activeRooms.set(waitingPlayer.id, room);
              activeRooms.set(bot.id, room);
              room.start();
            }
          }, botWaitMs);
        }
      } else if (type === 'create_custom_room') {
        player.name = data.playerName || 'Oda Kurucu';
        player.avatar = data.avatar || '👑';
        player.platform = data.platform || 'Mobil';
        player.totalScore = 0;

        const roundCount = Math.max(3, Math.min(30, parseInt(data.roundCount) || 10));
        const roundDurationSec = parseInt(data.roundDurationSec) || 10;
        const category = data.category || 'pop_90s';

        const code = generateRoomCode();
        customRooms[code] = {
          host: player,
          settings: { roundCount, roundDurationSec, category },
          guest: null,
        };

        player.send({
          type: 'room_created',
          roomCode: code,
          settings: { roundCount, roundDurationSec, category },
        });

        console.log(`🏠 [Özel Oda Açıldı] #${code} | ${player.name} | ${roundCount} Tur | ${category}`);
      } else if (type === 'reconnect_custom_room') {
        const code = (data.roomCode || '').trim();
        const roomEntry = customRooms[code];
        if (roomEntry) {
          if (roomEntry.pendingTimeout) clearTimeout(roomEntry.pendingTimeout);
          roomEntry.isHostPending = false;
          roomEntry.host = player;
          console.log(`♻️ [ÖZEL ODA #${code}] Kurucu (${player.name}) WhatsApp'tan geri döndü ve odaya yeniden bağlandı!`);
          player.send({
            type: 'room_created',
            roomCode: code,
            settings: roomEntry.settings,
          });

          // Eğer kurucu WhatsApp'tayken arkadaşı odaya katılmışsa maçı hemen başlat!
          if (roomEntry.guest) {
            const guest = roomEntry.guest;
            const settings = roomEntry.settings;
            delete customRooms[code];
            const questions = await prepareQuestions(settings.category, settings.roundCount);
            const room = new DuelRoom({
              id: 'custom_' + code + '_' + Date.now(),
              code,
              isCustom: true,
              settings,
              p1: player,
              p2: guest,
              questions,
            });
            activeRooms.set(player.id, room);
            activeRooms.set(guest.id, room);
            room.start();
          }
        } else {
          player.send({ type: 'error_message', message: `Oda süresi dolduğu için kapandı (#${code})` });
        }
      } else if (type === 'join_custom_room') {
        const code = (data.roomCode || '').trim();
        const roomEntry = customRooms[code];

        if (!roomEntry) {
          player.send({ type: 'error_message', message: `Geçersiz veya süresi dolmuş oda kodu: #${code}` });
          return;
        }

        if (roomEntry.guest) {
          player.send({ type: 'error_message', message: `Bu oda dolu! (#${code})` });
          return;
        }

        player.name = data.playerName || 'Arkadaş';
        player.avatar = data.avatar || '🎸';
        player.platform = data.platform || 'Mobil';
        player.totalScore = 0;

        roomEntry.guest = player;
        const host = roomEntry.host;
        const settings = roomEntry.settings;

        if (roomEntry.isHostPending) {
          // Kurucu WhatsApp'ta, misafir odaya alındı. Kurucu geri dönünce maç başlayacak.
          player.send({ type: 'waiting_for_host', message: 'Odaya bağlandınız! Kurucunun WhatsApp\'tan dönmesi bekleniyor...' });
          console.log(`⏳ [ÖZEL ODA #${code}] Misafir (${player.name}) katıldı, kurucu WhatsApp'tan dönünce başlayacak.`);
          return;
        }

        delete customRooms[code];

        const questions = await prepareQuestions(settings.category, settings.roundCount);
        const room = new DuelRoom({
          id: 'custom_' + code + '_' + Date.now(),
          code,
          isCustom: true,
          settings,
          p1: host,
          p2: player,
          questions,
        });

        activeRooms.set(host.id, room);
        activeRooms.set(player.id, room);
        room.start();
      } else if (type === 'ping') {
        player.send({ type: 'pong' });
      } else if (type === 'submit_answer' && player.room) {
        player.room.handleAnswer(player, data.optionIndex, data.timeRemainingMs);
      }
    } catch (e) {
      console.error('Hata:', e);
    }
  });

  ws.on('close', () => {
    if (player.botTimer) clearTimeout(player.botTimer);
    for (const cat in publicQueues) {
      publicQueues[cat] = publicQueues[cat].filter(p => p.id !== player.id);
    }
    for (const code in customRooms) {
      const cr = customRooms[code];
      if (cr.host.id === player.id && !cr.guest) {
        cr.isHostPending = true;
        console.log(`📱 [ÖZEL ODA #${code}] Kurucu arka plana/WhatsApp'a geçti. Oda 120 saniye canlı tutuluyor.`);
        if (cr.pendingTimeout) clearTimeout(cr.pendingTimeout);
        cr.pendingTimeout = setTimeout(() => {
          if (customRooms[code] && customRooms[code].isHostPending) {
            console.log(`⌛ [ÖZEL ODA #${code}] 120 saniye doldu, oda kapatıldı.`);
            delete customRooms[code];
          }
        }, 120000);
      }
    }
    if (player.room) {
      player.room.handleDisconnect(player);
      activeRooms.delete(player.id);
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('========================================================');
  console.log(`🚀 Müzik Düellosu Sunucusu ${PORT} portunda aktif!`);
  console.log('📚 8 Geniş Müzik Kategorisi ve 300+ Şarkı Havuzu Hazır!');
  console.log('========================================================');
});
