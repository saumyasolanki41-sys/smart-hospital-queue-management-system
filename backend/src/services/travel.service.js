const routes = new Map();
const weather = new Map();

function remember(cache, key, value, milliseconds) {
  if (cache.size >= 200) cache.clear();
  cache.set(key, { value, expiresAt: Date.now() + milliseconds });
  return value;
}

async function roadRoute(from, to) {
  const apiKey = process.env.OPENROUTESERVICE_API_KEY?.trim();
  if (!apiKey) return { reason: 'routing_not_configured' };
  const key = JSON.stringify([from.longitude, from.latitude, to.longitude, to.latitude]);
  const saved = routes.get(key);
  if (saved && saved.expiresAt > Date.now()) return saved.value;
  try {
    const response = await fetch('https://api.heigit.org/openrouteservice/v2/directions/driving-car', {
      method: 'POST', redirect: 'error', signal: AbortSignal.timeout(5000),
      headers: { Authorization: apiKey, 'Content-Type': 'application/json' },
      body: JSON.stringify({ coordinates: [[from.longitude, from.latitude], [to.longitude, to.latitude]] }),
    });
    if (!response.ok) return { reason: 'routing_unavailable' };
    const summary = (await response.json())?.routes?.[0]?.summary;
    if (typeof summary?.distance !== 'number' || !Number.isFinite(summary.distance) || summary.distance < 0 ||
        typeof summary?.duration !== 'number' || !Number.isFinite(summary.duration) || summary.duration < 0) {
      return { reason: 'routing_invalid_response' };
    }
    return remember(routes, key, { distanceKm: summary.distance / 1000, routeMinutes: summary.duration / 60 }, 60000);
  } catch { return { reason: 'routing_unavailable' }; }
}

async function pickupWeather(location) {
  const key = `${location.latitude.toFixed(3)},${location.longitude.toFixed(3)}`;
  const saved = weather.get(key);
  if (saved && saved.expiresAt > Date.now()) return saved.value;
  try {
    const url = new URL('https://api.open-meteo.com/v1/forecast');
    url.search = new URLSearchParams({ latitude: location.latitude, longitude: location.longitude,
      current: 'weather_code', timeformat: 'unixtime', timezone: 'UTC' }).toString();
    const response = await fetch(url, { redirect: 'error', signal: AbortSignal.timeout(5000) });
    if (!response.ok) return { reason: 'weather_unavailable' };
    const current = (await response.json())?.current;
    if (typeof current?.time !== 'number' || !Number.isFinite(current.time) ||
        Math.abs(Date.now() - current.time * 1000) > 60 * 60000) return { reason: 'weather_stale' };
    const code = current.weather_code;
    let severity;
    if ([0, 1, 2, 3].includes(code)) severity = 0;
    else if ([51, 53, 55, 61, 63, 65, 80, 81, 82].includes(code)) severity = 1;
    else if ([95, 96, 99].includes(code)) severity = 2;
    else return { reason: 'weather_unsupported' };
    return remember(weather, key, { severity, impact: severity, code, time: new Date(current.time * 1000) }, 5 * 60000);
  } catch { return { reason: 'weather_unavailable' }; }
}

module.exports = { roadRoute, pickupWeather };
