const https = require('https');
const fs = require('fs');

const artists = [
  { name: "Hande Yener", title: "Kırmızı Dönemi", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Demet Akalın", title: "Giderli Hit Kraliçesi", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Gülşen", title: "Of Of Fırtınası", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Yalın", title: "Zalim Romantiği", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Kenan Doğulu", title: "Çakkıdı & Shake It Up", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Murat Boz", title: "Aşkı Bulamam Ben", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Gökhan Özen", title: "Aramazsan Arama", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Göksel", title: "Depresyondayım Ruhu", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Emre Aydın", title: "Afili Yalnızlık", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Sıla", title: "Dan Sonra Çıkışı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Hadise", title: "Düm Tek Tek", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Athena", title: "For Real Coşkusu", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Bengü", title: "Korkma Kalbim", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Funda Arar", title: "Yak Gel", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Rafet El Roman", title: "Sürgün Romantiği", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Nil Karaibrahimgil", title: "Bütün Kızlar Toplandık", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Pinhani", title: "Hele Bi Gel", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Grup Hepsi", title: "Olmaz Oğlan", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "İsmail YK", title: "Şappur Şuppur Olayı", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Davut Güloğlu", title: "Nurcanım Coşkusu", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Keremcem", title: "Aşk Bitti", tier: "Bronz", shards: 15, emoji: "🥉" }
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
  console.log("2000ler Hit fotoğrafları çekiliyor...");
  let sqlStatements = [];
  let order = 1;

  for (const item of artists) {
    const id = 'badge_2000s_' + item.name.toLowerCase()
      .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
      .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
      .replace(/[^a-z0-9]/g, '_');
    const imgUrl = await getArtistImage(item.name);
    console.log(`[${order}/${artists.length}] ${item.name} -> ${imgUrl ? 'OK' : 'Resim Yok'}`);

    const safeTitle = item.title.replace(/'/g, "''");
    const safeName = item.name.replace(/'/g, "''");
    sqlStatements.push(
      `INSERT OR REPLACE INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order, is_active) VALUES ('${id}', 'hit_2000s', '${safeName}', '${safeTitle}', '${item.tier}', ${item.shards}, '${item.emoji}', '${imgUrl}', ${order}, 1);`
    );
    order++;
  }

  const fullSql = sqlStatements.join('\n');
  fs.writeFileSync('badges_2000s.sql', fullSql, 'utf8');
  console.log("badges_2000s.sql oluşturuldu!");
}

run();
