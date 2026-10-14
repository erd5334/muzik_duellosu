const https = require('https');
const fs = require('fs');

const artists = [
  { name: "Mabel Matiz", title: "Antidepresan Büyücüsü", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Edis", title: "Çok Çok Fenomeni", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Simge", title: "Aşkın Olayım Fırtınası", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Melike Şahin", title: "Diva Yorgun", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Mert Demir", title: "Ateşe Düştüm", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Emir Can İğrek", title: "Ali Cabbar Ağıtı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Zeynep Bastık", title: "Uslanmıyor Bu", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Madrigal", title: "Seni Dert Etmeler", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Yüzyüzeyken Konuşuruz", title: "Dinle Beni Bi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "İrem Derici", title: "Kalbimin Tek Sahibine", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Semicenk", title: "Düşer Aklıma", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Gökhan Türkmen", title: "Çatı Katı Sesi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Derya Uluğ", title: "Okyanus Dalgası", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "KÖFN", title: "Bi Tek Ben Anlarım", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Adamlar", title: "Rüyalarda Buruşmuşuz", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Aleyna Tilki", title: "Cevapsız Çınlama", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "İlyas Yalçıntaş", title: "İncir Ağacı Ruhu", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Mustafa Ceceli", title: "Limon Çiçekleri", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Can Bonomo", title: "Meczup Coşkusu", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Kalben", title: "Sadece", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Dolu Kadehi Ters Tut", title: "Gitme Masalı", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Canozan", title: "Sar Bu Şehri", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Bilal Sonses", title: "İki Kelime", tier: "Bronz", shards: 15, emoji: "🥉" }
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
  console.log("2010+ Pop rozetleri fotoğrafları çekiliyor...");
  let sqlStatements = [];
  let order = 1;

  for (const item of artists) {
    const id = 'badge_2010s_' + item.name.toLowerCase()
      .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
      .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
      .replace(/[^a-z0-9]/g, '_');
    const imgUrl = await getArtistImage(item.name);
    console.log(`[${order}/${artists.length}] ${item.name} -> ${imgUrl ? 'OK' : 'Resim Yok'}`);

    const safeTitle = item.title.replace(/'/g, "''");
    const safeName = item.name.replace(/'/g, "''");
    sqlStatements.push(
      `INSERT OR REPLACE INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order, is_active) VALUES ('${id}', 'pop_2010s', '${safeName}', '${safeTitle}', '${item.tier}', ${item.shards}, '${item.emoji}', '${imgUrl}', ${order}, 1);`
    );
    order++;
  }

  const fullSql = sqlStatements.join('\n');
  fs.writeFileSync('badges_2010s.sql', fullSql, 'utf8');
  console.log("badges_2010s.sql oluşturuldu!");
}

run();
