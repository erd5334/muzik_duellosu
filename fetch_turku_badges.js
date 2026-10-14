const https = require('https');
const fs = require('fs');

const artists = [
  { name: "Aşık Veysel", title: "Uzun İnce Yolun Piri", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Neşet Ertaş", title: "Bozkırın Tezenesi", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Aşık Mahzuni Şerif", title: "İşte Gidiyorum", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Muharrem Ertaş", title: "Zahidem Ustası", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Ruhi Su", title: "Mahsus Mahal", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Selda Bağcan", title: "Yalan Dünya Sesi", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Musa Eroğlu", title: "Mihriban Nefesi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Arif Sağ", title: "İnsan Olmaya Geldim", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Muhlis Akarsu", title: "Karlı Dağlar", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Ali Ekber Çiçek", title: "Haydar Haydar Üstadı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Erkan Oğur", title: "Perdesiz Bağlama Ruhu", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Sabahat Akkiraz", title: "Semahların Avazı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Belkıs Akkale", title: "Türkülerin Bacısı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Erdal Erzincan", title: "Turnalar Semahı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Güler Duman", title: "Ne Ağlarsın", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Zara", title: "Türküler Dolusu", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Bedia Akartürk", title: "Kesik Çayır Sesi", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Kıvırcık Ali", title: "Isırgan Otu Hüznü", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Cengiz Özkan", title: "Kırmızı Gül", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Özay Gönlüm", title: "Denizli Horozu", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Grup Abdal", title: "Nem Kaldı", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Yavuz Bingöl", title: "Sarı Gelin", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Tolga Çandar", title: "Ege Türküleri Ozanı", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Hasret Gültekin", title: "Derman Sendedir", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Hüseyin Turan", title: "Kirvem", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Ender Balkır", title: "Ahirim Sensin", tier: "Bronz", shards: 15, emoji: "🥉" }
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
  console.log("Türküler & Ozanlar rozetleri fotoğrafları çekiliyor...");
  let sqlStatements = [];
  let order = 1;

  for (const item of artists) {
    const id = 'badge_turku_' + item.name.toLowerCase()
      .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
      .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
      .replace(/[^a-z0-9]/g, '_');
    const imgUrl = await getArtistImage(item.name);
    console.log(`[${order}/${artists.length}] ${item.name} -> ${imgUrl ? 'OK' : 'Resim Yok'}`);

    const safeTitle = item.title.replace(/'/g, "''");
    const safeName = item.name.replace(/'/g, "''");
    sqlStatements.push(
      `INSERT OR REPLACE INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order, is_active) VALUES ('${id}', 'turku_tr', '${safeName}', '${safeTitle}', '${item.tier}', ${item.shards}, '${item.emoji}', '${imgUrl}', ${order}, 1);`
    );
    order++;
  }

  const fullSql = sqlStatements.join('\n');
  fs.writeFileSync('badges_turku.sql', fullSql, 'utf8');
  console.log("badges_turku.sql oluşturuldu!");
}

run();
