const https = require('https');
const fs = require('fs');

const artists = [
  { name: "Barış Manço", title: "Dönence Ozanı", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Cem Karaca", title: "Tamirci Çırağı", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Erkin Koray", title: "Rock'ın Babası", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "MFÖ", title: "Ele Güne Karşı", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Şebnem Ferah", title: "Rock Kraliçesi", tier: "Elmas", shards: 60, emoji: "💎" },
  { name: "Duman", title: "Köprüaltı Ruhu", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Teoman", title: "Paramparça Ozanı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Mor ve Ötesi", title: "Bir Derdim Var", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Barış Akarsu", title: "Islak Islak", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Haluk Levent", title: "Yollarda Bulur Seni", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Moğollar", title: "Anadolu Rock Çınarı", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "maNga", title: "Bir Kadın Çizeceksin", tier: "Altın", shards: 45, emoji: "🥇" },
  { name: "Fikret Kızılok", title: "Zamanın Gönül Kuşu", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Kıraç", title: "Dağlar Başı Fırtınası", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Pentagram", title: "Anatolia Efsanesi", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Özlem Tekin", title: "Dağları Deldim", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Bulutsuzluk Özlemi", title: "Sözlerimi Geri Alamam", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Ayna", title: "Akdeniz Rüzgarı", tier: "Gümüş", shards: 30, emoji: "🥈" },
  { name: "Murat Kekilli", title: "Bu Akşam Ölürüm", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Feridun Düzağaç", title: "Dipteyim Sondayım", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Kurban", title: "Sarı Çizmeli İsyankar", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Ogün Sanlısoy", title: "Korkma", tier: "Bronz", shards: 15, emoji: "🥉" },
  { name: "Yüksek Sadakat", title: "Belki Kuş Geçer", tier: "Bronz", shards: 15, emoji: "🥉" }
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
  console.log("Rock rozetleri fotoğrafları çekiliyor...");
  let sqlStatements = [];
  let order = 1;

  for (const item of artists) {
    const id = 'badge_rock_' + item.name.toLowerCase()
      .replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's')
      .replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ç/g, 'c')
      .replace(/[^a-z0-9]/g, '_');
    const imgUrl = await getArtistImage(item.name);
    console.log(`[${order}/${artists.length}] ${item.name} -> ${imgUrl ? 'OK' : 'Resim Yok'}`);

    const safeTitle = item.title.replace(/'/g, "''");
    const safeName = item.name.replace(/'/g, "''");
    sqlStatements.push(
      `INSERT OR REPLACE INTO badges (id, category_id, artist_name, title, tier, total_shards, emoji, image_url, display_order, is_active) VALUES ('${id}', 'rock_tr', '${safeName}', '${safeTitle}', '${item.tier}', ${item.shards}, '${item.emoji}', '${imgUrl}', ${order}, 1);`
    );
    order++;
  }

  const fullSql = sqlStatements.join('\n');
  fs.writeFileSync('badges_rock.sql', fullSql, 'utf8');
  console.log("badges_rock.sql oluşturuldu!");
}

run();
