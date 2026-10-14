const https = require('https');
const fs = require('fs');

const artists = [
  { name: "Müslüm Gürses", title: "Müslüm Baba", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "İbrahim Tatlıses", title: "İmparator", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Ferdi Tayfur", title: "Batan Güneş Kralı", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Orhan Gencebay", title: "Batsın Bu Dünya Atası", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Cengiz Kurtoğlu", title: "Duyanlara Duymayanlara", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Bergen", title: "Acıların Kadını", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Azer Bülbül", title: "Titrek Ses Titremesi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Kibariye", title: "Lafı mı Olur", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Güllü", title: "Kasımpaşalı Diva", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Ebru Gündeş", title: "Fırtınalar Sesi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Hakan Taşıyan", title: "Güz Gülleri", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Ümit Besen", title: "Nikah Masası Efendisi", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Ceylan", title: "Küçük Ceylan Fırtınası", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Hakkı Bulut", title: "İkimiz Bir Fidanız", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Emrah", title: "Ayrılamam Hüznü", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Coşkun Sabah", title: "Anılar Klasiği", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Arif Susam", title: "Taverna Ustası", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Mahsun Kırmızıgül", title: "Belalım Ağıtı", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Ebru Yaşar", title: "Seni Anan Doğurmuş", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Selahattin Özdemir", title: "Bir Kulum İşte", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Hakan Altun", title: "Telefonun Başında", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Gökhan Güney", title: "Tanrı İstemezse", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Kamuran Akkor", title: "Bir Ateşe Attın Beni", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Cansever", title: "Kime Bu İnat", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Mine Koşan", title: "Dert Bende", tier: "Bronz", shards: 15, emoji: "🥉" }
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
  console.log("Damar & Arabesk rozetleri fotoğrafları çekiliyor...");
  let sqlStatements = [];
  let order = 1;

  for (const item of artists) {
    const id = 'badge_arabesk_' + item.name.toLowerCase()
      .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
      .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
      .replace(/[^a-z0-9]/g, '_');
    const imgUrl = await getArtistImage(item.name);
    console.log(`[${order}/${artists.length}] ${item.name} -> ${imgUrl ? 'OK' : 'Resim Yok'}`);

    const safeTitle = item.title.replace(/'/g, "''");
    const safeName = item.name.replace(/'/g, "''");
    sqlStatements.push(
      `INSERT OR REPLACE INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order, is_active) VALUES ('${id}', 'arabesk_tr', '${safeName}', '${safeTitle}', '${item.tier}', ${item.shards}, '${item.emoji}', '${imgUrl}', ${order}, 1);`
    );
    order++;
  }

  const fullSql = sqlStatements.join('\n');
  fs.writeFileSync('badges_arabesk.sql', fullSql, 'utf8');
  console.log("badges_arabesk.sql oluşturuldu!");
}

run();
