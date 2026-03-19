/** Alert category code → Hebrew label */
export const ALERT_CATEGORIES = {
  1: 'ירי רקטות וטילים',
  2: 'חדירת כלי טיס עוין',
  3: 'רעידת אדמה',
  4: 'צונמי',
  5: 'אירוע חומרים מסוכנים',
  6: 'התרעה עירונית',
  13: 'איום טרור',
}

export function alertCategoryLabel(cat) {
  return ALERT_CATEGORIES[cat] ?? 'התרעה'
}

/** Format a Date as HH:MM:SS (24h) */
export function formatTime(date) {
  return date.toLocaleTimeString('he-IL', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  })
}

/** Format a Date as "יום שלישי, 19 במרץ 2026" */
export function formatDate(date) {
  return date.toLocaleDateString('he-IL', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
}
