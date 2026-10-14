const https = require('https');
const { execSync } = require('child_process');

const artists = [
  { name: "Tarkan", title: "Megastar", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Sezen Aksu", title: "Minik Serçe", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Yıldız Tilbe", title: "Delikanlım Ruhu", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Kenan Doğulu", title: "Popun Çapkın Prensi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Sertab Erener", title: "Ateşle Barut Divası", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Mustafa Sandal", title: "Onun Arabası Var", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Levent Yüksel", title: "Med Cezir Sesi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Aşkın Nur Yengi", title: "Sevgiliye Masallar", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Serdar Ortaç", title: "Karabiberim Çılgını", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Harun Kolçak", title: "Gir Kanıma Klasiği", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Yonca Evcimik", title: "Abone Kraliçesi", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Burak Kut", title: "Çılgın Bebek", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Çelik", title: "Hercai", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Mirkelam", title: "Koşan Adam", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Tayfun Duygulu", title: "Hadi Yine İyisin", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Hakan Peker", title: "Bir Efsane Ateşi", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Ozan Orhon", title: "Saman Alevi Fırtınası", tier: "Bronz", shards: 15, emoji: "🥉" }
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
  // 1. Deezer
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

  // 2. iTunes
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
  console.log("Rozet fotoğrafları çekiliyor...");
  let sqlStatements = [];
  let order = 1;

  for (const item of artists) {
    const id = 'badge_pop_' + item.name.toLowerCase()
      .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
      .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
      .replace(/[^a-z0-9]/g, '_');
    const imgUrl = await getArtistImage(item.name);
    console.log(`[${order}/${artists.length}] ${item.name} -> ${imgUrl ? 'OK' : 'Resim Yok'}`);

    const safeTitle = item.title.replace(/'/g, "''");
    const safeName = item.name.replace(/'/g, "''");
    sqlStatements.push(
      `INSERT OR REPLACE INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order, is_active) VALUES ('${id}', 'pop_90s', '${safeName}', '${safeTitle}', '${item.tier}', ${item.shards}, '${item.emoji}', '${imgUrl}', ${order}, 1);`
    );
    order++;
  }

  const fullSql = sqlStatements.join('\n');
  const fs = require('fs');
  fs.writeFileSync('badges_pop.sql', fullSql, 'utf8');
  console.log("badges_pop.sql oluşturuldu!");
}

run();
