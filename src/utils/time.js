export function timeAgo(iso) {
  if (!iso) return "";
  const minutes = Math.floor((Date.now() - new Date(iso).getTime()) / 60000);
  if (minutes < 1) return "just now";
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} h ago`;
  return `${Math.floor(hours / 24)} d ago`;
}

export const STALE_AFTER_MINUTES = 30;

export const isStale = (iso) => !iso || Date.now() - new Date(iso).getTime() > STALE_AFTER_MINUTES * 60000;