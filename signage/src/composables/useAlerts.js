import { ref, computed, isRef, onMounted, onUnmounted } from 'vue'
import { alertCategoryLabel } from '../utils/formatters.js'

/** config may be a plain object or a Vue ref wrapping one */
function getConfig(config) {
  return isRef(config) ? config.value : (config ?? {})
}

export function useAlerts(config) {
  const activeAlerts = ref([])    // array of location strings
  const alertTitle   = ref('')
  const alertCat     = ref(null)
  const lastUpdated  = ref(null)
  const fetchError   = ref('')

  const isActive = computed(() => activeAlerts.value.length > 0)

  let audio = null
  let prevAlertId = null
  let audioInitialized = false

  function ensureAudio() {
    if (audioInitialized) return
    const cfg = getConfig(config)
    if (cfg?.alerts?.audioEnabled !== false) {
      const src = cfg?.alerts?.audioFile ?? '/alert.mp3'
      audio = new Audio(src)
      audio.loop = false
    }
    audioInitialized = true
  }

  async function poll() {
    try {
      const res = await fetch('/api/alerts', {
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        cache: 'no-store',
      })

      const text = await res.text()

      // Empty response = no active alerts
      if (!text || text.trim() === '' || text.trim() === 'null') {
        activeAlerts.value = []
        alertTitle.value   = ''
        alertCat.value     = null
        prevAlertId        = null
        lastUpdated.value  = new Date()
        fetchError.value   = ''
        return
      }

      const data = JSON.parse(text)
      const newId = data.id

      // New alert: play sound
      if (newId && newId !== prevAlertId) {
        prevAlertId = newId
        ensureAudio()
        if (audio) {
          audio.currentTime = 0
          audio.play().catch(() => {})
        }
      }

      activeAlerts.value = Array.isArray(data.data) ? data.data : []
      alertTitle.value   = data.title ?? alertCategoryLabel(data.cat)
      alertCat.value     = data.cat ?? null
      lastUpdated.value  = new Date()
      fetchError.value   = ''
    } catch (err) {
      fetchError.value = err.message
    }
  }

  let timer
  onMounted(() => {
    poll()
    const cfg = getConfig(config)
    const interval = cfg?.alertPollMs ?? 5000
    timer = setInterval(poll, interval)
  })
  onUnmounted(() => clearInterval(timer))

  return { isActive, activeAlerts, alertTitle, alertCat, lastUpdated, fetchError }
}
