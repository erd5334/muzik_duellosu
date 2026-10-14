const https = require('https');
const fs = require('fs');

const artists = [
  { name: "Ceza", title: "Holocaust Hız Ustası", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Sagopa Kajmer", title: "Bir Pesimistin Gözyaşı", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Ezhel", title: "Geceler Şehri", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Cartel", title: "Bir Numara Öncüsü", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Norm Ender", title: "Mekanın Sahibi", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Fuat Ergin", title: "Omurga Rap Üstadı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Şanışer", title: "Susamam Sesi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Gazapizm", title: "Heyecanı Yok", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Şehinşah", title: "Karma Akımı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Uzi", title: "Krvn Rüzgarı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Motive", title: "10MG Ustası", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Sefo", title: "Bilmem Mi Çıkışı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "BLOK3", title: "Vur Fırtınası", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Lvbel C5", title: "Dacia Hiti", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Allâme", title: "Batarya Komutanı", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Hayki", title: "B1R Çığlığı", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Contra", title: "Ölü Efsanesi", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Defkhan", title: "Akrep Sözler", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "No.1", title: "Canımız Cehenneme", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Ben Fero", title: "Biladerim İçin", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Çakal", title: "İmdat ve Lütfen", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Hidra", title: "Ölüme İnat", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Sansar Salvo", title: "180 KM", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Joker", title: "Yaşamak Öldürür", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Ati242", title: "Değişmene Rağmen", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Dr. Fuchs", title: "İstanbul Gecesi", tier: "Bronz", shards: 15, emoji: "🥉" }
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
  console.log("Türkçe Rap rozetleri fotoğrafları çekiliyor...");
  let sqlStatements = [];
  let order = 1;

  for (const item of artists) {
    const id = 'badge_rap_' + item.name.toLowerCase()
      .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
      .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
      .replace(/[^a-z0-9]/g, '_');
    const imgUrl = await getArtistImage(item.name);
    console.log(`[${order}/${artists.length}] ${item.name} -> ${imgUrl ? 'OK' : 'Resim Yok'}`);

    const safeTitle = item.title.replace(/'/g, "''");
    const safeName = item.name.replace(/'/g, "''");
    sqlStatements.push(
      `INSERT OR REPLACE INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order, is_active) VALUES ('${id}', 'rap_tr', '${safeName}', '${safeTitle}', '${item.tier}', ${item.shards}, '${item.emoji}', '${imgUrl}', ${order}, 1);`
    );
    order++;
  }

  const fullSql = sqlStatements.join('\n');
  fs.writeFileSync('badges_rap.sql', fullSql, 'utf8');
  console.log("badges_rap.sql oluşturuldu!");
}

run();
