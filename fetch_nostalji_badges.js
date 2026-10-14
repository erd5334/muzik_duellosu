const https = require('https');
const fs = require('fs');

const artists = [
  { name: "Ajda Pekkan", title: "Süperstar", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Zeki Müren", title: "Sanat Güneşi", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Nilüfer", title: "Ta Uzak Yollardan", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Bülent Ersoy", title: "Diva", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Tanju Okan", title: "Kadınım Derinliği", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Ayten Alpman", title: "Memleketim Sesi", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Erol Evgin", title: "Sevdan Olmasa", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Nükhet Duru", title: "Ben Sana Vurgun", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "İlhan İrem", title: "Boşver Arkadaş Felsefesi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Kayahan", title: "Geceler Ustası", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Edip Akbayram", title: "Aldırma Gönül", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Semiramis Pekkan", title: "Bana Yalan Söylediler", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Hümeyra", title: "Kördüğüm Ruhu", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Özdemir Erdoğan", title: "Gurbet Melodisi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Seyyal Taner", title: "Son Verdim Kalbimin İşine", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Füsun Önal", title: "Ah Nerede Neşesi", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Cici Kızlar", title: "Delisin Çılgınlığı", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Yeliz", title: "Bu Ne Dünya Kardeşim", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Beyaz Kelebekler", title: "Sen Gidince", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Modern Folk Üçlüsü", title: "Dostluğa Davet", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Timur Selçuk", title: "İspanyol Meyhanesi", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Ayla Dikmen", title: "Anlamazdın Melankolisi", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Esmeray", title: "Unutama Beni Ruhu", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Tülay Özer", title: "İkimiz Bir Fidanın", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Neşe Karaböcek", title: "Artık Sevmeyeceğim", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Banu Kırbağ", title: "Unutulur Masalı", tier: "Bronz", shards: 15, emoji: "🥉" }
];

function fetchJson(url) {
  return new Promise((resolve) => {
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve(null);
        }
      });
    }).on('error', () => resolve(null));
  });
}

async function getArtistImage(name) {
  try {
    const dRes = await fetchJson(`https://api.deezer.com/search/artist?q=${encodeURIComponent(name)}`);
    if (dRes && dRes.data && dRes.data.length > 0) {
      const best = dRes.data[0];
      const img = best.picture_big || best.picture_medium || best.picture;
      if (img && !img.includes('placeholder')) {
        return img;
      }
    }
  } catch (e) {}

  try {
    const itRes = await fetchJson(`https://itunes.apple.com/search?term=${encodeURIComponent(name)}&entity=song&limit=1`);
    if (itRes && itRes.results && itRes.results.length > 0) {
      let art = itRes.results[0].artworkUrl100 || '';
      return art.replace('100x100bb', '600x600bb');
    }
  } catch (e) {}

  return '';
}

async function run() {
  console.log("70ler & 80ler Nostalji rozetleri fotoğrafları çekiliyor...");
  let sqlStatements = [];
  let order = 1;

  for (const item of artists) {
    const id = 'badge_nostalji_' + item.name.toLowerCase()
      .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
      .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
      .replace(/[^a-z0-9]/g, '_');
    const imgUrl = await getArtistImage(item.name);
    console.log(`[${order}/${artists.length}] ${item.name} -> ${imgUrl ? 'OK' : 'Resim Yok'}`);

    const safeTitle = item.title.replace(/'/g, "''");
    const safeName = item.name.replace(/'/g, "''");
    sqlStatements.push(
      `INSERT OR REPLACE INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order, is_active) VALUES ('${id}', 'nostalji_tr', '${safeName}', '${safeTitle}', '${item.tier}', ${item.shards}, '${item.emoji}', '${imgUrl}', ${order}, 1);`
    );
    order++;
  }

  const fullSql = sqlStatements.join('\n');
  fs.writeFileSync('badges_nostalji.sql', fullSql, 'utf8');
  console.log("badges_nostalji.sql oluşturuldu!");
}

run();
