const https = require('https');
const fs = require('fs');

const categoryId = 'cat_1791816391354';

const artists = [
  { name: "Ahmet Kaya", title: "Kum Gibi Efsanesi", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Selda Bağcan", title: "Adaletin Bu Mu Dünya", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Zülfü Livaneli", title: "Yiğidim Aslanım", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Grup Yorum", title: "Uğurlama Direnişi", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Ahmet Aslan", title: "Minnet Eylemem", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Yeni Türkü", title: "Telli Telli Neşesi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Ezginin Günlüğü", title: "Düşler Sokağı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Bülent Ortaçgil", title: "Eylül Akşamı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Onur Akın", title: "Asi ve Mavi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "İlkay Akkaya", title: "Ah Sensiz Melankolisi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Grup Kızılırmak", title: "Sırdaş Ezgiler", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Nurettin Rençber", title: "Ay Düşünce", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Kardeş Türküler", title: "Doğu Ezgileri", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Suavi", title: "Yalı Çapkını Rüzgarı", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Ferhat Tunç", title: "Vurgunum Sürgünü", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Servet Kocakaya", title: "Keke Feryadı", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Cevdet Bağca", title: "Al Ömrümü", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Grup Munzur", title: "Munzurun Çığlığı", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Aynur Doğan", title: "Keçe Kurdan", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Efkan Şeşen", title: "Dokuz Sekiz Hüznü", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Mehmet Atlı", title: "Dengbêj Ruhu", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Vedat Sakman", title: "Anılar Sokağı", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Rojda", title: "Lê Lê Çıkışı", tier: "Bronz", shards: 15, emoji: "🥉" }
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
  console.log("Özgün Müzik rozetleri fotoğrafları çekiliyor...");
  let sqlStatements = [];
  let order = 1;

  for (const item of artists) {
    const id = 'badge_ozgun_' + item.name.toLowerCase()
      .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
      .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
      .replace(/[^a-z0-9]/g, '_');
    const imgUrl = await getArtistImage(item.name);
    console.log(`[${order}/${artists.length}] ${item.name} -> ${imgUrl ? 'OK' : 'Resim Yok'}`);

    const safeTitle = item.title.replace(/'/g, "''");
    const safeName = item.name.replace(/'/g, "''");
    sqlStatements.push(
      `INSERT OR REPLACE INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order, is_active) VALUES ('${id}', '${categoryId}', '${safeName}', '${safeTitle}', '${item.tier}', ${item.shards}, '${item.emoji}', '${imgUrl}', ${order}, 1);`
    );
    order++;
  }

  const fullSql = sqlStatements.join('\n');
  fs.writeFileSync('badges_ozgun.sql', fullSql, 'utf8');
  console.log("badges_ozgun.sql oluşturuldu!");
}

run();
