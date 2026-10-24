const { DatabaseSync } = require('node:sqlite');
const path = require('path');
const db = new DatabaseSync(path.join(__dirname, 'database.sqlite'));

const data = {
  seasonId: 'season_1',
  seasonName: "Sezon 1: 90'lar Fırtınası",
  endDate: new Date(Date.now() + 28 * 24 * 3600 * 1000).toISOString(),
  missions: [
    { id: 'daily_matches_3', title: 'Sahneye Çık', description: '3 müzik düellosu tamamla', category: 'daily', actionKey: 'complete_match', target: 3, xpReward: 120, rewardType: 'energy', rewardAmount: 3, icon: '🎤' },
    { id: 'daily_win_1', title: 'Günün Yıldızı', description: 'Herhangi bir kategoride 1 galibiyet al', category: 'daily', actionKey: 'win_match', target: 1, xpReward: 150, rewardType: 'coins', rewardAmount: 75, icon: '⭐' },
    { id: 'daily_fast_2', title: 'Hızlı Refleks', description: '2 şarkıyı 3 saniyenin altında doğru bil', category: 'daily', actionKey: 'fast_answer', target: 2, xpReward: 130, rewardType: 'joker', rewardAmount: 1, icon: '⚡' },
    { id: 'weekly_wins_10', title: 'Seri Galip', description: 'Hafta boyunca toplam 10 düello kazan', category: 'weekly', actionKey: 'win_match', target: 10, xpReward: 600, rewardType: 'coins', rewardAmount: 250, icon: '🔥' },
    { id: 'weekly_pop90s_5', title: '90’lar Rüzgarı', description: "90'lar Pop kategorisinde 5 galibiyet elde et", category: 'weekly', actionKey: 'category_win', filterCategory: 'pop_90s', target: 5, xpReward: 500, rewardType: 'shard', rewardAmount: 15, icon: '📻' },
    { id: 'season_total_50', title: 'Sahne Efsanesi', description: 'Sezon boyunca 50 düello kazan', category: 'seasonal', actionKey: 'win_match', target: 50, xpReward: 2500, rewardType: 'shard', rewardAmount: 45, icon: '👑' }
  ],
  tiers: Array.from({ length: 20 }, (_, i) => ({
    level: i + 1,
    requiredXp: 250,
    freeReward: { type: 'coins', amount: 150 + (i * 10), title: (150 + (i * 10)) + ' Altın', icon: '🪙' },
    goldReward: { type: i === 19 ? 'shard' : 'joker', amount: i === 19 ? 50 : 2, title: i === 19 ? 'Efsanevi Plak Tacı & 50 Plak' : '2x Joker Paketi', icon: i === 19 ? '👑' : '✨' }
  }))
};

db.prepare('CREATE TABLE IF NOT EXISTS season_pass (id TEXT PRIMARY KEY, data_json TEXT, updated_at INTEGER)').run();
db.prepare('INSERT OR REPLACE INTO season_pass (id, data_json, updated_at) VALUES (?, ?, ?)').run('active_season', JSON.stringify(data), Date.now());
console.log('Sezon Pass verisi veritabanına başarıyla yazıldı!');
