const cache = new Map();

async function predict(path, payload, field, fallback) {
  const base = process.env.ML_SERVICE_URL?.trim();
  if (!base) return { minutes: fallback, source: 'fallback', reason: 'ml_not_configured' };
  const key = JSON.stringify([base, path, payload]);
  const saved = cache.get(key);
  if (saved && saved.expiresAt > Date.now()) return saved.result;
  let reason = 'ml_unavailable';
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const url = new URL(base);
      if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) break;
      url.pathname = path;
      url.search = '';
      url.hash = '';
      const response = await fetch(url, {
        method: 'POST', redirect: 'error', signal: AbortSignal.timeout(4000),
        headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload),
      });
      if (!response.ok) {
        if (response.status >= 500 && attempt === 0) continue;
        reason = response.status < 500 ? 'ml_rejected_input' : 'ml_unavailable';
        break;
      }
      const data = await response.json();
      const minutes = data?.[field];
      if (typeof minutes !== 'number' || !Number.isFinite(minutes) || minutes < 0 || minutes > 10080) {
        reason = 'ml_invalid_response';
        break;
      }
      const result = { minutes: Math.round(minutes * 100) / 100, source: 'ml', reason: null };
      if (cache.size >= 200) cache.clear();
      cache.set(key, { expiresAt: Date.now() + 10000, result });
      return result;
    } catch {
      if (attempt === 1) break;
    }
  }
  return { minutes: fallback, source: 'fallback', reason };
}

function clinicTime() {
  const time = new Date(Date.now() + 330 * 60000);
  return { hour: time.getUTCHours(), day: (time.getUTCDay() + 6) % 7 };
}

module.exports = { predict, clinicTime };
