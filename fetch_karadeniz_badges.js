const https = require('https');
const fs = require('fs');

const artists = [
  { name: "Kazım Koyuncu", title: "Şair Ceketli Çocuk", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Volkan Konak", title: "Kuzeyin Oğlu", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Erkan Ocaklı", title: "Karadeniz Türkülerinin Babası", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Kamil Sönmez", title: "Fadime'nin Düğünü", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "İsmail Türüt", title: "Hızlı Horon Ustası", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Resul Dindar", title: "Nayino Sevdası", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Selçuk Balcı", title: "Ayrılamam Ağıtı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Ekin Uzunlar", title: "Hüznün Gemileri", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Karmate", title: "Nayino Rüzgarı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Şevval Sam", title: "Karadeniz Gözdesi", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Hülya Polat", title: "Koçari Neşesi", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Zeynep Başkan", title: "Oy Asiye", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Sinan Yılmaz", title: "Kolbastı Ruhu", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Cimilli İbo", title: "Oy Oy Trabzon", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Apolas Lermi", title: "Mektup Ezgisi", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Gökhan Birben", title: "Hey Gidi Karadeniz", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Sait Uçar", title: "Yalancı Dünya Feryadı", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Recebim", title: "Kemençem", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Bizim Gönül", title: "Çaykara Güzeli", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Niyazi Koyuncu", title: "Hayde", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Ayhan Alptekin", title: "Oy Sevduğum", tier: "Bronz", shards: 15, emoji: "🥉" }
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
  console.log("Karadeniz rozetleri fotoğrafları çekiliyor...");
  let sqlStatements = [];
  let order = 1;

  for (const item of artists) {
    const id = 'badge_karadeniz_' + item.name.toLowerCase()
      .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
      .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
      .replace(/[^a-z0-9]/g, '_');
    const imgUrl = await getArtistImage(item.name);
    console.log(`[${order}/${artists.length}] ${item.name} -> ${imgUrl ? 'OK' : 'Resim Yok'}`);

    const safeTitle = item.title.replace(/'/g, "''");
    const safeName = item.name.replace(/'/g, "''");
    sqlStatements.push(
      `INSERT OR REPLACE INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order, is_active) VALUES ('${id}', 'cat_1791715274917', '${safeName}', '${safeTitle}', '${item.tier}', ${item.shards}, '${item.emoji}', '${imgUrl}', ${order}, 1);`
    );
    order++;
  }

  const fullSql = sqlStatements.join('\n');
  fs.writeFileSync('badges_karadeniz.sql', fullSql, 'utf8');
  console.log("badges_karadeniz.sql oluşturuldu!");
}

run();
