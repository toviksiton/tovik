import { ref, onMounted, onUnmounted } from 'vue'
import { formatTime, formatDate } from '../utils/formatters.js'

export function useClock() {
  const timeStr = ref('')
  const dateStr = ref('')

  function tick() {
    const now = new Date()
    timeStr.value = formatTime(now)
    dateStr.value = formatDate(now)
  }

  let timer
  onMounted(() => {
    tick()
    // 500ms to avoid missing a second due to drift
    timer = setInterval(tick, 500)
  })
  onUnmounted(() => clearInterval(timer))

  return { timeStr, dateStr }
}
